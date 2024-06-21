// Copyright © 2024 Charles Kerr. All rights reserved.

import Foundation
import AppKit

class GridContainer : NSViewController {
    override var nibName: NSNib.Name? {
        return "GridContainer"
    }
    var isGridEnable = false {
        didSet{
            activeGridController.isEnabled = isGridEnable
        }
    }
    @objc dynamic weak var sequence:SequenceDocument?
    var dotsPerSecond = BlinkyGlobals.dotsPerSecond {
        didSet{
            activeGridController.dotsPerSecond = dotsPerSecond
            ref1GridController.dotsPerSecond = dotsPerSecond
            ref2GridController.dotsPerSecond = dotsPerSecond
            ref3GridController.dotsPerSecond = dotsPerSecond
        }
    }
    @IBOutlet var activeGridController:TimeGridController!
    @IBOutlet var ref1GridController:TimeGridController!
    @IBOutlet var ref2GridController:TimeGridController!
    @IBOutlet var ref3GridController:TimeGridController!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        activeGridController.gridNumber = 0
        ref1GridController.gridNumber = 1
        ref2GridController.gridNumber = 2
        ref3GridController.gridNumber = 3

        activeGridController.view.frame = self.view.bounds
        self.view.addSubview(activeGridController.view)
        ref3GridController.view.frame = self.view.bounds
        self.view.addSubview(ref3GridController.view)
        ref2GridController.view.frame = self.view.bounds
        self.view.addSubview(ref2GridController.view)
        ref1GridController.view.frame = self.view.bounds
        self.view.addSubview(ref1GridController.view)
    }
    
    func setGrid(gridNumber:Int, timeGrid:TimeGrid?) {
        switch gridNumber {
        case 0:
            activeGridController.timeGrid = timeGrid
        case 1:
            ref1GridController.timeGrid = timeGrid
        case 2:
            ref2GridController.timeGrid = timeGrid
        case 3:
            ref3GridController.timeGrid = timeGrid
        default:
            break
        }
    }
    
    func refreshViews(withRebuild:Bool = false) {
        if withRebuild {
            self.activeGridController.drawPath = self.activeGridController.buildPaths()
        }
        self.activeGridController.refresh()
        if withRebuild {
            self.ref1GridController.drawPath = self.ref1GridController.buildPaths()
        }
        self.ref1GridController.refresh()
        if withRebuild {
            self.ref2GridController.drawPath = self.ref2GridController.buildPaths()
        }
        self.ref2GridController.refresh()

        if withRebuild {
            self.ref3GridController.drawPath = self.ref3GridController.buildPaths()
        }
        self.ref3GridController.refresh()
    }
    
}
