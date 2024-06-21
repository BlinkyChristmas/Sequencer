// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class BorderedView  : BackgroundView {
    var borderObserver:NSKeyValueObservation?
    deinit {
        borderObserver?.invalidate()
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = .width
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.autoresizingMask = .width
   }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        borderObserver?.invalidate()
        borderObserver = nil
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard self.window != nil else { return }
        self.layer?.borderWidth = 1.0
        self.layer?.borderColor = (NSApp.delegate as! AppDelegate).settingsData.borderColor.cgColor
        borderObserver = (NSApp.delegate as! AppDelegate).settingsData.observe(\.backgroundColor, changeHandler: { settings, _ in
            self.layer?.borderColor = settings.borderColor.cgColor
        })
    }
    
    override var isFlipped: Bool {
        return true
    }
    
    @IBOutlet var itemController:ItemController?
    
    override func menu(for event: NSEvent) -> NSMenu? {
        
        guard itemController != nil else { return super.menu(for: event) }
        return itemController!.menu(for: event)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        guard itemController != nil else { return acceptsFirstMouse(for: event)}
        return true
    }

}
