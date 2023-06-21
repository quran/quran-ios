//
//  HomeBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import FeaturesSupport
import ReadingSelectorFeature
import UIKit

@MainActor
public struct HomeBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let interactor = HomeInteractor(
            surasBuilder: SurasBuilder(container: container),
            juzsBuilder: JuzsBuilder(container: container)
        )
        let viewController = HomeViewController(
            interactor: interactor,
            readingSelectorBuilder: ReadingSelectorBuilder()
        )
        interactor.listener = listener
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
