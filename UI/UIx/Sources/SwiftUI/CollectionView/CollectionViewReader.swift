//
//  CollectionViewReader.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import SwiftUI

private struct CollectionViewControllerKey: EnvironmentKey {
    static let defaultValue: Binding<UICollectionView?>? = nil
}

extension EnvironmentValues {
    var _collectionView: Binding<UICollectionView?>? {
        get { self[CollectionViewControllerKey.self] }
        set { self[CollectionViewControllerKey.self] = newValue }
    }
}

public struct CollectionViewReader<Content: View>: View {
    // MARK: Lifecycle

    public init(@ViewBuilder content: @escaping (UICollectionView?) -> Content) {
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        let collectionView = $_collectionView
        let content = content
        let environmentCollectionView = _environmentCollectionView

        content(environmentCollectionView?.wrappedValue ?? collectionView.wrappedValue)
            .environment(\._collectionView, collectionView)
    }

    // MARK: Internal

    @State var _collectionView: UICollectionView? = nil
    @Environment(\._collectionView) var _environmentCollectionView
    let content: (UICollectionView?) -> Content
}
