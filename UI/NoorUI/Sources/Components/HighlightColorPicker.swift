//
//  HighlightColorPicker.swift
//

import Localization
import QuranAnnotations
import SwiftUI
import UIx

public struct HighlightColorPicker: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    // MARK: Lifecycle

    public init(
        selectedColor: HighlightColor?,
        partiallySelectedColors: Set<HighlightColor> = [],
        onSelect: @escaping AsyncItemAction<HighlightColor>,
        onRemove: AsyncAction? = nil
    ) {
        self.selectedColor = selectedColor
        self.partiallySelectedColors = partiallySelectedColors
        self.onSelect = onSelect
        self.onRemove = onRemove
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(HighlightColor.sortedColors, id: \.self) { color in
                        colorButton(
                            color: color,
                            isSelected: selectedColor == color,
                            isPartiallySelected: partiallySelectedColors.contains(color),
                            accessibilityLabel: color.localizedName
                        )
                    }

                    if let onRemove {
                        HStack(spacing: spacing) {
                            Capsule()
                                .fill(Color.separator)
                                .frame(width: 2, height: dividerHeight)
                                .accessibilityHidden(true)

                            AsyncButton(action: onRemove) {
                                Text(lAndroid("remove_button"))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.systemRed)
                                    .frame(minHeight: minimumTapLength)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(l("ayah.menu.delete-highlight"))
                        }
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(minWidth: proxy.size.width, alignment: .center)
                .animation(
                    accessibilityReduceMotion ? nil : .easeInOut(duration: 0.2),
                    value: onRemove != nil
                )
            }
        }
        .frame(height: minimumTapLength)
    }

    // MARK: Private

    @ScaledMetric private var circleLength = 36.0
    @ScaledMetric private var minimumTapLength = 44.0
    @ScaledMetric private var selectedStrokeWidth = 3.0
    @ScaledMetric private var dividerHeight = 24.0
    @ScaledMetric private var spacing = 8.0

    private let selectedColor: HighlightColor?
    private let partiallySelectedColors: Set<HighlightColor>
    private let onSelect: AsyncItemAction<HighlightColor>
    private let onRemove: AsyncAction?

    private func colorButton(
        color: HighlightColor,
        isSelected: Bool,
        isPartiallySelected: Bool,
        accessibilityLabel: String
    ) -> some View {
        AsyncButton {
            await onSelect(color)
        } label: {
            ZStack {
                Circle()
                    .fill(color.color)
                Circle()
                    .stroke(Color.separator.opacity(0.55), lineWidth: 1)

                if isSelected {
                    NoorSystemImage.checkmark.image
                        .font(.body.weight(.bold))
                        .foregroundStyle(selectionColor)
                }

                if isSelected {
                    Circle()
                        .stroke(selectionColor, lineWidth: selectedStrokeWidth)
                } else if isPartiallySelected {
                    Circle()
                        .strokeBorder(
                            selectionColor,
                            style: StrokeStyle(
                                lineWidth: selectedStrokeWidth,
                                lineCap: .round,
                                dash: [selectedStrokeWidth * 1.5]
                            )
                        )
                }
            }
            .frame(width: circleLength, height: circleLength)
            .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected || isPartiallySelected ? .isSelected : [])
    }

    private var selectionColor: Color {
        Color.label.opacity(0.72)
    }
}

struct HighlightColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HighlightColorPicker(
                selectedColor: .blue,
                partiallySelectedColors: [.red, .green],
                onSelect: { _ in },
                onRemove: {}
            )
            HighlightColorPicker(
                selectedColor: nil,
                onSelect: { _ in }
            )
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
