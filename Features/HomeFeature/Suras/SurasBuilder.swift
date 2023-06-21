//
//  SurasBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import QuranKit
import UIKit

struct SurasBuilder: HomeSegmentBuildable {
    let container: AppDependencies

    func build(withListener listener: QuranNavigator) -> UIViewController {
        let interactor = SurasInteractor()
        let lastPageService = LastPageService(persistence: container.lastPagePersistence)
        let viewController = SurasViewController(interactor: interactor, lastPageService: lastPageService)
        interactor.quranNavigator = listener
        return viewController
    }
}
