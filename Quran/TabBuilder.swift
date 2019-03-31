//
//  TabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol TabBuildable: Buildable {
    func build(withListener listener: TabListener) -> TabRouting
}

protocol TabDependenciesBuildable: Buildable {
    func build() -> TabRouter.Deps
}

final class TabDependenciesBuilder: Builder {

    func build() -> TabRouter.Deps {
        return TabRouter.Deps(
            quranBuilder: QuranBuilder(container: container)
        )
    }
}
