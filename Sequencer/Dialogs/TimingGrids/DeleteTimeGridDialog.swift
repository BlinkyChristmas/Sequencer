// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class DeleteTimeGridDialog  : NSWindowController {
    
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var rvalue = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "timeGridNames" {
            rvalue.insert("timeGrids")
        }
        return rvalue
    }
    
    override var windowNibName: NSNib.Name? {
        return "DeleteTimeGridDialog"
    }
    
    @objc dynamic var timeGrids:[TimeGrid]?
    @objc dynamic var selectedGrid:String?
    @objc dynamic var timeGridNames:[String]{
        guard timeGrids != nil else { return [String]()}
        return timeGrids!.map{ $0.name!}.sorted()
    }
    @IBAction func endDialog( _ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        let response = tag == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
        self.window!.sheetParent!.endSheet(self.window!, returnCode: response)
    }
}
