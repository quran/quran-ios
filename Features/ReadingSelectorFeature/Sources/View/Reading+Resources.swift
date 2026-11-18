//
//  Reading+Resources.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-19.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Localization
import QuranGeometry
import QuranKit

extension Reading {
    struct Property: Hashable {
        enum PropertType {
            case supports
            case lacks
        }

        // MARK: Internal

        let type: PropertType
        let property: String
    }

    var title: String {
        switch self {
        case .hafs_1405:
            return l("reading.hafs-1405.title")
        case .hafs_1421:
            return l("reading.hafs-1421.title")
        case .hafs_1440:
            return l("reading.hafs-1440.title")
        case .hafs_1439:
            return l("reading.hafs-1439.title")
        case .hafs_1441:
            return l("reading.hafs-1441.title")
        case .tajweed:
            return l("reading.tajweed.title")
        case .indoPak:
            return l("reading.indopak.title")
        }
    }

    var description: String {
        switch self {
        case .hafs_1405:
            return l("reading.hafs-1405.description")
        case .hafs_1421:
            return l("reading.hafs-1421.description")
        case .hafs_1440:
            return l("reading.hafs-1440.description")
        case .hafs_1439:
            return l("reading.hafs-1439.description")
        case .hafs_1441:
            return l("reading.hafs-1441.description")
        case .tajweed:
            return l("reading.tajweed.description")
        case .indoPak:
            return l("reading.indopak.description")
        }
    }

    var properties: [Property] {
        switch self {
        case .hafs_1405:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.hafs-1405.issue")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .supports, property: l("reading.selector.property.word-translation.supported")),
            ]
        case .hafs_1421:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.hafs-1421.issue")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        case .hafs_1440:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.hafs-1440.issue")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        case .hafs_1439:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.hafs-1439.issue")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        case .hafs_1441:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.hafs-1441.issue")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        case .tajweed:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.selector.property.pages.604")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        case .indoPak:
            return [
                Property(type: .supports, property: l("reading.selector.property.hafs")),
                Property(type: .supports, property: l("reading.selector.property.pages.610")),
                Property(type: .supports, property: l("reading.selector.property.lines.15")),
                Property(type: .lacks, property: l("reading.selector.property.word-translation.not-supported")),
            ]
        }
    }

    var imageName: String {
        switch self {
        case .hafs_1405:
            return "hafs_1405"
        case .hafs_1421:
            return "hafs_1421"
        case .hafs_1440:
            return "hafs_1440"
        case .hafs_1439:
            return "hafs_1439"
        case .hafs_1441:
            return "hafs_1441"
        case .tajweed:
            return "tajweed"
        case .indoPak:
            return "indopak"
        }
    }

    /// Sura headers drawn over the page 604 sample, as the reader draws them.
    var suraHeaders: [SuraHeaderLocation] {
        switch self {
        case .hafs_1421:
            return [
                suraHeader(112, x: 14, y: 93, width: 1092, height: 116),
                suraHeader(113, x: 14, y: 557, width: 1092, height: 116),
                suraHeader(114, x: 14, y: 1148, width: 1092, height: 116),
            ]
        case .hafs_1439:
            return [
                suraHeader(112, x: 21, y: 79, width: 1038, height: 110),
                suraHeader(113, x: 21, y: 535, width: 1038, height: 110),
                suraHeader(114, x: 21, y: 1101, width: 1038, height: 110),
            ]
        case .hafs_1441:
            return [
                suraHeader(112, x: 28, y: 106, width: 1384, height: 146),
                suraHeader(113, x: 28, y: 713, width: 1384, height: 146),
                suraHeader(114, x: 28, y: 1469, width: 1384, height: 146),
            ]
        case .hafs_1405, .hafs_1440, .tajweed, .indoPak:
            return []
        }
    }

    /// Ayah markers drawn over the page 604 sample, as the reader draws them.
    var ayahNumbers: [AyahNumberLocation] {
        switch self {
        case .hafs_1421:
            return [
                ayahNumber(112, 1, x: 747, y: 322),
                ayahNumber(112, 2, x: 425, y: 322),
                ayahNumber(112, 3, x: 78, y: 317),
                ayahNumber(112, 4, x: 289, y: 434),
                ayahNumber(113, 1, x: 656, y: 793),
                ayahNumber(113, 2, x: 276, y: 794),
                ayahNumber(113, 3, x: 722, y: 910),
                ayahNumber(113, 4, x: 70, y: 909),
                ayahNumber(113, 5, x: 288, y: 1019),
                ayahNumber(114, 1, x: 584, y: 1379),
                ayahNumber(114, 2, x: 164, y: 1376),
                ayahNumber(114, 3, x: 874, y: 1495),
                ayahNumber(114, 4, x: 187, y: 1493),
                ayahNumber(114, 5, x: 237, y: 1614),
                ayahNumber(114, 6, x: 323, y: 1728),
            ]
        case .hafs_1439:
            return [
                ayahNumber(112, 1, x: 719, y: 313),
                ayahNumber(112, 2, x: 412, y: 313),
                ayahNumber(112, 3, x: 64, y: 313),
                ayahNumber(112, 4, x: 290, y: 424),
                ayahNumber(113, 1, x: 621, y: 762),
                ayahNumber(113, 2, x: 257, y: 762),
                ayahNumber(113, 3, x: 691, y: 875),
                ayahNumber(113, 4, x: 64, y: 875),
                ayahNumber(113, 5, x: 289, y: 982),
                ayahNumber(114, 1, x: 562, y: 1321),
                ayahNumber(114, 2, x: 158, y: 1321),
                ayahNumber(114, 3, x: 841, y: 1436),
                ayahNumber(114, 4, x: 181, y: 1436),
                ayahNumber(114, 5, x: 226, y: 1545),
                ayahNumber(114, 6, x: 315, y: 1659),
            ]
        case .hafs_1441:
            return [
                ayahNumber(112, 1, x: 960, y: 419),
                ayahNumber(112, 2, x: 549, y: 419),
                ayahNumber(112, 3, x: 87, y: 419),
                ayahNumber(112, 4, x: 387, y: 567),
                ayahNumber(113, 1, x: 828, y: 1018),
                ayahNumber(113, 2, x: 345, y: 1018),
                ayahNumber(113, 3, x: 923, y: 1168),
                ayahNumber(113, 4, x: 87, y: 1168),
                ayahNumber(113, 5, x: 384, y: 1311),
                ayahNumber(114, 1, x: 750, y: 1764),
                ayahNumber(114, 2, x: 212, y: 1764),
                ayahNumber(114, 3, x: 1123, y: 1916),
                ayahNumber(114, 4, x: 241, y: 1916),
                ayahNumber(114, 5, x: 302, y: 2061),
                ayahNumber(114, 6, x: 423, y: 2214),
            ]
        case .hafs_1405, .hafs_1440, .tajweed, .indoPak:
            return []
        }
    }

    private func suraHeader(_ sura: Int, x: Int, y: Int, width: Int, height: Int) -> SuraHeaderLocation {
        SuraHeaderLocation(sura: Sura(quran: quran, suraNumber: sura)!, x: x, y: y, width: width, height: height)
    }

    private func ayahNumber(_ sura: Int, _ ayah: Int, x: Int, y: Int) -> AyahNumberLocation {
        AyahNumberLocation(ayah: AyahNumber(quran: quran, sura: sura, ayah: ayah)!, x: x, y: y)
    }
}
