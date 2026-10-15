#if QURAN_SYNC
//
//  MobileSyncLogBridge.swift
//
//
//  Created by Mohamed Afifi on 2026-10-11.
//

import Logging
import MobileSync

/// Sends Mobile Sync's logs, including its HTTP calls, to swift-log.
public enum MobileSyncLogBridge {
    // MARK: Public

    public static let label = "mobile-sync"

    /// Call once after `LoggingSystem.bootstrap` and before the Mobile Sync graph is created.
    public static func install(level: Logger.Level) {
        MobileSyncLogging.configure(
            sink: MobileSyncSwiftLogSink(logger: Logger(label: label)),
            minSeverity: minSeverity(for: level)
        )
    }

    // MARK: Internal

    static func minSeverity(for level: Logger.Level) -> MobileSyncLogSeverity {
        switch level {
        case .trace: .verbose
        case .debug: .debug
        case .info: .info
        case .notice, .warning: .warn
        case .error: .error
        case .critical: .assert
        }
    }
}

struct MobileSyncSwiftLogSink: MobileSyncLogSink {
    // MARK: Lifecycle

    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: Internal

    static func level(of severity: MobileSyncLogSeverity) -> Logger.Level {
        switch severity {
        case .verbose: .trace
        case .debug: .debug
        case .info: .info
        case .warn: .warning
        case .error: .error
        case .assert: .critical
        }
    }

    func log(severity: MobileSyncLogSeverity, tag: String, message: String) {
        logger.log(level: Self.level(of: severity), "\(message)", source: tag)
    }

    // MARK: Private

    private let logger: Logger
}
#endif
