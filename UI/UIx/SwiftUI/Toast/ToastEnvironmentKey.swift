//
//  ToastEnvironmentKey.swift
//
//
//  Created by Mohamed Afifi on 2024-09-22.
//

import SwiftUI
import VLogging

extension EnvironmentValues {
    public var showToast: ((Toast) -> Void)? {
        get { self[ToastPresenterKey.self] }
        set { self[ToastPresenterKey.self] = newValue }
    }
}

extension View {
    public func enableToastPresenter() -> some View {
        modifier(ToastPresenterModifier())
    }
}

private struct ToastPresenterKey: EnvironmentKey {
    static let defaultValue: ((Toast) -> Void)? = nil
}

private struct ToastPresenterModifier: ViewModifier {
    @State private var windowScene: UIWindowScene?

    func body(content: Content) -> some View {
        content
            .background(
                WindowSceneReader(windowScene: $windowScene)
            )
            .onPreferenceChange(WindowScenePreferenceKey.self) { windowScene in
                self.windowScene = windowScene
            }
            .environment(\.showToast) { toast in
                if let windowScene {
                    ToastPresenter.shared.showToast(toast, in: windowScene)
                } else {
                    logger.error("Failed to obtain windowScene")
                }
            }
    }
}

private struct WindowScenePreferenceKey: PreferenceKey {
    static var defaultValue: UIWindowScene? = nil

    static func reduce(value: inout UIWindowScene?, nextValue: () -> UIWindowScene?) {
        value = value ?? nextValue()
    }
}

private struct WindowSceneReader: UIViewRepresentable {
    @Binding var windowScene: UIWindowScene?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            windowScene = view.window?.windowScene
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            windowScene = uiView.window?.windowScene
        }
    }
}
