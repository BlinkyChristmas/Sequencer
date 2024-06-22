// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit
class TimeGridController : NSViewController {
    var dotsPerSecond = BlinkyGlobals.dotsPerSecond {
        didSet{
            drawPath = buildPaths()
            self.view.needsDisplay = true
        }
    }
    var drawPath:NSBezierPath?
    var dashes = [CGFloat(4.0), CGFloat(12.0)]
    var isPlayingObserver:NSKeyValueObservation?
    
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var rvalue = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "isActive" {
            rvalue.insert("timeGrid")
            rvalue.insert("gridNumber")
        }
        return rvalue
    }
    
    override var nibName: NSNib.Name? {
        return "TimeGridController"
    }
    
    var selectedTime:Int?
    var shadowTime:Int?
    var deltaTime:Int?
    var scratchEntries = Set<Double>()
    
    @objc dynamic var isActive:Bool {
        guard timeGrid != nil, gridNumber == 0 else { return false}
        return true ;
    }
    @objc dynamic var isEnabled = false {
        didSet{
            if isEnabled == true && isActive {
                self.view.window?.makeFirstResponder(self)
            }
        }
    }
    @objc dynamic var timeGrid:TimeGrid? {
        didSet{
            refresh()
        }
    }
    func refresh() {
        drawPath = buildPaths()
        self.view.needsDisplay = true

    }
    @objc dynamic var gridNumber = 1
    
    func menu(for event: NSEvent) -> NSMenu? {
        guard isActive,isEnabled else {return nil  }
        return NSMenu(title: "Popup") // We return an empty menu to stop propagation
    }

    func draw(_ dirtyRect: NSRect) {
        guard timeGrid != nil else { return }
        if drawPath == nil {
            drawPath = buildPaths()
        }
        timeGrid!.color.setStroke()
        drawPath?.stroke()
        if selectedTime != nil {
            let path = NSBezierPath()
            let height = self.view.bounds.height
            path.move(to: NSPoint(x: (selectedTime! - deltaTime!).milliSeconds  * dotsPerSecond, y: 0.0))
            path.line(to: NSPoint(x: (selectedTime! - deltaTime!).milliSeconds  * dotsPerSecond, y: height))
            path.lineWidth = 2.0
            path.close()
            (NSApp.delegate as! AppDelegate).settingsData.selectionColor.setStroke()
            path.stroke()
        }
    }
    
    func buildPaths() -> NSBezierPath {
        let path = NSBezierPath()
        guard timeGrid != nil else { return path }
        let height = self.view.bounds.height
        
        for time in timeGrid!.timeEntries.sorted() {
            var skipTime = false
            if selectedTime != nil {
                if time == selectedTime! {
                    if selectedTime! == time {
                        skipTime = true
                    }
                }
            }
            if !skipTime {
                path.move(to: NSPoint(x: time.milliSeconds * dotsPerSecond, y: 0.0))
                path.line(to: NSPoint(x: time.milliSeconds * dotsPerSecond, y: height))
            }
        }
        path.lineWidth = 1.0
        
        path.setLineDash(&dashes, count: 2, phase: CGFloat(gridNumber) * 4.0)
        path.close()
        return path
    }
    
    var enableSpaceBar = false {
        didSet{
            guard timeGrid != nil else { return }
            guard timeGrid!.isScratch  else { return }
            if enableSpaceBar {
                self.view.window?.makeFirstResponder(self)
                (self.view.window?.windowController as!SequenceController).topStatus = "Spacebar Active"

            }
            else {
                (self.view.window?.windowController as!SequenceController).topStatus = nil
                for entry in scratchEntries {
                    timeGrid!.timeEntries.insert(entry.milliSeconds)
                }
                scratchEntries.removeAll()
                self.refresh()
            }
        }
    }
    
    
}

extension TimeGridController {
    
