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
import QuranText
import SwiftUI
import UIx

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        #if QURAN_SYNC
        HomeViewUI(
            type: viewModel.type,
            readingBookmarks: viewModel.readingBookmarks,
            lastPages: viewModel.lastPages,
            suras: viewModel.suras,
            quarters: viewModel.quarters,
            quranFont: viewModel.reading.quranFont,
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
            quranFont: viewModel.reading.quranFont,
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
    let readingBookmarks: [PlacedReadingBookmark]
    #endif
    let lastPages: [LastPage]
    let suras: [Sura]
    let quarters: [QuarterItem]
    let quranFont: QuranFont

    let start: AsyncAction

    #if QURAN_SYNC
    let selectReadingBookmark: ItemAction<PlacedReadingBookmark>
    #endif
    let selectLastPage: ItemAction<LastPage>
    let selectSura: ItemAction<Sura>
    let selectQuarter: ItemAction<QuarterItem>
    let surahSortOrder: SurahSortOrder
    let isJuzExpanded: (Juz) -> Bool
    let setJuzExpanded: (Juz, Bool) -> Void

    var body: some View {
        ZStack {
            NoorList {
                #if QURAN_SYNC
                ContinueReadingSection(
                    readingBookmarks: readingBookmarks,
                    lastPages: lastPages,
                    selectReadingBookmark: selectReadingBookmark,
                    selectLastPage: selectLastPage
                )
                #else
                ContinueReadingSection(lastPages: lastPages, selectLastPage: selectLastPage)
                #endif

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
            // iOS 15's SwiftUI List produces invalid UITableView batch updates when
            // every section and row moves at once. Replace the list snapshot instead.
            .id(surahSortOrder.rawValue)
        }
        .task { await start() }
    }

    func suraView(_ sura: Sura) -> some View {
        let ayahsString = lFormat("verses", table: .android, sura.verses.count)
        let suraType = sura.isMakki ? lAndroid("makki") : lAndroid("madani")
        var subtitleComponents = [suraType, ayahsString]
        if !Locale.preferredLanguageLocale.isArabicLanguage {
            subtitleComponents.insert(sura.localizedTranslatedName(), at: 0)
        }
        let subtitle = subtitleComponents.joined(separator: " · ")

        return NoorListItem(
            title: "\(sura.localizedSuraNumber). \(sura: sura)",
            subtitle: .init(text: .text(subtitle), location: .bottom),
            accessory: .text(sura.page.localizedNumber, accessibilityLabel: sura.page.localizedName),
            action: .sync { selectSura(sura) }
        )
    }

    func quarterView(_ item: QuarterItem) -> some View {
        let quarter = item.quarter
        let ayah = quarter.firstVerse
        let page = ayah.page

        return NoorListItem(
            subheading: .text(quarter.localizedName),
            title: "\(ayah: ayah)",
            rightSubtitle: "\(quran: item.ayahText, font: quranFont, lineLimit: 1)",
            accessory: .text(page.localizedNumber, accessibilityLabel: page.localizedName),
            action: .sync { selectQuarter(item) }
        )
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

@MainActor
private struct HomePreview: View {
    static let ayahText: QuranText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"

    static var staticLastPages: [LastPage] {
        let pages = [0, 4, 49, 76, 105, 127, 150, 176, 200, 221].map { Quran.hafsMadani1405.pages[$0] }
        return (0 ..< pages.count).map { i -> LastPage in
            let timestamp = Date(timeIntervalSinceNow: -Double(i * 31 + 1) * 60)
            #if QURAN_SYNC
            return LastPage(
                id: "preview-\(i)",
                page: pages[i],
                modifiedOn: timestamp
            )
            #else
            return LastPage(
                page: pages[i],
                createdOn: timestamp,
                modifiedOn: timestamp
            )
            #endif
        }
    }

    let quran = Quran.hafsMadani1405

    @State var lastPages: [LastPage] = staticLastPages
    #if QURAN_SYNC
    @State var readingBookmarks: [PlacedReadingBookmark] = [
        PlacedReadingBookmark(
            id: "preview-teal", slot: .teal,
            placement: .ayah(Quran.hafsMadani1405.suras[0].verses[5]),
            modifiedOn: Date(timeIntervalSinceNow: -36000)
        ),
        PlacedReadingBookmark(
            id: "preview-coral", slot: .coral,
            placement: .page(Quran.hafsMadani1405.pages[22]),
            modifiedOn: Date(timeIntervalSinceNow: -86400)
        ),
        PlacedReadingBookmark(
            id: "preview-indigo", slot: .indigo,
            placement: .ayah(Quran.hafsMadani1405.suras[35].verses[57]),
            modifiedOn: Date(timeIntervalSinceNow: -259_200)
        ),
    ]
    #endif
    @State var type: HomeViewType = .suras
    @State var collapsedJuzs: Set<Juz> = []

    var body: some View {
        NavigationView {
            Group {
                #if QURAN_SYNC
                HomeViewUI(
                    type: type,
                    readingBookmarks: readingBookmarks,
                    lastPages: lastPages,
                    suras: quran.suras,
                    quarters: quran.quarters.map { QuarterItem(quarter: $0, ayahText: Self.ayahText) },
                    quranFont: .uthmanicHafs,
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
                    quranFont: .uthmanicHafs,
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

#Preview {
    HomePreview()
}
