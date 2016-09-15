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
open class TimeFraction : NSObject, NSCoding, NSCopying {
    
    /// The current progress of the time fraction in seconds
    fileprivate(set) open dynamic var progress : TimeInterval = 0.0
    
    /// Determines if the time fraction has been started
    fileprivate(set) open dynamic var started : Bool = false
    
    /// The progress color of the time fraction
    open var color : UIColor = UIColor.white {
        didSet {
            layer.strokeColor = color.cgColor
            layer.setNeedsDisplay()
        }
    }
    
    /**
    Designated Initializer.
    
    - parameter color: The progress color of the time fraction.
    
    - returns: A time fraction instance.
    */
    required public init(color: UIColor) {
        self.color = color
        layer = TimeFraction.setupLayer(color)
    }

    /**
    Starts progress of the time fraction.
    
    - returns: True, if starting has been successful.
    */
    @discardableResult
    open func start() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = true
        return started
    }
    
    /**
    Stops progress of the time fraction.
    
    - returns: True, if stopping has been successful.
    */
    @discardableResult
    open func stop() -> Bool {
        if (layer.superlayer == nil) { return false }
        started = false
        return true
    }
    
    /**
    Resets the progress.
    */
    open func reset() {
        stop()
        progress = 0.0
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
    }
    
    //
    // MARK: Coding
    //
    public required init?(coder aDecoder: NSCoder) {
        progress = aDecoder.decodeObject(forKey: "progress") as! TimeInterval
        color = aDecoder.decodeObject(forKey: "color") as! UIColor
        started = aDecoder.decodeObject(forKey: "started") as! Bool
        layer = TimeFraction.setupLayer(color)
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(progress, forKey: "progress")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(started, forKey: "started")
    }
    
    //
    // MARK: Copying
    //
    open func copy(with zone: NSZone?) -> Any {
        let timeFraction = TimeFraction(color: color)
        timeFraction.progress = progress
        timeFraction.started = started
        return timeFraction
    }

    //
    // MARK: Private Methods and Declarations
    //
    
    internal let layer : CAShapeLayer
    
    fileprivate class func setupLayer(_ color : UIColor) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 0.0
        return shapeLayer
    }
}


/**
*  TimeFractionProgressView
*/
open class TimeFractionProgressView : UIView {
    
    /// The maximum duration in seconds
    open var duration : TimeInterval = 30.0
    
    // The overall progress in seconds
    fileprivate(set) open dynamic var progress : TimeInterval = 0.0
    
    /// The appearance of the progressview can be adjusted by
    /// setting a different bezier path.
    open var customPath : UIBezierPath?
    
    /// The delegate will be notified when the maximum duration has 
    /// been reached.
    open weak var delegate : TimeFractionProgressViewDelegate?
    
    /**
    Inserts a time fraction into the progressview.
    
    - parameter timeFraction: The time fraction.
    
    - returns: The current number of fractions.
    */
    @discardableResult
    open func addTimeFraction(_ timeFraction : TimeFraction) -> Int {
        timeFraction.addObserver(self, forKeyPath: KVOStartedKey, options: .new, context: nil)
        fractions.append(timeFraction)
        createLayerPath(timeFraction)
        if (timeFraction.started) { startDisplayLink() } else { updateAppearance(nil) }
        return fractions.count
    }
    
