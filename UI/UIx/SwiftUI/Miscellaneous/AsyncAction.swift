//
//  AsyncAction.swift
//
//
//  Created by Mohamed Afifi on 2023-06-22.
//

import SwiftUI

public typealias AsyncAction = @MainActor @Sendable () async -> Void

public typealias ItemAction<Item> = @MainActor @Sendable (Item) -> Void
public typealias AsyncItemAction<Item> = @MainActor @Sendable (Item) async -> Void

extension Button {
    public init(asyncAction: @escaping AsyncAction, @ViewBuilder label: () -> Label) {
        self.init(action: {
            Task {
                await asyncAction()
            }
        }, label: label)
    }
}

extension View {
    public func onTapGesture(count: Int = 1, asyncAction action: @escaping AsyncAction) -> some View {
        onTapGesture(count: count, perform: {
            Task {
                await action()
            }
        })
    }
}
