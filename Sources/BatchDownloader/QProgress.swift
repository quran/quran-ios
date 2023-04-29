//
//  QProgress.swift
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
import WeakSet

public protocol QProgressListener: AnyObject {
    func onProgressUpdated(to progress: Double) async
}

public final class QProgress: NSObject, QProgressListener {
    private var children: [QProgress: Double] = [:]
    public let progressListeners = WeakSet<QProgressListener>()

    public private(set) var totalUnitCount: Double
    public private(set) var completedUnitCount: Double = 0

    public func update(totalUnitCount: Double? = nil, completedUnitCount: Double? = nil) async {
        self.totalUnitCount = totalUnitCount ?? self.totalUnitCount
        self.completedUnitCount = completedUnitCount ?? self.completedUnitCount
        await notifyProgressChanged()
    }

    private func notifyProgressChanged() async {
        let progress = progress
        for listener in progressListeners {
            await listener.onProgressUpdated(to: progress)
        }
    }

    public var progress: Double {
        Double(completedUnitCount) / Double(totalUnitCount)
    }

    public init(totalUnitCount: Double) {
        self.totalUnitCount = totalUnitCount
    }

    public func add(child: QProgress, withPendingUnitCount inUnitCount: Double) {
        children[child] = inUnitCount
        child.progressListeners.insert(self)
    }

    public func remove(child: QProgress) {
        children[child] = nil
        child.progressListeners.remove(self)
    }

    public func onProgressUpdated(to progress: Double) async {
        var completedUnitCount: Double = 0
        for (child, pendingUnitCount) in children {
            completedUnitCount += child.progress * pendingUnitCount
        }
        await update(completedUnitCount: completedUnitCount)
    }
}
