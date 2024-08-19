//
//  NoorList.swift
//
//
//  Created by Mohamed Afifi on 2023-07-04.
//

import SwiftUI

public struct NoorList<Content: View>: View {
    public enum ListType {
        case app
        case searching
    }

    // MARK: Lifecycle

    public init(listType: ListType = .app, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.listType = listType
    }

    // MARK: Public

    public var body: some View {
        configureList {
            List {
                content
            }
        }

        .listStyle(.insetGrouped)
    }

    // MARK: Private

    private let listType: ListType
    private let content: Content

    @ViewBuilder
    private func configureList(@ViewBuilder list: () -> some View) -> some View {
        let list = list()
        switch listType {
        case .app:
            list.listStyle(.insetGrouped)
        case .searching:
            list.listStyle(.plain)
        }
    }
}
