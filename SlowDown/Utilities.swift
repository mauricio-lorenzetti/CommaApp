//
//  Utilities.swift
//  SlowDown
//
//  Created by Mauk on 13/02/18.
//  Copyright © 2018 Mauricio Lorenzetti. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 5, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 5, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    
}

func delay(time: Double, execute:@escaping ()->()) {
    
    DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
        execute()
    })
    
}