    /**
    Deletes a time fraction from the progressview.
    
    - parameter timeFraction: The time fraction.
    
    - returns: The current number of fractions.
    */
    @discardableResult
    open func removeTimeFraction(_ timeFraction : TimeFraction) -> Int {
        if let index = fractions.index(of: timeFraction) {
            timeFraction.stop()
            fractions.remove(at: index)
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
    
    - returns: The time fractions count.
    */
    open func numberOfTimeFractions() -> Int {
        return fractions.count
    }
    
    /**
    Returns the time fraction of a given position in
    the progressview.
    
    - parameter position: The time fraction position.
    
    - returns: A time fraction.
    */
    open func timeFractionAtPosition(_ position : Int) -> TimeFraction? {
        return fractions[position]
    }
    
    /**
    Returns the position of a given time fraction in
    the progressview.
    
    - parameter timeFraction: A time fraction.
    
    - returns: The position of the time fraction.
    */
    open func positionOfTimeFraction(_ timeFraction : TimeFraction) -> Int {
        if let index = fractions.index(of: timeFraction) {
            return index
        }
        return -1
    }
    
    /**
    Resets all time fractions.
    */
    open func reset() {
        progress = 0.0
        for fraction in fractions {
            fraction.reset()
        }
    }
    
    open override func setNeedsDisplay() {
        super.setNeedsDisplay()
        updateAppearance(0)
    }
    
    //
    // MARK: Initializers
    //
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    //
    // MARK: Private Methods and Declarations
    //
    internal var fractions : Array<TimeFraction> = Array()
    fileprivate var displayLink : CADisplayLink?
    fileprivate var startTime : CFTimeInterval?
    fileprivate let KVOStartedKey = "started"
    
    fileprivate func commonSetup() {
        let displayLink = CADisplayLink(target: self, selector: #selector(TimeFractionProgressView.animateProgress(_:)))
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        self.displayLink = displayLink
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        for fraction in fractions {
            createLayerPath(fraction)
        }
    }
    
    fileprivate func createLayerPath(_ timeFraction : TimeFraction) {
        timeFraction.layer.removeFromSuperlayer()
        if let _customPath = self.customPath {
            timeFraction.layer.path = (_customPath.copy() as AnyObject).cgPath
            timeFraction.layer.lineWidth = _customPath.lineWidth
        } else {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: bounds.size.height / 2.0))
            path.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height / 2.0))
            timeFraction.layer.path = path.cgPath
            timeFraction.layer.lineWidth = bounds.size.height
        }
        layer.addSublayer(timeFraction.layer)
    }
    
    fileprivate func startDisplayLink() {
        if (currentProgress() < 1.0 && displayLink?.isPaused == true) {
            startTime = CACurrentMediaTime();
            displayLink?.isPaused = false
        }
    }
    
    fileprivate func stopDisplayLink() {
        displayLink?.isPaused = true
    }
    
    @objc fileprivate func animateProgress(_ displayLink : CADisplayLink) {
        let hasReachedMaximumDuration = currentProgress() >= 1.0
        let shouldStop = hasReachedMaximumDuration || hasStartedFractions() == false
        if (shouldStop) {
            stopDisplayLink()
            stopFractions()
            if hasReachedMaximumDuration {
                delegate?.timeFractionProgressViewDidReachMaximumDuration(self)
            }
            return
        }
        
        let elapsedTime = CACurrentMediaTime() - startTime!
        updateAppearance(elapsedTime)
        startTime = CACurrentMediaTime();
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let _ = change?[NSKeyValueChangeKey.newKey] as? Bool {
            startDisplayLink()
        } else if (hasStartedFractions() == false) {
            stopDisplayLink()
        }
    }
    
    fileprivate func updateAppearance(_ elapsedTime : CFTimeInterval?) {
        var overallProgress : TimeInterval = 0.0
        for (index, timeFraction) in fractions.enumerated() {
            var strokeStart : CGFloat = 0.0
            if (index > 0) {
                let previousFraction = fractions[index-1]
                strokeStart = previousFraction.layer.strokeEnd
            }
            
            if (timeFraction.started) { timeFraction.progress += elapsedTime! }
            CATransaction.setDisableActions(true)
            timeFraction.layer.strokeStart = strokeStart
            timeFraction.layer.strokeEnd = strokeStart + CGFloat(Float(timeFraction.progress) / Float(self.duration))
            CATransaction.setDisableActions(false)
            overallProgress += timeFraction.progress
        }
        progress = overallProgress
    }
    
    fileprivate func hasStartedFractions() -> Bool {
        for timeFraction in fractions {
            if (timeFraction.started) { return true }
        }
        return false;
    }
    
    fileprivate func currentProgress() -> CGFloat {
        if let lastTimeFraction = fractions.last {
            return lastTimeFraction.layer.strokeEnd
        }
        return 0.0
    }
    
    fileprivate func stopFractions() {
        for timeFraction in fractions { timeFraction.started = false }
    }

    deinit {
        displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
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
    func timeFractionProgressViewDidReachMaximumDuration(_ timeFractionProgressView : TimeFractionProgressView)
}


