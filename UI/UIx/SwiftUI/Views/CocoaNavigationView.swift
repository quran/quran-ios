//
//  CocoaNavigationView.swift
//
//
//  Created by Mohamed Afifi on 2022-12-25.
//

import SwiftUI

// Inspired by https://github.com/SwiftUIX/SwiftUIX/tree/master/Sources/Intramodular/Navigation
// but can size itself inside a popover.

public struct CocoaNavigationView<Root: View>: View {
    // MARK: Lifecycle

    public init(rootConfiguration: NavigationConfiguration = NavigationConfiguration(), @ViewBuilder root: () -> Root) {
        self.root = root()
        self.rootConfiguration = rootConfiguration
    }

    // MARK: Public

    public var body: some View {
        NavigationViewBody(root: root, rootConfiguration: rootConfiguration)
            .edgesIgnoringSafeArea(.all)
    }

    // MARK: Private

    private let root: Root
    private var rootConfiguration: NavigationConfiguration
}

public struct Navigator {
    // MARK: Public

    public func push(
        configuration: NavigationConfiguration = NavigationConfiguration(),
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

    public init(navigationBarHidden: Bool = false, title: String? = nil, backgroundColor: UIColor? = nil) {
        self.navigationBarHidden = navigationBarHidden
        self.title = title
        self.backgroundColor = backgroundColor
    }

    // MARK: Public

    public var navigationBarHidden: Bool
    public var title: String?
    public var backgroundColor: UIColor?
}

private struct NavigationViewBody<Root: View>: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate {
        func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
            navigationController.preferredContentSize = viewController.preferredContentSize
        }
    }

    let root: Root
    let rootConfiguration: NavigationConfiguration

    func makeUIViewController(context: Context) -> CocoaNavigationController {
        let navigationController = CocoaNavigationController()
        let root = root
            .environment(\.navigator, Navigator(navigationController: navigationController))
        let controller = ElementController(rootView: root, configuration: rootConfiguration)
        navigationController.setViewControllers([controller], animated: false)
        navigationController.delegate = context.coordinator
        navigationController.configuration = rootConfiguration
        return navigationController
    }

    func updateUIViewController(_ navigationController: CocoaNavigationController, context: Context) {
        if let rootViewController = navigationController.viewControllers.first as? ElementController<Root> {
            rootViewController.rootView = root
            rootViewController.configuration = rootConfiguration
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

private class CocoaNavigationController: UINavigationController {
    var configuration = NavigationConfiguration(navigationBarHidden: false, title: "") {
        didSet {
            if configuration.navigationBarHidden != oldValue.navigationBarHidden {
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
            guard !(configuration.navigationBarHidden && !newValue) else {
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
        super.setNavigationBarHidden(configuration.navigationBarHidden, animated: animated)
        DispatchQueue.main.async {
            self.preferredContentSize = self.preferredContentSize
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = nil
        super.viewWillAppear(animated)
        setNavigationBarHidden(configuration.navigationBarHidden, animated: false)
    }
}

private class ElementController<Content: View>: UIHostingController<Content> {
    // MARK: Lifecycle

    init(rootView: Content, configuration: NavigationConfiguration) {
        self.configuration = configuration
        super.init(rootView: rootView)
        configure()
    }

    @available(*, unavailable) @MainActor
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var configuration: NavigationConfiguration {
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

    // MARK: Private

    private var cocoaNavigation: CocoaNavigationController? {
        navigationController as? CocoaNavigationController
    }

    private func configure() {
        title = configuration.title
        viewIfLoaded?.backgroundColor = configuration.backgroundColor
    }
}
