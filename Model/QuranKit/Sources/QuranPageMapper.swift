//
//  QuranPageMapper.swift
//
//
//  Created by OpenAI on 2026-04-25.
//

public struct QuranPageMapper {
    // MARK: Lifecycle

    public init(destination: Quran) {
        self.destination = destination
    }

    // MARK: Public

    public let destination: Quran

    public func mapPage(_ sourcePage: Page) -> Page? {
        guard let destinationPreferredPage = mapAyah(sourcePage.middleAyah)?.page,
              let destinationFirstAyahPage = mapAyah(sourcePage.firstVerse)?.page,
              let destinationLastAyahPage = mapAyah(sourcePage.lastVerse)?.page
        else {
            return nil
        }

        let destinationAnchorPages = [
            destinationFirstAyahPage,
            destinationPreferredPage,
            destinationLastAyahPage,
        ]
        guard let destinationMinPage = destinationAnchorPages.min(),
              let destinationMaxPage = destinationAnchorPages.max()
        else {
            return nil
        }

        let destinationCandidates = (destinationMinPage.pageNumber ... destinationMaxPage.pageNumber)
            .compactMap { Page(quran: destination, pageNumber: $0) }

        let roundTripCandidates = destinationCandidates.filter { destinationCandidate in
            let destinationCandidateAyah = destinationCandidate.middleAyah
            let sourceCandidateAyah = AyahNumber(
                quran: sourcePage.quran,
                sura: destinationCandidateAyah.sura.suraNumber,
                ayah: destinationCandidateAyah.ayah
            )
            return sourceCandidateAyah?.page == sourcePage
        }

        return (roundTripCandidates.isEmpty ? destinationCandidates : roundTripCandidates)
            .min {
                abs($0.pageNumber - destinationPreferredPage.pageNumber) <
                    abs($1.pageNumber - destinationPreferredPage.pageNumber)
            }
    }

    public func mapAyah(_ sourceAyah: AyahNumber) -> AyahNumber? {
        AyahNumber(quran: destination, sura: sourceAyah.sura.suraNumber, ayah: sourceAyah.ayah)
    }
}

private extension Page {
    var middleAyah: AyahNumber {
        let pageVerses = verses
        return pageVerses[(pageVerses.count - 1) / 2]
    }
}
