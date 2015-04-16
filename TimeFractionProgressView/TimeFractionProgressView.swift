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
public class TimeFraction : NSObject, NSCoding, NSCopying {
    
    /// The current progress of the time fraction in seconds
    private(set) public dynamic var progress : NSTimeInterval = 0.0
    
    /// Determines if the time fraction has been started
    private(set) public dynamic var started : Bool = false
    
    /// The progress color of the time fraction
    public var color : UIColor = UIColor.whiteColor() {
        didSet {
            layer.strokeColor = color.CGColor
            layer.setNeedsDisplay()
        }
    }
    
    /**
    Designated Initializer.
    
    :param: color The progress color of the time fraction.
    
    :returns: A time fraction instance.
    */
    required public init(color: UIColor) {
        self.color = color
        layer = TimeFraction.setupLayer(color)
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
        progress = 0.0
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }
    
    //
    // MARK: Coding
    //
    public required init(coder aDecoder: NSCoder) {
        progress = aDecoder.decodeObjectForKey("progress") as! NSTimeInterval
        color = aDecoder.decodeObjectForKey("color") as! UIColor
        started = aDecoder.decodeObjectForKey("started") as! Bool
        layer = TimeFraction.setupLayer(color)
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(progress, forKey: "progress")
        aCoder.encodeObject(color, forKey: "color")
        aCoder.encodeObject(started, forKey: "started")
    }
    
    //
    // MARK: Copying
    //
    public func copyWithZone(zone: NSZone) -> AnyObject {
        let timeFraction = TimeFraction(color: color)
        timeFraction.progress = progress
        timeFraction.started = started
        return timeFraction
    }

    //
    // MARK: Private Methods and Declarations
    //
    
    internal let layer : CAShapeLayer
    
    private class func setupLayer(color : UIColor) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.CGColor
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.backgroundColor = UIColor.clearColor().CGColor
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 0.0
        return shapeLayer
    }
}


/**
*  TimeFractionProgressView
*/
public class TimeFractionProgressView : UIView {
    
    /// The maximum duration in seconds
    public var duration : NSTimeInterval = 30.0
    
    // The overall progress in seconds
    private(set) public dynamic var progress : NSTimeInterval = 0.0
    
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
    public func addTimeFraction(timeFraction : TimeFraction) -> Int {
        timeFraction.addObserver(self, forKeyPath: KVOStartedKey, options: .New, context: nil)
        fractions.append(timeFraction)
        createLayerPath(timeFraction)
        if (timeFraction.started) { startDisplayLink() } else { updateAppearance(nil) }
        return count(fractions)
    }
    
    /**
    Deletes a time fraction from the progressview.
    
    :param: timeFraction The time fraction.
    
    :returns: True, if the deletion was successful.
    */
    public func removeTimeFraction(timeFraction : TimeFraction) -> Int {
        if let index = find(fractions, timeFraction) {
            timeFraction.stop()
            fractions.removeAtIndex(index)
            timeFraction.removeObserver(self, forKeyPath: KVOStartedKey, context: nil)
            timeFraction.layer.removeFromSuperlayer()
            timeFraction.layer.path = nil
            return index
        }
        return -1
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
    public func positionOfTimeFraction(timeFraction : TimeFraction) -> Int {
        if let index = find(fractions, timeFraction) {
            return index
        }
        return -1
    }
    
    /**
    Resets all time fractions.
    */
    public func reset() {
        progress = 0.0
        for fraction in fractions {
            fraction.reset()
        }
    }
    
    
    //
    // MARK: Private Methods and Declarations
    //
    internal var fractions : Array<TimeFraction> = Array()
    private lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: Selector("animateProgress:"))
        instance.paused = true
        instance!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        return instance
    }()
    private var startTime : CFTimeInterval?
    private let KVOStartedKey = "started"
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for fraction in fractions {
            createLayerPath(fraction)
        }
    }
    
    private func createLayerPath(timeFraction : TimeFraction) {
        timeFraction.layer.removeFromSuperlayer()
        if let _customPath = self.customPath {
            timeFraction.layer.path = _customPath.copy().CGPath
            timeFraction.layer.lineWidth = _customPath.lineWidth
        } else {
            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x: 0, y: bounds.size.height / 2.0))
            path.addLineToPoint(CGPoint(x: bounds.size.width, y: bounds.size.height / 2.0))
            timeFraction.layer.path = path.CGPath
            timeFraction.layer.lineWidth = bounds.size.height
        }
        layer.addSublayer(timeFraction.layer)
    }
    
    private func startDisplayLink() {
        if (currentProgress() < 1.0 && displayLink?.paused == true) {
            startTime = CACurrentMediaTime();
            displayLink?.paused = false
        }
    }
    
    private func stopDisplayLink() {
        displayLink?.paused = true
    }
    
    @objc private func animateProgress(displayLink : CADisplayLink) {
        if (currentProgress() >= 1.0 || hasStartedFractions() == false) {
            stopDisplayLink()
            stopFractions()
            delegate?.timeFractionProgressViewDidReachMaximumDuration(self)
            return
        }
        
        let elapsedTime = CACurrentMediaTime() - startTime!
        updateAppearance(elapsedTime)
        startTime = CACurrentMediaTime();
    }
    
    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        let started : Bool = change[NSKeyValueChangeNewKey] as! Bool
        if (started) {
            startDisplayLink()
        } else if (hasStartedFractions() == false) {
            stopDisplayLink()
        }
    }
    
    private func updateAppearance(elapsedTime : CFTimeInterval?) {
        var overallProgress : NSTimeInterval = 0.0
        for (index, timeFraction) in enumerate(fractions) {
            var strokeStart : CGFloat = 0.0
            if (index > 0) {
                let previousFraction = fractions[index-1]
                strokeStart = previousFraction.layer.strokeEnd
            }
            
            if (displayLink?.paused == false) {
                if (timeFraction.started) { timeFraction.progress += elapsedTime! }
                timeFraction.layer.strokeStart = strokeStart
                timeFraction.layer.strokeEnd = strokeStart + CGFloat(Float(timeFraction.progress) / Float(self.duration))
                overallProgress += timeFraction.progress
            }
        }
        progress = overallProgress
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
        displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink = nil
        
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
@objc public protocol TimeFractionProgressViewDelegate {
    func timeFractionProgressViewDidReachMaximumDuration(timeFractionProgressView : TimeFractionProgressView)
}


