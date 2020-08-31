//
//  EraserTask.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/15.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class EraserTask  {
    let de = DrawingEditor.INSTANCE
    let parser = JSONParser.parser
    let erasedComponentIds: [Int]!
    var components: [DrawingComponent]!
    let queue = DispatchQueue(label: "eraseQueue")
    
    init(erasedComponentIds: [Int]) {
        //de.setDrawingView(((MainActivity) de.getContext()).getDrawingView());
        self.erasedComponentIds = erasedComponentIds
        self.components = [DrawingComponent]()
    }
    
    func execute() {
        
        queue.async {
            for i in 1..<self.erasedComponentIds.count {
                if let component = self.de.findDrawingComponentById(id: self.erasedComponentIds[i]) {
                    self.components.append(component)
                }
            }
            
            for i in 1..<self.erasedComponentIds.count {
                let id = self.erasedComponentIds[i]
                self.de.removeDrawingComponents(id: id)
            }
            
            self.de.eraseDrawingBoardArray(erasedComponentIds: self.erasedComponentIds)
            
            
            self.de.addHistory(item: DrawingItem(mode: Mode.ERASE, components: self.parser.getDrawingComponentAdapters(components: self.components)))    //fixme
            print("history.size()=\(self.de.history.count)")
            
            //self.de.printDrawingComponentArray(name: "cc", array: self.de.currentComponents, status: "erase")
            //self.de.printDrawingComponentArray(name: "dc", array: self.de.drawingComponents, status: "erase")
            
            DispatchQueue.main.async {
                self.de.clearDrawingImage()
                self.de.drawAllDrawingComponents()
            }
            
        }
        
    }
    
    func erase() {
        self.de.clearDrawingImage()
        
        for i in 1..<self.erasedComponentIds.count {
            if let component = self.de.findDrawingComponentById(id: self.erasedComponentIds[i]) {
                self.components.append(component)
            }
        }
        
        for i in 1..<self.erasedComponentIds.count {
            let id = self.erasedComponentIds[i]
            self.de.removeDrawingComponents(id: id)
        }
        
        self.de.drawAllDrawingComponents()
        
        
        self.de.eraseDrawingBoardArray(erasedComponentIds: self.erasedComponentIds)
        
        
        self.de.addHistory(item: DrawingItem(mode: Mode.ERASE, components: self.parser.getDrawingComponentAdapters(components: self.components)))    //fixme
        print("history.size()=\(self.de.history.count)")
        
        //self.de.lastDrawingImage = self.de.drawingView?.image
        
        //self.de.clearUndoArray()
        
        self.de.drawingView!.setNeedsDisplay()
        
        self.de.printDrawingComponentArray(name: "cc", array: self.de.currentComponents, status: "erase")
        self.de.printDrawingComponentArray(name: "dc", array: self.de.drawingComponents, status: "erase")
        
    }
}
