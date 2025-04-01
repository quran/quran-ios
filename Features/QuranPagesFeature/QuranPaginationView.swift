//
//  QuranPaginationView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-25.
//

import NoorUI
import QuranKit
import SwiftUI

public enum PagingStrategy {
    case singlePage
    case doublePage
}

public struct QuranPaginationView<Content: View>: View {
    // MARK: Lifecycle

    public init(pagingStrategy: PagingStrategy, selection: Binding<[Page]>, pages: [Page], content: @escaping (Page) -> Content) {
        self.pagingStrategy = pagingStrategy
        _selection = selection
        self.pages = pages
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        Group {
            switch pagingStrategy {
            case .singlePage:
                QuranSinglePaginationView(
                    selection: singlePageSelection,
                    pages: pages,
                    content: contentView
                )
            case .doublePage:
                QuranDoublePaginationView(
                    selection: $selection,
                    pages: pages,
                    content: contentView
                )
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .accessibilityIdentifier("pages")
        .themedBackground()
        .populateThemeStyle()
        .appearanceModeColorSchema()
        .ignoresSafeArea()
    }

    // MARK: Private

    @Environment(\.layoutDirection) private var layoutDirection

    private let pagingStrategy: PagingStrategy

    @Binding private var selection: [Page]
    private let pages: [Page]

    @ViewBuilder private let content: (Page) -> Content

    private var singlePageSelection: Binding<Page> {
        Binding(
            get: { selection[0] },
            set: { selection = [$0] }
        )
    }

    @ViewBuilder
    private func contentView(for page: Page) -> some View {
        content(page)
            .environment(\.layoutDirection, layoutDirection)
    }
}

private struct QuranDoublePaginationView<Content: View>: View {
    private struct DoublePage: Identifiable, Equatable {
        let first: Page
        let second: Page

        var id: [Page] { [first, second] }
    }

    // MARK: Internal

    @Binding var selection: [Page]
    let pages: [Page]
    @ViewBuilder let content: (Page) -> Content

    var body: some View {
        PageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            interPageSpacing: ContentDimension.interPageSpacing,
            animated: true,
            selection: doublePageSelection
        ) {
            ForEach(doublePages) { doublePage in
                HStack(spacing: 0) {
                    QuranSeparators.PageSideSeparator(leading: true)
                    content(doublePage.first)
                    QuranSeparators.PageMiddleSeparator()
                    content(doublePage.second)
                    QuranSeparators.PageSideSeparator(leading: false)
                }
            }
        }
    }

    // MARK: Private

    private var doublePageSelection: Binding<DoublePage> {
        Binding(
            get: {
                let pageIndex = selection.first.flatMap { pages.firstIndex(of: $0) } ?? 0
                return doublePages[pageIndex / 2]
            },
            set: { selection = [$0.first, $0.second] }
        )
    }

    private var doublePages: [DoublePage] {
        stride(from: 0, to: pages.count, by: 2).map {
            DoublePage(first: pages[$0], second: pages[$0 + 1])
        }
    }
}

private struct QuranSinglePaginationView<Content: View>: View {
    // MARK: Internal

    @Binding var selection: Page
    let pages: [Page]
    @ViewBuilder let content: (Page) -> Content

    var body: some View {
        PageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            interPageSpacing: ContentDimension.interPageSpacing,
            animated: true,
            selection: $selection
        ) {
            ForEach(pages) { page in
                Group {
                    if isRightSide(page) {
                        HStack(spacing: 0) {
                            QuranSeparators.PageSideSeparator(leading: true)
                            content(page)
                            QuranSeparators.PageMiddleSeparator()
                                .offset(x: middleOffset)
                                .padding(.leading, -middleOffset)
                        }
                    } else {
                        HStack(spacing: 0) {
                            content(page)
                            QuranSeparators.PageSideSeparator(leading: false)
                        }
                    }
                }
            }
        }
    }

    // MARK: Private

    private var middleOffset: CGFloat {
        QuranSeparators.middleWidth
    }

    private func isRightSide(_ page: Page) -> Bool {
        page.pageNumber % 2 == 1
    }
}

extension Page: @retroactive Identifiable {
    public var id: Int { pageNumber }
}

struct QuranPaginationView_Previews: PreviewProvider {
    struct QuranPaginationViewPreview: View {
        static let quran = Quran.hafsMadani1405

        @State var selection = [quran.pages[0]]
        let pages = quran.pages

        let pagingStrategy: PagingStrategy

        var body: some View {
            QuranPaginationView(
                pagingStrategy: pagingStrategy,
                selection: $selection,
                pages: pages
            ) { page in
                ZStack {
                    VStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Page: \(page.pageNumber) left")
                                Spacer()
                                Text("Page: \(page.pageNumber) Right")
                            }
                            Spacer()
                            HStack {
                                Text("Page: \(page.pageNumber)")
                                Spacer()
                                Text("Page: \(page.pageNumber)")
                            }
                            Spacer()
                            HStack {
                                Text("Page: \(page.pageNumber)")
                                Spacer()
                                Text("Page: \(page.pageNumber)")
                            }
                        }
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    // MARK: Internal

    static var previews: some View {
        QuranPaginationViewPreview(pagingStrategy: .singlePage)
        QuranPaginationViewPreview(pagingStrategy: .doublePage)
    }
}
