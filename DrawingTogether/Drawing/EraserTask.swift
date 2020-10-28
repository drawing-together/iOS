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
    //var erasedComponentIds: [Int]!
    var components = [DrawingComponent]()
    let queue = DispatchQueue(label: "eraseQueue")
    
    init() {
        
    }
    
    func execute(erasedComponentIds: [Int]) {
        if erasedComponentIds.count == 0 { return }
        
        //self.erasedComponentIds = erasedComponentIds
        self.components.removeAll()
        
        queue.async {
            //for i in 1..<self.erasedComponentIds.count {
            for i in 0..<erasedComponentIds.count {
                autoreleasepool {
                    if let component = self.de.findDrawingComponentById(id: erasedComponentIds[i]) {
                        if component.isSelected, let usersComponentId = component.usersComponentId {
                            self.de.setDrawingComponentSelected(usersComponentId, isSelected: false)
                            //self.de.clearMyCurrentImage()
                            self.de.drawingVC!.drawingView.isSelected = false
                        }
                        component.isSelected = false
                        self.components.append(component)
                    }
                }
            }
            
            //for i in 1..<self.erasedComponentIds.count {
            for i in 0..<erasedComponentIds.count {
                autoreleasepool {
                    let id = erasedComponentIds[i]
                    self.de.removeDrawingComponents(id: id)
                    
                    // MARK: monitoring
                    
                    // fixme nayeon
                    if(MQTTClient.client.master) {
                        MQTTClient.client.componentCount!.increaseErase()
                    }
                    
                }
            }
            
            self.de.eraseDrawingBoardArray(erasedComponentIds: erasedComponentIds)
            
            let copyComponents = self.components.map({ $0.clone()! })
            
            self.de.addHistory(item: DrawingItem(mode: Mode.ERASE, components: self.parser.getDrawingComponentAdapters(components: copyComponents)))    //fixme
            print("history.size()=\(self.de.history.count)")
            
            
            //self.de.printDrawingComponentArray(name: "cc", array: self.de.currentComponents, status: "erase")
            //self.de.printDrawingComponentArray(name: "dc", array: self.de.drawingComponents, status: "erase")
            
            DispatchQueue.main.async {
                self.de.clearDrawingImage()
                self.de.drawAllDrawingComponents()
                
                if self.de.currentMode == Mode.SELECT, self.de.drawingView!.isSelected, let component = self.de.selectedComponent {
                    if let id = component.id, let comp = self.de.findDrawingComponentById(id: id), comp.isSelected {
                        self.de.setPreSelectedComponents(id: id)
                        self.de.setPostSelectedComponents(id: id)
                        
                        self.de.clearMyCurrentImage()
                        
                        self.de.setPreAndPostSelectedComponentsImage()
                        
                        component.drawComponent(view: self.de.drawingVC!.myCurrentView, drawingEditor: self.de)
                        self.de.drawUnselectedComponents()
                        self.de.drawSelectedComponentBorder(component: component, color: self.de.mySelectedBorderColor.cgColor)
                    }
                }
            }
            
        }
        
    }
}
