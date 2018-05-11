//
//  main.swift
//  Android2iOS-Localization
//
//  Created by Mohamed Afifi on 4/13/18.
//  Copyright © 2018 Quran. All rights reserved.
//

import Foundation

print("Welcome to Android to iOS Localization")


let baseAndroidDir = "/Work/OpenSource/Quran/quran_android/app/src/main/res/"
let baseIOSDir = "/Work/OpenSource/Quran/Quran-iOS/App/Quran/"

let androidFiles = [
    "values/strings.xml",
    "values-ar/strings.xml",
    "values-de/strings.xml",
    "values-es/strings.xml",
    "values-fa/strings.xml",
    "values-fr/strings.xml",
    "values-kk/strings.xml",
    "values-my/strings.xml",
    "values-nl/strings.xml",
    "values-pt/strings.xml",
    "values-ru/strings.xml",
    "values-tr/strings.xml",
    "values-ug/strings.xml",
    "values-uz/strings.xml",
    "values-zh/strings.xml",
]
let iosFiles = [
    "Base.lproj/Android",
    "ar.lproj/Android",
    "de.lproj/Android",
    "es.lproj/Android",
    "fa.lproj/Android",
    "fr.lproj/Android",
    "kk.lproj/Android",
    "my.lproj/Android",
    "nl.lproj/Android",
    "pt.lproj/Android",
    "ru.lproj/Android",
    "tr.lproj/Android",
    "ug.lproj/Android",
    "uz.lproj/Android",
    "zh.lproj/Android",
]
precondition(androidFiles.count == iosFiles.count)

let converter = LocalizationConverter()

for (android, ios) in zip(androidFiles, iosFiles) {
    print("Translating:", android)
    let filePath = baseAndroidDir + android
    guard FileManager.default.fileExists(atPath: filePath) else {
        print("Cannot find file \(android)")
        continue
    }
    let url = URL(fileURLWithPath: filePath)
    let androidString = try! Data(contentsOf: url)
    let (s, p) = converter.convert(androidXml: androidString)
    try! s.write(toFile: baseIOSDir + ios + ".strings", atomically: true, encoding: .utf8)
    try! p.write(toFile: baseIOSDir + ios + ".stringsdict", atomically: true, encoding: .utf8)
}
