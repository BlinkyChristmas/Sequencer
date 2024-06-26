// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ItemController : NSViewController {
    enum DragType {
        case none,extendLeft,extendRight,move
    }
    var dragPoint = NSPoint.zero
    var currentDrag = DragType.none
    var currentCursor:NSCursor? {
        willSet {
            if currentCursor != nil {
                NSCursor.pop()
            }
        }
        didSet {
            if currentCursor != nil {
                currentCursor!.push()
            }
        }
    }
    var originalLayer = 0
    var originalFrame = NSRect.zero
    
    var lightBundle:LightBundle?
    
    override var nibName: NSNib.Name? {
        return "ItemController"
    }
    var clickTime = 0
    var clickPoint = CGPoint.zero
    @objc dynamic weak var sequenceItem:SeqItem? {
        didSet{
            makeEffects()
        }
    }
    @objc dynamic var isVisible = true
    
    
    @objc dynamic var isExpanded = false
    
    var maxLayer:Int {
        guard let item = sequenceItem else { return 0 }
         return item.effects.reduce(0, { max($0,$1.effectLayer)}) + 2
    }
    
    var controllers = [EffectController]()
    weak var selection:EffectController?
    var dotsPerSecond = BlinkyGlobals.dotsPerSecond
    
    var height:Double {
    
        let rowHeight = (NSApp.delegate as! AppDelegate).settingsData.rowSize
        if !isExpanded {
            return rowHeight +  BlinkyGlobals.effectMargin
        }
        return (Double(max(maxLayer,(NSApp.delegate as! AppDelegate).settingsData.startingLayerCount)) * (rowHeight + BlinkyGlobals.effectMargin/2.0)) + BlinkyGlobals.effectMargin/2.0
    }
    
    @IBOutlet var createEffectDialog:CreateEffectDialog!
    override var acceptsFirstResponder: Bool {
        guard (self.view.window?.windowController as? SequenceController)?.isGridEnabled ?? true  != false else { return false }
        return true
    }
    var frameData = [[PixelColor]]()
    
    func renderData(masterController:SequenceController, document:SequenceDocument,ourBundle:LightBundle,imageBase:URL,patternBase:URL) throws {
        let duration = masterController.musicPlayer.duration
        let grids = document.timeGrids

        do {
            frameData = try renderSequence(duration: duration, effects: sequenceItem!.effects, lightBundle: ourBundle, grids: grids, patternBase: patternBase, imageBase: imageBase, framePeriod: BlinkyGlobals.framePeriod)
        }
        catch {
            throw GeneralError(errorMessage: "Error rendering data for sequence item: \(sequenceItem?.name ?? "")",failure: error.localizedDescription)
        }
    }
    func renderData() throws {
        let master = self.view.window!.windowController as! SequenceController
        let doc = master.document as! SequenceDocument
        let bundles = (NSApp.delegate as! AppDelegate).bundleDictionay
        guard let patternBase =  (NSApp.delegate as! AppDelegate).settingsData.patternDirectory else {
            throw GeneralError(errorMessage: "Pattern directory is not defined in settings")
        }
        guard let imageBase =  (NSApp.delegate as! AppDelegate).settingsData.imageDirectory else {
            throw GeneralError(errorMessage: "Image directory is not defined in settings")
        }
        guard let bundleName  = sequenceItem?.bundleType  else {
            throw GeneralError(errorMessage: "No bundle type defined for: \(sequenceItem?.name ?? "")")
        }
        guard let ourBundle = bundles[bundleName] else {
            throw GeneralError(errorMessage: "Can not find bundle type: \(bundleName)")
        }
        try self.renderData(masterController: master, document: doc, ourBundle: ourBundle, imageBase: imageBase, patternBase: patternBase)
    }
    func testRender() async throws {
        try self.renderData()
    }
}


