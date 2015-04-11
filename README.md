# TimeFractionProgressView
This is a simple view to display multiple temporal progress graphs at the same time. The default appearance is a plain progress bar, but it's possible to define custom paths. **Take a look at the Example project to see how to use this library.**

<img style="border:1px solid #ccc;" src="https://raw.githubusercontent.com/mkoehnke/TimeFractionProgressView/master/Resources/TimeFractionProgress.gif?token=ABXNjbxbrzWiircwqkPkAEXDK3B215ORks5VMqEIwA%3D%3D">

# Installation
Copy the **TimeFractionProgressView.swift** file to your Swift project, add it to your target and you're good to go.

# Usage
The easiest way to get started is to add the TimeFractionProgressView as a custom view in your Storyboard. After that, you set the overall duration and add the number of time fractions, you want to display, in code:
 
```swift
progressView.duration = 30.0

let blue = TimeFraction(color: UIColor.blueColor())
progressView.addTimeFraction(blue)
        
let green = TimeFraction(color: UIColor.greenColor())
progressView.addTimeFraction(green)
```

To start and stop a time fraction, you simply call the following methods on the relevant object:

```swift
blue.start()
green.stop()
```

The duration of each time fraction can be monitored by observing the duration property using either Key-Value-Observing or a Swift equivalent.

## Custom Graph
A different appearance can be accomplished by setting **UIBezierPath** to the customPath property.
 
```swift
let bezierPath = UIBezierPath(ovalInRect: view.bounds)
bezierPath.lineWidth = 10
progressView.customPath = bezierPath
```

# License
TimeFractionProgressView is available under the MIT license. See the LICENSE file for more info.

# Recent Changes
The release notes can be found [here](https://github.com/mkoehnke/TimeFractionProgressView/releases).

