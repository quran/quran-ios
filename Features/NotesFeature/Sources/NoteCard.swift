//
//  NoteCard.swift
//

import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
struct NoteCard: View {
    // MARK: Internal

    let reference: MultipartText
    let location: String
    let quranText: MultipartText?
    let noteText: MultipartText?
    let modifiedDate: String
    let noteColor: Color?
    let editAccessibilityHint: String
    let selectAction: @MainActor @Sendable () -> Void
    let editAction: @MainActor @Sendable () -> Void

    @ScaledMetric private var cardCornerRadius = 20.0
    @ScaledMetric private var cardPadding = 18.0
    @ScaledMetric private var contentSpacing = 16.0
    @ScaledMetric private var metadataSpacing = 2.0
    @ScaledMetric private var footerSpacing = 8.0
    @ScaledMetric private var colorIndicatorWidth = 4.0
    @ScaledMetric private var colorIndicatorInset = 12.0

    var body: some View {
        VStack(spacing: 0) {
            Button(action: selectAction) {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    header

                    if let quranText {
                        HStack {
                            quranText.view(ofSize: .caption, alignment: .trailing)
                                .foregroundColor(.secondaryLabel)
                            Spacer(minLength: 0)
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, cardPadding)
                .padding(.top, cardPadding)
                .padding(.bottom, contentSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(BackgroundHighlightingStyle())

            Divider()
                .padding(.horizontal, cardPadding)
                .accessibilityHidden(true)

            Button(action: editAction) {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    if let noteText {
                        noteText.view(ofSize: .body)
                            .foregroundColor(.label)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    footer
                }
                .padding(.horizontal, cardPadding)
                .padding(.top, contentSpacing)
                .padding(.bottom, cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(BackgroundHighlightingStyle())
            .accessibilityHint(editAccessibilityHint)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        #if !QURAN_SYNC
            .overlay(alignment: .leading) {
                if let noteColor {
                    Capsule()
                        .fill(noteColor)
                        .frame(width: colorIndicatorWidth)
                        .padding(.vertical, colorIndicatorInset)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
        #endif
    }

    // MARK: Private

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: metadataSpacing) {
                reference
                    .view(ofSize: .footnote, allowsWrapping: false)

                Text(location)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }

            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack(spacing: footerSpacing) {
            Text(modifiedDate)
                .font(.footnote)
                .foregroundColor(.secondaryLabel)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.tertiaryLabel)
                .flipsForRightToLeftLayoutDirection(true)
                .accessibilityHidden(true)
        }
    }
}

@MainActor
private struct NoteCardPreview: View {
    var body: some View {
        let ayah = Quran.hafsMadani1405.suras[15].verses[26]
        let reference: MultipartText = "\(ayah: ayah)"
        let quranText: MultipartText = "\(quran: "ثُمَّ يَوْمَ الْقِيَامَةِ يُخْزِيهِمْ وَيَقُولُ أَيْنَ شُرَكَائِيَ الَّذِينَ كُنتُمْ تُشَاقُّونَ فِيهِمْ", color: .clear, lineLimit: 2)"

        NoteCard(
            reference: reference,
            location: "\(ayah.page.startJuz.localizedName) · \(ayah.page.localizedName)",
            quranText: quranText,
            noteText: .text("“Where are My partners?” — the question itself is the humiliation."),
            modifiedDate: "Yesterday",
            noteColor: .green,
            editAccessibilityHint: "Edit note",
            selectAction: {},
            editAction: {}
        )
        .padding()
        .frame(width: 390)
        .background(Color.systemGroupedBackground)
    }
}

#Preview {
    NoteCardPreview()
}
