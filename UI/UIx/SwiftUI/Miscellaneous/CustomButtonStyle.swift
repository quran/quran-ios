//
//  CustomButtonStyle.swift
//
//
//  Created by Mohamed Afifi on 2024-09-22.
//

import SwiftUI

public struct CustomButtonStyle<Content: View>: ButtonStyle {
    private let customize: (Configuration) -> Content

    public init(@ViewBuilder customize: @escaping (Configuration) -> Content) {
        self.customize = customize
    }

    public func makeBody(configuration: Configuration) -> some View {
        customize(configuration)
    }
}
