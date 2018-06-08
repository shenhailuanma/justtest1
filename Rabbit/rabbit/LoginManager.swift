//
//  LoginManager.swift
//  rabbit
//
//  Created by zhangxu on 2018/6/7.
//  Copyright © 2018 yicheng. All rights reserved.
//

import Foundation
import SwiftHTTP


class LoginManager {
    
    func login() {
        // just test
        HTTP.GET("https://www.baidu.com", parameters: ["hello": "world", "param2": "value2"]) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            print("opt finished: \(response.description)")
        }
    }
}
