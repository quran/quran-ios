//
//  ValueViewModel.swift
//
//
//  Created by Mohamed Afifi on 2022-03-01.
//

import Combine
import Foundation

@MainActor
public final class ValueViewModel<V>: ObservableObject {
    // MARK: Lifecycle

    public init(_ value: V) {
        self.value = value
    }

    // MARK: Public

    @Published public var value: V
}
