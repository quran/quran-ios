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
import VLogging
import WordTextService

@MainActor
public protocol WordPointerListener: AnyObject {
    func onWordPointerPanBegan()
    func word(at point: CGPoint) -> Word?
    func highlightWord(_ position: Word?)
}

@MainActor
final class WordPointerViewModel {
    enum PanResult {
        case none
        case hidePopover
        case showPopover(text: String)
    }

    // MARK: Lifecycle

    init(service: WordTextService) {
        self.service = service
    }

    // MARK: Internal

    weak var listener: WordPointerListener?

    func viewPanBegan() {
        listener?.onWordPointerPanBegan()
    }

    func viewPanned(to point: CGPoint) async -> PanResult {
        guard let word = listener?.word(at: point) else {
            logger.debug("No word found at position \(point)")
            unhighlightWord()
            return .hidePopover
        }
        logger.debug("Highlighting word \(word) at position: \(point)")
        listener?.highlightWord(word)

        if selectedWord == word {
            logger.debug("Same word selected before")
            return .none
        }
        do {
            if let text = try await service.textForWord(word) {
                logger.debug("Found text '\(text)' for word \(word)")
                selectedWord = word
                return .showPopover(text: text)
            } else {
                logger.debug("No text found for word \(word)")
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
