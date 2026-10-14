//
//  PagesDescription.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import Foundation
import Localization
import QuranKit

extension [Page] {
    /// The reader's page subtitle, such as "Page 2, Juz' 1", or "Pages 2–3, Juz' 1" when two pages show.
    ///
    /// The list must not be empty.
    func localizedDescription(language: Language? = nil) -> String {
        let pageNumbers = map(\.pageNumber)
        let firstPage = pageNumbers.min()!
        let lastPage = pageNumbers.max()!
        let juz = NumberFormatter.shared.format(map(\.startJuz).min()!.juzNumber)
        if firstPage == lastPage {
            return lFormat("page_description", table: .android, language: language, NumberFormatter.shared.format(firstPage), juz)
        }
        return lFormat(
            "quran.pages.description",
            language: language,
            NumberFormatter.shared.format(firstPage),
            NumberFormatter.shared.format(lastPage),
            juz
        )
    }
}
