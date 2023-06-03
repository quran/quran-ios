//
//  PageBookmarkPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import Foundation
import PromiseKit

public protocol PageBookmarkPersistence {
    func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never>
    func insertPageBookmark(_ page: Int) -> Promise<Void>
    func removePageBookmark(_ page: Int) -> Promise<Void>
}
