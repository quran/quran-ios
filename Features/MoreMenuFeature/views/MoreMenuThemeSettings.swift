//
//  MoreMenuThemeSettings.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-25.
//

import Combine
import Localization
import NoorUI
import QuranText
import SwiftUI
import UIx

private class ThemeSettingsController<V: View>: UIHostingController<V> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil

        sheetPresentationController?.prefersGrabberVisible = true
        sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        sheetPresentationController?.widthFollowsPreferredContentSizeWhenEdgeAttached = true

        if #available(iOS 16.0, *) {
            sheetPresentationController?.detents = [.custom(resolver: { _ in 400 })]
        } else {
            sheetPresentationController?.detents = [.medium()]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = nil
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize

        if #available(iOS 16.0, *) {
            let height = preferredContentSize.height
            sheetPresentationController?.detents = [.custom(resolver: { _ in height })]
            sheetPresentationController?.invalidateDetents()
        }
    }
}

struct MoreMenuThemeSettingsMenuItem: View {
    let showFontSize: Bool

    @Environment(\.navigator) private var navigator
    @State private var viewController: UIViewController?

    var body: some View {
        Button {
            // capture the window before dismissing
            let window = viewController?.view.window
            navigator?.dismiss {
                let controller = ThemeSettingsController(rootView: themeSettingsView())
                controller.modalPresentationStyle = .formSheet

                let parentVC = window?.rootViewController?.deepPresentedViewController()
                parentVC?.present(controller, animated: true)
            }
        } label: {
            NoorListItem(
                title: .text(l("menu.theme_settings")),
                accessory: .disclosureIndicator
            )
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .background(Color.systemBackground)
        UIViewControllerReader(viewController: $viewController)
    }

    private func themeSettingsView() -> some View {
        MoreMenuThemeSettingsView(showFontSize: showFontSize)
    }
}

private struct SectionHeader: View {
    let header: String
    var body: some View {
        Text(header)
            .font(.headline)
    }
}

private struct AppearanceModeSelectorButton: View {
    @Binding var selectedAppearance: AppearanceMode
    var body: some View {
        DropdownButton(items: [.auto, .dark, .light], selectedItem: $selectedAppearance) { appearance in
            Label(appearance.localizedName, systemImage: icon(for: appearance))
        }
    }

    private func icon(for mode: AppearanceMode) -> String {
        switch mode {
        case .auto: return "circle.righthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

private struct FontSizeView: View {
    let label: String
    let labelWidth: CGFloat
    @Binding var size: FontSize
    @Binding var labelSize: CGSize

    var body: some View {
        HStack(spacing: 30) {
            Text(label)
                .fixedSize()
                .onSizeChange {
                    labelSize = $0
                }
                .frame(width: labelWidth, alignment: .leading)

            FontSizeStepper(fontSize: $size)
        }
    }
}

struct MoreMenuThemeSettingsView: View {
    @StateObject var viewModel = MoreMenuThemeSettingsViewModel()

    let showFontSize: Bool

    @State private var arabicLabelSize: CGSize = .zero
    @State private var translationLabelSize: CGSize = .zero

    @ScaledMetric var compactVerticalPadding = 3.0

    var fontSizeLabelWidth: CGFloat {
        max(arabicLabelSize.width, translationLabelSize.width)
    }

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack {
                    HStack {
                        Text(l("menu.theme_settings"))
                            .font(.title)
                            .fontWeight(.semibold)
                        Spacer()
                        CloseButton()
                    }

                    if showFontSize {
                        FontSizeView(
                            label: l("menu.arabicFontSize"),
                            labelWidth: fontSizeLabelWidth,
                            size: $viewModel.arabicFontSize,
                            labelSize: $arabicLabelSize
                        )

                        Divider()
                            .padding(.vertical, compactVerticalPadding)

                        FontSizeView(
                            label: l("menu.translationFontSize"),
                            labelWidth: fontSizeLabelWidth,
                            size: $viewModel.translationFontSize,
                            labelSize: $translationLabelSize
                        )
                    }

                    Divider()
                        .padding(.vertical, compactVerticalPadding)

                    VStack(spacing: 0) {
                        HStack {
                            SectionHeader(header: "Themes") // TODO: Localize
                            Spacer()

                            AppearanceModeSelectorButton(selectedAppearance: $viewModel.appearanceMode)
                        }
                        .padding(.horizontal)

                        ThemeStyleSelector(selectedStyle: $viewModel.themeStyle)
                    }
                }
                .padding()
            }
        }
        .background(.thickMaterial)
    }
}

#Preview {
    VStack {
        Section {
            MoreMenuThemeSettingsMenuItem(showFontSize: true)
        }

        MoreMenuThemeSettingsView(showFontSize: false)
    }
}
