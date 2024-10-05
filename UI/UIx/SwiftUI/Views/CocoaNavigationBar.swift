//
//  CocoaNavigationBar.swift
//
//
//  Created by Mohamed Afifi on 2024-09-29.
//

import SwiftUI

public struct BarButton {
    public enum Content: Equatable {
        case image(UIImage?, style: UIBarButtonItem.Style)
        case system(UIBarButtonItem.SystemItem)
    }

    let content: Content
    let action: @MainActor () -> Void

    public init(_ content: Content, action: @escaping @MainActor () -> Void) {
        self.content = content
        self.action = action
    }
}

public struct CocoaNavigationBar: View {
    let title: String
    let leftButtons: [BarButton]
    let rightButtons: [BarButton]
    var prefersLargeTitles: Bool = false
    var standardAppearance: UINavigationBarAppearance?
    var scrollEdgeAppearance: UINavigationBarAppearance?

    public init(title: String, leftButtons: [BarButton], rightButtons: [BarButton]) {
        self.title = title
        self.leftButtons = leftButtons
        self.rightButtons = rightButtons
    }

    public var body: some View {
        NavigationBarRepresentable(
            title: title,
            leftButtons: leftButtons,
            rightButtons: rightButtons,
            prefersLargeTitles: prefersLargeTitles,
            standardAppearance: standardAppearance,
            scrollEdgeAppearance: scrollEdgeAppearance
        )
        // show the separator
        .padding(.bottom, 1)
    }

    public func prefersLargeTitles(_ prefersLargeTitles: Bool) -> Self {
        mutateSelf {
            $0.prefersLargeTitles = prefersLargeTitles
        }
    }

    public func standardAppearance(_ standardAppearance: UINavigationBarAppearance?) -> Self {
        mutateSelf {
            $0.standardAppearance = standardAppearance
        }
    }

    public func scrollEdgeAppearance(_ scrollEdgeAppearance: UINavigationBarAppearance?) -> Self {
        mutateSelf {
            $0.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }
}

private struct NavigationBarRepresentable: UIViewRepresentable {
    let title: String
    let leftButtons: [BarButton]
    let rightButtons: [BarButton]
    var prefersLargeTitles: Bool
    var standardAppearance: UINavigationBarAppearance?
    var scrollEdgeAppearance: UINavigationBarAppearance?

    func makeUIView(context: Context) -> NavigationBarView {
        NavigationBarView()
    }

    func updateUIView(_ view: NavigationBarView, context: Context) {
        view.configure(title: title, leftButtons: leftButtons, rightButtons: rightButtons)
    }

    class NavigationBarView: UINavigationBar {
        private let item = UINavigationItem()
        private var leftButtons: [BarButton] = []
        private var rightButtons: [BarButton] = []
        private var buttonActions: [UIBarButtonItem: @MainActor () -> Void] = [:]

        func configure(
            title: String,
            leftButtons: [BarButton],
            rightButtons: [BarButton]
        ) {
            item.title = title

            let leftButtonsEquals = self.leftButtons.map(\.content) == leftButtons.map(\.content)
            let rightButtonsEquals = self.rightButtons.map(\.content) == rightButtons.map(\.content)

            buttonActions.removeAll()

            let leftBarButtonItems = leftButtons.map { barButtonItem(of: $0) }
            item.setLeftBarButtonItems(leftBarButtonItems, animated: !leftButtonsEquals && topItem === item)
            let rightBarButtonItems = rightButtons.map { barButtonItem(of: $0) }
            item.setRightBarButtonItems(rightBarButtonItems, animated: !rightButtonsEquals && topItem === item)

            self.leftButtons = leftButtons
            self.rightButtons = rightButtons

            if topItem == nil {
                setItems([item], animated: false)
            }
        }

        private func barButtonItem(of button: BarButton) -> UIBarButtonItem {
            let buttonItem = switch button.content {
            case .image(let image, let style):
                UIBarButtonItem(image: image, style: style, target: self, action: #selector(buttonTapped))
            case .system(let systemItem):
                UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(buttonTapped))
            }
            buttonActions[buttonItem] = button.action
            return buttonItem
        }

        @objc
        private func buttonTapped(_ buttonItem: UIBarButtonItem) {
            let action = buttonActions[buttonItem]
            action?()
        }
    }
}

public extension UINavigationBarAppearance {
    static func defaultBackground() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        return appearance
    }

    static func opaqueBackground() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        return appearance
    }

    static func transparentBackground() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        return appearance
    }

    func backgroundColor(_ backgroundColor: UIColor?) -> Self {
        self.backgroundColor = backgroundColor
        return self
    }
}
