//
//  TranslationsAndSearchIntegerationTests.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//
import XCTest
@testable import Quran
import BatchDownloader
import SQLite

class TranslationsAndSearchIntegerationTests: XCTestCase {

    private let container = Container()
    private let shouldDownload = true

    override func setUp() {
        super.setUp()
        let translationsRetriever = container.createTranslationsRetrievalInteractor()
        let downloadManager = container.createDownloadManager()
        expectNotToThrow {
            if shouldDownload {
                let translations = try translationsRetriever.execute(()).wait()
                print("Found translations.count", translations.count)

                for item in translations.map({ $0.translation }) {
                    print("Downloading \(item.displayName) ...")
                    let destinationPath = Files.translationsPathComponent.stringByAppendingPath(item.rawFileName)
                    let download = DownloadRequest(url: item.fileURL, resumePath: destinationPath.resumePath, destinationPath: destinationPath)
                    expectNotToThrow {
                        let response = try downloadManager.download(DownloadBatchRequest(requests: [download])).wait()
                        try response.promise.wait(timeout: 10 * 60)
                    }
                }
            }
        }
    }

    func testDownloadingAndSearchingTranslationsText() {
        let localRetriever = container.createLocalTranslationsRetrievalInteractor()

        expectNotToThrow {
            let downloadedTranslations = try localRetriever.execute(()).wait()
            print("downloaded translations.count", downloadedTranslations.count)

            for translation in downloadedTranslations/*[2..<downloadedTranslations.count]*/ {
                print("Checking \(translation.translation.displayName) ...")
                let fileName = translation.translation.fileName
                let fileURL = Files.translationsURL.appendingPathComponent(fileName)
                let persistence = SQLiteTranslationTextPersistence(filePath: fileURL.absoluteString)

                for sura in 0..<Quran.SuraPageStart.count {
                    for ayah in 0..<Quran.numberOfAyahsForSura(sura + 1) {
                        let number = AyahNumber(sura: sura + 1, ayah: ayah + 1)
                        if let text = try persistence.getOptionalAyahText(forNumber: number) {
                            _ = try persistence.autocomplete(term: text)
                            _ = try persistence.search(for: text)
                        } else {
                            print("[Warning] Cannot find text for \(fileName): \(number)")
                        }
                    }
                }

            }
        }
    }

    func testShowMaxLengthOfTranslations() {
        expectNotToThrow {
            let localRetriever = container.createLocalTranslationsRetrievalInteractor()
            let downloadedTranslations = try localRetriever.execute(()).wait()
            print("downloaded translations.count", downloadedTranslations.count)

            let formatter = NumberFormatter()
            var array: [(String, AyahNumber, Int)] = []
            for translation in downloadedTranslations {

                let fileName = translation.translation.fileName
                let fileURL = Files.translationsURL.appendingPathComponent(fileName)

                // create the connection
                let connection = try Connection(fileURL.absoluteString, readonly: true)

                let rows = try connection.prepare("SELECT sura, ayah, MAX(LENGTH(text)) FROM verses")
                let first = rows.first(where: { _ in true})!
                let sura = first[0] as! Int64
                let ayah = first[1] as! Int64
                let length = first[2] as! Int64

                let ayahNumber = AyahNumber(sura: Int(sura), ayah: Int(ayah))
                let intLength = Int(length)
                array.append((translation.translation.displayName, ayahNumber, intLength))
                print("\(formatter.format(intLength)) at (\(sura),\(ayah)) for Translation \(translation.translation.displayName)")
            }
            print(array.sorted { $0.2 < $1.2 }.map { "\($0.2), \($0.1), \($0.0)" }.joined(separator: "\n"))
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: Files.translationsURL)
    }
}
