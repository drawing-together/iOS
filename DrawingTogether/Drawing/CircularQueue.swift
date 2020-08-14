//
//  CircularQueue.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/07/23.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class CircularQueue {
    var values: [MqttMessageFormat?]
    var capacity: Int
    var head: Int
    var tail: Int
    
    // capacity로 사이즈 초기화
    init(capacity: Int) {
        self.values = [MqttMessageFormat?](repeating: nil, count: capacity)
        self.capacity = 0
        self.head = -1
        self.tail = -1
    }
    
    // 꼬리에 요소 추가
    func offer(value: MqttMessageFormat) -> Bool {
        guard !isFull() else { return false }
        tail = nextIndex(value: tail)
        values[tail] = value
        
        if isEmpty() {
            head = tail
        }
        
        capacity += 1
        return true
    }
    
    // 머리 요소 제거해서 반환
    func poll() -> MqttMessageFormat? {
        guard !isEmpty() else { return nil }
        let headElement = values[head]
        values[head] = nil
        head = nextIndex(value: head)
        capacity -= 1
        return headElement
    }
    
    // 머리 요소 반환
    func peek() -> MqttMessageFormat? {
        guard !isEmpty() else { return nil }
        return values[head]
    }
    
    // 꼬리 요소 반환
    func rear() -> MqttMessageFormat? {
        guard !isEmpty() else { return nil }
        return values[tail]
    }
    
    
    func isEmpty() -> Bool {
        return capacity == 0
    }
    
    
    func isFull() -> Bool {
        return capacity >= values.count
    }
    
    
    func nextIndex(value: Int) -> Int {
        if value >= (values.count - 1) {
            return 0
        }
        return (value + 1)
    }
}
