//
//  HomeView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import FeaturesSupport
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        #if QURAN_SYNC
        HomeViewUI(
            type: viewModel.type,
            readingBookmark: viewModel.readingBookmark,
            lastPages: viewModel.lastPages,
            suras: viewModel.suras,
            quarters: viewModel.quarters,
            start: { await viewModel.start() },
            selectReadingBookmark: { viewModel.navigateTo($0) },
            selectLastPage: { viewModel.navigateTo($0) },
            selectSura: { viewModel.navigateTo($0) },
            selectQuarter: { viewModel.navigateTo($0) },
            surahSortOrder: viewModel.surahSortOrder,
            isJuzExpanded: { viewModel.isJuzExpanded($0) },
            setJuzExpanded: { viewModel.setJuz($0, expanded: $1) }
        )
        #else
        HomeViewUI(
            type: viewModel.type,
            lastPages: viewModel.lastPages,
            suras: viewModel.suras,
            quarters: viewModel.quarters,
            start: { await viewModel.start() },
            selectLastPage: { viewModel.navigateTo($0) },
            selectSura: { viewModel.navigateTo($0) },
            selectQuarter: { viewModel.navigateTo($0) },
            surahSortOrder: viewModel.surahSortOrder,
            isJuzExpanded: { viewModel.isJuzExpanded($0) },
            setJuzExpanded: { viewModel.setJuz($0, expanded: $1) }
        )
        #endif
    }
}

private struct HomeViewUI: View {
    let type: HomeViewType
    #if QURAN_SYNC
    let readingBookmark: ReadingPositionBookmark?
    #endif
    let lastPages: [LastPage]
    let suras: [Sura]
    let quarters: [QuarterItem]

    let start: AsyncAction

    #if QURAN_SYNC
    let selectReadingBookmark: ItemAction<ReadingPositionBookmark>
    #endif
    let selectLastPage: ItemAction<LastPage>
    let selectSura: ItemAction<Sura>
    let selectQuarter: ItemAction<QuarterItem>
    let surahSortOrder: SurahSortOrder
    let isJuzExpanded: (Juz) -> Bool
    let setJuzExpanded: (Juz, Bool) -> Void

    var body: some View {
        NoorList {
            #if QURAN_SYNC
            if let readingBookmark {
                NoorBasicSection(title: l("ayah.menu.reading-bookmark.title")) {
                    readingBookmarkView(readingBookmark)
                }
            }
            #endif

            NoorSection(title: lAndroid("recent_pages"), lastPages) { lastPage in
                lastPageView(lastPage)
            }

            switch type {
            case .suras:
                sectionsView(items: suras, groupBy: \.page.startJuz) { sura in
                    suraView(sura)
                }
            case .juzs:
                sectionsView(items: quarters, groupBy: \.quarter.juz) { quarter in
                    quarterView(quarter)
                }
            }
        }
        .task { await start() }
    }

    #if QURAN_SYNC
    func readingBookmarkView(_ bookmark: ReadingPositionBookmark) -> some View {
        ReadingBookmarkListItem(
            bookmark: bookmark,
            action: { selectReadingBookmark(bookmark) }
        )
    }
    #endif

    func lastPageView(_ lastPage: LastPage) -> some View {
        let ayah = lastPage.page.firstVerse
        return NoorListItem(
            image: .init(.lastPage, color: .secondaryLabel),
            title: "\(sura: ayah.sura)",
            subtitle: .init(text: lastPage.modifiedOn.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(lastPage.page.pageNumber))
        ) {
            selectLastPage(lastPage)
        }
    }

    func suraView(_ sura: Sura) -> some View {
        let ayahsString = lFormat("verses", table: .android, sura.verses.count)
        let suraType = sura.isMakki ? lAndroid("makki") : lAndroid("madani")

        let numberFormatter = NumberFormatter.shared

        return NoorListItem(
            title: "\(sura: sura, format: .numbered)",
            subtitle: .init(text: "\(suraType) - \(ayahsString)", location: .bottom),
            accessory: .text(numberFormatter.format(sura.page.pageNumber))
        ) {
            selectSura(sura)
        }
    }

    func quarterView(_ item: QuarterItem) -> some View {
        let quarter = item.quarter
        let ayah = quarter.firstVerse
        let page = ayah.page

        return NoorListItem(
            title: "\(quarter.localizedName) - \(ayah: ayah)",
            rightSubtitle: "\(quran: item.ayahText, lineLimit: 1)",
            accessory: .text(NumberFormatter.shared.format(page.pageNumber))
        ) {
            selectQuarter(item)
        }
    }