// ========= Effect Management
extension ItemController {
    var effectHeight:Double {
        (NSApp.delegate as! AppDelegate).settingsData.rowSize
    }
    func layerForY(position:Double)->Int {
        //Swift.print("We got asked the layer for \(position)")
        let base = position - BlinkyGlobals.effectMargin/2.0
        var elayer = 0
        if base >= 0.0 {
            elayer = Int( base / (effectHeight + BlinkyGlobals.effectMargin/2.0))
            //Swift.print("We got think it is \(elayer)")
        }
        return elayer
        
    }
    func makeEffects() {
        guard let sequenceItem = sequenceItem else { return }
        controllers = [EffectController]()
        for effect in sequenceItem.effects {
            let controller = EffectController(nibName: nil, bundle: nil)
            controller.effect = effect
            controllers.append(controller)
        }
    }

    func controllerFor(effect:ItemEffect) -> EffectController? {
        for entry in controllers {
            if entry.effect == effect {
                return entry
            }
        }
        return nil
    }
    
    func calculateOrigins() -> [NSPoint] {
        var origins = [NSPoint]()
        let height = (NSApp.delegate as! AppDelegate).settingsData.rowSize
        for controller in controllers.sorted(by: {displaySort(lhs: $0.effect!, rhs: $1.effect!)}) {
            let position = isExpanded ? Double(controller.effect!.effectLayer) : 0.0
            let y = position * (height  + BlinkyGlobals.effectMargin/2.0)
            let x = dotsPerSecond * controller.effect!.startTime.milliSeconds
            origins.append(NSPoint(x: x, y: y))
        }
        return origins
    }
    
    func shuffle(addToView:Bool = false ) {
        let height = (NSApp.delegate as! AppDelegate).settingsData.rowSize
        let origins = calculateOrigins()
        let controllers = controllers.sorted(by: {displaySort(lhs: $0.effect!, rhs: $1.effect!)})
        for index in 0..<controllers.count {
            controllers[index].view.frame = NSRect(origin: origins[index], size: NSSize(width: controllers[index].effect!.width.milliSeconds * dotsPerSecond, height: height))
            
            if addToView {
                self.view.addSubview(controllers[index].view)
            }
            /*
            if controllers[index].view.superview != nil {
            
                controllers[index].view.removeFromSuperview()
            }
            self.view.addSubview(controllers[index].view)
             */
        }
        shuffleViewDisplayOrder()
    }
    func shuffleViewDisplayOrder() {
        //var views = [NSView]()
        for controller in controllers.sorted(by: {displaySort(lhs: $0.effect!, rhs: $1.effect!)}).reversed() {
            if !controller.isSelected {
                let superview = controller.view.superview
                controller.view.removeFromSuperview()
                superview?.addSubview(controller.view,positioned: .above, relativeTo: nil)
                //views.append(controller.view)
            }
        }
        if selection != nil {
            if selection!.isSelected {
                let superview = selection!.view.superview
                selection!.view.removeFromSuperview()
                superview?.addSubview(selection!.view, positioned: .above, relativeTo: nil)
               //views.append(selection!.view)
            }
        }
        //self.view.subviews = views
    
    }
    
    func displaySort(lhs:ItemEffect,rhs:ItemEffect) -> Bool {
        if lhs.startTime <= rhs.startTime {
            if lhs.endTime < rhs.endTime { return true }
            if rhs.endTime < lhs.endTime { return false }
            if lhs.effectLayer <= rhs.effectLayer { return true}
            return false
        }
        if lhs.endTime < rhs.endTime { return true }
        if lhs.endTime > rhs.endTime { return false}
        if lhs.effectLayer <= rhs.effectLayer { return true}
        return false

    }
    
    func selectEffect(controller:EffectController?) -> EffectController? {
        guard controller != nil else {
            (self.view.superview as? DetailHolderView)?.selectedItem?.isSelected = false
            (self.view.superview as? DetailHolderView)?.selectedItem = nil
            selection?.isSelected = false
            selection = nil
            (self.view.window?.windowController as! SequenceController).shuffle()
            return controller
        }
        guard !controller!.isSelected  else { return controller}
        if selection != controller {
            selection?.isSelected = false
            selection = controller
        }
        selection?.isSelected = true
        //selection!.shadowEffect = (controller!.effect!.copy() as! ItemEffect)
        
        // update the "master selection"
        if (self.view.superview as? DetailHolderView)!.selectedItem != selection {
            (self.view.superview as? DetailHolderView)!.selectedItem?.isSelected = false
            (self.view.superview as? DetailHolderView)!.selectedItem = selection
        }
        (self.view.window?.windowController as! SequenceController).shuffle()
        return controller
    }
}

