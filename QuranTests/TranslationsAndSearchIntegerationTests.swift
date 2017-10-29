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

class TranslationsAndSearchIntegerationTests: XCTestCase {

    private let container = Container()
    private let shouldDownload = true

    func testDownloadingAndSearchingTranslationsText() {
        let translationsRetriever = container.createTranslationsRetrievalInteractor()
        let downloadManager = container.createDownloadManager()
        let localRetriever = container.createLocalTranslationsRetrievalInteractor()

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

    override func tearDown() {
        try? FileManager.default.removeItem(at: Files.translationsURL)
    }
}
