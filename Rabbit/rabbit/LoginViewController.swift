//
//  LoginViewController.swift
//  rabbit
//
//  Created by zhangxu on 2018/6/4.
//  Copyright © 2018 yicheng. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var tfUsername: UITextField!
    @IBOutlet var tfPassword: UITextField!
    @IBOutlet var btLogin: UIButton!
    
    @IBAction func login(_ sender: Any) {
        print("login tap")
    }
    
}
