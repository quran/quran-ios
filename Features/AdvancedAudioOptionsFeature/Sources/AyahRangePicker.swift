//
//  AyahRangePicker.swift
//  Quran
//

import Localization
import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
struct AyahRangePicker: View {
    let fromVerse: AyahNumber
    let toVerse: AyahNumber
    let updateFromVerseTo: ItemAction<AyahNumber>
    let updateToVerseTo: ItemAction<AyahNumber>

    @State private var expandedBoundary: Boundary?

    var body: some View {
        Group {
            BoundaryRow(
                title: lAndroid("from"),
                verse: fromVerse,
                isExpanded: expandedBoundary == .from
            ) {
                toggle(.from)
            }

            if expandedBoundary == .from {
                AyahWheelPicker(
                    selection: fromVerse,
                    minimum: nil,
                    onSelection: updateFromVerseTo
                )
            }

            BoundaryRow(
                title: lAndroid("to"),
                verse: toVerse,
                isExpanded: expandedBoundary == .to
            ) {
                toggle(.to)
            }

            if expandedBoundary == .to {
                AyahWheelPicker(
                    selection: toVerse,
                    minimum: fromVerse,
                    onSelection: updateToVerseTo
                )
            }
        }
    }

    private func toggle(_ boundary: Boundary) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedBoundary = expandedBoundary == boundary ? nil : boundary
        }
    }
}

private extension AyahRangePicker {
    enum Boundary {
        case from
        case to
    }
}

@MainActor
private struct BoundaryRow: View {
    let title: String
    let verse: AyahNumber
    let isExpanded: Bool
    let action: @MainActor () -> Void

    @ScaledMetric private var spacing: CGFloat = 8

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer(minLength: spacing)

                let reference: MultipartText = "\(ayah: verse)"
                reference
                    .view(ofSize: .body, allowsWrapping: false)
                    .foregroundStyle(isExpanded ? Color.appIdentity : .secondary)

                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isExpanded ? Color.appIdentity : Color(.tertiaryLabel))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(verse.localizedName)
    }
}

@MainActor
private struct AyahWheelPicker: View {
    let selection: AyahNumber
    let minimum: AyahNumber?
    let onSelection: ItemAction<AyahNumber>

    @ScaledMetric private var pickerHeight: CGFloat = 150
    @ScaledMetric private var ayahPickerWidth: CGFloat = 120

    private var model: AyahWheelPickerModel {
        AyahWheelPickerModel(selection: selection, minimum: minimum)
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker(lAndroid("sura"), selection: suraBinding) {
                ForEach(model.suras) { sura in
                    let reference: MultipartText = "\(sura.localizedSuraNumber) · \(sura: sura)"
                    reference
                        .view(ofSize: .body, allowsWrapping: false)
                        .tag(sura)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .clipped()

            Divider()

            Picker(l("ayah"), selection: ayahBinding) {
                ForEach(model.ayahs, id: \.self) { ayah in
                    Text(ayah.localizedAyahNumber)
                        .tag(ayah)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: ayahPickerWidth)
            .clipped()
            .id(selection.sura)
        }
        .frame(height: pickerHeight)
    }

    private var suraBinding: Binding<Sura> {
        Binding(
            get: { selection.sura },
            set: { onSelection(model.selecting(sura: $0)) }
        )
    }

    private var ayahBinding: Binding<AyahNumber> {
        Binding(
            get: { selection },
            set: { onSelection($0) }
        )
    }
}

struct AyahWheelPickerModel {
    let selection: AyahNumber
    let minimum: AyahNumber?

    var suras: [Sura] {
        selection.quran.suras.filter { sura in
            guard let minimum else { return true }
            return sura >= minimum.sura
        }
    }

    var ayahs: [AyahNumber] {
        selection.sura.verses.filter { ayah in
            guard let minimum, minimum.sura == selection.sura else { return true }
            return ayah >= minimum
        }
    }

    func selecting(sura: Sura) -> AyahNumber {
        let firstAyah = if let minimum, minimum.sura == sura {
            minimum.ayah
        } else {
            sura.firstVerse.ayah
        }
        let ayah = min(max(selection.ayah, firstAyah), sura.lastVerse.ayah)
        return AyahNumber(sura: sura, ayah: ayah)!
    }
}
