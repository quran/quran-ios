//
//  QuranThemedImage.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-04-01.
//

import SwiftUI

public struct QuranThemedImage: View {
    // MARK: Lifecycle

    public init(image: UIImage, renderingMode: RenderingMode = .tinted) {
        self.image = image
        self.renderingMode = renderingMode
    }

    // MARK: Public

    public enum RenderingMode: Equatable {
        case tinted
        case invertInDarkMode
    }

    public var body: some View {
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
                processingTask?.cancel()
            }
    }

    // MARK: Internal

    @Environment(\.themeStyle) var themeStyle
    @Environment(\.colorScheme) var colorScheme

    let image: UIImage
    let renderingMode: RenderingMode

    // MARK: Private

    @State private var themedImage: UIImage?
    @State private var processingTask: Task<Void, Never>? = nil

    /// Process the image on a background thread and update the state on the main thread.
    private func processImage(colorScheme: ColorScheme, themeStyle: ThemeStyle) {
        processingTask?.cancel()

        processingTask = Task {
            let processedImage = await processedImage(colorScheme: colorScheme, themeStyle: themeStyle)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                themedImage = processedImage
            }
        }
    }

    private func processedImage(colorScheme: ColorScheme, themeStyle: ThemeStyle) async -> UIImage? {
        switch renderingMode {
        case .tinted:
            // return await tintedImage(colorScheme: colorScheme, themeStyle: themeStyle)
            fallthrough // Tinting is not perfect, currently, let's reconsider it later
        case .invertInDarkMode:
            guard colorScheme == .dark || themeStyle == .quiet else {
                return nil
            }
            return await invertedImage()
        }
    }

    private func tintedImage(colorScheme: ColorScheme, themeStyle: ThemeStyle) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = image.tintedImageUsingFalseColorFilter(colorScheme: colorScheme, themeStyle: themeStyle)
                continuation.resume(returning: result)
            }
        }
    }

    private func invertedImage() async -> UIImage {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = image.inverted()
                continuation.resume(returning: result)
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
