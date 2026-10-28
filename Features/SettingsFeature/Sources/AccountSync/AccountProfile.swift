#if QURAN_SYNC
//
//  AccountProfile.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import MobileSync

/// The signed-in user, as the account card and screen show them.
struct AccountProfile: Equatable {
    // MARK: Lifecycle

    init(_ user: MobileSyncUser?) {
        let fullName = [user?.firstName, user?.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        name = [user?.name?.trimmingCharacters(in: .whitespacesAndNewlines), fullName]
            .compactMap { $0 }
            .first { !$0.isEmpty }
        email = user?.email?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        initials = Self.initials(name: name, email: email)
    }

    // MARK: Internal

    let name: String?
    let email: String?
    /// Up to two letters from the name, else the email's first letter.
    let initials: String

    // MARK: Private

    private static func initials(name: String?, email: String?) -> String {
        if let name {
            let words = name.split(whereSeparator: \.isWhitespace)
            let letters = [words.first, words.count > 1 ? words.last : nil].compactMap { $0?.first }
            return String(letters).uppercased()
        }
        return email?.first.map { String($0).uppercased() } ?? ""
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
#endif
