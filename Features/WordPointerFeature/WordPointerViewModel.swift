//
//  WordPointerViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Crashing
import QuranKit
import UIKit
import Utilities
import WordTextService

@MainActor
public protocol WordPointerListener: AnyObject {
    func onWordPointerPanBegan()
    func word(at point: CGPoint, in view: UIView) -> Word?
    func highlightWord(_ position: Word?)
}

@MainActor
final class WordPointerViewModel {
    // MARK: Lifecycle

    init(service: WordTextService) {
        self.service = service
    }

    // MARK: Internal

    enum PanResult {
        case none
        case hidePopover
        case showPopover(text: String)
    }

    weak var listener: WordPointerListener?

    func viewPanBegan() {
        listener?.onWordPointerPanBegan()
    }

    func viewPanned(to point: CGPoint, in view: UIView) async -> PanResult {
        guard let word = listener?.word(at: point, in: view) else {
            unhighlightWord()
            return .hidePopover
        }
        listener?.highlightWord(word)

        if selectedWord == word {
            return .none
        }
        do {
            if let text = try await service.textForWord(word) {
                selectedWord = word
                return .showPopover(text: text)
            } else {
                return .hidePopover
            }
        } catch {
            crasher.recordError(error, reason: "Error calling WordTextService")
            return .hidePopover
        }
    }

    func unhighlightWord() {
        listener?.highlightWord(nil)
        selectedWord = nil
    }

    // MARK: Private

    private let service: WordTextService

    private var selectedWord: Word?
}
