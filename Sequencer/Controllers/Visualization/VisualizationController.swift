// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class VisualizationController : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "VisualizationController"
    }
    @IBOutlet var visualView:VisualizationView!
    
    var visualization:Visualization?
    var lightFile:LightFile?
    
    var musicTitleObserver:NSKeyValueObservation?
    deinit {
        musicTitleObserver?.invalidate()
    }
    
    @objc dynamic var currentTime = 0.0 {
        didSet{
            guard self.window != nil else { return }
            self.visualView.needsDisplay = true
        }
    }
    var currentFrame:Int {
        Int((currentTime / ( Double(BlinkyGlobals.framePeriod) / 1000.0)).rounded())
    }
    @objc dynamic var isPlaying = false
    
    @objc dynamic weak var masterController:SequenceController? {
        willSet{
            if masterController != nil {
                self.unbind(NSBindingName("currentTime"))
                self.unbind(NSBindingName("isPlaying"))
                musicTitleObserver?.invalidate()
                musicTitleObserver = nil
                
            }
        }
        didSet {
            if masterController != nil {
                self.bind(NSBindingName("currentTime"), to: masterController!.musicPlayer!, withKeyPath: "currentTime")
                self.bind(NSBindingName("isPlaying"), to: masterController!.musicPlayer!, withKeyPath: "isPlaying")
                musicTitleObserver = masterController!.musicPlayer.observe(\.musicTitle, changeHandler: { player, _ in
                    var url = (NSApp.delegate as! AppDelegate).settingsData.lightDirectory
                    if url != nil {
                        if !player.musicTitle.isEmpty {
                            url = url!.appending(path: self.visualization!.dataLocation!).appending(path: player.musicTitle).appendingPathExtension("light")
                            
                            self.lightFile = try? LightFile(url: url!)
                        }
                    }
                })
            }
        }
    }
    
    @objc dynamic var visualScale = 1.0 {
        didSet{
           let size =  self.calculateSize(oldScale: oldValue, newScale: visualScale)
            self.window?.setFrame(NSRect(origin: self.window!.frame.origin, size: size), display: true)
        }
    }
    
    override func close() {
        //self.masterController?.windowWillClose(controller: self)
        super.close()
    }
    
    func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSBezierPath.fill(self.visualView.bounds)
        guard let lightFile = lightFile else { return }
        guard let visualization = visualization else { return }
        guard let data = try? lightFile.frameFor(frameNumber: currentFrame) else {  return }
        guard !visualization.visualItems.isEmpty else { return }
        let frame =  currentFrame
        if frame < lightFile.count {
            // we should draw something
            var baseTransform: AffineTransform?
            
            if visualScale != 1.0 {
                baseTransform = AffineTransform(scale: visualScale)
            }

            for item in visualization.visualItems {
                if baseTransform != nil {
                    (baseTransform! as NSAffineTransform).set()
                }
                item.draw(frame: Array(data[item.offset..<item.offset+item.lightBundle!.count]))
            }
        }
    }
    
    func calculateSize(oldScale:Double,newScale:Double)->NSSize {
        guard self.window != nil else { return visualization?.visualSize ?? NSSize.zero}
        let viewsize = self.visualView.frame.size
        let winsize = self.window!.frame.size
        let deltawidth = winsize.width - viewsize.width
        let deltaheight = winsize.height - viewsize.height
        let width = (viewsize.width / oldScale ) * newScale
        let height = (viewsize.height / oldScale) * newScale
        return NSSize(width: width + deltawidth, height: height + deltaheight)
    }
    
    func setupSizeDueToLoad() {
        // Ok now we get to do all the fun stuff!
        guard let visualization = self.visualization else { return }
        var origin = self.window!.frame.origin
        if visualization.visualOrigin != NSPoint.zero {
            origin = visualization.visualOrigin
        }
        if visualization.visualSize == NSSize.zero {
            return
        }
        self.window!.setFrame(NSRect(origin: origin, size: visualization.visualSize), display: true)
        Swift.print("Origin for \(self.window!.title) is \(origin)")
        self.window?.setFrameOrigin(origin)
        // Now, we adjust to the our scale
        self.visualScale = visualization.visualScale

    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = visualization!.name ?? "Undefined"
        self.setupSizeDueToLoad()
        if masterController!.musicPlayer.isLoaded {
            let url = masterController!.settingsData.lightDirectory!.appending(path: self.visualization!.dataLocation!).appending(path: masterController!.musicPlayer.musicTitle).appendingPathExtension("light")
            self.lightFile = try? LightFile(url: url)

        }
 
   }

}
