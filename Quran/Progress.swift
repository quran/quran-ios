//
//  Progress.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/21/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
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

import Foundation

protocol ProgressListener: class {
    func onProgressUpdated(to progress: Double)
}

class BlockProgressListener: ProgressListener {
    let body: (Double) -> Void
    init(_ body: @escaping (Double) -> Void) {
        self.body = body
    }

    func onProgressUpdated(to progress: Double) {
        body(progress)
    }
}

class Progress: NSObject, ProgressListener {

    private var children: [Progress: Double] = [:]
    let progressListeners = WeakSet<ProgressListener>()

    var totalUnitCount: Double {
        didSet { notifyProgressChanged() }
    }
    var completedUnitCount: Double = 0 {
        didSet { notifyProgressChanged() }
    }

    private func notifyProgressChanged() {
        let progress = self.progress
        for listener in progressListeners {
            listener.onProgressUpdated(to: progress)
        }
    }

    var progress: Double {
        return Double(completedUnitCount) / Double(totalUnitCount)
    }

    init(totalUnitCount: Double) {
        self.totalUnitCount = totalUnitCount
    }

    func addChild(_ child: Progress, withPendingUnitCount inUnitCount: Double) {
        children[child] = inUnitCount
        child.progressListeners.insert(self)
    }

    private func childProgressChanged() {
        var completedUnitCount: Double = 0
        for (child, pendingUnitCount) in children {
            completedUnitCount += child.progress * pendingUnitCount
        }
        self.completedUnitCount = completedUnitCount
    }

    func onProgressUpdated(to progress: Double) {
        var completedUnitCount: Double = 0
        for (child, pendingUnitCount) in children {
            completedUnitCount += child.progress * pendingUnitCount
        }
        self.completedUnitCount = completedUnitCount
    }
}
