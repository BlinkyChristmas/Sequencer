// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit
import UniformTypeIdentifiers
class SequenceController : NSWindowController {
    
    static override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var rvalue = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "gridNames" {
            rvalue.insert("sequence.timeGrids")
        }
        return rvalue
    }
    
    override var windowNibName: NSNib.Name? {
        return "SequenceDocument"
    }
    
    
    
    var ourRulerName = randomAlphanumericString(5)
    var durationObserver:NSKeyValueObservation?
    var currentTimeObserver:NSKeyValueObservation?
    var rowHeightObserver:NSKeyValueObservation?
    var activeGridColorObserver:NSKeyValueObservation?
    
    // Grids
    @objc dynamic var activeGrid:TimeGrid? {
        didSet{
            activeGridColorObserver?.invalidate()
            activeGridColorObserver = nil
            
            gridContainer.setGrid(gridNumber: 0, timeGrid: activeGrid)
            if activeGrid != nil {
                activeGridColorObserver = activeGrid?.observe(\.color, options: [.old,.new],changeHandler: { grid, values in
                   
                    let doc = self.document as! SequenceDocument
                    let old = values.oldValue!
                    let grid = self.activeGrid!
                    self.sequence.undoManager!.registerUndo(withTarget: doc) { doc in
                        grid.color = old
                        self.gridContainer.refreshViews()
                    }
                    self.gridContainer.refreshViews()
                })
            }
        }
    }
    @objc dynamic var activeGridName:String? {
        didSet{
            guard activeGridName != nil else { activeGrid = nil ; return }
            activeGrid = self.gridForName(name: activeGridName!)
        }
    }
    @objc dynamic var ref1Grid:TimeGrid? {
        didSet{
            gridContainer.setGrid(gridNumber: 1, timeGrid: ref1Grid)
        }
    }
    @objc dynamic var ref1GridName:String? {
        didSet{
            guard ref1GridName != nil else { ref1Grid = nil ; return }
            ref1Grid = self.gridForName(name: ref1GridName!)
        }
    }
    @objc dynamic var ref2Grid:TimeGrid? {
        didSet{
            gridContainer.setGrid(gridNumber: 2, timeGrid: ref2Grid)
        }
    }
    @objc dynamic var ref2GridName:String?{
        didSet{
            guard ref2GridName != nil else { ref2Grid = nil ; return }
            ref2Grid = self.gridForName(name: ref2GridName!)
        }
    }
    @objc dynamic var ref3Grid:TimeGrid? {
        didSet{
            gridContainer.setGrid(gridNumber: 3, timeGrid: ref3Grid)
        }
    }
    @objc dynamic var ref3GridName:String?{
        didSet{
            guard ref3GridName != nil else { ref3Grid = nil ; return }
            ref3Grid = self.gridForName(name: ref3GridName!)
        }
    }
    @IBAction func clearGrid( _ sender: Any?) {
        let tag = (sender as? NSControl)?.tag ?? 5
        switch tag {
        case 0:
            activeGridName = nil
            isGridEnabled = false
        case 1:
            ref1GridName = nil
        case 2:
            ref2GridName = nil
        case 3:
            ref3GridName = nil
        default:
            break
        }
    }
    @IBAction func clearScratch( _ sender: Any?) {
        let grid = gridForName(name: BlinkyGlobals.scratchGridName)
        if grid != nil {
            grid?.timeEntries.removeAll()
            self.gridContainer.refreshViews()
        }
    }
    
    @objc dynamic var gridNames:[String] {
        return sequence.timeGrids.map{ $0.name!}.sorted()
    }
    @objc dynamic var isGridEnabled = false {
        didSet{
            gridContainer.isGridEnable = isGridEnabled
            if isGridEnabled == true {
                if activeGrid != nil {
                    if self.window!.makeFirstResponder(gridContainer.activeGridController)  {
                        //Swift.print("Active grid enabled as first responder")
                    }
                }
            }
        }
    }
    
    @IBOutlet var createGridDialog:CreateTimeGridDialog!
    @IBOutlet var deleteTimeGridDialog:DeleteTimeGridDialog!
    @IBOutlet var modifyTimeGridDialog:ModifyTimingGridDialog!
    
    @IBOutlet var musicPlayer:MusicPlayer!
    @IBOutlet var scrollLeft:SynchronizedScollView!
    @IBOutlet var scrollRight:SynchronizedScollView!
    
    @IBOutlet var gridContainer:GridContainer!
    @IBOutlet var timeNowController:TimeNowController!
    
    @IBOutlet var exportDialog:ExportLightDialog!
    
    @IBOutlet var sequenceVisualizationController:SequenceVisualController!
    @IBOutlet var accessoryVisualizationController:AccessoryVisualizerController!
    
    var detailView = BackgroundView(frame: NSRect.zero)
    var infoView = BackgroundView(frame: NSRect.zero)
    var itemManager = ItemManager()
    
    @IBAction func seekToTime( _ sender: Any?) {
        musicPlayer.currentTime = seekTime
    }
    @objc dynamic var renderDataBeforePlay = false
    
    @objc dynamic var scale = 1.0 {
        didSet{
            dotsPerSecond = scale * BlinkyGlobals.dotsPerSecond
        }
    }
    @objc dynamic var dotsPerSecond = BlinkyGlobals.dotsPerSecond {
        didSet{
            scrollRight.registerScale(dotsPerSecond:dotsPerSecond,name:ourRulerName, abbreviation:ourRulerName )
            scrollRight.seekTo(seconds: musicPlayer.currentTime, dotsPerSecond:dotsPerSecond)
            detailView.setFrameSize(NSSize(width: musicPlayer.duration * dotsPerSecond, height: detailView.frame.height))
            itemManager.dotsPerSecond = dotsPerSecond
            gridContainer.dotsPerSecond = dotsPerSecond
            shuffle()
            gridContainer.refreshViews()
            self.timeNowController.setTime(time: musicPlayer.currentTime, dotsPerSecond: dotsPerSecond)
            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        durationObserver?.invalidate()
        currentTimeObserver?.invalidate()
        rowHeightObserver?.invalidate()
        activeGridColorObserver?.invalidate()
    }

    @objc dynamic var seekTime = 0.0
    @objc dynamic var topStatus:String?
}

