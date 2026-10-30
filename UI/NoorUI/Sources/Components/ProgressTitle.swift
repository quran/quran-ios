//
//  ProgressTitle.swift
//

import Localization
import SwiftUI

/// A button title that a spinner replaces while the button's action is in progress.
///
/// The title keeps its layout while hidden, so the button doesn't change size. VoiceOver keeps reading the title,
/// with a Loading value while in progress.
public struct ProgressTitle: View {
    // MARK: Lifecycle

    /// `color` colors both the title and the spinner.
    public init(_ title: String, isInProgress: Bool, color: Color) {
        self.title = title
        self.isInProgress = isInProgress
        self.color = color
    }

    // MARK: Public

    public var body: some View {
        Text(title)
            .foregroundStyle(color)
            .opacity(isInProgress ? 0 : 1)
            .overlay {
                if isInProgress {
                    ProgressView()
                        // `tint(_:)` doesn't color a spinner on iOS 15.
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                }
            }
            // A crossfade, without motion, so it stays under Reduce Motion.
            .animation(NoorAnimation.standard, value: isInProgress)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(isInProgress ? lAndroid("loading") : "")
    }

    // MARK: Private

    private let title: String
    private let isInProgress: Bool
    private let color: Color
}

#Preview {
    VStack {
        ForEach([false, true], id: \.self) { isInProgress in
            ProgressTitle("Sign In", isInProgress: isInProgress, color: .onAccent)
                .font(.headline)
                .padding()
                .background(Color.accentColor, in: Capsule())
        }
    }
    .padding()
}
