// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ModifyVisualNameDialog : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "ModifyVisualNameDialog"
    }
    
    @objc dynamic var visualName:String?
    
    @IBAction func endDialog( _ sender: Any?) {
        guard self.window!.makeFirstResponder(sender as! NSControl) else { return }
        let response = (sender as? NSControl)?.tag ?? 0 == 1 ? NSApplication.ModalResponse.OK : NSApplication.ModalResponse.cancel
        self.window!.sheetParent!.endSheet(self.window!, returnCode: response)
    }
    
}
