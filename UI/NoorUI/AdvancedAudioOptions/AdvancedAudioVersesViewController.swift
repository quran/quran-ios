//
//  AdvancedAudioVersesViewController.swift
//
//
//  Created by Afifi, Mohamed on 10/10/21.
//

import Localization
import UIKit

public class AdvancedAudioVersesViewController<Sura: AdvancedAudioUISura>: UITableViewController {
    private let onSelection: (Sura.Verse) -> Void
    private let suras: [Sura]
    private let selected: Sura.Verse

    public init(suras: [Sura], selected: Sura.Verse, onSelection: @escaping (Sura.Verse) -> Void) {
        self.suras = suras
        self.selected = selected
        self.onSelection = onSelection
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        if let selectedIndexPath = selectedIndexPath() {
            DispatchQueue.main.async {
                self.tableView?.scrollToRow(at: selectedIndexPath, at: .middle, animated: false)
            }
        }
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        suras.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suras[section].verses.count
    }

    private func selectedIndexPath() -> IndexPath? {
        for (section, sura) in suras.enumerated() {
            for (item, verse) in sura.verses.enumerated() {
                if verse == selected {
                    return IndexPath(item: item, section: section)
                }
            }
        }
        return nil
    }

    private func verseAtIndexPath(_ indexPath: IndexPath) -> Sura.Verse {
        suras[indexPath.section].verses[indexPath.item]
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let verse = verseAtIndexPath(indexPath)
        cell.textLabel?.text = verse.localizedName
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessoryType = verse == selected ? .checkmark : .none
        return cell
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        suras[section].localizedName
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelection(verseAtIndexPath(indexPath))
    }
}
