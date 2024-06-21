// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class CreateTimeGridDialog : NSWindowController,NSWindowDelegate {
    override var windowNibName: NSNib.Name? {
        return "CreateTimeGridDialog"
    }
    
    @IBOutlet var referenceGridController:ReferenceGridController!
    @objc dynamic var gridName:String?
    @objc dynamic var gridColor = NSColor.white
    @objc dynamic  var timeGrids:[TimeGrid]?
    @IBOutlet var groupBox:NSBox!
    @objc dynamic var referenceEnable = false {
        didSet{
            referenceGridController.isEnabled = referenceEnable
        }
    }
    @IBAction func endDialog( _ sender: Any?) {
        if self.window!.makeFirstResponder( sender as! NSControl) {
            let tag = (sender as? NSControl)?.tag ?? 0
            let rcode =  tag == 0 ? NSApplication.ModalResponse.cancel : NSApplication.ModalResponse.OK
            var shouldExit = true
            if tag == 1 {
                // A few checks to do
                if  referenceGridController.gridForName(name: gridName!) != nil {
                
                    NSAlert(error: GeneralError(errorMessage: "Grid '\(gridName!)' all ready exists")).beginSheetModal(for: self.window!)
                    shouldExit = false
                }
                else if referenceEnable && referenceGridController.selectedTimeGrid == nil {
                    NSAlert(error: GeneralError(errorMessage: "Reference Grid must be selected if enabled")).beginSheetModal(for: self.window!)
                    shouldExit = false

                }
            }
            if shouldExit {
                self.window!.sheetParent?.endSheet(self.window!, returnCode: rcode)
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard groupBox.subviews.count > 0 else { return }
        let groupView = groupBox.subviews[0]
        referenceGridController.view.frame = groupView.bounds
        groupView.addSubview(referenceGridController.view)
        referenceGridController.timeGrids = timeGrids
        referenceGridController.isEnabled = self.referenceEnable
    }
}
