// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class CreateEffectDialog : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "CreateEffectDialog"
    }
    @IBOutlet var arrayController:NSArrayController!
    @objc dynamic  var gridNames = [String]()
    @objc dynamic var patternDirectory:URL?
    @objc dynamic var timeGrids = [TimeGrid]()

    enum TrackingChanges:String,CaseIterable {
        case patternSelection,selectedGrid,effectLayer,startTime,endTime
    }
    var changes = [TrackingChanges]()
    @objc dynamic var patternSelection:String? {
        didSet {
            changes.append(.patternSelection)
        }
    }
    @objc dynamic var selectedGrid:String? {
        didSet{
            changes.append(.selectedGrid)
        }
    }
    @objc dynamic var effectLayer = 0 {
        didSet{
            changes.append(.effectLayer)
        }
    }
    @objc dynamic var startTime = 0.0 {
        didSet{
            changes.append(.startTime)
        }
    }
    @objc dynamic var endTime = 0.0 {
        didSet{
            changes.append(.endTime)
        }
    }
    @objc dynamic var actionPrompt = "Create"
    func resetChanges() {
        changes.removeAll()
    }
    @IBAction func selectPattern(_ sender : Any?) {
        let panel = NSOpenPanel()
        panel.directoryURL = patternDirectory
        panel.allowedContentTypes = [.xml]
        panel.prompt = "Select Pattern"
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK , panel.url != nil else { return }
            
            // Ok, we only want the back part
            let fullbase = self.patternDirectory!
            var selectedbase = panel.url!.path().replacingOccurrences(of: fullbase.path()+"/", with: "")
            selectedbase = selectedbase.replacingOccurrences(of: "%60", with: "`")
            /*
            if selectedbase.hasPrefix(fullbase) {
                selectedbase.removeFirst(fullbase.count)
            }
             */
            self.patternSelection = selectedbase
        }
    }
    
    @IBAction func endDialog( _ sender: Any?) {
        guard let control = sender as? NSControl else { return }
        if !self.window!.makeFirstResponder(control) {
            return
        }
        
        let response = control.tag == 1 ? NSApplication.ModalResponse.OK : NSApplication.ModalResponse.cancel
        if response == .OK {
            // Lets check our times
            guard let selectedGrid = self.selectedGrid else {
                NSAlert(error: GeneralError(errorMessage: "No grid was selected")).beginSheetModal(for: self.window!)
                return
            }
            let master = self.window?.sheetParent?.windowController as! SequenceController
            guard let grid = master.gridForName(name: selectedGrid) else {
                NSAlert(error: GeneralError(errorMessage: "Unable to find grid: \(selectedGrid)")).beginSheetModal(for: self.window!)
                return
            }
            guard let tempStart = grid.bestTimeFor(milliseconds: self.startTime.milliSeconds) else {
                NSAlert(error: GeneralError(errorMessage: "Unable to find time <= for: \(String(format:"%.3f",self.startTime)) in grid \(grid.name!)")).beginSheetModal(for: self.window!)
                return
            }
            guard let tempEnd = grid.bestTimeFor(milliseconds: self.endTime.milliSeconds,preferBefore: false) else {
                NSAlert(error: GeneralError(errorMessage: "Unable to find time  >= for: \(String(format:"%.3f",self.endTime)) in grid \(grid.name!)")).beginSheetModal(for: self.window!)
                return
            }
            guard tempEnd > tempStart else {
                NSAlert(error: GeneralError(errorMessage: "Best match for end time(\(tempEnd.milliString)) is not greater then best match for start time(\(tempStart.milliString)) in grid \(grid.name!)")).beginSheetModal(for: self.window!)
                return

            }
            self.startTime = tempStart.milliSeconds
            self.endTime = tempEnd.milliSeconds
        }
        self.window!.sheetParent?.endSheet(self.window!,returnCode: response)
    }
    
    var isModify = false {
        didSet{
            actionPrompt = isModify ? "Modify" : "Create"
            resetChanges()
        }
    }
    func loadEffect(effect:ItemEffect?) {
        if effect != nil {
            startTime = effect!.startTime.milliSeconds
            endTime = effect!.endTime.milliSeconds
            patternSelection = effect!.pattern
            effectLayer = effect!.effectLayer
            selectedGrid = effect!.gridName
            resetChanges()
         }
    }
}
