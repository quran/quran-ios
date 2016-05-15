//
//  Progress.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import KVOController_Swift

class Progress: NSProgress {

    let progress: NSProgress?

    var children: [NSProgress] = []

    init(observingProgress progress: NSProgress) {
        self.progress = progress
        super.init(parent: NSProgress.currentProgress(), userInfo: nil)

        observe(retainedObservable: progress,
                keyPath: "totalUnitCount",
                options: [.Initial, .New]) { [weak self] (observable, change: ChangeData<Int64>) in
            self?.totalUnitCount = observable.totalUnitCount
        }

        observe(retainedObservable: progress,
                keyPath: "completedUnitCount",
                options: [.Initial, .New]) { [weak self] (observable, change: ChangeData<Int64>) in
            self?.completedUnitCount = observable.completedUnitCount
        }
    }

    init(totalUnitCount unitCount: Int64) {
        self.progress = nil
        super.init(parent: nil, userInfo: nil)
        self.totalUnitCount = unitCount
        self.completedUnitCount = 0
    }

    func addChildIOS8Compatible(progress: NSProgress, withPendingUnitCount pendingUnitCount: Int64) {
        becomeCurrentWithPendingUnitCount(pendingUnitCount)
        children.append(Progress(observingProgress: progress))
        resignCurrent()
    }
}
