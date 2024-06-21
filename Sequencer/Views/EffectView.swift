// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class EffectView : NSView {
    
    var ourColor:CGColor = CGColor.white{
        didSet{
            self.layer?.backgroundColor = ourColor
        }
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.autoresizingMask = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.autoresizingMask = .none
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.layer?.borderWidth = 1.0
        self.layer?.borderColor = NSColor.darkGray.cgColor
    }

}
