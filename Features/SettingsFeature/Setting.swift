//
//  Setting.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-03-01.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Combine
import NoorUI
import UIKit
import UIx

public enum SettingID: Hashable {
    case theme
    case actionable
    case actionableSubtitle
    case info
}

struct SettingBox: Hashable, Identifiable {
    // MARK: Internal

    var data: IdentifiableSetting

    var id: SettingID { data.id }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    // MARK: Private

    private let uuid = UUID()
}

public protocol IdentifiableSetting {
    var id: SettingID { get }
}

public final class ThemeSetting: IdentifiableSetting {
    // MARK: Lifecycle

    public init(theme: ValueViewModel<Theme>) {
        self.theme = theme
    }

    // MARK: Public

    public var id: SettingID { .theme }

    // MARK: Internal

    let theme: ValueViewModel<Theme>
}

public struct InfoSetting: IdentifiableSetting {
    // MARK: Lifecycle

    public init(name: String, details: String) {
        self.name = name
        self.details = details
    }

    // MARK: Public

    public let id = SettingID.info

    // MARK: Internal

    let name: String
    let details: String
}

public protocol ActionableSetting: IdentifiableSetting {
    var name: String { get }
    var image: UIImage? { get }
    var action: (UIView) -> Void { get }
}

public final class Setting: ActionableSetting {
    // MARK: Lifecycle

    public init(name: String, image: UIImage?, action: @escaping (UIView) -> Void) {
        self.name = name
        self.image = image
        self.action = action
    }

    // MARK: Public

    public let name: String
    public let image: UIImage?
    public let action: (UIView) -> Void

    public var id: SettingID { .actionable }
}

public final class SubtitleSetting: ActionableSetting {
    // MARK: Lifecycle

    public init(name: String, image: UIImage?, subtitle: AnyPublisher<String, Never>, action: @escaping (UIView) -> Void) {
        self.name = name
        self.image = image
        self.subtitle = subtitle
        self.action = action
    }

    // MARK: Public

    public let name: String
    public let image: UIImage?
    public let action: (UIView) -> Void
    public let subtitle: AnyPublisher<String, Never>

    public var id: SettingID { .actionableSubtitle }
}

public struct SettingSection: Hashable {
    public typealias Id = String

    // MARK: Lifecycle

    public init(section: Id, settings: [IdentifiableSetting]) {
        self.section = section
        self.settings = settings.map { SettingBox(data: $0) }
    }

    // MARK: Internal

    let section: Id
    let settings: [SettingBox]
}
