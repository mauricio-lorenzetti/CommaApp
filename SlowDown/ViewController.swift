//
//  ViewController.swift
//  SlowDown
//
//  Created by Mauk on 10/02/18.
//  Copyright © 2018 Mauricio Lorenzetti. All rights reserved.
//

import UIKit
import Pulsator
import Hero
import CoreMotion
import AMPopTip

class ViewController: UIViewController {
    
    @IBOutlet weak var commaImage: UIImageView!
    
    let commasCompletedKey = "commasCompleted"
    var timer:Timer?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    override var shouldAutorotate: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //handle device orientation when locked
        let motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates()
        
        timer = Timer(fire: Date(), interval: 0.2, repeats: true, block: { (timer) in
                // Get the accelerometer data.
                if let data = motionManager.accelerometerData {
                    if  abs(data.acceleration.x) > 0.7 && abs(data.acceleration.x) < 1.0 {
                        self.transitionToTimer(orientation: data.acceleration.x > 0 ? UIInterfaceOrientationMask.landscapeLeft : UIInterfaceOrientationMask.landscapeRight )
                        timer.invalidate()
                    }
            }
        })
        
        // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
        
        delay(time: 1.0, execute: showPoptip)
    }
    
    @objc private func showPoptip() {
        commaImage.shake()
        let popTip = PopTip()
        popTip.shouldDismissOnTap = true
        popTip.entranceAnimation = .scale
        popTip.bubbleColor = UIColor(red: 247.0/255.0, green: 215.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        let commasCompleted = UserDefaults.standard.integer(forKey: commasCompletedKey)
        popTip.show(text: "\(commasCompleted) commas completed", direction: .right, maxWidth: 100, in: self.view, from: commaImage.frame, duration: 4)
    }
    
    private func transitionToTimer(orientation: UIInterfaceOrientationMask) {
        let timerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "timerVC") as! TimerViewController
        
        //info
        timerVC.orientation = orientation
        
        //hero
        timerVC.hero.isEnabled = true
        timerVC.hero.modalAnimationType = .zoom
        self.hero.replaceViewController(with: timerVC)
    }
    
    @objc func deviceDidRotate(notification: NSNotification) {
        if UIDevice.current.orientation.isLandscape {
            transitionToTimer(orientation: UIInterfaceOrientationMask.landscape)
        }
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if commaImage.frame.contains((touches.first?.location(in: self.view))!) {
            showPoptip()
        }
    }
    
}
