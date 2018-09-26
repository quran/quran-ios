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

public protocol QProgressListener: class {
    func onProgressUpdated(to progress: Double)
}

open class BlockQProgressListener: QProgressListener {
    private let body: (Double) -> Void
    public init(_ body: @escaping (Double) -> Void) {
        self.body = body
    }

    open func onProgressUpdated(to progress: Double) {
        body(progress)
    }
}

open class QProgress: NSObject, QProgressListener {

    private var children: [QProgress: Double] = [:]
    public let progressListeners = WeakSet<QProgressListener>()

    open var totalUnitCount: Double {
        didSet { notifyProgressChanged() }
    }
    open var completedUnitCount: Double = 0 {
        didSet { notifyProgressChanged() }
    }

    private func notifyProgressChanged() {
        let progress = self.progress
        for listener in progressListeners {
            listener.onProgressUpdated(to: progress)
        }
    }

    open var progress: Double {
        return Double(completedUnitCount) / Double(totalUnitCount)
    }

    public init(totalUnitCount: Double) {
        self.totalUnitCount = totalUnitCount
    }

    open func add(child: QProgress, withPendingUnitCount inUnitCount: Double) {
        children[child] = inUnitCount
        child.progressListeners.insert(self)
    }

    open func remove(child: QProgress) {
        children[child] = nil
        child.progressListeners.remove(self)
    }

    private func childProgressChanged() {
        var completedUnitCount: Double = 0
        for (child, pendingUnitCount) in children {
            completedUnitCount += child.progress * pendingUnitCount
        }
        self.completedUnitCount = completedUnitCount
    }

    open func onProgressUpdated(to progress: Double) {
        var completedUnitCount: Double = 0
        for (child, pendingUnitCount) in children {
            completedUnitCount += child.progress * pendingUnitCount
        }
        self.completedUnitCount = completedUnitCount
    }
}
