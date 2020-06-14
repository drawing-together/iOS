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
    let erasedComponentIds: [Int]?
    var components: [DrawingComponent]?
    
    init(erasedComponentIds: [Int]) {
        //de.setDrawingView(((MainActivity) de.getContext()).getDrawingView());
        self.erasedComponentIds = erasedComponentIds
        self.components = [DrawingComponent]()
        
        
    }
    
    func execute() {
        DispatchQueue.global(qos: .background).async {
            
            DispatchQueue.main.async {
                self.de.clearDrawingBitmap()
                
                for i in 1..<self.erasedComponentIds!.count {
                    self.components!.append(self.de.findDrawingComponentById(id: self.erasedComponentIds![i])!)
                }
                
                for i in 1..<self.erasedComponentIds!.count {
                    let id = self.erasedComponentIds![i]
                    self.de.removeDrawingComponents(id: id)
                }
                
                self.de.drawAllDrawingComponents()
                self.de.drawAllCurrentStrokes()
                
                self.de.eraseDrawingBoardArray(erasedComponentIds: self.erasedComponentIds!)
                
                
                self.de.addHistory(item: DrawingItem(mode: Mode.ERASE, components: self.parser.getDrawingComponentAdapters(components: self.components!)))    //fixme
                print("history.size()=\(self.de.history.count)")
                //self.de.setLastDrawingBitmap(self.de.getDrawingBitmap().copy(self.de.getDrawingBitmap().getConfig(), true));
                
                //de.clearUndoArray();
                //de.getDrawingView().invalidate();
                
                self.de.printCurrentComponents(status: "erase")
                self.de.printDrawingComponents(status: "erase")
            }
            
        }
    }
}
