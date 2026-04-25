import FeaturesSupport
import Localization
import SwiftUI
import UIx

final class HighlightsViewController: UIHostingController<HighlightsView> {
    init(viewModel: HighlightsViewModel) {
        super.init(rootView: HighlightsView(viewModel: viewModel))
        title = l("highlights.title")
        addCloudSyncInfo()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HighlightColorViewController: UIHostingController<HighlightColorView> {
    init(collection: HighlightCollection, viewModel: HighlightsColorViewModel) {
        super.init(rootView: HighlightColorView(viewModel: viewModel))
        title = l(collection.localizationKey)
        addCloudSyncInfo()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
