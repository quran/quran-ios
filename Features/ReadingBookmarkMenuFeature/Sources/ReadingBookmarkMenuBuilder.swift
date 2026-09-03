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

    public func build(page: Page, pages: [Page]) -> UIViewController {
        build(target: .pages(page, pages))
    }

    public func build(ayah: AyahNumber) -> UIViewController {
        build(target: .ayah(ayah))
    }

    // MARK: Private

    private let container: AppDependencies

    private func build(target: ReadingBookmarkMenuViewModel.Target) -> UIViewController {
        let viewModel = ReadingBookmarkMenuViewModel(
            service: container.readingBookmarkService(),
            target: target
        )
        let view = ReadingBookmarkMenuView(viewModel: viewModel)
            .enableToastPresenter()
        return AutoUpdatingPreferredContentSizeHostingController(rootView: view)
    }
}
#endif
