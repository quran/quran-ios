# KVOController-Swift

[![CI Status](http://img.shields.io/travis/mohamede1945/KVOController-Swift.svg?style=flat)](https://travis-ci.org/mohamede1945/KVOController-Swift)
[![Version](https://img.shields.io/cocoapods/v/KVOController-Swift.svg?style=flat)](http://cocoapods.org/pods/KVOController-Swift)
[![License](https://img.shields.io/cocoapods/l/KVOController-Swift.svg?style=flat)](http://cocoapods.org/pods/KVOController-Swift)
[![Platform](https://img.shields.io/cocoapods/p/KVOController-Swift.svg?style=flat)](http://cocoapods.org/pods/KVOController-Swift)

Have you ever wondered if you can implement a generic key-value observing for Swift. It makes your life easy and saves you a lot of casting.
This project is inspired by facebook/KVOController. So, it doesn't only provide a neat API for KVO', but also makes use of Swift generics feature.

## Requirements

- iOS 7.0+ / Mac OS X 10.9+
- Xcode 6.3

## Usage

**Simple use**
```Swift
observe(retainedObservable: clock, keyPath: "date", options: .New | .Initial)
    { [weak self] (observable: Clock, change: ChangeData<NSDate>) -> () in

        if let date = change.newValue {
            self?.timeLabel.text = formatter.stringFromDate(date)
        }
}
```
You can make use of automatic unobserving behavior or if you really want to unobserve, simply call
```Swift
  unobserve(clock, keyPath: "date")
```


## Installation

KVOController-Swift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "KVOController-Swift"
```

**For iOS 7.x:**

> Embedded frameworks require a minimum deployment target of iOS 8.

To use KVOController-Swift with a project targeting iOS 7, you must include KVOController.swift directly into your project.


## Author

Mohamed Afifi, mohamede1945@gmail.com

## License

KVOController-Swift is available under the MIT license. See the LICENSE file for more info.
