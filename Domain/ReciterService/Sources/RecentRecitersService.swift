//
//  RecentRecitersService.swift
//
//
//  Created by Zubair Khan on 12/6/22.
//

import Foundation
import QuranAudio

public class RecentRecitersService {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func recentReciters(_ allReciters: [Reciter]) -> [Reciter] {
        var recentReciters: [Reciter] = []
        for recentReciterId in preferences.recentReciterIds {
            if let recentReciter = allReciters.first(where: { $0.id == recentReciterId }) {
                recentReciters.append(recentReciter)
            }
        }
        recentReciters.reverse()
        return recentReciters
    }

    public func updateRecentRecitersList(_ reciter: Reciter) {
        var recentReciterIds = preferences.recentReciterIds

        // Remove from the set if it exists in the set so it can go to the front (recently selected)
        recentReciterIds.remove(reciter.id)

        // Remove the least recently selected reciter if the list contains max reciters
        if !recentReciterIds.isEmpty && recentReciterIds.count >= Self.maxNumOfRecentReciters {
            recentReciterIds.remove(at: 0)
        }
        recentReciterIds.append(reciter.id)

        preferences.recentReciterIds = recentReciterIds
    }

    // MARK: Private

    private static let maxNumOfRecentReciters: Int = 3

    private let preferences = ReciterPreferences.shared
}
