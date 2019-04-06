//
//  AdvancedAudioOptionsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol AdvancedAudioOptionsRouting: ViewableRouting {
}

protocol AdvancedAudioOptionsPresentable: Presentable {
    var listener: AdvancedAudioOptionsPresentableListener? { get set }
    var options: AdvancedAudioOptions { get }
    func dismissView(withDuration duration: TimeInterval)
}

protocol AdvancedAudioOptionsListener: class {
    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
    func dismissAudioOptions()
}

final class AdvancedAudioOptionsInteractor: PresentableInteractor<AdvancedAudioOptionsPresentable>,
                                            AdvancedAudioOptionsInteractable, AdvancedAudioOptionsPresentableListener {

    weak var router: AdvancedAudioOptionsRouting?
    weak var listener: AdvancedAudioOptionsListener?

    override init(presenter: AdvancedAudioOptionsPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func onPlayButtonTapped() {
        listener?.updateAudioOptions(to: presenter.options)
        startDismissing()
    }

    func onDismissTapped() {
        startDismissing()
    }

    private func startDismissing() {
        presenter.dismissView(withDuration: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.listener?.dismissAudioOptions()
        }
    }
}