// ======= Support functions
extension ItemController {
    
    @objc dynamic var imageDirectory:URL? {
        guard let temp = (NSApp.delegate as! AppDelegate).settingsData.imageDirectory else { return nil}
        guard let bundleType = sequenceItem?.bundleType else { return nil }
        guard let lightBundle  = (NSApp.delegate as! AppDelegate).bundleDictionay[bundleType] else { return nil }
        var imagedir = lightBundle.imageDirectory
        if imagedir == nil {
            imagedir = bundleType
        }
        return temp.appending(path: imagedir!)
    }
    
    @objc dynamic var patternDirectory:URL? {
        guard let temp = (NSApp.delegate as! AppDelegate).settingsData.patternDirectory else { return nil}
        guard let bundleType = sequenceItem?.bundleType else { return nil }
        guard let lightBundle  = (NSApp.delegate as! AppDelegate).bundleDictionay[bundleType] else { return nil }
        var patterndir = lightBundle.patternDirectory
        if patterndir == nil {
            patterndir = bundleType
        }
        
        return temp.appending(path: patterndir!)
    }
    
    @objc dynamic var gridNames:[String] {
        return (self.view.window?.windowController as? SequenceController)!.sequence.timeGrids.map{ $0.name!}.sorted()
    }
    
    @objc dynamic var timeGrids:[TimeGrid] {
        return (self.view.window?.windowController as? SequenceController)!.sequence.timeGrids
    }
    @objc dynamic var activeGrid:TimeGrid? {
        return (self.view.window?.windowController as? SequenceController)!.activeGrid
    }
    
    func checkForCoverage(effect:ItemEffect) -> ItemEffect? {
        for child in self.sequenceItem!.effects  {
            if effect.isCoveredOrWillCover(effect: child) {
                return child
            }
        }
        return nil
    }
}

// ======= View Management
extension ItemController {
}

// ======== Key Management
extension ItemController {
    
