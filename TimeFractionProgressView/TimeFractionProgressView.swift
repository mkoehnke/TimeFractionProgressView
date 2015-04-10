//
//  TimeFractionProgressView.swift
//  TimeFractionProgressViewSample
//
//  Created by Mathias Köhnke on 08/04/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

class TimeFraction : NSObject {
    
    private(set) dynamic var duration : NSTimeInterval = 0
    private(set) dynamic var started : Bool = false
    private(set) var color : UIColor = UIColor.whiteColor()
    private let layer : CAShapeLayer
    
    required init(color: UIColor) {
        layer = CAShapeLayer()
        layer.strokeColor = color.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }

    func start() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = true
        return started
    }
    
    func stop() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = false
        return true
    }
    
    func reset() {
        stop()
        duration = 0.0
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }
}

protocol TimeFractionProgressViewDelegate {
    func timeFractionProgressViewDidReachMaximumDuration(timeFractionProgressView : TimeFractionProgressView)
}


class TimeFractionProgressView : UIView {
    
    var duration : NSTimeInterval = 30.0
    var customPath : UIBezierPath?
    var delegate : TimeFractionProgressViewDelegate?
    
    private var displayLink : CADisplayLink?
    private var startTime : CFTimeInterval?
    private var fractions : Array<TimeFraction> = Array()
    private let KVOStartedKey = "started"
    
    func insert(timeFraction : TimeFraction) -> Int? {
        timeFraction.addObserver(self, forKeyPath: KVOStartedKey, options: .New, context: nil)
        fractions.append(timeFraction)
        setNeedsLayout()
        return count(fractions)
    }
    
    func remove(timeFraction : TimeFraction) -> Int? {
        timeFraction.removeObserver(self, forKeyPath: KVOStartedKey, context: nil)
        timeFraction.layer.removeFromSuperlayer()
        timeFraction.layer.path = nil
        return nil
    }
    
    func numberOfTimeFractions() -> Int {
        return fractions.count
    }
    
    func timeFractionAtPosition(position : Int) -> TimeFraction? {
        return fractions[position]
    }
    
    func positionOfTimeFraction(timeFraction : TimeFraction) -> Int? {
        return find(fractions, timeFraction)
    }
    
    func reset() {
        for fraction in fractions {
            fraction.reset()
        }
    }
    
    override func layoutSubviews() {
        let oldBounds : CGRect = bounds
        super.layoutSubviews()
        
        for fraction in fractions {
            if (fraction.layer.superlayer == nil || fraction.layer.path == nil || !CGRectEqualToRect(oldBounds, bounds)) {
                if let _customPath = self.customPath {
                    fraction.layer.path = _customPath.copy().CGPath
                    fraction.layer.lineWidth = _customPath.lineWidth
                } else {
                    let path = UIBezierPath()
                    path.moveToPoint(CGPoint(x: 0, y: bounds.size.height / 2.0))
                    path.addLineToPoint(CGPoint(x: bounds.size.width, y: bounds.size.height / 2.0))
                    fraction.layer.path = path.CGPath
                    fraction.layer.lineWidth = bounds.size.height
                }
                layer.addSublayer(fraction.layer)
            }
        }
    }
    
    private func startDisplayLink() {
        if (currentProgress() < 1.0) {
            startTime = CACurrentMediaTime();
            self.displayLink = CADisplayLink(target: self, selector: Selector("animateProgress:"))
            self.displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        }
    }
    
    private func stopDisplayLink() {
        if let _displayLink = self.displayLink {
            self.displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
            self.displayLink = nil
        }
    }
    
    @objc private func animateProgress(displayLink : CADisplayLink) {
        if (currentProgress() >= 1.0 || hasStartedFractions() == false) {
            stopDisplayLink()
            stopFractions()
            delegate?.timeFractionProgressViewDidReachMaximumDuration(self)
            return
        }
        
        let elapsedTime = CACurrentMediaTime() - startTime!
        
        for (index, timeFraction) in enumerate(fractions) {
            var strokeStart : CGFloat = 0.0
            if (index > 0) {
                let previousFraction = fractions[index-1]
                strokeStart = previousFraction.layer.strokeEnd
            }

            if let _displayLink = self.displayLink {
                if (timeFraction.started) { timeFraction.duration += elapsedTime }
                timeFraction.layer.strokeStart = strokeStart
                timeFraction.layer.strokeEnd = strokeStart + CGFloat(Float(timeFraction.duration) / Float(self.duration))
            }
        }

        startTime = CACurrentMediaTime();
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        let started : Bool = change[NSKeyValueChangeNewKey] as! Bool
        if (started && displayLink == nil) {
            startDisplayLink()
        } else if (hasStartedFractions() == false) {
            stopDisplayLink()
        }
    }
    
    private func hasStartedFractions() -> Bool {
        for timeFraction in fractions {
            if (timeFraction.started) { return true }
        }
        return false;
    }
    
    private func currentProgress() -> CGFloat {
        if let lastTimeFraction = fractions.last {
            return lastTimeFraction.layer.strokeEnd
        }
        return 0.0
    }
    
    private func stopFractions() {
        for timeFraction in fractions { timeFraction.started = false }
    }

    deinit {
        for timeFraction in fractions {
            if (layer.superlayer != nil) {
                timeFraction.removeObserver(self, forKeyPath: KVOStartedKey, context: nil)
            }
        }
    }
}