//
// ViewController.swift
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
                progressView.addTimeFraction(TimeFraction(color: button.backgroundColor!))
            }
        }
    }

    @IBAction func buttonTouched(button : UIButton) {
        let timeFractions = timeFractionsAtPosition(button.tag - 1)
        if (timeFractions.first!.started) {
            timeFractions.first!.removeObserver(self, forKeyPath: KVODurationKey, context: nil)
            for timeFraction in timeFractions { timeFraction.stop() }
        } else {
            timeFractions.first!.addObserver(self, forKeyPath: KVODurationKey, options: .New, context: nil)
            for timeFraction in timeFractions { timeFraction.start() }
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

