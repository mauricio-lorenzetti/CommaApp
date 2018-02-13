//
//  TimerViewController.swift
//  SlowDown
//
//  Created by Mauk on 10/02/18.
//  Copyright © 2018 Mauricio Lorenzetti. All rights reserved.
//

import UIKit
import Pulsator
import AudioToolbox.AudioServices
import UIKit.UIGestureRecognizerSubclass
import CoreMotion
import Hero
import AMPopTip

enum State {
    case ready
    case running
    case finished
}

class TimerViewController: UIViewController {

    @IBOutlet weak var leftFingerprint: UIImageView!
    @IBOutlet weak var rightFingerprint: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var touchView: UIView!
    @IBOutlet weak var commaImage: UIImageView!
    
    var state:State = .ready
    
    var isRightPressed:Bool = false
    var isLeftPressed:Bool = false
    var orientation:UIInterfaceOrientationMask = UIInterfaceOrientationMask.landscapeLeft
    
    let commasCompletedKey = "commasCompleted"
    let timerPulsator = Pulsator()
    let leftPulsator = Pulsator()
    let rightPulsator = Pulsator()
    
    var rightGestureRecognizer:UILongPressGestureRecognizer?
    var leftGestureRecognizer:UILongPressGestureRecognizer?
    var tapGestureRecognizer:UITapGestureRecognizer?
    var timer:Timer?
    var accelerometerTimer:Timer?
    var timerStartTime:Date?
    var timerDuration:TimeInterval = 60.0
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return orientation }
    
    override var shouldAutorotate: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //register to receive notifications from device orientation change
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        var leftTransform = leftFingerprint.transform
        leftTransform = leftTransform.rotated(by: .pi/9.0)
        leftTransform = leftTransform.scaledBy(x: -1.0, y: 1.0)
        leftFingerprint.transform = leftTransform
        rightFingerprint.transform = rightFingerprint.transform.rotated(by: -.pi/9.0)
        
        rightPulsator.backgroundColor = UIColor.white.cgColor
        rightPulsator.animationDuration = 4.0
        rightPulsator.numPulse = 2
        rightPulsator.timingFunction = .deceleration
        rightPulsator.keyTimeForHalfOpacity = 0.25
        rightPulsator.radius = 106.0
        rightPulsator.transform = CATransform3DTranslate(rightPulsator.transform, rightFingerprint.bounds.midX, rightFingerprint.bounds.midY, 0.0)
        rightFingerprint.layer.addSublayer(rightPulsator)
        
        leftPulsator.backgroundColor = UIColor.white.cgColor
        leftPulsator.animationDuration = 4.0
        leftPulsator.numPulse = 2
        leftPulsator.timingFunction = .deceleration
        leftPulsator.keyTimeForHalfOpacity = 0.25
        leftPulsator.radius = 106.0
        leftPulsator.transform = rightPulsator.transform
        leftFingerprint.layer.addSublayer(leftPulsator)
        
        timerPulsator.backgroundColor = UIColor.white.cgColor
        timerPulsator.animationDuration = 4.0
        timerPulsator.timingFunction = .easeOut
        timerPulsator.keyTimeForHalfOpacity = 0.4
        timerPulsator.radius = 96.0
        timerPulsator.transform = CATransform3DTranslate(timerPulsator.transform, timerLabel.frame.midX, timerLabel.frame.midY, -5.0)
        self.view.layer.addSublayer(timerPulsator)
        
        leftFingerprint.isMultipleTouchEnabled = false
        rightFingerprint.isMultipleTouchEnabled = false
        
        rightGestureRecognizer = UILongPressGestureRecognizer(target: self, action: nil)
        rightGestureRecognizer?.allowableMovement = 50.0
        rightGestureRecognizer?.minimumPressDuration = 0.001
        rightGestureRecognizer?.numberOfTouchesRequired = 1
        rightGestureRecognizer?.delaysTouchesEnded = false
        rightGestureRecognizer?.delegate = self
        rightFingerprint.addGestureRecognizer(rightGestureRecognizer!)
        
        leftGestureRecognizer = UILongPressGestureRecognizer(target: self, action: nil)
        leftGestureRecognizer?.allowableMovement = 50.0
        leftGestureRecognizer?.minimumPressDuration = 0.001
        leftGestureRecognizer?.numberOfTouchesRequired = 1
        leftGestureRecognizer?.delaysTouchesEnded = false
        leftGestureRecognizer?.delegate = self
        leftFingerprint.addGestureRecognizer(leftGestureRecognizer!)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tapGestureRecognizer?.numberOfTapsRequired = 1
        tapGestureRecognizer?.numberOfTouchesRequired = 1
        tapGestureRecognizer?.delegate = self
        touchView.addGestureRecognizer(tapGestureRecognizer!)
        
        //handle device orientation when locked
        let motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates()
        
        accelerometerTimer = Timer(fire: Date(), interval: 0.2, repeats: true, block: { (timer) in
            // Get the accelerometer data.
            if let data = motionManager.accelerometerData {
                if  abs(data.acceleration.x) < 0.3 && self.state != .running {
                    self.deviceDidRotate()
                    timer.invalidate()
                }
            }
        })
        
        // Add the timer to the current run loop.
        RunLoop.current.add(self.accelerometerTimer!, forMode: .defaultRunLoopMode)
        
        changeState(to: .ready)
    }
    
    private func changeState(to newState: State) {
        
        self.state = newState
        
        switch newState {
            case .running:
                if leftPulsator.isPulsating {
                    leftPulsator.stop()
                }
                if rightPulsator.isPulsating {
                    rightPulsator.stop()
                }
                if !timerPulsator.isPulsating {
                    timerPulsator.start()
                }
                timerStartTime = Date()
                tactileFeedback()
                startTimer()
                
                //UI
                self.messageLabel.text = "take a deep breath"
                UIView.animate(withDuration: 12.0, animations: {
                    self.timerLabel.alpha = 0.0
                }, completion: { (success) in
                    UIView.transition(with: self.messageLabel,
                                      duration: 8.0,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self?.messageLabel.text = "close your eyes and relax"
                        }, completion: nil)
                })
                
                UIView.animate(withDuration: timerDuration) {
                    self.view.backgroundColor = UIColor(red: 153.0/255.0, green: 212.0/255.0, blue: 255.0/255.0, alpha: 1.0)
                }
                break
            
            case .ready:
                if !leftPulsator.isPulsating {
                    leftPulsator.start()
                }
                if !rightPulsator.isPulsating {
                    rightPulsator.start()
                }
                if timerPulsator.isPulsating {
                    timerPulsator.stop()
                }
                stopTimer()
                
                //UI
                timerLabel.text = "01:00"
                self.messageLabel.text = "rest your thumbs on the marks"
                self.view.backgroundColor = UIColor(red: 244.0/255.0, green: 166.0/255.0, blue: 131.0/255.0, alpha: 1.0)
                self.timerLabel.alpha = 1.0
                self.view.layer.removeAllAnimations()
                self.timerLabel.layer.removeAllAnimations()
                self.messageLabel.layer.removeAllAnimations()
                break
            
            case .finished:
                timerPulsator.stop()
                stopTimer()
                tactileFeedback()
                showPoptip()
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: commasCompletedKey) + 1, forKey: commasCompletedKey)
                self.messageLabel.text = "comma finished. tap anywhere"
                self.timerLabel.alpha = 1.0
                self.view.backgroundColor = UIColor(red: 153.0/255.0, green: 212.0/255.0, blue: 255.0/255.0, alpha: 1.0)
                UIView.animate(withDuration: 2.0) {
                    self.view.backgroundColor = UIColor(red: 244.0/255.0, green: 166.0/255.0, blue: 131.0/255.0, alpha: 1.0)
                }
                break
        }
    }
    
    @objc func tapDetected() {
        if state == .finished {
            changeState(to: .ready)
        }
    }
    
    @objc func deviceDidRotate() {
        if UIDevice.current.orientation.isPortrait {
            let initialVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "initialVC") as! ViewController
            
            initialVC.hero.isEnabled = true
            initialVC.hero.modalAnimationType = .fade
            self.hero.replaceViewController(with: initialVC)
        }
    }
    
    private func showPoptip() {
        commaImage.shake()
        let popTip = PopTip()
        popTip.font = UIFont.boldSystemFont(ofSize: 16.0)
        popTip.entranceAnimation = .scale
        popTip.bubbleColor = UIColor(red: 247.0/255.0, green: 215.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        popTip.show(text: "+1", direction: .right, maxWidth: 100, in: self.view, from: commaImage.frame, duration: 4)
    }
    
    private func tactileFeedback() {
        AudioServicesPlaySystemSound(SystemSoundID(1519)) //TODO: support devices older than iPhone 6S
    }
    
    private func startTimer() {
        timer = Timer(timeInterval: 0.05, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    private func stopTimer() {
        timer?.invalidate()
    }
    
    @objc private func updateTimer() {
        
        let sinceStart = Date().timeIntervalSince(timerStartTime!)
        
        if sinceStart < timerDuration {
            //UI
            timerPulsator.animationDuration = timerPulsator.animationDuration * (1 + sinceStart/timerDuration)
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = [.pad]
            timerLabel.text = formatter.string(from: timerDuration - sinceStart)
        } else {
            changeState(to: .finished)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension TimerViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        
        if !isLeftPressed {
            isLeftPressed = leftFingerprint.frame.contains(touch.location(in: self.view))
        }
        if !isRightPressed {
            isRightPressed = rightFingerprint.frame.contains(touch.location(in: self.view))
        }
        
        if state == .ready && isLeftPressed && isRightPressed {
            changeState(to: .running)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesOver(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesOver(touches)
    }
    
    private func touchesOver(_ touches: Set<UITouch>) {
        
        guard let touch = touches.first else { return }
        
        if leftFingerprint.frame.contains(touch.location(in: self.view)) {
            isLeftPressed = false
        }
        if rightFingerprint.frame.contains(touch.location(in: self.view)) {
            isRightPressed = false
        }
        
        if state == .running {
            changeState(to: .ready)
        }
    }
    
    
}

