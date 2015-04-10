//
//  ViewController.swift
//  TimeFractionProgressViewSample
//
//  Created by Mathias Köhnke on 08/04/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TimeFractionProgressViewDelegate {
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var defaultProgressView: TimeFractionProgressView!
    @IBOutlet weak var customProgressView: TimeFractionProgressView!
    
    let KVODurationKey = "duration"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomProgressView()
        for button in buttons() {
            for progressView in progressViews() {
                progressView.insert(TimeFraction(color: button.backgroundColor!))
            }
        }
    }

    @IBAction func buttonTouched(button : UIButton) {
        let timeFractions = timeFractionsAtPosition(button.tag - 1)
        if (timeFractions.first!.started) {
            timeFractions.first!.removeObserver(self, forKeyPath: KVODurationKey, context: nil)
            for timeFraction in timeFractions { timeFraction.stop() }
        } else {
            for timeFraction in timeFractions { timeFraction.start() }
            timeFractions.first!.addObserver(self, forKeyPath: KVODurationKey, options: .New, context: nil)
        }
        button.selected = timeFractions.first!.started
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        let progress : Float? = change[NSKeyValueChangeNewKey] as? Float
        let index = progressViews().first?.positionOfTimeFraction(object as! TimeFraction)
        if let _index = index, _progress = progress {
            let title = NSString(format: "%.1f", _progress)
            buttons()[_index].setTitle(title as String, forState: .Normal)
        }
    }
    
    private func progressViews() -> Array<TimeFractionProgressView> {
        return [customProgressView, defaultProgressView]
    }
    
    private func buttons() -> Array<UIButton> {
        return [button1, button2, button3]
    }
    
    private func timeFractionsAtPosition(position : Int) -> Array<TimeFraction> {
        var fractions = Array<TimeFraction>()
        for progressView in progressViews() {
            fractions.append(progressView.timeFractionAtPosition(position)!)
        }
        return fractions
    }
    
    private func setupCustomProgressView() {
        let lineWidth : CGFloat = 10.0
        let width = customProgressView.bounds.size.width - lineWidth
        let height = customProgressView.bounds.size.height - lineWidth
        let bezierPath = UIBezierPath(ovalInRect: CGRectMake(lineWidth/2, lineWidth/2, width, height))
        bezierPath.lineWidth = lineWidth
        customProgressView.customPath = bezierPath
        customProgressView.delegate = self
    }
    
    
    // MARK: TimeFractionProgressViewDelegate
    
    func timeFractionProgressViewDidReachMaximumDuration(timeFractionProgressView: TimeFractionProgressView) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            for progressView in self.progressViews() { progressView.reset() }
            for button in self.buttons() {
                button.selected = false
                button.setTitle("0.0", forState: .Normal)
            }
        }
    }
}

