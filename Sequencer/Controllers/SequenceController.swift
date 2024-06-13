// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class SequenceController : NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "SequenceDocument"
    }
    
    var ourRulerName = randomAlphanumericString(5)
    var durationObserver:NSKeyValueObservation?
    
    @IBOutlet var musicPlayer:MusicPlayer!
    @IBOutlet var scrollLeft:SynchronizedScollView!
    @IBOutlet var scrollRight:SynchronizedScollView!
    
    @IBAction func seekToTime( _ sender: Any?) {
        musicPlayer.currentTime = seekTime
    }
    
    
    @objc dynamic var scale = 1.0 {
        didSet{
            dotsPerSecond = scale * BlinkyGlobals.dotsPerSecond
        }
    }
    @objc dynamic var dotsPerSecond = BlinkyGlobals.dotsPerSecond {
        didSet{
            scrollRight.registerScale(dotsPerSecond:dotsPerSecond,name:ourRulerName, abbreviation:ourRulerName )
            scrollRight.seekTo(seconds: musicPlayer.currentTime, dotsPerSecond:dotsPerSecond)
        }
    }
    @objc dynamic var seekTime = 0.0
    @objc dynamic var topStatus:String?
}

// ========== Window Delegate
extension SequenceController : NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        musicPlayer.stop()
    }
}
// ========== Convenience symbols
extension SequenceController {
    @objc dynamic var settingsData:SettingsData { (NSApp.delegate as! AppDelegate).settingsData }
    @objc dynamic var sequence:SequenceDocument { self.document as! SequenceDocument}
}

// ========== Basic startup
extension SequenceController {
    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        guard (self.document as? SequenceDocument)?.visualizationName != nil else { return displayName}
        return String(format:"%@ - %@",(self.document as! SequenceDocument).visualizationName!,displayName)

    }
    override func awakeFromNib() {
        super.awakeFromNib()
        scrollRight.hasHorizontalRuler = true
        scrollRight.rulersVisible = true
        scrollRight.registerScale(dotsPerSecond: dotsPerSecond, name: ourRulerName, abbreviation: ourRulerName)
        self.musicPlayer.volume = 0.25
        durationObserver = self.musicPlayer.observe(\.duration, changeHandler: { (_, _) in
            self.musicLoaded()
            self.durationObserver?.invalidate()
            self.durationObserver = nil
        })
        musicPlayer.loadMusic(url: (NSApp.delegate as! AppDelegate).settingsData.musicDirectory!.appending(path: (self.document as! SequenceDocument).musicName!).appendingPathExtension(for: .wav))
    }
    
    func musicLoaded() {
        // Put into here, anything that should happen on music load
    }
}