// ======= Visualization
extension SequenceController {
    @IBAction func showVisualizer( _ sender: Any?) {
        sequenceVisualizationController.showWindow(sender)
    }
    /*
    @IBAction func showVisualAccessory(_ sender: Any?) {
        accessoryVisualizationController.showWindow(self)
    }
     */
}
// ======= Time Grid Dialogs
extension SequenceController {
    @IBAction func createTimeGrid( _ sender: Any?) {
        createGridDialog.timeGrids = sequence.timeGrids
        createGridDialog.gridName = nil 
        self.window!.beginSheet(createGridDialog.window!) { response in
            guard response == .OK else { return }
            var entries = Set<Int>()
            if self.createGridDialog.referenceEnable {
                entries = self.createGridDialog.referenceGridController.timesBasedOnFactor()
                
            }
            let timeGrid = TimeGrid(name: self.createGridDialog.gridName!,color: self.createGridDialog.gridColor,timeEntries: entries)
            self.sequence.willChangeValue(for: \.timeGrids)
            self.sequence.timeGrids.append(timeGrid)
            self.sequence.didChangeValue(for: \.timeGrids)
            self.sequence.undoManager?.registerUndo(withTarget: self.sequence, handler: { seq in
                let index = seq.timeGrids.firstIndex(where: {$0.name == timeGrid.name})
                if index != nil {
                    seq.willChangeValue(for: \.timeGrids)
                    seq.timeGrids.remove(at: index!)
                    seq.didChangeValue(for: \.timeGrids)
                    
                }
            })

        }
    }
    @IBAction func modifyTimeGrid( _ sender: Any?) {
        modifyTimeGridDialog.timeGrids = sequence.timeGrids
        modifyTimeGridDialog.selectedGrid = nil
        self.window?.beginSheet(modifyTimeGridDialog.window!, completionHandler: { response in
            guard response == .OK else { return }
            guard let gridName = self.modifyTimeGridDialog.selectedGrid else { return }
            guard let grid = self.gridForName(name: gridName) else { return }
            let entries = self.modifyTimeGridDialog.referenceGridController.timesBasedOnFactor()
            self.sequence.willChangeValue(for: \.timeGrids)
            let oldValues = grid.timeEntries
            if self.modifyTimeGridDialog.shouldAppend {
                for entry in entries {
                    grid.timeEntries.insert(entry)
                }
            }
            else {
                grid.timeEntries = entries
            }
            self.sequence.didChangeValue(for: \.timeGrids)
            self.sequence.undoManager?.registerUndo(withTarget: self.sequence, handler: { seq in
                seq.willChangeValue(for: \.timeGrids)
                grid.timeEntries = oldValues
                seq.didChangeValue(for: \.timeGrids)
                self.gridContainer.refreshViews()
            })
            
        })
    }
    @IBAction func deleteTimeGrid( _ sender: Any?) {
        deleteTimeGridDialog.timeGrids = sequence.timeGrids
        deleteTimeGridDialog.selectedGrid = nil
        self.window?.beginSheet(deleteTimeGridDialog.window!, completionHandler: { response in
            guard response == .OK else { return }
            guard let grid = self.gridForName(name: self.deleteTimeGridDialog.selectedGrid!) else { return }
            let index = self.sequence.timeGrids.firstIndex(of: grid)
            if index != nil {
                self.sequence.willChangeValue(for: \.timeGrids)
                self.sequence.timeGrids.remove(at: index!)
                self.sequence.didChangeValue(for: \.timeGrids)
                self.sequence.undoManager?.registerUndo(withTarget: self.sequence, handler: { seq in
                    self.sequence.willChangeValue(for: \.timeGrids)
                    self.sequence.timeGrids.append(grid)
                    self.sequence.didChangeValue(for: \.timeGrids)
                    self.gridContainer.refreshViews()
               })
            }
        })

    }
}

