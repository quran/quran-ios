import SwiftUI
import UIx

public struct AnnotationListItem: View {
    @ScaledMetric private var contentSpacing = ContentDimension.interPageSpacing
    @ScaledMetric private var footerSpacing = ContentDimension.interSpacing / 2

    public init(
        subheading: MultipartText,
        verseText: MultipartText,
        noteText: String?,
        modifiedDateText: String,
        pageNumberText: String,
        action: AsyncAction? = nil
    ) {
        self.subheading = subheading
        self.verseText = verseText
        self.noteText = noteText
        self.modifiedDateText = modifiedDateText
        self.pageNumberText = pageNumberText
        self.action = action
    }

    public var body: some View {
        if let action {
            AsyncButton(action: action) {
                content
            }
        } else {
            content
        }
    }

    let subheading: MultipartText
    let verseText: MultipartText
    let noteText: String?
    let modifiedDateText: String
    let pageNumberText: String
    let action: AsyncAction?

    private var trimmedNoteText: String? {
        let trimmed = noteText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private var content: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: contentSpacing) {
                subheading.view(ofSize: .caption)
                    .foregroundColor(Color.secondaryLabel)

                verseText.view(ofSize: .body)

                VStack(alignment: .leading, spacing: footerSpacing) {
                    if let trimmedNoteText {
                        Text(trimmedNoteText)
                    }

                    Text(modifiedDateText)
                        .foregroundColor(Color.secondaryLabel)
                        .font(.footnote)
                }
            }

            Spacer(minLength: ContentDimension.interPageSpacing)

            Text(pageNumberText)
                .foregroundColor(.secondaryLabel)
                .fontWeight(.light)
        }
        .foregroundColor(.primary)
        .contentShape(Rectangle())
    }
}
