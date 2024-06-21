// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit
import UniformTypeIdentifiers

class ExportLightType : NSObject {
    @objc dynamic var name:String?
    @objc dynamic var offset = 0
    @objc dynamic var count = 0
    
    convenience init(name: String? , offset: Int, count: Int ) {
        self.init()
        self.name = name
        self.offset = offset
        self.count = count 
    }
}

class ExportLightDialog : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "ExportLightDialog"
    }
    @objc dynamic var exportItems = [ExportLightType]()
    @objc dynamic var saveToSequence = false
    @objc dynamic var saveURL:URL?
    
    @IBAction func selectFile(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.lightDirectory
        panel.allowedContentTypes = [UTType.light]
        panel.canCreateDirectories = true
        panel.prompt = "Set light file"
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK, panel.url != nil  else { return }
            self.saveURL = panel.url
        }
    }
    @IBAction func endDialog(_ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        if self.window!.makeFirstResponder(sender as! NSControl) {
            let response = tag == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
            self.window!.sheetParent!.endSheet(self.window!, returnCode: response)
        }
    }
}
