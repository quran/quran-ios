//
//  QuranPageTitleView.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranPageTitleView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        loadViewFromNib()
        titleLabel.text = ""
        detailsLabel.text = ""
    }

    private func loadViewFromNib() {
        let nibName = "QuranPageTitleView"
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Couldn't load '\(nibName).xib' as the first item should be a UIView subclass.")
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                      options: [], metrics: nil, views: ["view": contentView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                      options: [], metrics: nil, views: ["view": contentView]))
        contentView.backgroundColor = .clear
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let containerHeight = superview?.bounds.height ?? size.height
        let isCompressed = containerHeight < 34
        let spacing: CGFloat =  isCompressed ? 0 : 3

        titleLabel.font = UIFont.boldSystemFont(ofSize: isCompressed ? 13 : 15)
        detailsLabel.font = UIFont.systemFont(ofSize: isCompressed ? 11 : 13, weight: UIFontWeightLight)

        titleLabel.sizeToFit()
        detailsLabel.sizeToFit()

        let titleSize = titleLabel.bounds.size
        let detailsSize = detailsLabel.bounds.size
        let result = CGSize(width: max(titleSize.width, detailsSize.width, size.width),
                            height: titleSize.height + detailsSize.height + spacing)
        return result
    }
}

extension QuranPageTitleView {
    func setPageNumber(_ pageNumber: Int, navigationBar: UINavigationBar?) {
        let pageDescriptionFormat = NSLocalizedString("page_description", tableName: "Android", comment: "")
        let pageDescription = String.localizedStringWithFormat(pageDescriptionFormat, pageNumber, Juz.juzFromPage(pageNumber).juzNumber)
        titleLabel.text = Quran.nameForSura(Quran.PageSuraStart[pageNumber - 1])
        detailsLabel.text = pageDescription
        sizeToFit()
        navigationBar?.setNeedsLayout()
    }
}
