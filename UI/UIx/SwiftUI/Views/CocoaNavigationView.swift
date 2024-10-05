//
//  CocoaNavigationView.swift
//
//
//  Created by Mohamed Afifi on 2022-12-25.
//

import SwiftUI

// Inspired by https://github.com/SwiftUIX/SwiftUIX/tree/master/Sources/Intramodular/Navigation
// but can size itself inside a popover.

public protocol StackableViewController: UIViewController { }

public struct CocoaNavigationView<Root: View>: View {
    // MARK: Lifecycle

    public init(rootConfiguration: NavigationConfiguration? = nil, @ViewBuilder root: () -> Root) {
        self.root = root()
        self.rootConfiguration = rootConfiguration
    }

    // MARK: Public

    public var body: some View {
        NavigationViewBody(
            root: root,
            rootConfiguration: rootConfiguration,
            prefersLargeTitles: prefersLargeTitles,
            standardAppearance: standardAppearance,
            scrollEdgeAppearance: scrollEdgeAppearance
        )
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: Private

    private let root: Root
    private var rootConfiguration: NavigationConfiguration?
    private var standardAppearance: UINavigationBarAppearance?
    private var scrollEdgeAppearance: UINavigationBarAppearance?
    private var prefersLargeTitles = false

    public func standardAppearance(_ standardAppearance: UINavigationBarAppearance) -> Self {
        mutateSelf {
            $0.standardAppearance = standardAppearance
        }
    }

    public func scrollEdgeAppearance(_ scrollEdgeAppearance: UINavigationBarAppearance) -> Self {
        mutateSelf {
            $0.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }
}

public struct Navigator {
    // MARK: Public

    public func push(
        configuration: NavigationConfiguration? = nil,
        animated: Bool = true,
        @ViewBuilder _ view: () -> some View
    ) {
        let view = view()
            .environment(\.navigator, Navigator(navigationController: navigationController))
        let viewController = ElementController(rootView: view, configuration: configuration)
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    // MARK: Internal

    let navigationController: UINavigationController
}

extension EnvironmentValues {
    private struct NavigatorEnvironmentKey: EnvironmentKey {
        static var defaultValue: Navigator? { nil }
    }

    public var navigator: Navigator? {
        get { self[NavigatorEnvironmentKey.self] }
        set { self[NavigatorEnvironmentKey.self] = newValue }
    }
}

public struct NavigationConfiguration {
    // MARK: Lifecycle

    public init(
        navigationBarHidden: Bool = false,
        title: String? = nil,
        backgroundColor: UIColor? = nil,
        leftBarButtons: [BarButton] = [],
        rightBarButtons: [BarButton] = []
    ) {
        self.navigationBarHidden = navigationBarHidden
        self.title = title
        self.backgroundColor = backgroundColor
        self.leftBarButtons = leftBarButtons
        self.rightBarButtons = rightBarButtons
    }

    // MARK: Public

    public var navigationBarHidden: Bool
    public var title: String?
    public var backgroundColor: UIColor?
    public var leftBarButtons: [BarButton]
    public var rightBarButtons: [BarButton]
}

private struct NavigationViewBody<Root: View>: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate {
        func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
            navigationController.preferredContentSize = viewController.preferredContentSize
        }
    }

    let root: Root
    let rootConfiguration: NavigationConfiguration?
    let prefersLargeTitles: Bool
    let standardAppearance: UINavigationBarAppearance?
    let scrollEdgeAppearance: UINavigationBarAppearance?

    func makeUIViewController(context: Context) -> CocoaNavigationController {
        let navigationController = CocoaNavigationController()
        let navigatorRoot = root
            .environment(\.navigator, Navigator(navigationController: navigationController))
        let controller = ElementController(rootView: AnyView(navigatorRoot), configuration: rootConfiguration)
        navigationController.setViewControllers([controller], animated: false)
        navigationController.delegate = context.coordinator
        navigationController.configuration = rootConfiguration
        return navigationController
    }

    func updateUIViewController(_ navigationController: CocoaNavigationController, context: Context) {
        if let rootViewController = navigationController.viewControllers.first as? ElementController<AnyView> {
            let navigatorRoot = root
                .environment(\.navigator, Navigator(navigationController: navigationController))
            rootViewController.rootView = AnyView(navigatorRoot)
            rootViewController.configuration = rootConfiguration
        }
        navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
        if let standardAppearance {
            navigationController.navigationBar.standardAppearance = standardAppearance
        }
        if let scrollEdgeAppearance {
            navigationController.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

private class CocoaNavigationController: UINavigationController {
    var configuration: NavigationConfiguration? {
        didSet {
            guard let configuration else { return }
            if configuration.navigationBarHidden != oldValue?.navigationBarHidden {
                if configuration.navigationBarHidden != isNavigationBarHidden {
                    setNavigationBarHidden(configuration.navigationBarHidden, animated: true)
                }
            }
        }
    }

    override var isNavigationBarHidden: Bool {
        get {
            super.isNavigationBarHidden
        } set {
            guard !((configuration?.navigationBarHidden ?? false) && !newValue) else {
                return
            }

            super.isNavigationBarHidden = newValue
            DispatchQueue.main.async {
                self.preferredContentSize = self.preferredContentSize
            }
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        preferredContentSize = container.preferredContentSize
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != isNavigationBarHidden else {
            return
        }
        super.setNavigationBarHidden(configuration?.navigationBarHidden ?? hidden, animated: animated)
        DispatchQueue.main.async {
            self.preferredContentSize = self.preferredContentSize
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = nil
        super.viewWillAppear(animated)
        setNavigationBarHidden(configuration?.navigationBarHidden ?? false, animated: false)
    }
}

private class ElementController<Content: View>: UIHostingController<Content> {
    // MARK: Lifecycle

    init(rootView: Content, configuration: NavigationConfiguration?) {
        self.configuration = configuration
        super.init(rootView: rootView)
        configure()
    }

    @available(*, unavailable) @MainActor
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var configuration: NavigationConfiguration? {
        didSet {
            cocoaNavigation?.configuration = configuration
            configure()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cocoaNavigation?.configuration = configuration
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        preferredContentSize = container.preferredContentSize
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)
        if let mainElementVC = childController as? StackableViewController {
            observeNavigationItem(of: mainElementVC)
        }
    }

    // MARK: Private

    private var childNavigationItemObservations: [NSKeyValueObservation]?
    private var buttonActions: [UIBarButtonItem: @MainActor () -> Void] = [:]

    private var cocoaNavigation: CocoaNavigationController? {
        navigationController as? CocoaNavigationController
    }

    private func observeNavigationItem(of child: some StackableViewController) {
        let options: NSKeyValueObservingOptions = [.new, .initial]
        let action: (UIViewController) -> Void = { [weak self] childController in
            self?.syncNavigationItem(with: childController.navigationItem)
        }
        childNavigationItemObservations = [
            observe(\.navigationItem.title, on: child, options: options, action: action),
            observe(\.navigationItem.rightBarButtonItem, on: child, options: options, action: action),
            observe(\.navigationItem.rightBarButtonItems, on: child, options: options, action: action),
            observe(\.navigationItem.leftBarButtonItem, on: child, options: options, action: action),
            observe(\.navigationItem.leftBarButtonItems, on: child, options: options, action: action),
        ]

        if #available(iOS 16.0, *) {
            childNavigationItemObservations?.append(contentsOf: [
                observe(\.navigationItem.leadingItemGroups, on: child, options: options, action: action),
                observe(\.navigationItem.trailingItemGroups, on: child, options: options, action: action),
            ])
        }
    }

    private func observe(
        _ keyPath: KeyPath<UIViewController, some Any>,
        on viewController: UIViewController,
        options: NSKeyValueObservingOptions,
        action: @escaping (UIViewController) -> Void
    ) -> NSKeyValueObservation {
        viewController.observe(keyPath, options: options) { viewController, _ in
            action(viewController)
        }
    }

    private func syncNavigationItem(with navigationItem: UINavigationItem) {
        self.navigationItem.title = navigationItem.title
        self.navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
        self.navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems

        if #available(iOS 16.0, *) {
            self.navigationItem.leadingItemGroups = navigationItem.leadingItemGroups
            self.navigationItem.trailingItemGroups = navigationItem.trailingItemGroups
        }
    }

    private func configure() {
        guard let configuration else {
            return
        }
        title = configuration.title
        viewIfLoaded?.backgroundColor = configuration.backgroundColor

        buttonActions.removeAll()
        let leftBarButtonItems = configuration.leftBarButtons.map { barButtonItem(of: $0) }
        navigationItem.leftBarButtonItems = leftBarButtonItems
        let rightBarButtonItems = configuration.rightBarButtons.map { barButtonItem(of: $0) }
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    private func barButtonItem(of button: BarButton) -> UIBarButtonItem {
        let buttonItem = switch button.content {
        case .image(let image, let style):
            UIBarButtonItem(image: image, style: style, target: self, action: #selector(barButtonTapped))
        case .system(let systemItem):
            UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(barButtonTapped))
        }
        buttonActions[buttonItem] = button.action
        return buttonItem
    }

    @objc
    private func barButtonTapped(_ buttonItem: UIBarButtonItem) {
        let action = buttonActions[buttonItem]
        action?()
    }
}