// ========== Window Delegate
extension SequenceController : NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if musicPlayer.isPlaying {
            musicPlayer.stop()
        }
        sequenceVisualizationController.close()
    }
}
// ========== Convenience symbols
extension SequenceController {
    @objc dynamic var settingsData:SettingsData { (NSApp.delegate as! AppDelegate).settingsData }
    @objc dynamic var sequence:SequenceDocument { self.document as! SequenceDocument}
    
    func gridForName(name:String) -> TimeGrid? {
        for entry in sequence.timeGrids {
            if entry.name == name {
                return entry
            }
        }
        return nil
    }
    
    func displayMouseTime(time:Double) {
        topStatus = String(format: "Mouse position: %.3f", time)
    }
}

// ========== Basic startup
extension SequenceController {
    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        guard (self.document as? SequenceDocument)?.visualizationName != nil else { return displayName}
        return String(format:"%@ - %@",(self.document as! SequenceDocument).visualizationName!,displayName)

    }
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(forName: NSNotification.Name("shuffle"), object: itemManager, queue: .main) { notification in
            self.shuffle()
            self.gridContainer.refreshViews()
        }
        scrollRight.hasHorizontalRuler = true
        scrollRight.rulersVisible = true
        scrollRight.registerScale(dotsPerSecond: dotsPerSecond, name: ourRulerName, abbreviation: ourRulerName)
        self.musicPlayer.volume = 0.25
        itemManager.sequence = self.sequence
        itemManager.master = self 
        self.detailView.setFrameSize(NSSize(width: detailView.frame.width, height: self.itemManager.height))
        self.itemManager.detailHolder.frame = self.detailView.bounds
        self.detailView.addSubview(self.itemManager.detailHolder)
        self.infoView.setFrameSize(NSSize(width: BlinkyGlobals.infoWidth, height: self.itemManager.height))
        self.gridContainer.view.frame = detailView.bounds
        detailView.addSubview(self.gridContainer.view)
        timeNowController.view.frame = NSRect(origin: CGPoint.zero, size: NSSize(width: 1.0, height: self.detailView.frame.height))
        detailView.addSubview(timeNowController.view)
        rowHeightObserver = (NSApp.delegate as! AppDelegate).settingsData.observe(\.rowSize, changeHandler: { _,_  in
            self.shuffle()
            self.gridContainer.refreshViews()
        })
        durationObserver = self.musicPlayer.observe(\.duration, changeHandler: { player, _ in
            self.durationObserver?.invalidate()
            self.durationObserver = nil
            self.musicLoaded()
            self.detailView.setFrameSize(NSSize(width: player.duration * self.dotsPerSecond, height: self.detailView.frame.height))
            self.scrollRight.documentView = self.detailView
            self.scrollLeft.documentView = self.infoView
            self.scrollLeft.synchronizedScrollView = self.scrollRight
            self.scrollRight.synchronizedScrollView = self.scrollLeft
            self.currentTimeObserver = player.observe(\.currentTime, changeHandler: { player, _ in
                self.scrollRight.seekTo(seconds: player.currentTime, dotsPerSecond: self.dotsPerSecond)
                self.timeNowController.setTime(time: player.currentTime, dotsPerSecond: self.dotsPerSecond)
            })
        })
        guard (self.document as? SequenceDocument)?.musicName != nil else {
            return 
        }
        sequenceVisualizationController.itemManager = self.itemManager
        sequenceVisualizationController.masterController = self
        sequenceVisualizationController.visualName = sequence.visualizationName
        sequenceVisualizationController.globalScale = sequence.visualScale
        let size = sequence.visualSize
        if size.width > 0.0 && size.height > 0.0 {
            sequenceVisualizationController.showWindow(nil)
            let frameRect = self.sequenceVisualizationController.window!.frame
            let newRect = NSRect(origin: frameRect.origin, size: size)
            self.sequenceVisualizationController.window!.setFrame(newRect, display: true)
        }
        
        musicPlayer.loadMusic(url: (NSApp.delegate as! AppDelegate).settingsData.musicDirectory!.appending(path: (self.document as! SequenceDocument).musicName!).appendingPathExtension(for: .wav))
    }
    
    func musicLoaded() {
        // Put into here, anything that should happen on music load
        self.itemManager.addControllers(infoHolder: self.infoView)
        sequenceVisualizationController.musicName = musicPlayer.musicTitle
        accessoryVisualizationController.musicName = musicPlayer.musicTitle
        accessoryVisualizationController.masterController = self
        accessoryVisualizationController.windowTitle = "Accessory Visualization Control: \( (self.document as! SequenceDocument).displayName ?? "unknown" )"
   }
    
    @IBAction func playMusic(_ sender : Any?)  {
        if musicPlayer.isPlaying {
            musicPlayer.stop()
        }
        else {
            defer{
                topStatus = nil
            }
            if renderDataBeforePlay {
                do{
                    topStatus = "Rendering data"
                   
                    try  itemManager.renderLightData(background: false)
                }
                catch {
                    NSAlert(error: error).beginSheetModal(for: self.window!)
                    return
                }

            }
            topStatus = "Playing"
            renderDataBeforePlay = false
            musicPlayer.play()

        }
    }
}

