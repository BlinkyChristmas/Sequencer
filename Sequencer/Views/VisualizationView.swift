// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class VisualizationView : NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
        self.wantsLayer = true
        self.clipsToBounds = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
        self.wantsLayer = true
        self.clipsToBounds = true
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        guard self.superview?.window?.windowController != nil else { return }
        let controller = self.superview!.window!.windowController! as! VisualizationController
        let origin = controller.visualization!.visualOrigin
        self.window?.setFrameOrigin(origin)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        (self.window?.windowController as? VisualizationController)?.draw(dirtyRect)
    }
}
