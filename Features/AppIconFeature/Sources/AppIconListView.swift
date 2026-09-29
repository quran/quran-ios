//
//  AppIconListView.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Localization
import NoorUI
import SwiftUI
import UIKit
import UIx

struct AppIconListView: View {
    @StateObject var viewModel: AppIconListViewModel

    var body: some View {
        AppIconListViewUI(
            sections: viewModel.sections,
            selectedOption: viewModel.selectedOption,
            error: $viewModel.error,
            select: { await viewModel.select($0) }
        )
    }
}

private struct AppIconListViewUI: View {
    // MARK: Internal

    let sections: [AppIconCatalog.Section]
    let selectedOption: AppIconOption
    @Binding var error: Error?
    let select: AsyncItemAction<AppIconOption>

    var body: some View {
        NoorList {
            ForEach(sections) { section in
                NoorBasicSection(title: section.title) {
                    ForEach(section.options) { option in
                        row(option, previewLength: previewLength(section.previewSize))
                    }
                }
            }
        }
        .onChange(of: selectedOption.id) { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .errorAlert(error: $error)
    }

    // MARK: Private

    @ScaledMetric(relativeTo: .body) private var largePreviewLength = 56.0
    @ScaledMetric(relativeTo: .body) private var regularPreviewLength = 48.0

    private func previewLength(_ size: AppIconCatalog.Section.PreviewSize) -> CGFloat {
        switch size {
        case .large: largePreviewLength
        case .regular: regularPreviewLength
        }
    }

    private func row(_ option: AppIconOption, previewLength: CGFloat) -> some View {
        let isSelected = option == selectedOption
        let defaultCaption = option.isPrimary ? l("app_icon.default") : nil
        return NoorListItem(
            image: .init(appIcon: option, length: previewLength),
            title: .text(option.name),
            subtitle: defaultCaption.map { .init(text: .text($0), location: .bottom) },
            accessory: isSelected ? .image(.checkmark, color: .accentColor) : nil,
            action: .async { await select(option) }
        )
        // The selected trait replaces the checkmark for VoiceOver.
        .accessibilityLabel([option.name, defaultCaption].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct Container: View {
        @State var selectedOption = previewOptions[0]

        var body: some View {
            AppIconListViewUI(
                sections: [
                    .init(id: "signature", title: "Signature", previewSize: .large, options: Array(previewOptions[0 ..< 2])),
                    .init(id: "colors", title: "Colors", previewSize: .regular, options: Array(previewOptions[2...])),
                ],
                selectedOption: selectedOption,
                error: .constant(nil),
                select: { selectedOption = $0 }
            )
        }
    }
    return Container()
}

private let previewOptions = [
    previewOption("navy-gold", nil, light: 0x000066, dark: 0xE2AF56),
    previewOption("teal-white", "AppIcon-TealWhite", light: 0x1B6B71, dark: 0x2BA9B2),
    previewOption("blue", "AppIcon-Blue", light: 0x025F9D, dark: 0x56B1FE),
    previewOption("green", "AppIcon-Green", light: 0x03694E, dark: 0x1EC192),
]

private func previewOption(_ id: String, _ alternateIconName: String?, light: Int, dark: Int) -> AppIconOption {
    AppIconOption(
        id: id,
        alternateIconName: alternateIconName,
        name: id.capitalized,
        previewImageName: "app-icon-\(id)",
        accent: AppIconAccent(light: UIColor(rgb: light), dark: UIColor(rgb: dark), onDark: .black)
    )
}
