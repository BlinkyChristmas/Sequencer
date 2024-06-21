// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class TimeGridView    : NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.autoresizingMask = [.width,.height]
        self.autoresizesSubviews = true
   }

    
    override var isFlipped: Bool {
        return true
    }
    
    @IBOutlet weak var timeController:TimeGridController?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        
        guard timeController != nil else { return super.menu(for: event) }
        guard timeController!.isActive && timeController!.isEnabled else {return super.menu(for: event) }
        return timeController!.menu(for: event)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        guard timeController != nil else { return super.acceptsFirstMouse(for: event)}
        if timeController!.isActive && timeController!.isEnabled {
            return true
        }
        return false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard timeController != nil else { return }
        timeController!.draw(dirtyRect)
    }
}
