//
//  AdvancedAudioVersesViewController.swift
//
//
//  Created by Afifi, Mohamed on 10/10/21.
//

import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI

struct AdvancedAudioVersesView: View {
    let suras: [Sura]
    let selected: AyahNumber
    let onSelection: @MainActor (AyahNumber) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(suras) { sura in
                    SuraSectionView(
                        sura: sura,
                        selected: selected,
                        onSelection: onSelection
                    )
                }
            }
            .listStyle(.insetGrouped)
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
        }
    }
}

private struct SuraSectionView: View {
    let sura: Sura
    let selected: AyahNumber
    let onSelection: @MainActor (AyahNumber) -> Void

    var body: some View {
        Section {
            ForEach(sura.verses, id: \.self) { ayah in
                AyahRowView(
                    ayah: ayah,
                    isSelected: ayah == selected,
                    onSelection: onSelection
                )
                .id(ayah)
            }
        } header: {
            let title: MultipartText = "\(sura: sura)"
            title.view(ofSize: .caption, allowsWrapping: false)
        }
    }
}

private struct AyahRowView: View {
    let ayah: AyahNumber
    let isSelected: Bool
    let onSelection: @MainActor (AyahNumber) -> Void

    var body: some View {
        Button {
            onSelection(ayah)
        } label: {
            HStack {
                ("\(ayah: ayah)" as MultipartText)
                    .view(ofSize: .body)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    NoorSystemImage.checkmark.image
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
