//
//  AdvancedAudioVersesViewController.swift
//
//
//  Created by Afifi, Mohamed on 10/10/21.
//

import QuranKit
import UIKit

class AdvancedAudioVersesViewController: UITableViewController {
    // MARK: Lifecycle

    init(suras: [Sura], selected: AyahNumber, onSelection: @MainActor @escaping (AyahNumber) -> Void) {
        self.suras = suras
        self.selected = selected
        self.onSelection = onSelection
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        suras.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suras[section].verses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let verse = verseAtIndexPath(indexPath)
        cell.textLabel?.text = verse.localizedName
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessoryType = verse == selected ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        suras[section].localizedName()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelection(verseAtIndexPath(indexPath))
    }

    // MARK: Private

    private let onSelection: (AyahNumber) -> Void
    private let suras: [Sura]
    private let selected: AyahNumber

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

    private func verseAtIndexPath(_ indexPath: IndexPath) -> AyahNumber {
        suras[indexPath.section].verses[indexPath.item]
    }
}
