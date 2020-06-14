//
//  AccessDatabaseForLogin.swift
//  DrawingTogether
//
//  Created by admin on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import Firebase
import SVProgressHUD

class AccessDatabase {
    
    var ref: DatabaseReference!
    
    var topic: String!
    var password: String!
    var name: String!
    var masterName: String!
    var existTopic: Bool!
    
    func connect() {
        ref = Database.database().reference()
    }
    
    func runTransaction(topic: String, password: String, name: String, masterMode: Bool, handler: @escaping(String, Bool) -> Void) {
        self.topic = topic
        self.password = password
        self.name = name
        
        ref.child(topic).runTransactionBlock( {(currData: MutableData) -> TransactionResult in
            self.existTopic = false
            
            if var post =  currData.value as? [String: AnyObject] {  // not nil
                self.existTopic = true
                
                if masterMode {
                    print("exist topic")
                    self.masterName = ""
                }
                else {
                    post["username"] = [self.name: self.name] as AnyObject?  // override ,,, uu
                    self.masterName = post["master"] as? String
                }
                
                currData.value = post
                return TransactionResult.success(withValue: currData)
            }
            
            print("new topic")
            self.existTopic = false
            var post = [String: AnyObject]()
            
            if masterMode {
                post["password"] = self.password as AnyObject?
                post["username"] = [self.name: self.name] as AnyObject?
                post["master"] = self.name as AnyObject?
                self.masterName = self.name
            }
            else {
                print("not exist topic")
                self.masterName = ""
            }
            
            currData.value = post
            return TransactionResult.success(withValue: currData)
            
        }) { (error, commited, snapshot) in
            if let error = error { print(error.localizedDescription) }
            if commited {
                print("commited")
                handler(self.masterName, self.existTopic)
            }
        }
        
    }
    
}
