// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit
import UniformTypeIdentifiers
class AccessoryVisualizerController : NSWindowController {
    
    override var windowNibName: NSNib.Name? {
        return "AccessoryVisualizerController"
    }
    var musicName:String?
    weak var masterController:SequenceController?
    
    
    @IBOutlet var arrayController:NSArrayController!
    @objc dynamic var controllers = [VisualizerController]()
    @objc dynamic var windowTitle:String?
    var bundleDictionary:[String:LightBundle]{
        return (NSApp.delegate as! AppDelegate).bundleDictionay
    }
    @IBAction func createNewVisualization(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.prompt = "Selection Visualization file"
        guard let type = UTType(filenameExtension: "visualization") else { return }
        panel.allowedContentTypes = [ type ]
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK else { return }
            guard panel.url != nil else { return }
            let object = VisualizerController()
            if object.window == nil {
                object.loadWindow()
            }
            try? object.loadVisualization(url: panel.url!, bundles: self.bundleDictionary)
            object.loadLightFile(musicName: self.musicName!, masterController: self.masterController!)
            /*
            object.bind(NSBindingName("currentTime"), to: self.musicPlayer!, withKeyPath: "currentTime")
             */
            self.arrayController.addObject(object )
        }
        
    }
    
    /*
    @IBAction func importVisualization(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.prompt = "Select Bulk Visualization file"
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.beginSheetModal(for: self.window!) { response in
            guard response == .OK else { return }
            guard panel.url != nil else { return }
            guard let contents = try? String(contentsOf: panel.url!) else { return }
            //self.processBulk(contents: contents)
        }
    }
    */
    @IBAction func endDialog(_ sender: Any?) {
        self.close()
    }
    @IBAction func showAll(_ sender: Any?) {
        for entry in controllers {
            entry.showWindow(self)
        }

    }
    /*
    func processBulk(contents:String) {
        guard let master = masterLocation else { return }
        let lines = contents.components(separatedBy: "\n").map{ $0.trimmingCharacters(in: .whitespaces)}
        for line in lines {
            let components = line.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces)}
            if components.count == 2 {
                if components[0].lowercased() == "visual" {
                    let url = master.appending(path: components[1])
                    let object = VisualizerController()
                    if object.window == nil {
                        object.loadWindow()
                    }
                    try? object.loadVisualization(url: url, bundles: self.bundleDictionary)
                    if self.musicPlayer.isLoaded {
                        try? object.loadMusic(music: self.musicPlayer.musicTitle, base: self.masterLocation!)
                    }
                    object.bind(NSBindingName("currentTime"), to: self.musicPlayer!, withKeyPath: "currentTime")

                    self.arrayController.addObject(object )

                }
            }
        }
    }
     */
    
    func windowWillClose(_ notification: Notification) {
        for entry in controllers {
            entry.close()
        }
    }


}
