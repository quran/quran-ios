//
//  QuranResources.swift
//
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Foundation

public enum QuranResources {
    public static let quranUthmaniV2Database = Bundle.module
        .url(forResource: "Databases/quran.ar.uthmani.v2.db", withExtension: "")!
}