// =========== View Management
extension SequenceController {
    func shuffle() {
        let height = self.itemManager.height
        // Desync scroll views for a minute
        let leftSync = self.scrollLeft.synchronizedScrollView
        let rightSync = self.scrollRight.synchronizedScrollView
        self.scrollLeft.synchronizedScrollView = nil
        self.scrollRight.synchronizedScrollView = nil
        self.infoView.setFrameSize(NSSize(width: self.infoView.frame.width, height: height))
        self.detailView.setFrameSize(NSSize(width: self.detailView.frame.width, height: height))
        self.itemManager.shuffle()
        self.scrollLeft.synchronizedScrollView = leftSync
        self.scrollRight.synchronizedScrollView = rightSync
    }
}

// =========== Dialogs
extension SequenceController {
    @objc func modifyVisualName( _ sender: Any?) {
        let controller = ModifyVisualNameDialog(window: nil)
        controller.visualName = sequence.visualizationName
        
        self.window!.beginSheet(controller.window!) { response in
            guard response == .OK else { return }
            if (self.sequence.visualizationName != controller.visualName) {
                let oldName = controller.visualName
                self.sequence.visualizationName = oldName
                self.synchronizeWindowTitleWithDocumentName()
                self.sequence.undoManager?.registerUndo(withTarget: self.sequence, handler: { sequence in
                    sequence.visualizationName = oldName
                    self.synchronizeWindowTitleWithDocumentName()
                })
                
            }
        }
    }
    
