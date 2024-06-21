// 

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var settingsData:SettingsData!
    @IBOutlet var newSequenceDialog:NewSequenceDialog!
    
    var bundleDictionay = [String:LightBundle]()
    var bundleObserver:NSKeyValueObservation?
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        bundleObserver = settingsData.observe(\.bundleFile, changeHandler: { settings, _ in
            self.processBundles()
        })
        self.processBundles()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    func processBundles() {
        guard let url = settingsData.completeBundle else {
            NSDocumentController.shared.presentError(GeneralError(errorMessage: "Unable to process bundles", failure: "Bundle file or Base Directory is not set"))
            return
        }
        do{
            bundleDictionay = try Sequencer.processBundles(url: url)
        }
        catch{
            NSDocumentController.shared.presentError(GeneralError(errorMessage: "Unable to process bundles", failure: error.localizedDescription))
        }
    }

}

extension AppDelegate {
    @IBAction func importDIYBSEQ( _ sender: Any? ) {
        let panel = NSOpenPanel()
        panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.sequenceDirectory
        panel.allowedContentTypes = [.diybseq]
        panel.prompt = "Select diybseq sequence for import"
        let response = panel.runModal()
        if response == .OK {
            do{
                let untitled = (try NSDocumentController.shared.makeUntitledDocument(ofType:BlinkyGlobals.sequenceIdentifier )) as! SequenceDocument
                let document = (try NSDocumentController.shared.makeDocument(withContentsOf: panel.url!, ofType: BlinkyGlobals.sequenceIdentifier)) as! SequenceDocument
                untitled.timeGrids = document.timeGrids
                untitled.sequenceItems = document.sequenceItems
                untitled.musicName = document.musicName
                untitled.framePeriod = document.framePeriod
                untitled.visualizationName = panel.url!.deletingLastPathComponent().lastPathComponent
                var channelOffset = 0
                for item in untitled.sequenceItems {
                    if item.bundleType != nil  {
                        item.dataOffset = channelOffset
                        let bundle = bundleDictionay[item.bundleType!]
                        if bundle != nil {
                            channelOffset += bundle!.count
                        }
                    }
                }
                untitled.makeWindowControllers()
                untitled.showWindows()
                NSDocumentController.shared.addDocument(untitled)
                untitled.updateChangeCount(.changeDone)
            }
            catch{
                NSDocumentController.shared.presentError(GeneralError(errorMessage: "Unable to import: \(panel.url?.path() ?? "" )", failure: error.localizedDescription))
                
            }
        }
    }

    @IBAction func newDocument( _ sender: Any?) {
        let value =  NSApp.runModal(for: self.newSequenceDialog.window!)
        guard value == .OK else { return}
        do {
            let untitled = (try NSDocumentController.shared.makeUntitledDocument(ofType:BlinkyGlobals.sequenceIdentifier )) as! SequenceDocument
            let visualalization = try Visualization(url: newSequenceDialog.selectedVisualization!, bundles: self.bundleDictionay)
            var dataOffset = 0
            untitled.visualizationName = visualalization.name
            untitled.visualScale = visualalization.scale
            untitled.musicName = self.newSequenceDialog.music
            for item in visualalization.visualItems {
                let seqItem = SeqItem()
                seqItem.name = item.name
                seqItem.bundleType = item.bundleType
                seqItem.dataOffset = dataOffset
                dataOffset = dataOffset + bundleDictionay[seqItem.bundleType!]!.count
                seqItem.visualScale = item.scale
                seqItem.visualOrigin = item.origin
                untitled.sequenceItems.append(seqItem)
            }
            // Now, get any timegrids
            if self.newSequenceDialog.selectedImport != nil {
                let sequence = try SequenceDocument(url: self.newSequenceDialog.selectedImport!)
                untitled.timeGrids = sequence.timeGrids
            }
            untitled.makeWindowControllers()
            untitled.showWindows()
            NSDocumentController.shared.addDocument(untitled)
            untitled.updateChangeCount(.changeDone)
        }
        catch{
            NSAlert(error: GeneralError(errorMessage: "Unable to create new sequence")).runModal()
        }
        
    }
}
