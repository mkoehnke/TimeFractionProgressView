//
// TimeFractionProgressView.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

/**
*  TimeFraction
*/
public class TimeFraction : NSObject {
    
    /// The current duration of the time fraction
    private(set) dynamic var duration : NSTimeInterval = 0
    
    /// Determines if the time fraction has been started
    private(set) dynamic var started : Bool = false
    
    /// The progress color of the time fraction
    private(set) var color : UIColor = UIColor.whiteColor()
    
    /**
    Designated Initializer.
    
    :param: color The progress color of the time fraction.
    
    :returns: A time fraction instance.
    */
    required public init(color: UIColor) {
        layer = CAShapeLayer()
        layer.strokeColor = color.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }

    /**
    Starts progress of the time fraction.
    
    :returns: True, if starting has been successful.
    */
    public func start() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = true
        return started
    }
    
    /**
    Stops progress of the time fraction.
    
    :returns: True, if stopping has been successful.
    */
    public func stop() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = false
        return true
    }
    
    /**
    Resets the progress.
    */
    public func reset() {
        stop()
        duration = 0.0
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }
    
    //
    // MARK: Private Methods and Declarations
    //
    
    private let layer : CAShapeLayer
}


/**
*  TimeFractionProgressView
*/
public class TimeFractionProgressView : UIView {
    
    /// The maximum duration
    public var duration : NSTimeInterval = 30.0
    
    /// The appearance of the progressview can be adjusted by
    /// setting a different bezier path.
    public var customPath : UIBezierPath?
    
    /// The delegate will be notified when the maximum duration has 
    /// been reached.
    public var delegate : TimeFractionProgressViewDelegate?
    
    /**
    Inserts a time fraction into the progressview.
    
    :param: timeFraction The time fraction.
    
    :returns: True, if the insertion was successful.
    */
    public func insert(timeFraction : TimeFraction) -> Int? {
        timeFraction.addObserver(self, forKeyPath: KVOStartedKey, options: .New, context: nil)
        fractions.append(timeFraction)
        setNeedsLayout()
        return count(fractions)
    }
    
    /**
    Deletes a time fraction from the progressview.
    
    :param: timeFraction The time fraction.
    
    :returns: True, if the deletion was successful.
    */
    public func remove(timeFraction : TimeFraction) -> Int? {
        timeFraction.removeObserver(self, forKeyPath: KVOStartedKey, context: nil)
        timeFraction.layer.removeFromSuperlayer()
        timeFraction.layer.path = nil
        return nil
    }
    
    /**
    Returns the number of time fractions currently attached to 
    the progress view.
    
    :returns: The time fractions count.
    */
    public func numberOfTimeFractions() -> Int {
        return fractions.count
    }
    
    /**
    Returns the time fraction of a given position in
    the progressview.
    
    :param: position The time fraction position.
    
    :returns: A time fraction.
    */
    public func timeFractionAtPosition(position : Int) -> TimeFraction? {
        return fractions[position]
    }
    
    /**
    Returns the position of a given time fraction in
    the progressview.
    
    :param: timeFraction A time fraction.
    
    :returns: The position of the time fraction.
    */
    public func positionOfTimeFraction(timeFraction : TimeFraction) -> Int? {
        return find(fractions, timeFraction)
    }
    
    /**
    Resets all time fractions.
    */
    public func reset() {
        for fraction in fractions {
            fraction.reset()
        }
    }
    
    
    //
    // MARK: Private Methods and Declarations
    //
    
    private var displayLink : CADisplayLink?
    private var startTime : CFTimeInterval?
    private var fractions : Array<TimeFraction> = Array()
    private let KVOStartedKey = "started"
    
    override public func layoutSubviews() {
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
    
    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
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

//
// MARK: Delegate Methods
//

/**
*  The delegate of the time fraction progressview.
*/
public protocol TimeFractionProgressViewDelegate {
    func timeFractionProgressViewDidReachMaximumDuration(timeFractionProgressView : TimeFractionProgressView)
}


