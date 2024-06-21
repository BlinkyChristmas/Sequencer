// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class VisualizationView : NSView {
    
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
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        guard let controller = self.window?.windowController as? VisualizerController else {   return }
        NSColor.black.setFill()
        NSBezierPath.fill(self.bounds)
        guard let data = try? controller.lightFile.frameFor(frameNumber: controller.currentFrame) else {  return }
        guard !controller.visualization.visualItems.isEmpty else {  return }
        if controller.scale != 1.0 {
            (AffineTransform(scale: controller.scale) as NSAffineTransform).set()
        }
        for item in controller.visualization.visualItems {
            item.draw(frame: Array(data[item.offset..<item.offset+item.lightBundle!.count]))
        }
    }
    
}
