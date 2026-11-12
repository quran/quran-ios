//
//  AppDistribution.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import Foundation
import StoreKit

/// Where this copy of the app came from.
public enum AppDistributionChannel: Sendable {
    case appStore
    case testFlight
    /// Debug, simulator, and Xcode builds.
    case development
}

/// Tells how this copy of the app was installed.
public protocol AppDistribution: Sendable {
    var channel: AppDistributionChannel { get async }
}

public struct DefaultAppDistribution: AppDistribution {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var channel: AppDistributionChannel {
        get async {
            #if DEBUG || targetEnvironment(simulator)
            return .development
            #else
            if #available(iOS 16.0, *), let channel = await Self.appTransactionChannel() {
                return channel
            }
            return Self.receiptChannel()
            #endif
        }
    }

    // MARK: Private

    /// TestFlight signs the app transaction in the sandbox environment.
    @available(iOS 16.0, *)
    private static func appTransactionChannel() async -> AppDistributionChannel? {
        guard let result = try? await AppTransaction.shared else {
            return nil
        }
        let environment = switch result {
        case .verified(let transaction), .unverified(let transaction, _):
            transaction.environment
        }
        switch environment {
        case .sandbox:
            return .testFlight
        case .xcode:
            return .development
        default:
            return .appStore
        }
    }

    /// TestFlight installs a sandbox receipt; used when the app transaction can't be read.
    private static func receiptChannel() -> AppDistributionChannel {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? .testFlight : .appStore
    }
}
