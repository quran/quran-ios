//
//  ViewModelContainer.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import Combine
import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct ViewModelContainer<ViewModel: ObservableObject, Content: View>: View {
    // MARK: Lifecycle

    public init(_ viewModel: ViewModel, content: @escaping (ObservedObject<ViewModel>.Wrapper) -> Content) {
        self.viewModel = viewModel
        self.content = { wrapper, _ in content(wrapper) }
    }

    public init(_ viewModel: ViewModel, content: @escaping (ViewModel) -> Content) {
        self.viewModel = viewModel
        self.content = { _, vm in content(vm) }
    }

    // MARK: Public

    public var body: some View {
        content($viewModel, viewModel)
    }

    // MARK: Internal

    @ObservedObject var viewModel: ViewModel
    let content: (ObservedObject<ViewModel>.Wrapper, ViewModel) -> Content
}
