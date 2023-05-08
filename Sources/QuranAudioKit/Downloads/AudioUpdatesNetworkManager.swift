//
//  AudioUpdatesNetworkManager.swift
//
//
//  Created by Mohamed Afifi on 2021-11-28.
//

import BatchDownloader
import Foundation

struct AudioUpdatesNetworkManager {
    let networkManager: NetworkManager

    func getAudioUpdates(revision: Int) async throws -> AudioUpdates? {
        let data = try await networkManager.request("/data/audio_updates.php", parameters: [("revision", "\(revision)")])
        return try parse(data: data)
    }

    private func parse(data: Data) throws -> AudioUpdates? {
        if data.isEmpty { // no updates
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AudioUpdates.self, from: data)
    }
}
