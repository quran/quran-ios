#if QURAN_SYNC
import AppDependencies
import NoorUI
import QuranKit
import SwiftUI
import UIKit
import UIx

@MainActor
public struct ReadingBookmarkMenuBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(
        page: Page,
        pages: [Page],
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        build(target: .pages(page, pages), bottomBarsHeight: bottomBarsHeight)
    }

    public func build(
        ayah: AyahNumber,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        build(target: .ayah(ayah), bottomBarsHeight: bottomBarsHeight)
    }

    // MARK: Private

    private let container: AppDependencies

    /// `bottomBarsHeight` keeps toasts above the presenter's bottom bars, like the reader's audio bar.
    private func build(
        target: ReadingBookmarkMenuViewModel.Target,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        let viewModel = ReadingBookmarkMenuViewModel(
            service: container.readingBookmarkService(),
            target: target
        )
        let view = ReadingBookmarkMenuView(viewModel: viewModel)
            .enableToastPresenter(bottomBarsHeight: bottomBarsHeight)
        return AutoUpdatingPreferredContentSizeHostingController(rootView: view)
    }
}
#endif
