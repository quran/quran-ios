//
//  QuranThemedImage.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-04-01.
//

import SwiftUI

struct QuranThemedImage: View {
    @Environment(\.themeStyle) var themeStyle
    @Environment(\.colorScheme) var colorScheme

    let image: UIImage

    @State private var themedImage: UIImage?
    @State private var processingTask: Task<Void, Never>? = nil

    var body: some View {
        Image(uiImage: themedImage ?? image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onChange(of: themeStyle) { newThemeStyle in
                processImage(colorScheme: colorScheme, themeStyle: newThemeStyle)
            }
            .onChange(of: colorScheme) { newColorScheme in
                processImage(colorScheme: newColorScheme, themeStyle: themeStyle)
            }
            .onAppear {
                processImage(colorScheme: colorScheme, themeStyle: themeStyle)
            }
            .onDisappear {
                // Cancel any ongoing task when view disappears
                processingTask?.cancel()
            }
    }

    /// Process the image on a background thread and update the state on the main thread.
    private func processImage(colorScheme: ColorScheme, themeStyle: ThemeStyle) {
        // Cancel any ongoing processing task
        processingTask?.cancel()

        // Create a new task for image processing
        processingTask = Task {
            // Run the processing on a background queue
            let processedImage = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = image.tintedImageUsingFalseColorFilter(colorScheme: colorScheme, themeStyle: themeStyle)
                    continuation.resume(returning: result)
                }
            }

            // If the task has been cancelled, exit early.
            guard !Task.isCancelled else { return }

            // Update the UI on the main thread
            await MainActor.run {
                themedImage = processedImage
            }
        }
    }
}

extension UIImage {
    func tintedImageUsingFalseColorFilter(colorScheme: ColorScheme, themeStyle: ThemeStyle) -> UIImage? {
        tintedImageUsingFalseColorFilter(with: themeStyle.textColor.resolvedColor(with: colorScheme.traitCollection))
    }
}

extension ColorScheme {
    var traitCollection: UITraitCollection {
        switch self {
        case .light: return UITraitCollection(userInterfaceStyle: .light)
        case .dark: return UITraitCollection(userInterfaceStyle: .dark)
        @unknown default: return UITraitCollection(userInterfaceStyle: .light)
        }
    }
}