    func buildExportItems() -> [ExportLightType] {
        var exportItems = [ExportLightType]()
        let bundleDict = (NSApp.delegate as! AppDelegate).bundleDictionay
        for item in sequence.sequenceItems {
            guard item.bundleType  != nil else {
                NSAlert(error: GeneralError(errorMessage: "Sequence Item: \(item.name ?? "") - has no bundle type")).beginSheetModal(for: self.window!)
                return exportItems
            }
            guard let lightBundle = bundleDict[item.bundleType!] else {
                
                NSAlert(error: GeneralError(errorMessage: "Could not find bundle type: \(item.bundleType!) for sequence Item: \(item.name ?? "") ")).beginSheetModal(for: self.window!)
                return exportItems
            }
            exportItems.append(ExportLightType(name: item.name, offset: item.dataOffset, count: lightBundle.count))
        }
        return exportItems

    }
    @IBAction func shuffleLightData(_ sender:Any?) {
        let exportItems = buildExportItems()
        guard !exportItems.isEmpty else { return }
        self.exportDialog.exportItems = exportItems
        self.window?.beginSheet(exportDialog.window!, completionHandler: { response in
            guard response == .OK else { return }
            if self.exportDialog.saveToSequence  {
                for index in 0..<self.sequence.sequenceItems.count {
                    self.sequence.sequenceItems[index].dataOffset = self.exportDialog.exportItems[index].offset
                }
            }
            self.renderAndSave(offsets: self.exportDialog.exportItems, lightURL: self.exportDialog.saveURL!)
        })

    }
    @IBAction func exportLightData(_ sender: Any?) {
        let panel = NSSavePanel()
        let exportItems = buildExportItems()
        guard !exportItems.isEmpty else { return }
        panel.allowedContentTypes = [UTType.light]
        panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.lightDirectory
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK else { return }
            self.renderAndSave(offsets: self.exportDialog.exportItems, lightURL: panel.url!)
        }
    }
    
    func renderAndSave(offsets:[ExportLightType],lightURL:URL) {
        // Total number of channels in a frame will be
        var frameLength = 0
        for item in offsets {
            frameLength = max(frameLength,item.offset + item.count)
        }
        let frameCount = Int(musicPlayer.duration / (Double(BlinkyGlobals.framePeriod)/1000.0)) + 1
        var frameData = [[UInt8]].init(repeating: [UInt8].init(repeating: 0, count: frameLength), count: frameCount)
        //Swift.print("Frame count: \(frameCount)  Frame Length: \(frameLength)  File size: \(frameData.count) Which should equal: \(frameLength * frameCount + 54)")
        let bundleDictionary = (NSApp.delegate as! AppDelegate).bundleDictionay
        
        do {
            try  itemManager.renderLightData()
            for (itemIndex,item) in itemManager.detailControllers.enumerated() {
                let bundleType = bundleDictionary[item.sequenceItem!.bundleType!]!
                let itemOffset = offsets[itemIndex].offset
                for frameIndex in 0..<frameCount {
                    var channelOffset = 0
                    for (lightIndex,light) in bundleType.lights.enumerated() {
                        //Swift.print("Saving: \(item.frameData[frameIndex][lightIndex].description) for light \(light.name) for frame: \(frameIndex) for sequence item: \(item.sequenceItem?.name ?? "")")
                        let data = light.dataForPixelColor(pixelColor: item.frameData[frameIndex][lightIndex])
                        let array = [UInt8](data)
                        for value in array {
                            frameData[frameIndex][itemOffset + channelOffset] = value
                            channelOffset += 1
                        }
                    }
                }
            }
            let lightFile = LightFile(frameCount: frameCount, frameLength: frameLength, musicName: self.musicPlayer.musicTitle, framePeriod: Double(BlinkyGlobals.framePeriod)/1000.0, lightData: frameData)
            try lightFile.saveTo(url: lightURL)
        }
        catch {
            NSAlert(error: GeneralError(errorMessage: "Error exporting to \(lightURL.path())", failure: error.localizedDescription)).beginSheetModal(for: self.window!)
        }
    }
}
// =========== Light Data Management
extension SequenceController {
    /*
    @IBAction func renderLightData(_ sender: Any? ) {
        do {
            try itemManager.renderLightData(background: true)
        }
        catch {
            NSAlert(error: error).beginSheetModal(for: self.window!)
        }
    }
     */
    @IBAction func renderInLineLightData( _ sender: Any?){
        
        do {
            try itemManager.renderLightData(background: false)
        }
        catch {
            NSAlert(error: error).beginSheetModal(for: self.window!)
        }
        /*
        Task {
            await self.itemManager.renderAllData()
        }
         */
    }
}

