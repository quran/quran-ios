//
//  AdvancedAudioOptionsViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-07.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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
import GenericDataSources
import QueuePlayer
import UIKit

protocol AdvancedAudioOptionsViewControllerDelegate: class {
    func advancedAudioOptionsViewController(_ controller: AdvancedAudioOptionsViewController, finishedWith options: AdvancedAudioOptions)
}

class AdvancedAudioOptionsViewController: UIViewController, UIGestureRecognizerDelegate {

    weak var delegate: AdvancedAudioOptionsViewControllerDelegate?

    private let dataSource = CompositeDataSource(sectionType: .multi)
    private let firstSection = SectionDataSource(sectionType: .single)
    private let secondSection = SectionDataSource(sectionType: .single)
    private let from: AyahDataSource
    private let to: AyahDataSource
    private let verseRuns: RunsDataSource
    private let listRuns: RunsDataSource

    private var selectionDS: SelectionDataSource? {
        didSet {
            oldValue?.editingDS = nil
            UIView.animate(withDuration: 0.2) {
                self.playButton.transform = CGAffineTransform(rotationAngle: self.selectionDS != nil ? .pi / 2 : 0)
            }
        }
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationBar: UINavigationBar!
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
        button.sizeToFit()
        return button
    }()

    init(options: AdvancedAudioOptions) {

        from = AyahDataSource(ayah: options.range.lowerBound)
        to = AyahDataSource(ayah: options.range.upperBound)
        verseRuns = RunsDataSource(runs: options.verseRuns)
        listRuns = RunsDataSource(runs: options.listRuns)

        super.init(nibName: nil, bundle: nil)

        from.to = to
        to.from = from

        dataSource.add(firstSection)
        dataSource.add(secondSection)

        firstSection.add(from)
        firstSection.add(to)

        secondSection.add(verseRuns)
        secondSection.add(listRuns)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.tintColor = .appIdentity()
        navigationBar.barTintColor = .white
        navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(customView: playButton)

        from.items = [lAndroid("play_from")]
        to.items = [lAndroid("play_to")]
        verseRuns.items = [lAndroid("play_each_verse").replacingOccurrences(of: ":", with: "") + l("repetitionExperimentalSuffix")]
        listRuns.items = [lAndroid("play_verses_range").replacingOccurrences(of: ":", with: "") + l("repetitionExperimentalSuffix")]

        tableView.ds_useDataSource(dataSource)
        tableView.ds_register(cellNib: AdvancedAudioOptionsTableViewCell.self)
        tableView.ds_register(cellNib: AdvancedAudioOptionsSelectionTableViewCell.self)
        tableView.tableFooterView = UIView()

        let selectionHandler = BlockSelectionHandler<String, AdvancedAudioOptionsTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] (ds, collection, indexPath) in
            self?.deselect(indexPath: indexPath, collection: collection, ds: cast(ds))
        }
        for ds in [from, to, verseRuns, listRuns] {
            ds.setSelectionHandler(selectionHandler)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.round(corners: [.topLeft, .topRight], radius: 14)
    }

    private func deselect(indexPath: IndexPath, collection: GeneralCollectionView, ds: ItemDataSource) {
        collection.ds_deselectItem(at: indexPath, animated: true)
        tableView.ds_performBatchUpdates({
            collection.ds_reloadItems(at: [indexPath], with: .fade)
            if let selectionDS = self.selectionDS {
                let oldEditingDS = selectionDS.editingDS
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    oldEditingDS?.updateOtherDataSource()
                }

                if let index = self.firstSection.index(of: selectionDS) {
                    self.firstSection.removeDataSource(at: index)
                } else if let index = self.secondSection.index(of: selectionDS) {
                    self.secondSection.removeDataSource(at: index)
                }
                if oldEditingDS == ds {
                    self.selectionDS = nil
                    return
                }
            }

            let selectionDS = SelectionDataSource()
            selectionDS.items = [()]
            if let index = self.firstSection.index(of: ds) {
                self.firstSection.insertDataSource(selectionDS, at: index + 1)
            } else if let index = self.secondSection.index(of: ds) {
                self.secondSection.insertDataSource(selectionDS, at: index + 1)
            }

            selectionDS.editingDS = ds
            self.selectionDS = selectionDS
        }, completion: nil)
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        if let editingDS = selectionDS?.editingDS {
            deselect(indexPath: IndexPath(item: 0, section: 0), collection: unwrap(editingDS.ds_reusableViewDelegate), ds: editingDS)
        } else {
            let options = AdvancedAudioOptions(
                range: VerseRange(lowerBound: from.ayah, upperBound: to.ayah),
                verseRuns: verseRuns.runs,
                listRuns: listRuns.runs)
            delegate?.advancedAudioOptionsViewController(self, finishedWith: options)
            dismissController()
        }
    }

    @IBAction func dismissView(_ sender: Any) {
        dismissController()
    }

    private func dismissController() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.bottomConstraint.constant = -self.tableView.frame.height
            self.view.layoutIfNeeded()
        }, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

