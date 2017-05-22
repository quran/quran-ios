//  AdsBannerView.swift
//  Jgrammar
//
//  Created by Nguyen Van Dung on 12/11/16.
//  Copyright © 2016 Dht. All rights reserved.
//

import Foundation
import GoogleMobileAds

class AdsBannerView: GADBannerView {

    deinit {
        Logger.log(NSStringFromClass(self.classForCoder) + "." + #function)
        NotificationCenter.default.removeObserver(self)
    }

    override init(adSize: GADAdSize, origin: CGPoint) {
        super.init(adSize: adSize, origin: origin)
        registerNotification()
    }

    override init(adSize: GADAdSize) {
        super.init(adSize: adSize)
        registerNotification()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerNotification()
    }

    func registerNotification() {
        NotificationCenter.default.removeObserver(self)
        weak var weakself = self
        NotificationCenter.default.addObserver(forName: NotificationName.kNotificationDidPurchase.name(), object: nil, queue:OperationQueue.main) { (notification) in
            weakself?.delegate = nil
            weakself?.isHidden = true
            weakself?.removeFromSuperview()
        }
    }
}

class AdsInterstitialView: GADInterstitial {
    
    deinit {
        Logger.log(NSStringFromClass(self.classForCoder) + "." + #function)
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(adUnitID: String) {
        super.init(adUnitID: adUnitID)
        registerNotification()
    }
    
    func registerNotification() {
        NotificationCenter.default.removeObserver(self)
        weak var weakself = self
        NotificationCenter.default.addObserver(forName: NotificationName.kNotificationDidPurchase.name(), object: nil, queue:OperationQueue.main) { (notification) in
            weakself?.delegate = nil
        }
    }
}
