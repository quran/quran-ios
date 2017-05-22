//
//  GoogleAdmod.swift
//  Jgrammar
//
//  Created by Nguyen Van Dung on 11/7/16.
//  Copyright © 2016 Dht. All rights reserved.
//

import Foundation

class GoogleAdmob {
    static var bannerUnitId: String {
        get {
            #if DEBUG
                return "ca-app-pub-3940256099942544/2934735716"
            #else
                return "ca-app-pub-6241639100526574/8928461442"
            #endif
        }
    }
    static var fullscreenUnitId: String {
        get {
            #if DEBUG
                return "ca-app-pub-3940256099942544/4411468910"
            #else
                return "ca-app-pub-6241639100526574/5835394248"
            #endif
        }
    }
    static var secondRepeatShow: Double {
        get {
            #if DEBUG
                return 10.0
            #else
                return 90.0
            #endif
        }
    }
}
