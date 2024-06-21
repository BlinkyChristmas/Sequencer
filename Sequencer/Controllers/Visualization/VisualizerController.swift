// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class VisualizerController : NSWindowController{
    override var windowNibName: NSNib.Name?{
        return "VisualizerController"
    }
    @objc dynamic var currentTime:Double = 0.0 {
        didSet{
            self.currentFrame = Int(currentTime / ( Double(BlinkyGlobals.framePeriod)/1000.0))
        }
    }
    var currentFrame = 0{
        didSet{
            self.window?.contentView?.needsDisplay = true
            
        }
    }
    var lightFile = LightFile()
    var visualization = Visualization()
    @objc dynamic var name:String {
        return visualization.name!
    }
    @objc dynamic var scale = 1.0 {
        didSet{
            self.window?.contentView?.needsDisplay = true
        }
    }
    deinit {
        self.unbind(NSBindingName("currentTime"))
        self.close()
    }
}

extension VisualizerController {
    func loadVisualization(url:URL,bundles:[String:LightBundle]) throws {
        visualization = try Visualization(url: url, bundles: bundles)
        self.window?.title = visualization.name ?? "Visualization"
        self.scale = visualization.scale
    }
    
    func loadLightFile(musicName:String, masterController:SequenceController) {
        do {
            lightFile =  try LightFile(url: (NSApp.delegate as! AppDelegate).settingsData.lightDirectory!.appending(path: visualization.dataLocation!).appending(path: musicName).appendingPathExtension("light") )
            masterController.bind(NSBindingName("currentTime"), to: masterController.musicPlayer!, withKeyPath: "currentTime")
        }
        catch {
            
        }
    }
    func loadMusic(music:String,base:URL) throws  {
        guard let location = visualization.dataLocation else {
            throw NSError(domain: "Sequencer", code: 0, userInfo: [NSLocalizedDescriptionKey:"Data location is nil"])
        }
        //Swift.print("path is '\(base.path())' and location is '\(location)' and file is \(music+".light")'")
        let url = base.appending(path: location).appending(path:music + ".light")
        do{
            lightFile = try LightFile(url: url)
        }
        catch {
            Swift.print("Load: \(url.path()) failed with \(error.localizedDescription)")
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        //guard  visualization.screenSize != nil,visualization.screenCoordinates != nil else { return }
        //self.window?.setFrame(NSRect(origin: visualization.screenCoordinates!, size: visualization.screenSize!), display: true)
    }
}
