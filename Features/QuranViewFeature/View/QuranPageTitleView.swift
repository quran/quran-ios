//
//  QuranPageTitleView.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Localization
import QuranKit
import UIKit

class QuranPageTitleView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var pages: [Int] = []

    override var intrinsicContentSize: CGSize {
        label.attributedText?.size() ?? .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateIsCompressed()
    }

    // MARK: Private

    private let label = UILabel()

    private var firstLine: String = "" {
        didSet { updateAttributedText() }
    }

    private var secondLine: String = "" {
        didSet { updateAttributedText() }
    }

    private var isCompressed = false {
        didSet { updateAttributedText() }
    }

    private func setUp() {
        label.numberOfLines = 0
        label.textAlignment = .center

        label.translatesAutoresizingMaskIntoConstraints = false
        addAutoLayoutSubview(label)
        label.vc.center()
    }

    private func updateIsCompressed(_ size: CGSize? = nil) {
        if let containerHeight = navigationBar?.bounds.height ?? size?.height {
            isCompressed = containerHeight < 34
        }
    }

    private func updateAttributedText() {
        let string = NSMutableAttributedString(string: firstLine, attributes: [
            .font: UIFont.boldSystemFont(ofSize: 15),
        ])
        if !isCompressed {
            string.append(NSAttributedString(string: "\n"))
        } else {
            string.append(NSAttributedString(string: "  "))
        }
        string.append(NSAttributedString(string: secondLine, attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .light),
        ]))
        label.attributedText = string
    }
}

private extension UIView {
    var navigationBar: UINavigationBar? {
        if let navigationBar = self as? UINavigationBar {
            return navigationBar
        } else {
            return superview?.navigationBar
        }
    }
}

extension QuranPageTitleView {
    func setPages(_ pages: [Page], navigationBar: UINavigationBar?) {
        print("\n\n\n\n")
        self.pages = pages.map(\.pageNumber)
        let suras = pages.map(\.startSura)
        let juzs = pages.map(\.startJuz)
        let pageNumbers = pages.map(\.pageNumber).map(NumberFormatter.shared.format).joined(separator: " - ")
        let pageDescription = lFormat(
            "page_description",
            table: .android,
            pageNumbers,
            NumberFormatter.shared.format(juzs.min()!.juzNumber)
        )
        firstLine = suras.min()!.localizedName(withPrefix: true)
        secondLine = pageDescription
    }
}
