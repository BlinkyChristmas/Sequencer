// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SequenceVisualController : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "SequenceVisualController"
    }
    @objc dynamic weak var itemManager:ItemManager?
    @objc dynamic var visualName: String?
    var globalScale = 1.0
    @objc dynamic var musicName: String?
    @objc dynamic var currentTime = 0.0 {
        didSet{
            self.window?.contentView?.needsDisplay = true
        }
    }
    var frame:Int {
        Int( ( currentTime / ( Double(BlinkyGlobals.framePeriod) / 1000.0) ).rounded() )
    }
    @objc dynamic weak var masterController:SequenceController? {
        willSet{
            if masterController != nil {
                self.unbind(NSBindingName("currentTime"))
            }
        }
        didSet{
            if masterController != nil {
                self.bind(NSBindingName("currentTime"), to: masterController!.musicPlayer!, withKeyPath: "currentTime")
            }
        }
    }
}

extension SequenceVisualController {
    
    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        return "Visualizer: \(visualName ?? "" ) - \(musicName ?? "")"
    }
    override func windowDidLoad() {
        self.window?.title = "Visualizer: \(visualName ?? "" ) - \(musicName ?? "")"
    }
    func drawView() {
        guard let itemManager = itemManager else { return }
        //var baseTransform = AffineTransform.identity
        var baseTransform: AffineTransform?
        if globalScale != 1.0 {
            baseTransform = AffineTransform(scale: globalScale)
        }
        for controller in itemManager.detailControllers {
            if controller.lightBundle != nil {
                var transform:AffineTransform = .identity
                if controller.sequenceItem!.visualScale != 1.0 {
                    transform.append(AffineTransform(scale: controller.sequenceItem!.visualScale))
                    
                }
                
                if controller.sequenceItem!.visualOrigin != NSPoint.zero {
                    transform.append(AffineTransform(translationByX: controller.sequenceItem!.visualOrigin.x, byY: controller.sequenceItem!.visualOrigin.y))
                }
                //Swift.print(" SequenceItem: \(controller.sequenceItem!.name!) has a scale of \(controller.sequenceItem!.visualScale)")
                
                if baseTransform != nil {
                    transform.append(baseTransform!)
                }
                
                (transform as NSAffineTransform).set()
                if frame < controller.frameData.count {
                    controller.lightBundle!.drawLights(colors: controller.frameData[frame])
                }
            }
        }
    }
}
