//
//  NavigationSearch.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import UIKit

/// The search field of a screen's navigation bar.
///
/// iPhone and iPad get a `UISearchController` in the navigation item. An iOS app running on a Mac
/// gets a plain search bar in a bar button item instead. There, activating a navigation bar search
/// controller lays out its presentation with `+[UINavigationBar defaultSizeForOrientation:]`, which
/// reads the main scene bounds through `UIScreen`, and UIKit throws "Accessing the focus system
/// through UIScreen is no longer supported." This reproduces on macOS 27 with this single-scene app;
/// production reports it from macOS 26.2 on for builds since 3.0.1, while builds with an older SDK,
/// such as 2.6.8, never crashed. A plain search bar has no presentation, so it never takes that path.
@MainActor
public final class NavigationSearch {
    // MARK: Lifecycle

    public convenience init(placeholder: String, delegate: UISearchBarDelegate, hidesNavigationBarDuringPresentation: Bool) {
        self.init(
            placeholder: placeholder,
            delegate: delegate,
            hidesNavigationBarDuringPresentation: hidesNavigationBarDuringPresentation,
            isiOSAppOnMac: ProcessInfo.processInfo.isiOSAppOnMac
        )
    }

    init(placeholder: String, delegate: UISearchBarDelegate, hidesNavigationBarDuringPresentation: Bool, isiOSAppOnMac: Bool) {
        if isiOSAppOnMac {
            searchController = nil
            searchBar = ToolbarSearchBar()
            barButtonItem = UIBarButtonItem(customView: searchBar)
        } else {
            let searchController = UISearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarDuringPresentation
            self.searchController = searchController
            searchBar = searchController.searchBar
            barButtonItem = nil
        }
        searchBar.placeholder = placeholder
        searchBar.delegate = delegate
    }

    // MARK: Public

    public let searchBar: UISearchBar

    /// The search bar's item on a Mac, where there is no search controller; `nil` on iPhone and iPad.
    ///
    /// `install(in:hidesSearchBarWhenScrolling:)` doesn't place it: callers add it to their trailing
    /// items themselves, so screens whose trailing items are managed elsewhere (such as by an edit
    /// mode controller) can include it there.
    public let barButtonItem: UIBarButtonItem?

    /// Adds the search controller to the navigation item on iPhone and iPad.
    /// On a Mac it adds nothing; place `barButtonItem` in the trailing items instead.
    public func install(in navigationItem: UINavigationItem, hidesSearchBarWhenScrolling: Bool) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = hidesSearchBarWhenScrolling
    }

    public func deactivate() {
        if let searchController {
            searchController.isActive = false
        } else {
            searchBar.endEditing(true)
        }
    }

    // MARK: Internal

    let searchController: UISearchController?
}

/// A search bar for a Mac toolbar. Its width follows Dynamic Type and gives way in narrow windows.
/// It has no Cancel button, so Escape cancels while its field is editing.
private final class ToolbarSearchBar: UISearchBar {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        searchBarStyle = .minimal
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        updateWidth()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// The search field is first responder while editing, and its key commands reach this bar through the responder chain.
    override var keyCommands: [UIKeyCommand]? {
        searchTextField.isFirstResponder ? [cancelCommand] : nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateWidth()
        }
    }

    func updateWidth() {
        widthConstraint.constant = UIFontMetrics.default.scaledValue(for: Self.preferredWidth, compatibleWith: traitCollection)
    }

    // MARK: Private

    private static let preferredWidth: CGFloat = 220

    private lazy var cancelCommand: UIKeyCommand = {
        let command = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(cancel))
        command.wantsPriorityOverSystemBehavior = true
        return command
    }()

    private lazy var widthConstraint = widthAnchor.constraint(equalToConstant: Self.preferredWidth)

    /// Mirrors tapping a Cancel button: clears the text, ends editing, and tells the delegate.
    @objc
    private func cancel() {
        guard searchTextField.isFirstResponder else {
            return
        }
        if let text, !text.isEmpty {
            self.text = ""
            delegate?.searchBar?(self, textDidChange: "")
        }
        endEditing(true)
        delegate?.searchBarCancelButtonClicked?(self)
    }
}