    @ViewBuilder
    func sectionsView<Item: Identifiable>(
        items: [Item],
        groupBy: (Item) -> Juz,
        @ViewBuilder listItem: @escaping (Item) -> some View
    ) -> some View {
        let itemsByJuz = Dictionary(grouping: items, by: groupBy)
        let juzs = itemsByJuz.keys.sorted {
            surahSortOrder.rawValue * ($0.juzNumber - $1.juzNumber) < 0
        }

        ForEach(juzs) { juz in
            let items = (itemsByJuz[juz] ?? []).sorted {
                switch ($0, $1) {
                case let (thisSura as Sura, thatSura as Sura):
                    surahSortOrder.rawValue * (thisSura.suraNumber - thatSura.suraNumber) < 0
                case let (thisQuarter as QuarterItem, thatQuarter as QuarterItem):
                    surahSortOrder.rawValue * (thisQuarter.quarter.quarterNumber - thatQuarter.quarter.quarterNumber) < 0
                default:
                    false
                }
            }
            let isExpanded = Binding(
                get: { isJuzExpanded(juz) },
                set: { setJuzExpanded(juz, $0) }
            )
            NoorSection(title: juz.localizedName, isExpanded: isExpanded, items) { item in
                listItem(item)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    struct Preview: View {
        static let ayahText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"

        static var staticLastPages: [LastPage] {
            let pages = Quran.hafsMadani1405.pages.shuffled()
            return (0 ..< 3).map { i in
                #if QURAN_SYNC
                LastPage(
                    id: "preview-\(i)",
                    page: pages[i],
                    modifiedOn: Date(timeIntervalSince1970: Double(i) * 60 * -3)
                )
                #else
                LastPage(
                    page: pages[i],
                    createdOn: Date(timeIntervalSince1970: Double(i) * 60 * -3),
                    modifiedOn: Date(timeIntervalSince1970: Double(i) * 60 * -3)
                )
                #endif
            }
        }

        let quran = Quran.hafsMadani1405

        @State var lastPages: [LastPage] = staticLastPages
        #if QURAN_SYNC
        @State var readingBookmark = ReadingPositionBookmark(
            id: "preview-reading-bookmark",
            location: .page(Quran.hafsMadani1405.pages[269]),
            modifiedOn: Date(timeIntervalSinceNow: -180)
        )
        #endif
        @State var type: HomeViewType = .juzs
        @State var collapsedJuzs: Set<Juz> = []

        var body: some View {
            NavigationView {
                Group {
                    #if QURAN_SYNC
                    HomeViewUI(
                        type: type,
                        readingBookmark: readingBookmark,
                        lastPages: lastPages,
                        suras: quran.suras,
                        quarters: quran.quarters.map { QuarterItem(quarter: $0, ayahText: Self.ayahText) },
                        start: {},
                        selectReadingBookmark: { _ in },
                        selectLastPage: { _ in },
                        selectSura: { _ in },
                        selectQuarter: { _ in },
                        surahSortOrder: .ascending,
                        isJuzExpanded: { !collapsedJuzs.contains($0) },
                        setJuzExpanded: { juz, expanded in
                            if expanded { collapsedJuzs.remove(juz) } else { collapsedJuzs.insert(juz) }
                        }
                    )
                    #else
                    HomeViewUI(
                        type: type,
                        lastPages: lastPages,
                        suras: quran.suras,
                        quarters: quran.quarters.map { QuarterItem(quarter: $0, ayahText: Self.ayahText) },
                        start: {},
                        selectLastPage: { _ in },
                        selectSura: { _ in },
                        selectQuarter: { _ in },
                        surahSortOrder: .ascending,
                        isJuzExpanded: { !collapsedJuzs.contains($0) },
                        setJuzExpanded: { juz, expanded in
                            if expanded { collapsedJuzs.remove(juz) } else { collapsedJuzs.insert(juz) }
                        }
                    )
                    #endif
                }
                .navigationTitle("Home")
                .toolbar {
                    if type == .suras {
                        Button("Juzs") { type = .juzs }
                    } else {
                        Button("Suras") { type = .suras }
                    }

                    if lastPages.isEmpty {
                        Button("Populate Last Pages") { lastPages = Self.staticLastPages }
                    } else {
                        Button("Empty") { lastPages = [] }
                    }
                }
            }
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Preview()
        }
    }
}
