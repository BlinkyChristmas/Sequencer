// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit
import UniformTypeIdentifiers
class NewSequenceDialog : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "NewSequenceDialog"
    }
    
    @objc dynamic var musicNames:[String] {
        (NSApp.delegate as! AppDelegate).settingsData.musicFiles.sorted()
    }
    
    @objc dynamic var selectedVisualization: URL?
    @objc dynamic var selectedImport:URL?
    
    @IBAction func selectLocation(_ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 10
        let panel = NSOpenPanel()
        switch tag {
        case 0:
            panel.allowedContentTypes = [.visualization]
            panel.prompt = "Select visualization file"
            panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.visualizationDirectory
            
        case 1:
            panel.allowedContentTypes = [.sequence]
            panel.prompt = "Selection Sequence file"
            panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.sequenceDirectory

        default:
            return
        }
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK,panel.url != nil else { return }
            switch tag {
            case 0:
                self.selectedVisualization = panel.url
            case 1:
                self.selectedImport = panel.url
            default:
                break
            }
        }
    }
    
    @objc dynamic var music:String?
    @IBAction func endDialog(_ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        let response = tag == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
        self.close()
        NSApp.stopModal(withCode: response)
    }
}
