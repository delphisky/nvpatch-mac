//
//  ViewController.swift
//  nvpatch-mac
//
//  Created by 崔瑜 on 2018/05/29.
//  Copyright © 2018年 崔瑜. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        txtLog.string = "请将文件拖到此处...\n";
        self.view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL]);
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: Properties
    @IBOutlet weak var txtInfo: NSTextField!
    @IBOutlet weak var btnOpen: NSButton!
    @IBOutlet var txtLog: NSTextView!

    // MARK: Actions
    
    @IBAction func btnOpenClicked(_ sender: NSButton) {
        let opendlg = NSOpenPanel();
        opendlg.allowsMultipleSelection = true;
        opendlg.canChooseDirectories = false;
        opendlg.canChooseFiles = true;
        opendlg.showsTagField = true;
        //opendlg.allowedFileTypes = ["avi", "mp4", "mpeg", "rmvb"];
        
        opendlg.begin(completionHandler: { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                for url in opendlg.urls {
                    self.FileAppend(fileurl: url);
                }
            }
        })
    }
    
    // cuiyu
    private func MsgLogInsert(_ msg: String){
        txtLog.insertText(msg + "\n", replacementRange: NSMakeRange(0, 0));
    }
    
    private func fileSize(filePath: String) -> UInt64 {
        let manager = FileManager.default;
        var fileSize: UInt64 = 0;
        //if manager.fileExists(atPath: filePath) {
        let attr: NSDictionary = try! manager.attributesOfFileSystem(forPath: filePath) as NSDictionary;
        fileSize = attr.fileSize();
        //}
        return fileSize;
        
    }
    
    private func BytesCompare(val1: [UInt8], val2: [UInt8]) -> Bool{
        if val1.count != val2.count{
            return false;
        }
        var r = true;
        for i in 0..<val1.count {
            if val1[i] != val2[i] {
                r = false;
                break;
            }
        }
        return r;
    }
    
    private func UpdateInfo(_ msg: String){
        txtInfo.stringValue = msg;
        txtLog.insertText(msg, replacementRange: NSMakeRange(0, 0));
    }
    
    let StdTag_V00: Data = Data([ 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8 ]);
    let StdTag_V01: Data = Data([ 1, 23, 56, 78, 24, 68, 70, 93, 83, 48, 63, 24, 55, 62, 77, 81 ]);
    
    // 执行 V01 版本第 2 步，将添加了 16 字节结尾 Tag 的文件 size/2 处的 4 字节取反
    private func FilePatch_V01(_ f: FileHandle, _ size: UInt64){
        f.seek(toFileOffset: size / 2);
        var data = f.readData(ofLength: 4);
        for i in 0..<data.count {
            data[i] = ~data[i];
        }
        f.seek(toFileOffset: size / 2);
        f.write(data);
    }
    
    // V00 升级到 V01
    private func FileUpdate_V00_V01(_ f: FileHandle, _ size: UInt64){
        // 1. 修改结尾的 16 字节 Tag
        f.seek(toFileOffset: size - 16);
        f.write(StdTag_V01);
        
        // 2. 1/2 处 4 字节取反
        FilePatch_V01(f, size);

        f.synchronizeFile();
    }
    
    // 原始文件 -> 最新版本
    private func FilePatch(_ f: FileHandle, _ size: UInt64){
        // 1. 追加结尾 16 字节 Tag
        f.seekToEndOfFile();
        f.write(StdTag_V01);
        
        // 2. 1/2 处 4 字节取反
        FilePatch_V01(f, size + 16);

        f.synchronizeFile();
    }
    
    private func FileAppend(fileurl: URL){
        txtInfo.stringValue = "正在处理文件：" + fileurl.lastPathComponent;
        let f = try? FileHandle(forUpdating: fileurl);
        if f == nil {
            MsgLogInsert(fileurl.lastPathComponent + " 打开失败！");
            return ;
        }
        let fileSize = f?.seekToEndOfFile();
        f?.seek(toFileOffset: fileSize! - 16);
        let data = f?.readData(ofLength: 16);
        if data == StdTag_V01 {
            MsgLogInsert(fileurl.lastPathComponent + " 已经处理过！");
        } else if data == StdTag_V00{
            FileUpdate_V00_V01((f)!, fileSize!);
            MsgLogInsert(fileurl.lastPathComponent + " 升级完成 V00->V01！");
        } else {
            FilePatch((f)!, fileSize!);
            MsgLogInsert(fileurl.lastPathComponent + " 处理完成 V01！");
        }
        f?.closeFile();
        txtInfo.stringValue = "处理完成：" + fileurl.lastPathComponent;
    }

}

