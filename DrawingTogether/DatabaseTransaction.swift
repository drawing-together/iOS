//
//  DatabaseTransaction.swift
//  DrawingTogether
//
//  Created by admin on 2020/08/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Firebase
import SVProgressHUD

class DatabaseTransaction {
    
    var ref: DatabaseReference!
    
    var masterName: String!
    
    var topicError: Bool!
    var passwordError: Bool!
    var nameError: Bool!
    
    func connect() {
        ref = Database.database().reference()
    }
    
    func runTransactionLogin(topic: String, password: String, name: String, masterMode: Bool, handler: @escaping(String, String, Bool, Bool, Bool) -> Void) {
        SVProgressHUD.show()
        
        ref.child(topic).runTransactionBlock( {(currData: MutableData) -> TransactionResult in
            self.topicError = false
            self.passwordError = false
            self.nameError = false
            
            if var post =  currData.value as? [String: AnyObject] {  // not nil
                self.topicError = true
                print("[received]")
                print(post)
                
                switch (masterMode) {
                case true:
                    print("[master mode]: exist topic")
                    self.masterName = ""
                case false:
                    print("[join mode]: exist topic")
                    if password != post["password"]! as? String {
                        self.passwordError = true
                        break
                    }
                    if var names = post["username"]! as? [String: String] {
                        print("[Dictionary]")
                        print(names)
                        if names.keys.contains(name) {
                            self.nameError = true
                            break
                        }
                        names[name] = name
                        post["username"] = names as AnyObject
                        self.masterName = post["master"] as? String
                        
                        print("[upload]")
                        print(post)
                        break
                    }
                    if let names = post["username"]! as? NSArray {
                        print("Array")
                        print(names)
                        if names.contains(name) {
                            self.nameError = true
                            break
                        }
                        var dic = [String: String]()
                        for (_, value) in names.enumerated() {
                            if let val = value as? String {
                                dic[val] = val
                            }
                        }
                        dic[name] = name
                        post["username"] = dic as AnyObject
                        self.masterName = post["master"] as? String
                        print("new name")
                    }
                    
                }
                currData.value = post
                return TransactionResult.success(withValue: currData)
            }
            
            switch (masterMode) {
            case true:
                print("[master mode]: new topic")
                var post = [String: AnyObject]()
                post["password"] = password as AnyObject
                
                var username = [String: String]()
                username[name] = name
                post["username"] = username as AnyObject
                
                post["master"] = name as AnyObject
                self.masterName = name

                print("[upload]")
                print(post)
                currData.value = post
            case false:
                print("join mode: not exist topic")
                self.masterName = ""
            }
            return TransactionResult.success(withValue: currData)
            
        }) { (error, commited, snapshot) in
            var errorMsg = ""
            if let error = error {
                print(error.localizedDescription)
                errorMsg = error.localizedDescription
            }
            if commited {
                print("commited")
                handler(errorMsg, self.masterName, self.topicError, self.passwordError, self.nameError)
            }
        }
        
    }
    
    func runTranscationExit(topic: String, name: String, masterMode: Bool, handler: @escaping(String) -> Void) {
        
        ref.child(topic).runTransactionBlock( {(currData: MutableData) -> TransactionResult in
            
            if var post =  currData.value as? [String: AnyObject], masterMode {
                currData.value = nil
            }
            if var post =  currData.value as? [String: AnyObject], !masterMode {
                print("[received]")
                print(post)
                
                if var names = post["username"]! as? [String: String] {
                    print("Dictionary")
                    if names.keys.contains(name) {
                        names[name] = nil
                        post["username"] = names as AnyObject
                        
                        print("[upload]")
                        print(post)
                        currData.value = post
                    }
                }
                else if let names = post["username"]! as? NSArray {
                    print("Array")
                    if names.contains(name) {
                        var dic = [String: String]()
                        for (_, value) in names.enumerated() {
                            if let val = value as? String {
                                dic[val] = val
                            }
                        }
                        dic[name] = nil
                        post["username"] = dic as AnyObject

                        print("[upload]")
                        print(post)
                        currData.value = post
                    }
                }
            }
            return TransactionResult.success(withValue: currData)
            
        }) { (error, commited, snapshot) in
            var errorMsg = ""
            if let error = error {
                print(error.localizedDescription)
                errorMsg = error.localizedDescription
            }
            if commited {
                print("commited")
                handler(errorMsg)
            }
        }
        
    }
    
}
