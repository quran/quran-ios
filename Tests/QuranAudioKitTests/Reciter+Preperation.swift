//
//  Reciter+Preperation.swift
//  
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
@testable import QuranAudioKit
import Zip

extension Reciter {
    var gaplessDatabaseZip: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return  databaseName + ".zip"
    }
    
    var gaplessDatabaseDB: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return  databaseName + ".db"
    }
    
    func prepareGaplessReciterForTests(unZip: Bool = false) throws {
        let directory = localFolder()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let dbSource = resource(gaplessDatabaseZip)
        let zipDestination = directory.appendingPathComponent(gaplessDatabaseZip)
        let dbDestination = directory.appendingPathComponent(gaplessDatabaseDB)
        
        let zipFileExists = FileManager.default.fileExists(atPath: zipDestination.path)
        let dbFileExists = FileManager.default.fileExists(atPath: dbDestination.path)
        
        if zipFileExists == false {
            try FileManager.default.copyItem(at: dbSource, to: zipDestination)
        }
        if unZip, dbFileExists == false {
            try Zip.unzipFile(zipDestination, destination: directory, overwrite: true, password: nil, progress: nil)
        }
    }
    
    private func resource(_ path: String) -> URL {
        Bundle.module.url(forResource: "test_data/" + path, withExtension: nil)!
    }
}
