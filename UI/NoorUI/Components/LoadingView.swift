//
//  LoadingView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-07.
//

import SwiftUI

public struct LoadingView: View {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}
