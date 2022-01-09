//
//  AudioUpdatesNetworkManager.swift
//
//
//  Created by Mohamed Afifi on 2021-11-28.
//

import BatchDownloader
import Foundation
import PromiseKit

protocol AudioUpdatesNetworkManager {
    func getAudioUpdates(revision: Int) -> Promise<AudioUpdates?>
}

struct DefaultAudioUpdatesNetworkManager: AudioUpdatesNetworkManager {
    let networkManager: NetworkManager

    func getAudioUpdates(revision: Int) -> Promise<AudioUpdates?> {
        networkManager.request("/data/audio_updates.php", parameters: [("revision", "\(revision)")])
            .map(parse)
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
