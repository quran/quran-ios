//
//  FontSizeStepper.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-27.
//

import Localization
import NoorUI
import QuranText
import SwiftUI
import VLogging

struct FontSizeStepper: View {
    // MARK: Internal

    @Binding var fontSize: FontSize
    let range = Array(FontSize.allCases.sorted().reversed())

    @ScaledMetric var cornerRadius = Dimensions.cornerRadius
    @ScaledMetric var defaultSpacing = 5
    @ScaledMetric var dotsSpacing = 8

    var body: some View {
        VStack(spacing: defaultSpacing) {
            HStack(spacing: 0) {
                // Decrease button (smaller A)
                stepperButton {
                    guard currentSizeIndex > 0 else {
                        logger.error("FontSizeStepper: Cannot decrease font size beyond 0 index.")
                        return
                    }
                    fontSize = range[currentSizeIndex - 1]
                }
                .font(.body)
                .disabled(currentSizeIndex == 0)

                Divider()

                // Increase button (larger A)
                stepperButton {
                    guard currentSizeIndex < range.count - 1 else {
                        logger.error("FontSizeStepper: Cannot increase font size beyond \(range.count - 1) index.")
                        return
                    }
                    fontSize = range[currentSizeIndex + 1]
                }
                .font(.title2)
                .disabled(currentSizeIndex == range.count - 1)
            }
            .padding(.vertical, defaultSpacing)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.systemGray5)
            )
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .bottom) {
                HStack(spacing: dotsSpacing) {
                    ForEach(range.indices, id: \.self) { stepIndex in
                        Circle()
                            .fill(stepIndex <= currentSizeIndex ? Color.black : .systemGray5)
                            .frame(width: defaultSpacing, height: defaultSpacing)
                    }
                }
                .opacity(showDots ? 1 : 0)
                .animation(.bouncy, value: showDots)
                .onSizeChange { dotsSize = $0 }
                .offset(y: dotsOffset)
            }
        }
        .onDisappear {
            hideTimer?.invalidate()
            hideTimer = nil
        }
    }

    // MARK: Private

    @State private var dotsSize: CGSize = .zero

    // Dots visibility
    private let hideDelay = 2.0
    @State private var showDots = false
    @State private var hideTimer: Timer? = nil

    private var currentSizeIndex: Int {
        let index = range.firstIndex(of: fontSize)
        if index == nil {
            logger.error("Couldn't find \(fontSize) in \(range)")
        }
        return index!
    }

    private var dotsOffset: CGFloat {
        dotsSize.height / 2 + dotsSpacing
    }

    @ViewBuilder
    private func stepperButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
            showDotsTemporarily()
        } label: {
            Text(l("menu.fontSizeLetter"))
                .frame(maxWidth: .infinity)
        }
        .tint(.label)
    }

    /// Shows the dots briefly, then hides them after `hideDelay` seconds.
    private func showDotsTemporarily() {
        showDots = true
        // Invalidate any previous timer
        hideTimer?.invalidate()

        // Start a new one
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { _ in
            showDots = false
            hideTimer = nil
        }
    }
}

// MARK: - Preview

#Preview {
    struct FontSizeStepper_Previews: View {
        @State var size = FontSize.medium

        var body: some View {
            HStack {
                Text("Quran")
                FontSizeStepper(fontSize: $size)
            }
            .padding()
        }
    }

    return FontSizeStepper_Previews()
}
