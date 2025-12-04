//
//  AppInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Analytics
import CloudKit
import Crashing
import Foundation
import LastPagePersistence
import VLogging

@MainActor
final class AppInteractor {
    // MARK: Lifecycle

    init(supportsCloudKit: Bool, analytics: AnalyticsLibrary, lastPagePersistence: LastPagePersistence, tabs: [TabBuildable]) {
        self.analytics = analytics
        self.lastPagePersistence = lastPagePersistence
        self.tabs = tabs
        self.supportsCloudKit = supportsCloudKit
    }

    // MARK: Internal

    weak var presenter: AppPresenter?

    func start() {
        let viewControllers = tabs.map { $0.build() }
        presenter?.setViewControllers(viewControllers, animated: false)

        guard supportsCloudKit else {
            return
        }

        // log cloud kit logged in status
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            self.logIsLoggedIntoCloudKit()
        }
    }

    // MARK: Private

    private let supportsCloudKit: Bool
    private let analytics: AnalyticsLibrary
    private let tabs: [TabBuildable]
    private let lastPagePersistence: LastPagePersistence

    private nonisolated func logIsLoggedIntoCloudKit() {
        CKContainer.default().accountStatus { [analytics] status, error in
            if let error {
                logger.error("Error while checking account status \(error)")
                analytics.cloudkitLoggedIn(.error)
            } else {
                analytics.cloudkitLoggedIn(status == .available ? .ok : .fail)
                if status == .available {
                    self.logLastPagesMatch()
                }
            }
        }
    }

    private nonisolated func logLastPagesMatch() {
        let db = CKContainer.default().privateCloudDatabase
        let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
        let query = CKQuery(recordType: "CD_MO_LastPage", predicate: NSPredicate(format: "TRUEPREDICATE"))
        db.fetch(withQuery: query, inZoneWith: zone.zoneID, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [analytics] result in
            switch result {
            case let .failure(error):
                logger.error("Error while accessing CloudKit \(error)")
                analytics.cloudkitLastPagesMatch(.error)
            case let .success(output):
                let records = output.matchResults.compactMap { try? $0.1.get() }
                let ckLastPages = Set(records.compactMap { $0["CD_page"] as? Int })
                Task {
                    do {
                        let cdLastPages = try await self.lastPagePersistence.retrieveAll()
                        let inSync = Set(cdLastPages.map(\.page)).isSubset(of: ckLastPages)
                        analytics.cloudkitLastPagesMatch(inSync ? .ok : .fail)
                    } catch {
                        crasher.recordError(error, reason: "Failed to retrieve last pages from persistence.")
                    }
                }
            }
        }
    }
}

private enum CloudKitStatus: String {
    case ok
    case fail
    case error
}

private extension AnalyticsLibrary {
    func cloudkitLoggedIn(_ status: CloudKitStatus) {
        logEvent("cloudkitLoggedIn", value: status.rawValue)
    }

    func cloudkitLastPagesMatch(_ status: CloudKitStatus) {
        logEvent("cloudkitLastPagesMatch", value: status.rawValue)
    }
}
