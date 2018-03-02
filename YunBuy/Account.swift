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
    
    func readPassword() -> String? {
        return KeychainSwift().get("password");
    }
}
