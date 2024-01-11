// From: https://github.com/airbnb/epoxy-ios/blob/ecee1ace58d58e3cc918a2dea28095de713b1112

// Created by eric_horacek on 10/8/21.
// Copyright © 2021 Airbnb Inc. All rights reserved.

import SwiftUI

#if !os(macOS)

    // MARK: - EpoxySwiftUIUIHostingController

    /// A `UIHostingController` that hosts SwiftUI views within an Epoxy container, e.g. an Epoxy
    /// `CollectionView`.
    ///
    /// Exposed publicly to allow consumers to reason about these view controllers, e.g. to opt
    /// collection view cells out of automated view controller impression tracking.
    ///
    /// - SeeAlso: `EpoxySwiftUIHostingView`
    open class EpoxySwiftUIHostingController<Content: View>: UIHostingController<Content> {
        // MARK: Lifecycle

        /// Creates a `UIHostingController` that optionally ignores the `safeAreaInsets` when laying out
        /// its contained `RootView`.
        public convenience init(rootView: Content, ignoreSafeArea: Bool) {
            self.init(rootView: rootView)

            clearBackground()

            // We unfortunately need to call a private API to disable the safe area. We can also accomplish
            // this by dynamically subclassing this view controller's view at runtime and overriding its
            // `safeAreaInsets` property and returning `.zero`. An implementation of that logic is
            // available in this file in the `2d28b3181cca50b89618b54836f7a9b6e36ea78e` commit if this API
            // no longer functions in future SwiftUI versions.
            _disableSafeArea = ignoreSafeArea
        }

        // MARK: Open

        override open func viewDidLoad() {
            super.viewDidLoad()

            clearBackground()
        }

        // MARK: Internal

        func clearBackground() {
            // A `UIHostingController` has a system background color by default as it's typically used in
            // full-screen use cases. Since we're using this view controller to place SwiftUI views within
            // other view controllers we default the background color to clear so we can see the views
            // below, e.g. to draw highlight states in a `CollectionView`.
            view.backgroundColor = .clear
        }
    }
#endif
