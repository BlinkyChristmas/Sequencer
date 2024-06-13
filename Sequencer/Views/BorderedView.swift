// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class BorderedView  : BackgroundView {
    var borderObserver:NSKeyValueObservation?
    deinit {
        borderObserver?.invalidate()
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
}
