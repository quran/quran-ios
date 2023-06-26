//
//  MoreMenuEmpty.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuEmpty: View {
    var body: some View {
        VStack {
            Divider()
            Divider()
        }
        .hidden()
    }
}

struct MoreMenuEmpty_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Something")
            MoreMenuEmpty()
            Text("Something")
        }
    }
}
