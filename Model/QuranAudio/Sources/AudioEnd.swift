//
//  AudioEnd.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

/// Where playback stops. Saved by raw value, so cases keep their raw values;
/// new cases take new ones.
public enum AudioEnd: Int {
    case sura = 0
    case juz = 1
    case page = 2
    case quran = 3
    case quarter = 4
    case hizb = 5
}
