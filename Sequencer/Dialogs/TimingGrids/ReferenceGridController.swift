// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ReferenceGridController   : NSViewController {
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var rvalue = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "gridNames" {
            rvalue.insert("timeGrids")
        }
        return rvalue
    }
    
    override var nibName: NSNib.Name? {
        return "ReferenceGridController"
    }
    @IBAction func setFactorDirection( _ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 0
        shouldReduce = tag == 0 ? true : false
    }
    @objc dynamic var gridNames:[String] {
        guard timeGrids != nil else { return [String]()}
        return timeGrids!.map { $0.name! }.sorted()
    }
    @objc dynamic var timeGrids:[TimeGrid]?
    
    @objc dynamic var selectedTimeGridName:String? {
        didSet{
            selectedTimeGrid = gridForName(name: selectedTimeGridName)
            if selectedTimeGrid == nil {
                self.startTime = 0.0
                self.endTime = 0.0
            }
            else {
                self.startTime = selectedTimeGrid?.findTimeBeforeEqual(milliseconds: startTime.milliSeconds)?.milliSeconds ?? 0.0
                if endTime.milliSeconds != 0 {
                    var temp  = selectedTimeGrid?.findTimeAfterEqual(milliseconds: endTime.milliSeconds) ?? 0
                    if temp <= self.startTime.milliSeconds {
                        temp += 50
                        temp  = selectedTimeGrid?.findTimeAfterEqual(milliseconds: endTime.milliSeconds) ?? 0
                    }
                    self.endTime = temp.milliSeconds
                }
                else {
                    endTime = selectedTimeGrid?.lastTime  ?? 0.0
                }
                
            }
        }
    }
    @objc dynamic var selectedTimeGrid:TimeGrid?
    
    @objc dynamic var startTime = 0.0
    @objc dynamic var endTime = 0.0
    
    @objc dynamic var isEnabled = true {
        didSet{
            for entry in self.view.subviews {
                let control = entry as? NSControl
                if control != nil {
                    control?.isEnabled = isEnabled
                }
            }
        }
    }
    
    @objc dynamic var shouldReduce = false
    @objc dynamic var modificationFactor = 1
    func gridForName(name:String?) -> TimeGrid? {
        guard timeGrids != nil else { return nil }
        guard name != nil else { return nil }
        for entry in timeGrids! {
            if entry.name == name {
                return entry
            }
        }
        return nil
    }
    func timesBasedOnFactor() -> Set<Int> {
        var rvalue = Set<Int>()
        guard selectedTimeGrid != nil else { return rvalue }
        // what time should we use to start
        let ourStart = selectedTimeGrid!.findTimeAfterEqual(milliseconds: startTime.milliSeconds) ?? 0
        let ourEnd = selectedTimeGrid!.findTimeBeforeEqual(milliseconds: endTime.milliSeconds) ?? 0
        guard ourEnd > ourStart else { return rvalue }
        // gather all the times in question
        var candidateEntries = [Int]()
    
        for entry in selectedTimeGrid!.timeEntries.sorted() {
            if entry >= ourStart && entry <= ourEnd {
                candidateEntries.append(entry)
            }
        }
        guard !candidateEntries.isEmpty else { return rvalue}
        if shouldReduce {
            for index in stride(from: 0, to: candidateEntries.count, by: modificationFactor+1) {
                rvalue.insert(candidateEntries[index])
            }
        }
        else {
            if candidateEntries.count > 1 {
                for index in 0..<candidateEntries.count-1 {
                    let start = candidateEntries[index]
                    let end = candidateEntries[index+1]
                    let delta = end - start
                    let increment = delta / (modificationFactor + 1)
                    
                    for factor in 0...modificationFactor {
                        rvalue.insert(start + (factor * increment))
                    }
                }
                rvalue.insert(candidateEntries[candidateEntries.count-1])
            }
            else {
                rvalue.insert(candidateEntries[0])
            }
        }
        return rvalue
    }
    
}
