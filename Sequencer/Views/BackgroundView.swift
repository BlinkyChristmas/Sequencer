// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class BackgroundView  : NSView {
    var backgroundObserver:NSKeyValueObservation?
    deinit {
        backgroundObserver?.invalidate()
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.autoresizesSubviews = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.autoresizesSubviews = true
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        backgroundObserver?.invalidate()
        backgroundObserver = nil
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow() 
        guard self.window != nil else { return }
        self.layer?.backgroundColor = (NSApp.delegate as! AppDelegate).settingsData.backgroundColor.cgColor
        backgroundObserver = (NSApp.delegate as! AppDelegate).settingsData.observe(\.backgroundColor, changeHandler: { settings, _ in
            self.layer?.backgroundColor = settings.backgroundColor.cgColor
        })
    }
    
    override var isFlipped: Bool {
        return true 
    }
}