    func copyEffect(effectItem:ItemEffect) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(effectItem)
            NSPasteboard.general.clearContents()
            if NSPasteboard.general.setData(data, forType: .sequenceEffect) != true  {
                throw GeneralError(errorMessage: "Unable to copy to pasteboard", failure: nil)
            }
            
        }
        catch {
            NSAlert(error: GeneralError(errorMessage: "Unable to copy effect: \(effectItem.description)", failure: error.localizedDescription)).beginSheetModal(for: self.view.window!)
        }

    }
    func pasteEffect() {
        guard let data = NSPasteboard.general.data(forType: .sequenceEffect) else { return }
        let decoder = JSONDecoder()
        var errorName:String?
        let pasteLayer = layerForY(position: clickPoint.y)
        let master = self.view.window!.windowController as! SequenceController
        let doc = master.document as! SequenceDocument
        do {
            let item = try decoder.decode(ItemEffect.self, from: data)
            errorName = item.description
            let delta = item.endTime - item.startTime
            let grid = master.gridForName(name: item.gridName!)
            if grid == nil {
                throw GeneralError(errorMessage: "Unable to find grid: \(item.gridName ?? "none") in pasted item")
            }
            let startTime = grid!.bestTimeFor(milliseconds: clickTime)
            if startTime == nil {
                throw GeneralError(errorMessage: "Unable to find matching time for \(clickTime.milliString) in grid: \(item.gridName ?? "none") in pasted item")
            }
            let endTime = grid!.bestTimeFor(milliseconds: startTime! + delta)
            if endTime == nil {
                throw GeneralError(errorMessage: "Unable to find matching time for \((startTime! + delta).milliString) in grid: \(item.gridName ?? "none") in pasted item")
            }
            item.startTime = startTime!
            item.endTime = endTime!
            item.effectLayer = pasteLayer
            let coverEffect = checkForCoverage(effect: item)
            if coverEffect != nil {
                throw GeneralError(errorMessage: "Effect: \(item.description) would be covered or cover: \(coverEffect!.description)" )
            }
            // now , we can actually do something
            let undo = doc.undoManager
            
            let controller = EffectController(nibName: nil, bundle: nil)
            self.sequenceItem?.effects.append(item)
            controller.effect = item
            self.controllers.append(controller)
            self.view.addSubview(controller.view)
            undo?.registerUndo(withTarget: doc, handler: { seq in
                var index = self.controllers.firstIndex(of: controller)
                if index != nil {
                    self.controllers[index!].view.removeFromSuperview()
                    self.controllers.remove(at: index!)
                }
                index = self.sequenceItem!.effects.firstIndex(of: item)
                if index != nil {
                    self.sequenceItem!.effects.remove(at: index!)
                }
                master.shuffle()
            })
            master.shuffle()
            
        }
        catch {
            NSAlert(error: GeneralError(errorMessage: "Unable to paste effect: \(errorName ?? "") ", failure: error.localizedDescription)).beginSheetModal(for: self.view.window!)

        }


    }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == Keycode.escape{
             if selection != nil {
                 if currentDrag != .none {
                     endDrag(controller: selection, cancel: true,layer:originalLayer)
                 }
             }
         }

        else if event.keyCode == Keycode.c  {
            if event.modifierFlags.contains(.command) {
                // we are trying to copy the selected effect
                if selection != nil {
                    if selection!.isSelected {
                        copyEffect(effectItem:selection!.effect! )
                    }
                }
            }
        }
        else if event.keyCode == Keycode.v {
            if event.modifierFlags.contains(.command) {
                pasteEffect()
            }
        }
        else if event.keyCode == Keycode.delete || event.keyCode == Keycode.forwardDelete {
            if (selection?.isSelected ?? false )  == true {
                let item = NSMenuItem()
                item.representedObject = selection
                self.deleteEffect(item)
                currentDrag = .none
                currentCursor = nil 
            }
        }

    }
}
// ======= Mouse Management
extension ItemController {
    func convert(event:NSEvent) -> CGPoint {
        self.view.convert(event.locationInWindow, from: nil)
    }
    func updateStatus(point:CGPoint) {
        (self.view.window!.windowController as? SequenceController)?.displayMouseTime(time: point.x/dotsPerSecond)
    }
    
    
    override func mouseExited(with event: NSEvent) {
        if currentDrag != .none {
            endDrag(controller: selection, cancel: true,layer: originalLayer)
        }
    }
    override func mouseDown(with event: NSEvent) {
        //if (self.view.window!.windowController as! SequenceController).isGridEnabled
        let ourPoint = convert(event: event)
        clickTime = (ourPoint.x / dotsPerSecond).milliSeconds
        clickPoint = ourPoint
        updateStatus(point: ourPoint)
        dragPoint = ourPoint
        originalLayer = layerForY(position: ourPoint.y)
        if self.view.window!.makeFirstResponder(self) {
            if selection != nil {
                if selection!.isSelected {
                    
                    if NSPointInRect(ourPoint,selection!.view.frame) {
                        self.originalFrame = selection!.view.frame
                        let (drag,cursor) = determineCursorDrag(rect: selection!.view.frame, point: ourPoint)
                        self.currentDrag = drag
                        self.currentCursor = cursor
                        return
                    }
                }
            }
            // If we are here, we had nothing selected or at least not where we clicked
            // So lets see if there is something selected
            var potential = [EffectController]()
            let sorted = controllers.sorted(by: {displaySort(lhs: $0.effect!, rhs: $1.effect!)})
            for entry in sorted {
                if NSPointInRect(ourPoint, entry.view.frame) {
                    potential.append(entry)
                }
            }
            // We either want the first or last
            guard !potential.isEmpty else { _ = selectEffect(controller: nil); currentDrag = .none; currentCursor = nil; return }
            let (drag,cursor) = determineCursorDrag(rect: selectEffect(controller: potential.first)!.view.frame, point: ourPoint)
            self.currentDrag = drag
            currentCursor = cursor
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        //let ourPoint = convert(event: event)
        
        if (selection?.isSelected ?? false ) == true {
            var layer:Int? = nil
            if isExpanded {
                layer = layerForY(position: selection!.view.frame.origin.y + selection!.view.frame.size.height/2.0 )
            }
            /*
            var layer = selection!.effect!.effectLayer
            if event.modifierFlags.contains(.command) {
                layer = layerForY(position: ourPoint.y)
            }
             */
            if currentDrag != .none {
                endDrag(controller: selection, cancel: false,layer:layer)
            }
        }
        currentDrag = .none
        currentCursor = nil


    }
    
    override func mouseDragged(with event: NSEvent) {
        let ourPoint = convert(event: event)
        let allowLayer = event.modifierFlags.contains(.command)
        let delty = allowLayer == true && isExpanded == true ? ourPoint.y - dragPoint.y:  0.0
        guard selection != nil else { currentDrag = .none; currentCursor = nil; return }
        if NSPointInRect(ourPoint, self.view.bounds) {
            updateStatus(point: ourPoint)
            if selection?.isSelected ?? false {
                self.view.autoscroll(with: event)
                switch currentDrag {
                case .extendLeft:
                    let delta = dragPoint.x - ourPoint.x
                    let origin = NSPoint(x: selection!.view.frame.origin.x - delta, y: selection!.view.frame.origin.y )
                    let size = NSSize(width: selection!.view.frame.width + delta , height: selection!.view.frame.height)
                    selection!.view.frame = NSRect(origin: origin, size: size)
                case .extendRight:
                    let delta = ourPoint.x - dragPoint.x
                    let size = NSSize(width: selection!.view.frame.width + delta , height: selection!.view.frame.height)
                    selection!.view.setFrameSize(size)
                case .move:
                    let delta = ourPoint.x - dragPoint.x
                    
                    let origin = NSPoint(x:selection!.view.frame.origin.x + delta,y:selection!.view.frame.origin.y + delty)
                    selection!.view.setFrameOrigin(origin)
                    
                case .none:
                    break
                }
                dragPoint = ourPoint
            }
        }
        else {
           //Swift.print("Outside bounds")
        }
    }

    func determineCursorDrag(rect:NSRect,point:NSPoint) -> (DragType,NSCursor?) {
        if point.x >= rect.origin.x && point.x <=  min(rect.origin.x + 10.0,rect.origin.x + (rect.size.width / 4.0))   {
            return (DragType.extendLeft,NSCursor.resizeLeftRight)
        }
        else if point.x <= rect.origin.x + rect.size.width && point.x >=  max(rect.origin.x + rect.size.width - 10.0 ,rect.origin.x + rect.size.width - rect.size.width/4.0){
            return (DragType.extendRight,NSCursor.resizeLeftRight)
        }
        else if NSPointInRect(point, rect) {
            return (DragType.move,NSCursor.openHand)
        }
        return (DragType.none,nil)
    }
    func endDrag(controller:EffectController? , cancel:Bool, layer:Int? = nil) {
        guard currentDrag != .none else { return }
        currentDrag = .none
        currentCursor = nil
        guard let controller = controller else { return }
        let master = self.view.window!.windowController as! SequenceController

        if cancel {
            // We need to set the frame back
            controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dotsPerSecond)
        }
        else {
            // Ok, so what we need to do here, is find  the proped start and stop times
            let startMaybe = controller.view.frame.origin.x / dotsPerSecond
            let endMaybe = controller.view.frame.width / dotsPerSecond + startMaybe
            guard let grid = (controller.view.window?.windowController as? SequenceController)?.gridForName(name: controller.effect!.gridName!) else {
                // we should do an error here
                NSAlert(error:GeneralError(errorMessage: "Unable to find grid \(controller.effect!.gridName ?? "none")")).beginSheetModal(for: self.view.window!)
                // we need to reset the controller
                controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dotsPerSecond)
                return
            }
            guard let realstart = grid.bestTimeFor(milliseconds: startMaybe.milliSeconds) else  {
                // This is a real problem!
                NSAlert(error:GeneralError(errorMessage: "Unable to find best time in \(controller.effect!.gridName! ) for \(startMaybe.milliSeconds.milliString)")).beginSheetModal(for: self.view.window!)
                // we need to reset the controller
                controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dotsPerSecond)
                return
            }
            guard let realend = grid.bestTimeFor(milliseconds: endMaybe.milliSeconds, preferBefore: false) else {
                // This is a real problem!
                NSAlert(error:GeneralError(errorMessage: "Unable to find best time in \(controller.effect!.gridName! ) for \(endMaybe.milliSeconds.milliString)")).beginSheetModal(for: self.view.window!)
                // we need to reset the controller
                controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dotsPerSecond)
                return
            }
            let oldStart = controller.effect!.startTime
            let oldEnd = controller.effect!.endTime
            let oldLayer = controller.effect!.effectLayer
            if layer != nil {
                controller.effect?.effectLayer   = layer!
            }
            controller.effect!.startTime = realstart
            controller.effect!.endTime = realend
            //let dots = dotsPerSecond
            //controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dotsPerSecond)
            
            let master = self.view.window!.windowController as! SequenceController
            let doc = master.document as! SequenceDocument
            (self.view.window?.windowController?.document as? SequenceDocument)!.undoManager?.registerUndo(withTarget: doc, handler: { seq in
                controller.effect!.startTime = oldStart
                controller.effect!.endTime = oldEnd
                controller.effect!.effectLayer = oldLayer
                
                _ = self.selectEffect(controller: nil)
                master.shuffle()
                
            })

        }
        master.shuffle()

    }
    
    @objc func createEffectWithCopy( _ sender: Any?) {
        let menuItem  =  sender as? NSMenuItem
        if menuItem?.representedObject == nil {
            createEffect(sender)
            return
        }
        createEffectDialog.gridNames = self.gridNames
        createEffectDialog.patternDirectory = self.patternDirectory
        createEffectDialog.timeGrids = self.timeGrids
        let selectedController = (menuItem!.representedObject as? EffectController)!
        createEffectDialog.loadEffect(effect: selectedController.effect?.copy() as? ItemEffect)
        createEffectDialog.selectedGrid = selectedController.effect!.gridName
        createEffectDialog.startTime = selectedController.effect!.startTime.milliSeconds
        createEffectDialog.endTime = selectedController.effect!.endTime.milliSeconds
        createEffectDialog.isModify = false
        createEffectDialog.effectLayer = selectedController.effect!.effectLayer
        let master = self.view.window!.windowController as! SequenceController
        let seq = master.document as! SequenceDocument
        let undo =  seq.undoManager
        //let active = self.activeGrid
        self.view.window?.beginSheet(createEffectDialog.window!,completionHandler: { response in
            guard response == .OK else { return }
            let effect = ItemEffect()
            effect.pattern = self.createEffectDialog.patternSelection
            effect.gridName = self.createEffectDialog.selectedGrid
            effect.effectLayer = self.createEffectDialog.effectLayer
            effect.startTime = self.createEffectDialog.startTime.milliSeconds
            effect.endTime = self.createEffectDialog.endTime.milliSeconds
            let coverEffect = self.checkForCoverage(effect: effect)
            if coverEffect != nil {
                NSAlert(error:  GeneralError(errorMessage: "Effect: \(effect.description) would be covered or cover: \(coverEffect!.description)" )).beginSheetModal(for: self.view.window!)
                return
            }

            let controller = EffectController(nibName: nil, bundle: nil)
            self.sequenceItem?.effects.append(effect)
            
            
            controller.effect = effect
            self.controllers.append(controller)
            self.view.addSubview(controller.view)
            undo!.registerUndo(withTarget: seq, handler: { seq in
               var index = self.controllers.firstIndex(where: { $0.effect == effect})
               if index != nil {
                    self.controllers[index!].view.removeFromSuperview()
                    self.controllers.remove(at: index!)
                }
                index = self.sequenceItem!.effects.firstIndex(of: effect)
                if index != nil {
                    self.sequenceItem!.effects.remove(at: index!)
                }
                master.shuffle()
            })
            // We should select the one we just copied, or just nil it
            
            self.selection = self.selectEffect(controller: nil)
            master.shuffle()
        })
    }
    @objc func createEffect( _ sender: Any?) {
        createEffectDialog.gridNames = self.gridNames
        createEffectDialog.patternDirectory = self.patternDirectory
        createEffectDialog.timeGrids = self.timeGrids
        createEffectDialog.loadEffect(effect: ItemEffect())
        createEffectDialog.isModify = false
        createEffectDialog.effectLayer = layerForY(position: clickPoint.y)
        let master = self.view.window!.windowController as! SequenceController
        let seq = master.document as! SequenceDocument
        let undo =  seq.undoManager
        let active = self.activeGrid
        if active != nil {
            createEffectDialog.selectedGrid = active!.name
            var time = active!.bestTimeFor(milliseconds: clickTime)
            if time != nil {
                createEffectDialog.startTime = time!.milliSeconds
                createEffectDialog.endTime  = time!.milliSeconds
                time = active!.bestTimeFor(milliseconds: time! + 10000)
                if time != nil {
                    createEffectDialog.endTime  = time!.milliSeconds
                }
            }
        }
        else {
            createEffectDialog.startTime = 0.0
            createEffectDialog.endTime = (self.view.window!.windowController as! SequenceController).musicPlayer.duration
        }
        self.view.window?.beginSheet(createEffectDialog.window!,completionHandler: { response in
            guard response == .OK else { return }
            let effect = ItemEffect()
            effect.pattern = self.createEffectDialog.patternSelection
            effect.gridName = self.createEffectDialog.selectedGrid
            effect.effectLayer = self.createEffectDialog.effectLayer
            effect.startTime = self.createEffectDialog.startTime.milliSeconds
            effect.endTime = self.createEffectDialog.endTime.milliSeconds
            let coverEffect = self.checkForCoverage(effect: effect)
            if coverEffect != nil {
                NSAlert(error:  GeneralError(errorMessage: "Effect: \(effect.description) would be covered or cover: \(coverEffect!.description)" )).beginSheetModal(for: self.view.window!)
                return
            }

            let controller = EffectController(nibName: nil, bundle: nil)
            self.sequenceItem?.effects.append(effect)
            
            
            controller.effect = effect
            self.controllers.append(controller)
            self.view.addSubview(controller.view)
            undo!.registerUndo(withTarget: seq, handler: { seq in
               var index = self.controllers.firstIndex(where: { $0.effect == effect})
               if index != nil {
                    self.controllers[index!].view.removeFromSuperview()
                    self.controllers.remove(at: index!)
                }
                index = self.sequenceItem!.effects.firstIndex(of: effect)
                if index != nil {
                    self.sequenceItem!.effects.remove(at: index!)
                }
                master.shuffle()
            })
            master.shuffle()
        })
    }
    @objc func modifyEffect( _ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let controller = menuItem.representedObject as? EffectController else { return}
        createEffectDialog.gridNames = self.gridNames
        createEffectDialog.patternDirectory = self.patternDirectory
        createEffectDialog.timeGrids = self.timeGrids

        createEffectDialog.loadEffect(effect: controller.effect!)
        createEffectDialog.isModify = true
        self.view.window?.beginSheet(createEffectDialog.window!, completionHandler: { response in
            guard response == .OK else { return }
            guard !self.createEffectDialog.changes.isEmpty else { return }
            let master = (self.view.window!.windowController as? SequenceController)!

            // First, do we have to adjust the times?, no, we now do that in the dialog
 
            let undo = (master.document as? SequenceDocument)?.undoManager
            let effect = controller.effect!
            let dots = self.dotsPerSecond
            undo?.beginUndoGrouping()
            undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dots)
                master.shuffle()
            })
            for item in self.createEffectDialog.changes {
                switch item {
                case .patternSelection:
                    let old = effect.pattern
                    undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                        effect.pattern = old
                    })
                    effect.pattern = self.createEffectDialog.patternSelection
                case .selectedGrid:
                    let old = effect.gridName
                    undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                        effect.gridName = old
                    })
                    effect.gridName = self.createEffectDialog.selectedGrid
                case .effectLayer:
                    let old = effect.effectLayer
                    undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                        effect.effectLayer = old
                    })
                    effect.effectLayer = self.createEffectDialog.effectLayer
                case .startTime:
                    let old = effect.startTime
                    undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                        effect.startTime = old
                    })
                    effect.startTime = self.createEffectDialog.startTime.milliSeconds
                case .endTime:
                    let old = effect.endTime
                    undo?.registerUndo(withTarget: master.document as! SequenceDocument, handler: { doc in
                        effect.endTime = old
                    })
                    effect.endTime = self.createEffectDialog.endTime.milliSeconds
                }
            }
            undo?.endUndoGrouping()
            controller.resetFrame(startTime: controller.effect!.startTime, endTime: controller.effect!.endTime, dotsPerSecond: dots)
            master.shuffle()

        })
        

    }
    @objc func deleteEffect( _ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        let master = self.view.window?.windowController as! SequenceController
        let doc = master.document as! SequenceDocument
        let controller = menuItem.representedObject as? EffectController
        if controller != nil {
            // We just delete the one that is selected
            let effect = controller!.effect
            
            controller!.view.removeFromSuperview()
            var index = self.controllers.firstIndex(where: { $0 == controller!})
            if index != nil {
                self.controllers.remove(at: index!)
            }
            index = self.sequenceItem!.effects.firstIndex(of: effect!)
            if index != nil {
                self.sequenceItem!.effects.remove(at: index!)
            }
            _ = selectEffect(controller: nil)
            doc.undoManager?.registerUndo(withTarget: doc, handler: { seq in
                let controller = EffectController(nibName: nil, bundle: nil)
                self.sequenceItem?.effects.append(effect!)
                controller.effect = effect
                self.controllers.append(controller)
                self.view.addSubview(controller.view)
                master.shuffle()
            })
            master.shuffle()
        }

    }
    @objc func selectEffect(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let controller = menuItem.representedObject as? EffectController else { return}
        if menuItem.state != .on {
            _ = selectEffect(controller: controller)
        }
        else {
            _ = selectEffect(controller: nil)
        }
    }
    
    func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu(title: "Popup")
        let ourPoint = convert(event: event)
        
        updateStatus(point: ourPoint)
        clickTime = (ourPoint.x / dotsPerSecond).milliSeconds
        clickPoint = ourPoint
        menu.addItem(withTitle: "Create", action: #selector(createEffect(_:)), keyEquivalent: "")
        var valid = [EffectController]()
        var containsSelected = false
        for controller in controllers.sorted(by: {displaySort(lhs: $0.effect!, rhs: $1.effect!)}) {
            if NSPointInRect(clickPoint, controller.view.frame) {
                valid.append(controller)
                if controller.isSelected  {
                    containsSelected = true
                }
            }
        }
        if containsSelected {
            var menuItem = NSMenuItem(title: "Create with copy", action: #selector(createEffectWithCopy(_:)), keyEquivalent: "")
            menuItem.representedObject = selection
            menu.addItem(menuItem)
            menuItem = NSMenuItem(title: "Delete", action: #selector(deleteEffect(_:)), keyEquivalent: "")
            menuItem.representedObject = selection
            menu.addItem(menuItem)
            menuItem = NSMenuItem(title: "Edit", action: #selector(modifyEffect(_:)), keyEquivalent: "")
            menuItem.representedObject = selection
            menu.addItem(menuItem)
        }
        for entry in valid {
            let menuItem = NSMenuItem(title: entry.description, action: #selector(selectEffect(_:)), keyEquivalent: "")
            menuItem.representedObject = entry
            menu.addItem(menuItem)
            if entry.isSelected {
                menuItem.state = .on
            }
        }
        return menu
    }
}
