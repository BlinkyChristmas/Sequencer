// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class TimeNowController : NSViewController {
    override var nibName: NSNib.Name? {
        return "TimeNowController"
    }
    
    func setTime(time:Double,dotsPerSecond:Double) {
        view.setFrameOrigin(NSPoint(x:time * dotsPerSecond,y:0.0))
    }
    
}
