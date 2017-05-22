//
//  MainTabBarController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit
import Foundation
import GoogleMobileAds
import SnapKit

protocol ScrollableToTop {
    func scrollToTop()
}

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, GADInterstitialDelegate {
    var bottomView: UIView!
    var bannerView: AdsBannerView!
    var interstitialView: AdsInterstitialView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barStyle = .default
        delegate = self
        addBottomView()
        addBannerAdmode()
        addBannerAllPageAdmode()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view?.layoutIfNeeded()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        bannerView?.snp.makeConstraints({ (make) in
            make.top.bottom.left.right.equalTo(self.bottomView)
        })
    }
    
    private func startTimer() {
    
    }
    
    private func stopTimer() {
        
    }

    func addBottomView() {
        bottomView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 60))
        self.view.addSubview(bottomView)
        bottomView?.snp.makeConstraints({ (make) in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-49)
            make.height.equalTo(50)
        })
    }

    func addBannerAdmode() {
        if let appDelegate = AppDelegate.shareInstance(), appDelegate.hasPurchased() {
            return
        }
        bannerView = AdsBannerView(adSize: kGADAdSizeBanner, origin: CGPoint(x: 0, y: 0))
        bannerView?.adUnitID = GoogleAdmob.bannerUnitId
        bannerView?.rootViewController = self
        bannerView?.load(GADRequest())
        bottomView?.addSubview(bannerView)
        bottomView?.backgroundColor = UIColor.clear
    }
    
    func addBannerAllPageAdmode() {
        if let appDelegate = AppDelegate.shareInstance(), appDelegate.hasPurchased() {
            return
        }
        interstitialView = AdsInterstitialView(adUnitID: GoogleAdmob.fullscreenUnitId)
        let request = GADRequest()
        request.testDevices = [ kGADSimulatorID ]
        interstitialView.load(request)
        interstitialView.delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController && viewController.isViewLoaded {
            (viewController as? ScrollableToTop)?.scrollToTop()
        }
        return true
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial!) {
        print("Interstitial loaded successfully")
        ad.present(fromRootViewController: self)
//        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//            interstitialView.present(fromRootViewController: rootViewController)
//        }
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial!) {
        print("Fail to receive interstitial")
    }
}
