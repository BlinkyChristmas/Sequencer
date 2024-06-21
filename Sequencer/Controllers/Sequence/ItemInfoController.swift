// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ItemInfoController : NSViewController {
    override var nibName: NSNib.Name? {
        return "ItemInfoController"
    }
    
    @objc dynamic weak var sequenceItem: SeqItem?
    
    @objc dynamic var isExpanded = false
    
}

extension ItemInfoController {
    @objc dynamic var settingsData:SettingsData {
        return (NSApp.delegate as! AppDelegate).settingsData
    }
    
}
