// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ModifyTimingGridDialog : NSWindowController {
    
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var rvalue = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "timeGridNames" {
            rvalue.insert("timeGrids")
        }
        return rvalue
    }

    override var windowNibName: NSNib.Name? {
        return "ModifyTimingGridDialog"
    }
    
    @IBOutlet var referenceGridController:ReferenceGridController!
    @IBOutlet var groupBox:NSBox!

    var shouldAppend = false
    
    @objc dynamic var selectedGrid:String?
    @objc dynamic var timeGrids:[TimeGrid]?
    @objc dynamic var timeGridNames:[String]{
        guard timeGrids != nil else { return [String]()}
        return timeGrids!.map{ $0.name!}.sorted()
    }

    @IBAction func setAppendingStatus( _ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        if tag == 0 {
            self.shouldAppend = false
        }
        else {
            shouldAppend = true
        }
    }
    @IBAction func endDialog( _ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        let response = tag == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
        self.window!.sheetParent!.endSheet(self.window!, returnCode: response)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard groupBox.subviews.count > 0 else { return }
        let groupView = groupBox.subviews[0]
        referenceGridController.view.frame = groupView.bounds
        groupView.addSubview(referenceGridController.view)
        referenceGridController.timeGrids = timeGrids
        referenceGridController.isEnabled = true
    }

}
