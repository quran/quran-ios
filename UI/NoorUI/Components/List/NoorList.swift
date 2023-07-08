//
//  NoorList.swift
//
//
//  Created by Mohamed Afifi on 2023-07-04.
//

import SwiftUI

public struct NoorList<Content: View>: View {
    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Private

    private let content: Content
}

extension NoorList {
    public func refreshableIfAvailable(action: @escaping @Sendable () async -> Void) -> some View {
        Group {
            if #available(iOS 15.0, *) {
                refreshable(action: action)
            } else {
                self
            }
        }
    }
}
