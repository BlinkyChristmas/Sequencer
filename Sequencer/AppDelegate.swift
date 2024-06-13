// 

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var settingsData:SettingsData!
    
    @IBAction func importDIYBSEQ( _ sender: Any? ) {
        let panel = NSOpenPanel()
        panel.directoryURL = (NSApp.delegate as! AppDelegate).settingsData.sequenceDirectory
        panel.allowedContentTypes = [.diybseq]
        panel.prompt = "Select diybseq sequence for import"
        let response = panel.runModal()
        if response == .OK {
            do{
                let untitled = try NSDocumentController.shared.makeDocument(withContentsOf: panel.url!, ofType: BlinkyGlobals.sequenceIdentifier)
                untitled.makeWindowControllers()
                untitled.showWindows()
            }
            catch{
                NSAlert(error: GeneralError(errorMessage: "Unable to import: \(panel.url?.path() ?? "" )", failure: error.localizedDescription)).runModal()
            }

        }

    }
    
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

