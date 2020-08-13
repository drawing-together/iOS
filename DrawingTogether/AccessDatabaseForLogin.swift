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
    
    var topicError: Bool!
    var passwordError: Bool!
    var nameError: Bool!
    
    func connect() {
        ref = Database.database().reference()
    }
    
    func runTransaction(topic: String, password: String, name: String, masterMode: Bool, handler: @escaping(String, Bool, Bool, Bool) -> Void) {
        SVProgressHUD.show()
        
        self.topic = topic
        self.password = password
        self.name = name
        
        ref.child(self.topic).runTransactionBlock( {(currData: MutableData) -> TransactionResult in
            self.topicError = false
            self.passwordError = false
            self.nameError = false
            
            if var post =  currData.value as? [String: AnyObject] {  // not nil
                self.topicError = true
                print(post)
                
                switch (masterMode) {
                case true:
                    print("master mode")
                    print("exist topic")
                    self.masterName = ""
                case false:
                    print("join mode")
                    print("exist topic")
                    if self.password != post["password"]! as? String {
                        self.passwordError = true
                        print("pwderr")
                        break
                    }
                    if var names = post["username"]! as? [String: AnyObject] {
                        print("dicccccccccccccccccccc")
                        if names.keys.contains(self.name) {
                            self.nameError = true
                            break
                        }
                        names[self.name] = self.name as AnyObject?
                        post["username"] = names as AnyObject?
                        self.masterName = post["master"] as? String
                        print("new name")
                    }
                    if var names = post["username"]! as? NSArray {
                        print("arrrrrrrrrrrrrrrrrrrrr")
                        print(names)
                        if names.contains(self.name) {
                            self.nameError = true
                            break
                        }

                        var arrayToDic = [String: AnyObject]()
                        for (_, value) in names.enumerated() {
                            arrayToDic[value as! String] = value as AnyObject?
                        }
                        arrayToDic[self.name] = self.name as AnyObject?
                        post["username"] = arrayToDic as AnyObject?
                        self.masterName = post["master"] as? String
                        print("new name")
                    }
                    
                }
                
                currData.value = post
                return TransactionResult.success(withValue: currData)
            }
            
            switch (masterMode) {
            case true:
                print("master mode")
                print("new topic")
                var post = [String: AnyObject]()
                post["password"] = self.password as AnyObject
                post["username"] = [self.name: self.name] as AnyObject
                post["master"] = self.name as AnyObject
                self.masterName = self.name
                print(post)
                currData.value = post
            case false:
                print("join mode")
                print("not exist topic")
                self.masterName = ""
            }
            return TransactionResult.success(withValue: currData)
            
        }) { (error, commited, snapshot) in
            if let error = error { print(error.localizedDescription) }
            if commited {
                print("commited")
                handler(self.masterName, self.topicError, self.passwordError, self.nameError)
            }
        }
        
    }
    
}
