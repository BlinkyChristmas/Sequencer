// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class DetailItemView : BorderedView {
    
    var tracking:NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if tracking != nil {
            self.removeTrackingArea(tracking!)
        }
        
        let rect = self.bounds
        //rect = NSRect(x: rect.origin.x+1, y: rect.origin.y+1, width: rect.size.width-2, height:rect.size.height-2)
        tracking = NSTrackingArea(rect: rect, options: [.activeInActiveApp,.mouseEnteredAndExited,.inVisibleRect], owner: self, userInfo: nil)
        self.addTrackingArea(tracking!)
    }
    
}
