//
//  UIView+CornerRadius.swift
//  hippo
//
//  Created by 张旭 on 2018/5/31.
//  Copyright © 2018 张旭. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0;
        }
    }
}
