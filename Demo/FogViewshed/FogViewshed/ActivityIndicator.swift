//
//  DownloadingActivity.swift
//  FogMachine
//
//  Created by Ram Subramaniam on 2/9/16.
//  Copyright © 2016 NGA. All rights reserved.
//

import Foundation
import UIKit

public struct ActivityIndicator {
    // based on - http://stackoverflow.com/questions/28785715/how-to-display-an-activity-indicator-with-text-on-ios-8-with-swift
    // https://github.com/icanzilb/SwiftSpinner/blob/master/SwiftSpinner/SwiftSpinner.swift
    private struct Settings {
        private static var BackgroundColor = UIColor.whiteColor()
        private static var ActivityColor = UIColor.blackColor()
        private static var TextColor = UIColor.blackColor()
        private static var FontName = "HelveticaNeue-Light"
        private static var SuccessIcon = "✔︎"
        private static var FailIcon = "✘"
        private static var SuccessText = "Success"
        private static var FailText = "Failure"
        private static var SuccessColor = UIColor(red: 0/255, green: 155/255, blue: 69/255, alpha: 1.0)  //UIColor.greenColor()
        private static var FailColor = UIColor.redColor()
        private static var ActivityWidth = UIScreen.ScreenWidth / Settings.WidthDivision
        private static var ActivityHeight = ActivityWidth / 5
        private static var WidthDivision: CGFloat {
            get {
                if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                    return  3.5
                } else {
                    return 1.6
                }
            }
        }
    }
    
    private static var instance: LoadingActivity?
    private static var hidingInProgress = false
    
    /// Disable UI stops users touch actions until DownloadingActivity is hidden. Return success status
    public static func show(text: String, disableUI: Bool = false) -> Bool {
        guard instance == nil else {
            print("Activity: You still have an active activity, please stop that before creating a new one")
            return false
        }
        
        guard topMostController != nil else {
            print("Activity Error: You don't have any views set. You may be calling them in viewDidLoad. Try viewDidAppear instead.")
            return false
        }
        // Separate creation from showing
        instance = LoadingActivity(text: text, disableUI: disableUI)
        dispatch_async(dispatch_get_main_queue()) {
            instance?.showLoadingActivity()
        }
        return true
    }
    
    /// Returns success status
    public static func hide(success success: Bool? = nil, animated: Bool = false, errorMsg: String = "None.") -> Bool {
        guard instance != nil else {
            return false
        }
        
        guard hidingInProgress == false else {
            return false
        }
        
        if !NSThread.currentThread().isMainThread {
            dispatch_async(dispatch_get_main_queue()) {
                instance?.hideLoadingActivity(success: success, animated: animated, errorMsg: errorMsg)
            }
        } else {
            instance?.hideLoadingActivity(success: success, animated: animated, errorMsg: errorMsg)
        }
        
        return true
    }
    
    private class LoadingActivity: UIView {
        var textLabel: UILabel!
        var activityView: UIActivityIndicatorView!
        var icon: UILabel!
        var UIDisabled = false
        
        convenience init(text: String, disableUI: Bool) {
            self.init(frame: CGRect(x: 0, y: 0, width: Settings.ActivityWidth, height: Settings.ActivityHeight))
            center = CGPoint(x: UIScreen.mainScreen().bounds.midX, y: UIScreen.mainScreen().bounds.midY)
            autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin]
            backgroundColor = Settings.BackgroundColor
            alpha = 1
            layer.cornerRadius = 8
            createShadow()
            
            let yPosition = frame.height/2 - 20
            
            activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityView.frame = CGRect(x: 10, y: yPosition, width: 40, height: 40)
            activityView.color = Settings.ActivityColor
            activityView.startAnimating()
            
            textLabel = UILabel(frame: CGRect(x: 60, y: yPosition, width: Settings.ActivityWidth - 70, height: 40))
            textLabel.textColor = Settings.TextColor
            textLabel.font = UIFont(name: Settings.FontName, size: 30)
            textLabel.adjustsFontSizeToFitWidth = true
            textLabel.minimumScaleFactor = 0.25
            textLabel.numberOfLines = 3
            textLabel.textAlignment = NSTextAlignment.Center
            textLabel.text = text
            
            if disableUI {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                UIDisabled = true
            }
        }
        
        func showLoadingActivity() {
            addSubview(activityView)
            addSubview(textLabel)
            
            topMostController!.view.addSubview(self)
        }
        
        func createShadow() {
            layer.shadowPath = createShadowPath().CGPath
            layer.masksToBounds = false
            layer.shadowColor = UIColor.blackColor().CGColor
            layer.shadowOffset = CGSizeMake(0, 0)
            layer.shadowRadius = 5
            layer.shadowOpacity = 0.5
        }
        
        func createShadowPath() -> UIBezierPath {
            let myBezier = UIBezierPath()
            myBezier.moveToPoint(CGPoint(x: -3, y: -3))
            myBezier.addLineToPoint(CGPoint(x: frame.width + 3, y: -3))
            myBezier.addLineToPoint(CGPoint(x: frame.width + 3, y: frame.height + 3))
            myBezier.addLineToPoint(CGPoint(x: -3, y: frame.height + 3))
            myBezier.closePath()
            return myBezier
        }
        
        func hideLoadingActivity(success success: Bool?, animated: Bool, errorMsg: String) {
            hidingInProgress = true
            if UIDisabled {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
            
            var animationDuration: Double = 0
            if success != nil {
                if success! {
                    animationDuration = 0.5
                } else {
                    animationDuration = 1.5
                }
            }
            
            icon = UILabel(frame: CGRect(x: 10, y: frame.height/2 - 20, width: 40, height: 40))
            icon.font = UIFont(name: Settings.FontName, size: 60)
            icon.textAlignment = NSTextAlignment.Center
            
            //if animated {
            //    textLabel.fadeTransition(animationDuration)
            //}
            
            if success != nil {
                if success! {
                    icon.textColor = Settings.SuccessColor
                    icon.text = Settings.SuccessIcon
                    textLabel.text = Settings.SuccessText
                } else {
                    icon.textColor = Settings.FailColor
                    icon.text = Settings.FailIcon
                    textLabel.text = "\(errorMsg)"
                }
            }
            
            addSubview(icon)
            
            if animated {
                icon.alpha = 0
                activityView.stopAnimating()
                UIView.animateWithDuration(animationDuration, animations: {
                    self.icon.alpha = 1
                    }, completion: { (value: Bool) in
                        self.callSelectorAsync(#selector(UIView.removeFromSuperview), delay: animationDuration)
                        instance = nil
                        hidingInProgress = false
                })
            } else {
                activityView.stopAnimating()
                self.callSelectorAsync(#selector(UIView.removeFromSuperview), delay: animationDuration)
                instance = nil
                hidingInProgress = false
            }
        }
    }
}

private extension UIView {
    /// Extension: insert view.fadeTransition right before changing content
    func fadeTransition(duration: CFTimeInterval) {
        let animation: CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = duration
        self.layer.addAnimation(animation, forKey: kCATransitionFade)
    }
}

private extension NSObject {
    func callSelectorAsync(selector: Selector, delay: NSTimeInterval) {
        let timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
}

private extension UIScreen {
    class var Orientation: UIInterfaceOrientation {
        get {
            return UIApplication.sharedApplication().statusBarOrientation
        }
    }
    class var ScreenWidth: CGFloat {
        get {
            if UIInterfaceOrientationIsPortrait(Orientation) {
                return UIScreen.mainScreen().bounds.size.width
            } else {
                return UIScreen.mainScreen().bounds.size.height
            }
        }
    }
    class var ScreenHeight: CGFloat {
        get {
            if UIInterfaceOrientationIsPortrait(Orientation) {
                return UIScreen.mainScreen().bounds.size.height
            } else {
                return UIScreen.mainScreen().bounds.size.width
            }
        }
    }
}

private var topMostController: UIViewController? {
    var presentedVC = UIApplication.sharedApplication().keyWindow?.rootViewController
    while let pVC = presentedVC?.presentedViewController {
        presentedVC = pVC
    }
    
    return presentedVC
}

