// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SequenceVisualizationView : NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.autoresizingMask = [.width,.height]
        self.clipsToBounds = true 
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.autoresizingMask = [.width,.height]
        self.clipsToBounds = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.setFill()
        NSBezierPath.fill(self.bounds)
        guard self.window?.windowController != nil else { return }
        (self.window!.windowController as! SequenceVisualController).drawView() 
    }
}
