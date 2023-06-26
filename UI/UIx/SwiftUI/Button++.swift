//
//  Button++.swift
//
//
//  Created by Mohamed Afifi on 2023-06-22.
//

import SwiftUI

public typealias AsyncAction = @MainActor @Sendable () async -> Void

extension Button {
    public init(asyncAction: @escaping AsyncAction, @ViewBuilder label: () -> Label) {
        self.init(action: {
            Task {
                await asyncAction()
            }
        }, label: label)
    }
}
