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
        //opendlg.allowedFileTypes = ["png", "jpg", "bmp", "webp"];
        
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
        //txtLog2.documentView?.insertText("hello\n");
        //txtLog.insertText("hello cuiyu\n");
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
    
    let StdTag: Data = Data([ 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8 ]);
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
        if data == StdTag {
            MsgLogInsert(fileurl.lastPathComponent + " 已经处理过！");
        } else {
            f?.seekToEndOfFile();
            f?.write(StdTag);
            f?.synchronizeFile();
            MsgLogInsert(fileurl.lastPathComponent + " 处理完成！");
        }
        f?.closeFile();
    }

}