    override var acceptsFirstResponder: Bool {
        guard self.isActive, self.isEnabled else { return false }
        return true
    }
    override func resignFirstResponder() -> Bool {
        if selectedTime != nil {
            selectedTime = nil
            shadowTime = nil
            self.refresh()
        }
        return super.resignFirstResponder()
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        if gridNumber == 0 {
            isPlayingObserver = (self.view.window!.windowController as! SequenceController).musicPlayer.observe(\.isPlaying, changeHandler: { player, _ in
                if self.timeGrid?.isScratch  ?? false && self.isEnabled {
                    if player.isPlaying {
                        self.enableSpaceBar = true
                     }
                    else {
                        self.enableSpaceBar = false
                    }
                }
            })
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        guard self.isActive && self.isEnabled && timeGrid != nil else { self.nextResponder?.mouseDown(with: event); return }
        if self.view.window!.makeFirstResponder(self) {
            let point = self.view.convert(event.locationInWindow, from: nil)
            // See if we have a modifier
            if event.modifierFlags.contains(.command) {
                // we are adding a time
                let time = (point.x / dotsPerSecond).milliSeconds
                (self.view.window!.windowController as! SequenceController).displayMouseTime(time: time.milliSeconds)
                if !timeGrid!.timeEntries.contains(time) {
                    timeGrid?.timeEntries.insert(time)
                    self.refresh()
                    let grid = timeGrid!
                    let seq = (self.view.window!.windowController as! SequenceController).document as! SequenceDocument
                    seq.undoManager?.registerUndo(withTarget: seq, handler: { seq in
                        grid.timeEntries.remove(time);
                        self.refresh()
                    })
                }
                
            }
            else {
                // Did we find a time?
                let time = (point.x / dotsPerSecond).milliSeconds
                let entry = timeGrid?.findTime(milliseconds: time, tolerance: 10)
                if entry != nil {
                    (self.view.window!.windowController as! SequenceController).displayMouseTime(time: entry!.milliSeconds)
                    shadowTime = entry!
                    
                    selectedTime = entry!
                    deltaTime = time - entry!
                    self.refresh()
                }
                else if selectedTime != nil {
                    (self.view.window!.windowController as! SequenceController).displayMouseTime(time: time.milliSeconds)
                    selectedTime = nil
                    shadowTime = nil
                    self.refresh()
                }
                else {
                    (self.view.window!.windowController as! SequenceController).displayMouseTime(time: time.milliSeconds)
                }
                
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard self.isActive && self.isEnabled else { self.nextResponder?.mouseDragged(with: event); return }
        let point = self.view.convert(event.locationInWindow, from: nil)
        let time = (point.x / dotsPerSecond).milliSeconds
        self.view.autoscroll(with: event)
        (self.view.window!.windowController as! SequenceController).displayMouseTime(time: time.milliSeconds)
        if selectedTime != nil {
            selectedTime = time - deltaTime!
            self.view.needsDisplay = true
        }

    }
    override func mouseUp(with event: NSEvent) {
        guard self.isActive && self.isEnabled else { self.nextResponder?.mouseUp(with: event); return }
        let point = self.view.convert(event.locationInWindow, from: nil)
        let time = (point.x / dotsPerSecond).milliSeconds
        let seq = (self.view.window!.windowController as! SequenceController).document as! SequenceDocument
        if selectedTime != nil {
            // we need to modify the time
            let actualTime = selectedTime! - deltaTime!
            let shadow = self.shadowTime!
            if timeGrid!.timeEntries.contains(actualTime) {
                // The time is all ready contained, so we just "delete" the original
                timeGrid!.timeEntries.remove(shadow)
                let grid = timeGrid!
                seq.undoManager?.registerUndo(withTarget: seq, handler: { seq in
                    grid.timeEntries.insert(shadow);
                    self.shadowTime = nil
                    self.selectedTime = nil
                    self.refresh()
                })
            }
            else {
                // It doesn't so we are moving the time
                timeGrid!.timeEntries.remove(shadow)
                timeGrid!.timeEntries.insert(actualTime)
                let grid = timeGrid!
                seq.undoManager?.registerUndo(withTarget: seq, handler: { seq in
                    grid.timeEntries.remove(actualTime);
                    grid.timeEntries.insert(shadow)
                    self.shadowTime = nil
                    self.selectedTime = nil
                    
                    self.refresh()
                })
                shadowTime = time
                selectedTime = time
                self.refresh()
            }
            
            selectedTime = actualTime

        }

    }
    override func keyDown(with event: NSEvent) {
        guard self.isActive && self.isEnabled  else { self.nextResponder?.keyDown(with: event); return }
        let seq = (self.view.window!.windowController as! SequenceController).document as! SequenceDocument
        
        if event.keyCode == Keycode.delete && selectedTime != nil {
            //Swift.print("Removing entry: \(shadowTime!)")
            timeGrid?.timeEntries.remove(shadowTime!)
            timeGrid?.timeEntries.remove(selectedTime!)
            let shadow = shadowTime!
            shadowTime = nil
            selectedTime = nil
            let grid = timeGrid!
            seq.undoManager?.registerUndo(withTarget: seq, handler: { seq in
                grid.timeEntries.insert(shadow);
                self.shadowTime = nil
                self.selectedTime = nil
                (self.view.window?.windowController as? SequenceController)!.gridContainer.refreshViews(withRebuild: true )
            })
            (self.view.window?.windowController as? SequenceController)!.gridContainer.refreshViews(withRebuild: true )
        }
        else if event.keyCode == Keycode.spaceBar && enableSpaceBar {
            
            scratchEntries.insert( (self.view.window!.windowController as! SequenceController).musicPlayer.currentTime)
        }
    }
    override func keyUp(with event: NSEvent) {
        guard self.isActive && self.isEnabled else { self.nextResponder?.keyUp(with: event); return }
    }
    
}
