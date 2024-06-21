// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class TimeNowView : NSView {
    var timeColorObserver: NSKeyValueObservation?
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.autoresizingMask = [.height]
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.autoresizingMask = [.height]
    }
    deinit {
        timeColorObserver?.invalidate()
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        timeColorObserver?.invalidate()
        timeColorObserver = nil
    }
    
    override func viewDidMoveToWindow() {
        guard self.window != nil else { return }
        self.setFrameSize(NSSize(width: 1.0, height: self.superview!.bounds.height))
        self.layer?.backgroundColor = (NSApp.delegate as! AppDelegate).settingsData.timeNowColor.cgColor
        timeColorObserver = (NSApp.delegate as! AppDelegate).settingsData.observe(\.timeNowColor, changeHandler: { settingsData, _ in
            self.layer?.backgroundColor = settingsData.backgroundColor.cgColor
        })
    }
}
