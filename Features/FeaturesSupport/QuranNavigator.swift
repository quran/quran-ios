//
//  QuranNavigator.swift
//
//
//  Created by Mohamed Afifi on 2023-06-19.
//

import QuranAnnotations
import QuranKit

@MainActor
public protocol QuranNavigator: AnyObject {
    func navigateTo(page: Page, lastPage: LastPage?, highlightingSearchAyah: AyahNumber?)
}
