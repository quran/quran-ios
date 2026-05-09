#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionPickerBuilder.swift
    //
    //  Created by Ahmed Nabil on 2026-05-09.
    //

    import QuranKit
    import UIKit

    @MainActor
    public struct AyahBookmarkCollectionPickerBuilder {
        // MARK: Lifecycle

        public init(
            ayahBookmarkCollectionService: AyahBookmarkCollectionService,
            readingBookmarkService: ReadingBookmarkService
        ) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.readingBookmarkService = readingBookmarkService
        }

        // MARK: Public

        public func build(
            verses: [AyahNumber],
            didSaveReadingBookmark: @escaping () -> Void,
            didFinish: @escaping () -> Void
        ) -> UIViewController {
            let viewModel = AyahBookmarkCollectionPickerViewModel(
                ayahBookmarkCollectionService: ayahBookmarkCollectionService,
                readingBookmarkService: readingBookmarkService,
                verses: verses,
                didSaveReadingBookmark: didSaveReadingBookmark,
                didFinish: didFinish
            )
            return AyahBookmarkCollectionPickerViewController(viewModel: viewModel)
        }

        // MARK: Private

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let readingBookmarkService: ReadingBookmarkService
    }
#endif