extension UIView {
    func round(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

private class SectionDataSource: CompositeDataSource {

    func removeDataSource(at index: Int) {
        remove(at: index)
        ds_reusableViewDelegate?.ds_deleteItems(at: [IndexPath(item: index, section: 0)], with: .fade)
        ds_reusableViewDelegate?.ds_reloadItems(at: [IndexPath(item: index - 1, section: 0)], with: .none)
    }

    func insertDataSource(_ dataSource: DataSource, at index: Int) {
        insert(dataSource, at: index)
        let indexPath = IndexPath(item: index, section: 0)
        ds_reusableViewDelegate?.ds_insertItems(at: [indexPath], with: .fade)
        DispatchQueue.main.async {
            self.ds_reusableViewDelegate?.ds_scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
}

private class ItemDataSource: BasicDataSource<String, AdvancedAudioOptionsTableViewCell>,
  AdvancedAudioOptionsSelectionTableViewCellDelegate {

    var isSelected: Bool = false

    override init() {
        super.init()
        itemHeight = 44
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: AdvancedAudioOptionsTableViewCell,
                                    with item: String,
                                    at indexPath: IndexPath) {
        cell.textLabel?.text = item
        cell.detailTextLabel?.text = detailsText
        cell.detailTextLabel?.textColor = isSelected ? #colorLiteral(red: 0.1058823529, green: 0.4196078431, blue: 0.4431372549, alpha: 1) : .black
    }

    var detailsText: String { unimplemented() }
    var selectionItems: [[String]] { unimplemented() }

    func advancedAudioOptionsSelectionTableViewCell(_ cell: AdvancedAudioOptionsSelectionTableViewCell, didSelectRow: Int, in component: Int) {
        unimplemented()
    }

    func pickerLoaded(_ picker: UIPickerView) {
        unimplemented()
    }

    func updateOtherDataSource() { }
}

private class AyahDataSource: ItemDataSource {

    weak var from: AyahDataSource?
    weak var to  : AyahDataSource?

    let numberFormatter = NumberFormatter()

    var ayah: AyahNumber

    init(ayah: AyahNumber) {
        self.ayah = ayah
    }

    private func suraName(_ sura: Int) -> String {
        return "\(numberFormatter.format(sura)). \(Quran.nameForSura(sura))"
    }

    override var detailsText: String {
        let ayahNumberString = String.localizedStringWithFormat(lAndroid("quran_ayah"), ayah.ayah)
        let suraName = self.suraName(ayah.sura)
        return "\(suraName), \(ayahNumberString)"
    }

    override var selectionItems: [[String]] {
        let suras = (1...Quran.SuraPageStart.count).map { suraName($0) }
        let ayahs = (1...Quran.numberOfAyahsForSura(ayah.sura)).map { numberFormatter.format($0) }
        return [suras, ayahs]
    }

    override func advancedAudioOptionsSelectionTableViewCell(
        _ cell: AdvancedAudioOptionsSelectionTableViewCell,
        didSelectRow row: Int,
        in component: Int) {
        print("sura:", cell.picker.selectedRow(inComponent: 0))
        let component1 = cell.picker.selectedRow(inComponent: 0)
        ayah = AyahNumber(sura: component1 + 1, ayah: ayah.ayah)
        if component == 0 {
            cell.items = selectionItems
        }
        let component2 = cell.picker.selectedRow(inComponent: 1)
        ayah = AyahNumber(sura: ayah.sura, ayah: component2 + 1)

        guard let cell = ds_reusableViewDelegate?.ds_cellForItem(at: IndexPath(item: 0, section: 0)) as? UITableViewCell else {
            return
        }
        UIView.transition(with: unwrap(cell.detailTextLabel), duration: 0.2, options: .transitionCrossDissolve, animations: {
            cell.detailTextLabel?.text = self.detailsText
        }, completion: nil)
    }

    override func pickerLoaded(_ picker: UIPickerView) {
        picker.selectRow(ayah.sura - 1, inComponent: 0, animated: false)
        picker.selectRow(ayah.ayah - 1, inComponent: 1, animated: false)
    }

    override func updateOtherDataSource() {
        let fromAyah: AyahNumber
        let toAyah: AyahNumber

        if let from = from {
            fromAyah = from.ayah
            toAyah = self.ayah
        } else if let to = to {
            fromAyah = self.ayah
            toAyah = to.ayah
        } else {
            return
        }

        if fromAyah.sura > toAyah.sura || (fromAyah.sura == toAyah.sura && fromAyah.ayah > toAyah.ayah) {
            if let from = from {
                from.ayah = toAyah
            } else if let to = to {
                to.ayah = fromAyah
            }
            let ds = from ?? to
            let cell = ds?.ds_reusableViewDelegate?.ds_cellForItem(at: IndexPath(item: 0, section: 0)) as? UITableViewCell
            UIView.transition(with: unwrap(cell?.detailTextLabel), duration: 0.3, options: .transitionFlipFromBottom, animations: {
                cell?.detailTextLabel?.text = ds?.detailsText
            }, completion: nil)
        }
    }
}

private class RunsDataSource: ItemDataSource {
    var runs: Runs
    private let selections: [Runs] = [.one, .two, .three, .indefinite]
    init(runs: Runs) {
        self.runs = runs
    }

    override var detailsText: String {
        return runs.localizedDescription
    }

    override var selectionItems: [[String]] {
        return [selections.map { $0.localizedDescription }]
    }

    override func advancedAudioOptionsSelectionTableViewCell(
        _ cell: AdvancedAudioOptionsSelectionTableViewCell,
        didSelectRow row: Int,
        in component: Int) {
        runs = selections[row]
        ds_reusableViewDelegate?.ds_reloadItems(at: [IndexPath(item: 0, section: 0)], with: .none)
    }

    override func pickerLoaded(_ picker: UIPickerView) {
        let index = unwrap(selections.index(of: runs))
        picker.selectRow(index, inComponent: 0, animated: false)
    }
}

private class SelectionDataSource: BasicDataSource<Void, AdvancedAudioOptionsSelectionTableViewCell> {

    var editingDS: ItemDataSource? {
        didSet {
            oldValue?.isSelected = false
            editingDS?.isSelected = true
        }
    }

    override init() {
        super.init()
        itemHeight = 163
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: AdvancedAudioOptionsSelectionTableViewCell,
                                    with item: Void,
                                    at indexPath: IndexPath) {
        cell.items = editingDS?.selectionItems ?? []
        cell.delegate = editingDS
        editingDS?.pickerLoaded(cell.picker)
    }
}

private extension Runs {
    var localizedDescription: String {
        switch self {
        case .one: return lAndroid("repeatValues1")
        case .two: return lAndroid("repeatValues2")
        case .three: return lAndroid("repeatValues3")
        case .indefinite: return lAndroid("repeatValues4")
        default:
            fatalError("unsupported value")
        }
    }
}
