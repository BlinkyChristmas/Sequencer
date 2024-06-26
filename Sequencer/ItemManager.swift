// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class ItemManager : NSObject {
    weak var master:SequenceController?
    @objc dynamic var detailHolder = DetailHolderView(frame: NSRect.zero)
    
    @objc dynamic weak var sequence:SequenceDocument? {
        didSet{
            makeControllers()
        }
    }
    
    var dotsPerSecond = BlinkyGlobals.dotsPerSecond {
        didSet{
            for item in detailControllers{
                item.dotsPerSecond = dotsPerSecond
            }
        }
    }
    
    var detailControllers = [ItemController]()
    var infoControllers = [ItemInfoController]()
    
    var observers = [NSKeyValueObservation]()
    var height:Double {
        var value = BlinkyGlobals.itemMargin/2.0
        for controller in detailControllers {
            if controller.isVisible {
                value += controller.height + BlinkyGlobals.itemMargin/2.0
            }
        }
        return value
    }
    
    init(detailHolder: DetailHolderView = DetailHolderView(frame: NSRect.zero), sequence: SequenceDocument? = nil, dotsPerSecond: Double = BlinkyGlobals.dotsPerSecond, detailControllers: [ItemController] = [ItemController](), infoControllers: [ItemInfoController] = [ItemInfoController](), observers: [NSKeyValueObservation] = [NSKeyValueObservation]()) {
        self.detailHolder = detailHolder
        self.sequence = sequence
        self.dotsPerSecond = dotsPerSecond
        self.detailControllers = detailControllers
        self.infoControllers = infoControllers
        self.observers = observers
        
    }
    
    func makeControllers() {
        guard let sequence = sequence else { return }
        for item in sequence.sequenceItems {
            let controller = ItemController()
            controller.lightBundle = (NSApp.delegate as! AppDelegate).bundleDictionay[item.bundleType!]
            let infoController = ItemInfoController()
            controller.sequenceItem = item
            infoController.sequenceItem = item
            // Add the make effects here
            controller.makeEffects()
            // Build the observer
            let observer = infoController.observe(\.isExpanded) { controller, _ in
                self.itemExpansionChanged(sequenceItem: controller.sequenceItem!, expansion: controller.isExpanded)
            }
            observers.append(observer)
            detailControllers.append(controller)
            infoControllers.append(infoController)
        }
    }
    func renderLightData(background:Bool = false )  throws  {
        if !background {
            for controller in detailControllers {
                 try  controller.renderData()
            }

        }
        else {
            try messingRound()
        }
    }
    
    
    func messingRound2() throws {
        var tasks = [Task<(),Never>]()
        for controller in detailControllers {
            let imageBase = (NSApp.delegate as! AppDelegate).settingsData.imageDirectory!
            let patternBase = (NSApp.delegate as! AppDelegate).settingsData.patternDirectory!
        
            let doc = master!.document as! SequenceDocument
            let bundles = (NSApp.delegate as! AppDelegate).bundleDictionay
            guard let bundleName  = controller.sequenceItem?.bundleType  else {
                throw GeneralError(errorMessage: "No bundle type defined for: \(controller.sequenceItem?.name ?? "")")
            }
            guard let ourBundle = bundles[bundleName] else {
                throw GeneralError(errorMessage: "Can not find bundle type: \(bundleName)")
            }
             let task = Task {
                 _ = try?  await controller.renderData(masterController: self.master!, document: doc, ourBundle: ourBundle, imageBase: imageBase, patternBase: patternBase)
            }
            tasks.append(task)
        }
        
    }
    
    func messingRound() throws  {
        
        //var queues = [DispatchQueue]()
        let queue = DispatchConcurrentQueue(label: "renderqueue")
        for controller in detailControllers {
            let imageBase = (NSApp.delegate as! AppDelegate).settingsData.imageDirectory!
            let patternBase = (NSApp.delegate as! AppDelegate).settingsData.patternDirectory!
        
            let doc = master!.document as! SequenceDocument
            let bundles = (NSApp.delegate as! AppDelegate).bundleDictionay
            guard let bundleName  = controller.sequenceItem?.bundleType  else {
                throw GeneralError(errorMessage: "No bundle type defined for: \(controller.sequenceItem?.name ?? "")")
            }
            guard let ourBundle = bundles[bundleName] else {
                throw GeneralError(errorMessage: "Can not find bundle type: \(bundleName)")
            }

            queue.async {
                _ = try? controller.renderData(masterController: self.master!, document: doc, ourBundle: ourBundle, imageBase: imageBase, patternBase: patternBase)
            }
        }
    
        
     }
    func addControllers(infoHolder:NSView) {
        guard let sequence = sequence else { return }
        let origins = calculateOrigins()
        for index  in 0..<sequence.sequenceItems.count {
           
            detailControllers[index].view.frame = NSRect(origin: origins[index], size: NSSize(width: self.detailHolder.bounds.width, height: detailControllers[index].height))
            self.detailHolder.addSubview(detailControllers[index].view)
            detailControllers[index].shuffle(addToView: true)
            infoControllers[index].view.frame = NSRect(origin: origins[index], size: NSSize(width: infoHolder.bounds.width, height: detailControllers[index].height))
            infoHolder.addSubview(infoControllers[index].view)
        }
                
    }
    func renderAllData() async {
        do{
            for controller in detailControllers {
                try await controller.renderData()
            }
        }
        catch{
            // We should do something with the array
            await NSAlert(error: GeneralError(errorMessage:"Error rendering data",failure: error.localizedDescription)).beginSheetModal(for: self.master!.window!)
        }

    }
    
    
}

// ============ Height/Shuffle Managment
extension ItemManager {
    
    func itemExpansionChanged( sequenceItem:SeqItem , expansion:Bool) {
        guard let index = findController(sequenceItem: sequenceItem) else { return }
        detailControllers[index].isExpanded = expansion
        NotificationCenter.default.post(name: NSNotification.Name("shuffle"), object: self)
    }

    func shuffle() {
        let origins = calculateOrigins()
        for index in 0..<detailControllers.count {
            let origin = origins[index]
            let height = detailControllers[index].height
            
            detailControllers[index].view.frame = NSRect(origin: origin, size: NSSize(width: detailControllers[index].view.frame.width, height:height ))
            detailControllers[index].shuffle()
            infoControllers[index].view.frame = NSRect(origin: origin, size: NSSize(width:  infoControllers[index].view.frame.width, height: height))
        }
    }
    
    func calculateOrigins() -> [NSPoint] {
        var origins = [NSPoint]()
        var currentY = BlinkyGlobals.itemMargin/2.0
        for controller in detailControllers {
            var origin = NSPoint.zero
            if controller.isVisible {
                origin = NSPoint(x: 0.0, y: currentY)
                currentY += controller.height + BlinkyGlobals.itemMargin/2.0
            }
            origins.append(origin)
        }
        return origins
    }
    
    func updateHeightOrigins() {
        
    }
    
    func findController(sequenceItem: SeqItem) -> Int? {
        return detailControllers.firstIndex { $0.sequenceItem == sequenceItem }

    }
    func findController(controller:ItemController) -> Int? {
        return detailControllers.firstIndex { $0 == controller }
    }

}
