//
//  ReadingSelectorBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import UIKit

@MainActor
public struct ReadingSelectorBuilder {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func build() -> UIViewController {
        ReadingSelectorViewController()
    }
}
