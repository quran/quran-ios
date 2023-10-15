//
//  HomeView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        HomeViewUI(
            type: viewModel.type,
            lastPages: viewModel.lastPages,
            suras: viewModel.suras,
            quarters: viewModel.quarters,
            start: { await viewModel.start() },
            selectLastPage: { viewModel.navigateTo($0) },
            selectSura: { viewModel.navigateTo($0) },
            selectQuarter: { viewModel.navigateTo($0) }
        )
    }
}

private struct HomeViewUI: View {
    let type: HomeViewType
    let lastPages: [LastPage]
    let suras: [Sura]
    let quarters: [QuarterItem]

    let start: AsyncAction

    let selectLastPage: ItemAction<Page>
    let selectSura: ItemAction<Sura>
    let selectQuarter: ItemAction<QuarterItem>

    var body: some View {
        NoorList {
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
        .task(start)
    }

    func lastPageView(_ lastPage: LastPage) -> some View {
        let ayah = lastPage.page.firstVerse
        return NoorListItem(
            image: .init(.lastPage, color: .secondaryLabel),
            title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
            subtitle: .init(text: lastPage.createdOn.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(lastPage.page.pageNumber))
        ) {
            selectLastPage(lastPage.page)
        }
    }

    func suraView(_ sura: Sura) -> some View {
        let ayahsString = lFormat("verses", table: .android, sura.verses.count)
        let suraType = sura.isMakki ? lAndroid("makki") : lAndroid("madani")

        let numberFormatter = NumberFormatter.shared

        return NoorListItem(
            title: "\(sura.localizedName(withNumber: true)) \(sura: sura.arabicSuraName)",
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
        let localizedVerse = ayah.localizedName
        let arabicSuraName = ayah.sura.arabicSuraName

        return NoorListItem(
            title: "\(quarter.localizedName) - \(localizedVerse) \(sura: arabicSuraName)",
            rightSubtitle: "\(verse: item.ayahText, color: .clear, lineLimit: 1)",
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
        let juzs = itemsByJuz.keys.sorted()
        ForEach(juzs) { juz in
            NoorSection(title: juz.localizedName, itemsByJuz[juz] ?? []) { item in
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
                LastPage(
                    page: pages[i],
                    createdOn: Date(timeIntervalSince1970: Double(i) * 60 * -3),
                    modifiedOn: Date(timeIntervalSince1970: Double(i) * 60 * -3)
                )
            }
        }

        let quran = Quran.hafsMadani1405

        @State var lastPages: [LastPage] = staticLastPages
        @State var type: HomeViewType = .juzs

        var body: some View {
            NavigationView {
                HomeViewUI(
                    type: type,
                    lastPages: lastPages,
                    suras: quran.suras,
                    quarters: quran.quarters.map { QuarterItem(quarter: $0, ayahText: Self.ayahText) },
                    start: {},
                    selectLastPage: { _ in },
                    selectSura: { _ in },
                    selectQuarter: { _ in }
                )
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
