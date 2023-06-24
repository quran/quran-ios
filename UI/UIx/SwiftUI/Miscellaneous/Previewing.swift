//
//  Previewing.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
public enum Previewing {
    public static func list(@ViewBuilder content: @escaping () -> some View) -> some View {
        ScrollView {
            ForEach(0 ..< 10) { _ in
                content()
            }
        }
    }
}
