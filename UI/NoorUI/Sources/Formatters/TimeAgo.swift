//
//  TimeAgo.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/6/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import Foundation

extension Date {
    public func timeAgo() -> String {
        TimeAgoFormatter.shared.string(for: self, relativeTo: Date())
    }
}

struct TimeAgoFormatter {
    // MARK: Lifecycle

    /// Uses `locale`, or the formatters' default (current) locale when `nil`.
    init(locale: Locale? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = (locale ?? dateFormatter.locale).fixedLocaleNumbers()
        dateFormatter.dateStyle = .full
        self.dateFormatter = dateFormatter

        let relativeDateFormatter = RelativeDateTimeFormatter()
        relativeDateFormatter.locale = (locale ?? relativeDateFormatter.locale).fixedLocaleNumbers()
        relativeDateFormatter.unitsStyle = .full
        // `.named` says "now", "yesterday", … instead of "in 0 seconds", "1 day ago", ….
        relativeDateFormatter.dateTimeStyle = .named
        self.relativeDateFormatter = relativeDateFormatter
    }

    // MARK: Internal

    static let shared = TimeAgoFormatter()

    func string(for date: Date, relativeTo now: Date) -> String {
        let diff = now.timeIntervalSince(date)
        // Far in the past, or further in the future than clock skew explains.
        if diff > Self.fullDateThreshold || diff < -Self.futureSkewTolerance {
            return dateFormatter.string(from: date)
        }
        // `.named` only says "now" for a zero offset; format under-a-minute (and small
        // future skew) dates as zero so they never read "in N seconds" / "N seconds ago".
        let reference = diff < Self.nowThreshold ? now : date
        return relativeDateFormatter.localizedString(for: reference, relativeTo: now)
    }

    // MARK: Private

    private static let nowThreshold: TimeInterval = 60
    private static let futureSkewTolerance: TimeInterval = 60 * 60
    private static let fullDateThreshold: TimeInterval = 60 * 60 * 24 * 30

    private let dateFormatter: DateFormatter
    private let relativeDateFormatter: RelativeDateTimeFormatter
}
