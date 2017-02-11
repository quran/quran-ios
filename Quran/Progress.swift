//
//  Progress.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import KVOController_Swift

class Progress: Foundation.Progress {

    let progress: Foundation.Progress?

    var children: [Foundation.Progress] = []

    init(observingProgress progress: Foundation.Progress) {
        self.progress = progress
        super.init(parent: Foundation.Progress.current(), userInfo: nil)

        observe(retainedObservable: progress,
                keyPath: "totalUnitCount",
                options: [.initial, .new]) { [weak self] (observable, _: ChangeData<Int64>) in
            self?.totalUnitCount = observable.totalUnitCount
        }

        observe(retainedObservable: progress,
                keyPath: "completedUnitCount",
                options: [.initial, .new]) { [weak self] (observable, _: ChangeData<Int64>) in
            self?.completedUnitCount = observable.completedUnitCount
        }
    }

    init(totalUnitCount unitCount: Int64) {
        self.progress = nil
        super.init(parent: nil, userInfo: nil)
        self.totalUnitCount = unitCount
        self.completedUnitCount = 0
    }

    func addChildIOS8Compatible(_ progress: Foundation.Progress, withPendingUnitCount pendingUnitCount: Int64) {
        becomeCurrent(withPendingUnitCount: pendingUnitCount)
        children.append(Progress(observingProgress: progress))
        resignCurrent()
    }
}
