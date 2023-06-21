//
//  JuzsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import QuranKit
import QuranTextKit
import UIKit

@MainActor
struct JuzsBuilder: HomeSegmentBuildable {
    let container: AppDependencies

    func build(withListener listener: QuranNavigator) -> UIViewController {
        let textRetriever = QuranTextDataService(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let interactor = JuzsInteractor(textRetriever: textRetriever)
        let lastPageService = LastPageService(persistence: container.lastPagePersistence)
        let viewController = JuzsViewController(interactor: interactor, lastPageService: lastPageService)
        interactor.quranNavigator = listener
        return viewController
    }
}
