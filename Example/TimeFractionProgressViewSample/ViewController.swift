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
    @IBOutlet weak var progressLabel: UILabel!
    
    let KVOProgressKey = "progress"
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if customProgressView.customPath == nil {
            setupCustomProgressView()
            for button in buttons() {
                for progressView in progressViews() {
                    progressView.addTimeFraction(TimeFraction(color: button.backgroundColor!))
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressViews().first?.addObserver(self, forKeyPath: KVOProgressKey, options: .new, context: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        progressViews().first?.removeObserver(self, forKeyPath: KVOProgressKey, context: nil)
    }
    
    @IBAction func buttonTouched(_ button : UIButton) {
        let timeFractions = timeFractionsAtPosition(button.tag - 1)
        if (timeFractions.first!.started) {
            timeFractions.first!.removeObserver(self, forKeyPath: KVOProgressKey, context: nil)
            for timeFraction in timeFractions { timeFraction.stop() }
        } else {
            timeFractions.first!.addObserver(self, forKeyPath: KVOProgressKey, options: .new, context: nil)
            for timeFraction in timeFractions { timeFraction.start() }
        }
        button.isSelected = timeFractions.first!.started
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let _progress = change?[NSKeyValueChangeKey.newKey] as? Float {
            if let _timeFraction = object as? TimeFraction {
                let index = progressViews().first?.positionOfTimeFraction(_timeFraction)
                if let _index = index {
                    let title = NSString(format: "%.1f", _progress)
                    buttons()[_index].setTitle(title as String, for: UIControlState())
                }
            } else if let _ = object as? TimeFractionProgressView {
                progressLabel.text = NSString(format: "%.1f", _progress) as String
            }
        }
    }
    
    fileprivate func progressViews() -> Array<TimeFractionProgressView> {
        return [customProgressView, defaultProgressView]
    }
    
    fileprivate func buttons() -> Array<UIButton> {
        return [button1, button2, button3]
    }
    
    fileprivate func timeFractionsAtPosition(_ position : Int) -> Array<TimeFraction> {
        var fractions = Array<TimeFraction>()
        for progressView in progressViews() {
            fractions.append(progressView.timeFractionAtPosition(position)!)
        }
        return fractions
    }
    
    fileprivate func setupCustomProgressView() {
        let lineWidth : CGFloat = 10.0
        let width = customProgressView.bounds.size.width - lineWidth
        let height = customProgressView.bounds.size.height - lineWidth
        let bezierPath = UIBezierPath(ovalIn: CGRect(x: lineWidth/2, y: lineWidth/2, width: width, height: height))
        bezierPath.lineWidth = lineWidth
        customProgressView.customPath = bezierPath
        customProgressView.delegate = self
    }
    
    
    // MARK: TimeFractionProgressViewDelegate
    
    func timeFractionProgressViewDidReachMaximumDuration(_ timeFractionProgressView: TimeFractionProgressView) {
        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            for progressView in self.progressViews() { progressView.reset() }
            for button in self.buttons() {
                button.isSelected = false
                button.setTitle("0.0", for: UIControlState())
            }
        }
    }
}

