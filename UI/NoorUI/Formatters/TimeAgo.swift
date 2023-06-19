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
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = formatter.locale.fixedLocaleNumbers()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = formatter.locale.fixedLocaleNumbers()
        formatter.unitsStyle = .full
        return formatter
    }()

    public func timeAgo() -> String {
        let now = Date()
        let diff = now.timeIntervalSince(self)
        // if it is over 30 days
        if diff > 60 * 60 * 24 * 30 {
            return Self.dateFormatter.string(from: self)
        } else {
            return Self.relativeDateFormatter.localizedString(for: self, relativeTo: now)
        }
    }
}
