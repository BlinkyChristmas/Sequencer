// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class DetailHolderView : BackgroundView {
    @objc dynamic weak var selectedItem:EffectController?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = [.width,.height]
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.autoresizingMask = [.width,.height]
    }

}
