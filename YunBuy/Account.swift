//
//  Account.swift
//  YunBuy
//
//  Created by Jia Tian on 3/2/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import Foundation
import KeychainSwift

struct Account {
    
    func readUsername() -> String? {
        return KeychainSwift().get("username");
    }
    
    func setUsername(username: String) {
        KeychainSwift().set(username, forKey: "username")
    }
    
    func readPassword() -> String? {
        return KeychainSwift().get("password");
    }
    func setPassword(password: String) {
        KeychainSwift().set(password, forKey: "password")
    }
    
    func readPayPassword() -> String? {
        return KeychainSwift().get("pay_password")
    }
    
    func setPayPassword(password: String) {
        KeychainSwift().set(password, forKey: "pay_password")
    }
    
    func getToken() -> String? {
        return KeychainSwift().get("token");
    }
    
    func setToken(token: String) {
        KeychainSwift().set(token, forKey: "token")
    }
}
