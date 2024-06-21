// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class EffectController : NSViewController {
    override var nibName: NSNib.Name? {
        return "EffectController"
    }
    var gridColorObserver:NSKeyValueObservation?
    var gridNameObserver:NSKeyValueObservation?
    deinit{
        gridColorObserver?.invalidate()
        gridNameObserver?.invalidate()
        if self.view.superview != nil {
            self.view.removeFromSuperview()
        }
    }
    @objc dynamic var isSelected = false {
        didSet{
            if isSelected {
                self.view.layer?.backgroundColor = settingsData.selectionColor.cgColor
            }
            else {
                self.setColor(gridName: self.effect?.gridName)
            }
        }
    }
    
    @objc dynamic var effect:ItemEffect? {
        willSet{
            gridColorObserver?.invalidate()
            gridColorObserver = nil
            gridNameObserver?.invalidate()
            gridNameObserver = nil
        }
        didSet{
            guard effect != nil else { return }
            gridNameObserver = effect?.observe(\.gridName, changeHandler: { effect, _ in
                self.gridColorObserver?.invalidate()
                self.gridColorObserver = nil
                self.setColor(gridName: effect.gridName)
           })
            
        }
    }
//    @objc dynamic weak var shadowEffect:ItemEffect?
    
    
    func setColor(gridName:String?) {
        if self.view.window?.windowController != nil {
            guard let gridName = gridName else { return }
            let grid = (self.view.window!.windowController as! SequenceController).gridForName(name: gridName)
            if grid == nil {
                if !isSelected {
                    self.view.layer?.backgroundColor = NSColor.red.cgColor
                }
            }
            else {
                if !isSelected {
                    self.view.layer?.backgroundColor = grid!.color.cgColor
                }
                // And register our observer
                gridColorObserver = grid?.observe(\.color, changeHandler: { grid, _ in
                    if !self.isSelected {
                        self.view.layer?.backgroundColor = grid.color.cgColor
                    }
                })
            }
        }
    }
    override var description: String {
        return effect?.description ?? "none"
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.view.window?.windowController != nil else { return }
        
        self.setColor(gridName: effect?.gridName)
    }
    
    func resetFrame(startTime:Int,endTime:Int, dotsPerSecond:Double) {
        let origin = NSPoint(x: startTime.milliSeconds * dotsPerSecond, y: self.view.frame.origin.y)
        let size = NSSize(width: (endTime - startTime).milliSeconds * dotsPerSecond, height: self.view.frame.height)
        self.view.frame = NSRect(origin: origin, size: size)
    }
}

extension EffectController {
    @objc dynamic var settingsData:SettingsData {
        return (NSApp.delegate as! AppDelegate).settingsData
    }
}
