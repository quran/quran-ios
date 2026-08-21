#if QURAN_SYNC
import AnnotationsService
import Combine
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import ReadingService
import UIKit

@MainActor
struct AyahSetBuilder {
    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        ayahHighlightService: MobileSyncAyahHighlightService,
        quranTextDataService: QuranTextDataService,
        navigateToAyah: @escaping (AyahNumber) -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.ayahHighlightService = ayahHighlightService
        self.quranTextDataService = quranTextDataService
        self.navigateToAyah = navigateToAyah
    }

    func buildCollection(
        _ collection: AyahBookmarkCollection,
        collectionDeleted: @escaping () -> Void
    ) -> UIViewController {
        build(
            dataSource: BookmarkCollectionAyahSetDataSource(
                collection: collection,
                service: ayahBookmarkCollectionService
            ),
            dataSourceDeleted: collectionDeleted
        )
    }

    func buildHighlights(color: HighlightColor, ayahs: [AyahNumber]) -> UIViewController {
        build(
            dataSource: HighlightAyahSetDataSource(
                color: color,
                initialAyahs: ayahs,
                service: ayahHighlightService
            ),
            dataSourceDeleted: {}
        )
    }

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let quranTextDataService: QuranTextDataService
    private let navigateToAyah: (AyahNumber) -> Void

    private func build(
        dataSource: any AyahSetDataSource,
        dataSourceDeleted: @escaping () -> Void
    ) -> UIViewController {
        let readingPreferences = ReadingPreferences.shared
        let viewModel = AyahSetViewModel(
            dataSource: dataSource,
            quranTextDataService: quranTextDataService,
            quranFontSource: QuranFontSource(
                current: { readingPreferences.reading.quranFont },
                updates: readingPreferences.$reading.map(\.quranFont)
            ),
            navigateToAyah: navigateToAyah,
            dataSourceDeleted: dataSourceDeleted
        )
        return AyahSetViewController(viewModel: viewModel)
    }
}
#endif
