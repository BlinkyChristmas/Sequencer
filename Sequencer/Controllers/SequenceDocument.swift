// 

import Cocoa
import UniformTypeIdentifiers
class SequenceDocument: NSDocument {

    @objc dynamic var sequenceItems = [SeqItem]()
    @objc dynamic var timeGrids = [TimeGrid]()
    @objc dynamic var musicName:String?
    @objc dynamic var visualScale = 1.0
    @objc dynamic var visualSize = NSSize.zero
    @objc dynamic var visualizationName:String?
    @objc dynamic var framePeriod = 0.037
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return false
    }


    override func makeWindowControllers() {
        self.addWindowController(SequenceController())
    }
    override func data(ofType typeName: String) throws -> Data {
        guard typeName == BlinkyGlobals.sequenceIdentifier else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        let root = XMLElement(name: "sequence")
        var node = XMLNode(kind: .attribute)
        node.name = "framePeriod"
        node.stringValue = String(format:"%.3f",framePeriod)
        root.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "musicName"
        node.stringValue = self.musicName
        root.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "visualScale"
        node.stringValue = String(format:"%.3f",self.visualScale)
        root.addAttribute(node)
        
        node = XMLNode(kind: .attribute)
        node.name = "visualSize"
        node.stringValue = visualSize.stringValue
        root.addAttribute(node)
        

        node = XMLNode(kind: .attribute)
        node.name = "visualizationName"
        node.stringValue = self.visualizationName
        root.addAttribute(node)
        
        for entry in sequenceItems {
            root.addChild(entry.xml)
        }
        for entry in timeGrids {
            root.addChild(entry.xml)
        }
        let xmldoc = XMLDocument(rootElement: root)
        xmldoc.version = "1.0"
        xmldoc.characterEncoding = "UTF-8"

        return xmldoc.xmlData(options: .nodePrettyPrint)

    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard typeName == BlinkyGlobals.sequenceIdentifier else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        let xmldoc = try XMLDocument(data: data)
        xmldoc.version = "1.0"
        xmldoc.characterEncoding = "UTF-8"
        guard xmldoc.rootElement()?.name == "sequence" else {
            throw GeneralError(errorMessage: "Sequence is missing the proper root element 'sequence'")
        }
        try processAttributes(xmldoc: xmldoc)
        for item in xmldoc.rootElement()!.elements(forName: "sequenceItem") {
            sequenceItems.append(try SeqItem(element: item))
        }
        // now get the grids
        for grid in xmldoc.rootElement()!.elements(forName: "timingGrid") {
            timeGrids.append(try TimeGrid(element: grid))
        }
        // For legacy purposes, we try to get timing grids that are nested
        for child in xmldoc.rootElement()!.elements(forName: "timingGrids") {
            for grid in child.elements(forName: "timingGrid") {
                timeGrids.append(try TimeGrid(element: grid))
            }
        }
    }
    
    func processAttributes(xmldoc:XMLDocument) throws {
        var node = xmldoc.rootElement()?.attribute(forName: "musicName")
        if node?.stringValue == nil {
            node = xmldoc.rootElement()?.attribute(forName: "media")
        }
        guard node?.stringValue != nil else {
            throw GeneralError(errorMessage: "Sequence is missing musicName attribute value")
        }
        musicName = URL(filePath: node!.stringValue!).deletingPathExtension().lastPathComponent
        
        node = xmldoc.rootElement()?.attribute(forName: "visualScale")
        if node?.stringValue != nil {
            guard let temp = Double(node!.stringValue!) else {
                throw GeneralError(errorMessage: "Invalid value for scale attribute in sequence document: \(node!.stringValue!)")
            }
            visualScale = temp
        }
        node = xmldoc.rootElement()?.attribute(forName: "visualSize")
        if node?.stringValue != nil {
            visualSize = (try? NSSize.sizeFor(string: node!.stringValue!)) ?? NSSize.zero
        }

        // and lastly get the visualizationName
        node = xmldoc.rootElement()?.attribute(forName: "visualizationName")
        if node?.stringValue != nil {
            visualizationName = node!.stringValue
        }

    }
    
    convenience init(url:URL) throws {
        self.init()
        let data = try Data(contentsOf: url)
        try read(from: data, ofType:  BlinkyGlobals.sequenceIdentifier)
    }
}

