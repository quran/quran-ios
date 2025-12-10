//
//  QuranVerticalPaginationView.swift
//  Quran
//
//  Created by Adnan on 12/08/25.
//

import NoorUI
import QuranKit
import SwiftUI

struct QuranVerticalPaginationView<Content: View>: View {
    // MARK: Internal

    @Binding var selection: [Page]
    let pages: [Page]
    @ViewBuilder let content: (Page) -> Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredPages) { page in
                        VStack(spacing: 0) {
                            content(page)
                                .environment(\.scrollingEnabled, false) // Disable internal scrolling
                            
                            if page != filteredPages.last {
                                QuranSeparators.PageMiddleSeparator()
                            }
                        }
                        .id(page)
                        .background(GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: PageVisibilityPreferenceKey.self,
                                    value: [PageVisibility(page: page, minY: geo.frame(in: .named("QuranVerticalScroll")).minY, height: geo.size.height)]
                                )
                        })
                        .onAppear {
                            handlePageAppear(page)
                        }
                    }
                }
            }
            .coordinateSpace(name: "QuranVerticalScroll")
            .onAppear {
                initializeRange()
                // Trigger initial scroll after a short delay to allow layout
                if let first = selection.first {
                    pendingInitialScrollPage = first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(first, anchor: .top)
                    }
                }
            }
            .onPreferenceChange(PageVisibilityPreferenceKey.self) { visibilities in
                handleVisibilityChange(visibilities, proxy: proxy)
            }
            .onChange(of: selection) { newSelection in
                handleSelectionChange(newSelection, proxy: proxy)
            }
        }
    }

    // MARK: Private

    @State private var isProgrammaticScroll = false
    @State private var lastUserScrolledPage: Page?
    @State private var loadedRange: ClosedRange<Int>?
    
    @State private var isDefaultRange = false
    @State private var pendingInitialScrollPage: Page?
    
    private let pageBuffer = 20
    private let expandThreshold = 10

    private var filteredPages: [Page] {
        guard let range = loadedRange else { return [] }
        let safeStart = max(0, range.lowerBound)
        let safeEnd = min(pages.count - 1, range.upperBound)
        guard safeStart <= safeEnd else { return [] }
        return Array(pages[safeStart...safeEnd])
    }

    private func initializeRange() {
        guard let first = selection.first else {
            // Mark as default to prevent overwriting correct selection later via visibility
            isDefaultRange = true
            loadedRange = 0...min(pageBuffer, pages.count - 1)
            return
        }
        
        let pageIndex = first.pageNumber - 1
        
        guard pageIndex >= 0 && pageIndex < pages.count else {
            isDefaultRange = true
            loadedRange = 0...min(pageBuffer, pages.count - 1)
            return
        }
        
        isDefaultRange = false
        // Always start from page 0 to avoid upward expansion (which causes scroll jumps)
        // Only expand downward dynamically
        let end = min(pages.count - 1, pageIndex + pageBuffer)
        loadedRange = 0...end
    }
    
    private func handlePageAppear(_ page: Page) {
        let index = page.pageNumber - 1
        guard index >= 0, let currentRange = loadedRange else { return }
        
        if index >= currentRange.upperBound - expandThreshold {
            let newEnd = min(pages.count - 1, currentRange.upperBound + pageBuffer)
            if newEnd > currentRange.upperBound {
                loadedRange = currentRange.lowerBound...newEnd
            }
        }
        
        // Note: We intentionally do NOT expand upwards or shrink.
        // Both cause scroll position jumps when LazyVStack recalculates.
    }
    
    private func handleVisibilityChange(_ visibilities: [PageVisibility], proxy: ScrollViewProxy) {
        if let targetPage = pendingInitialScrollPage {
            proxy.scrollTo(targetPage, anchor: .top)
            
            if let visiblePage = visibilities.first(where: { $0.page.pageNumber == targetPage.pageNumber }) {
                if visiblePage.height > 100 {
                    DispatchQueue.main.async {
                        self.pendingInitialScrollPage = nil
                    }
                }
            }
            return
        }
        
        guard !isProgrammaticScroll, !isDefaultRange, !visibilities.isEmpty else { return }
        
        let sorted = visibilities.sorted { $0.minY < $1.minY }
        
        let topPage = sorted.first { $0.minY > -200 } ?? sorted.last
        
        if let topPage, selection.first?.pageNumber != topPage.page.pageNumber {
            lastUserScrolledPage = topPage.page
            selection = [topPage.page]
        }
    }
    
    private func handleSelectionChange(_ newSelection: [Page], proxy: ScrollViewProxy) {
        guard let first = newSelection.first else { return }
        let index = first.pageNumber - 1
        guard index >= 0 && index < pages.count else { return }
        
        if first.pageNumber == lastUserScrolledPage?.pageNumber {
            return
        }

        isProgrammaticScroll = true
        
        let needsRangeUpdate: Bool = {
            guard let range = loadedRange else { return true }
            return isDefaultRange || !range.contains(index)
        }()
        
        if needsRangeUpdate {
             isDefaultRange = false 
             
             let start = max(0, index - pageBuffer)
             let end = min(pages.count - 1, index + pageBuffer)
             loadedRange = start...end
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 proxy.scrollTo(first, anchor: .top)
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                     self.isProgrammaticScroll = false
                 }
             }
             return
        }
        
        withAnimation {
             proxy.scrollTo(first, anchor: .top)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             self.isProgrammaticScroll = false
        }
    }
}

private struct PageVisibility: Equatable {
    let page: Page
    let minY: CGFloat
    let height: CGFloat
}

private struct PageVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [PageVisibility] = []
    static func reduce(value: inout [PageVisibility], nextValue: () -> [PageVisibility]) {
        value.append(contentsOf: nextValue())
    }
}
