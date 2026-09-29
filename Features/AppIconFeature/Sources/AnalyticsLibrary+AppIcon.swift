//
//  AnalyticsLibrary+AppIcon.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import Foundation
import NoorUI

extension AnalyticsLibrary {
    func openingAppIcons(from source: AppIconListSource) {
        logEvent("OpeningAppIconsFrom", value: source.rawValue)
    }

    /// Logs an icon change attempt and its outcome: `success`, or the error's domain and code.
    func changeAppIcon(from previousOption: AppIconOption, to option: AppIconOption, error: Error?) {
        logEvent("ChangeAppIconFrom", value: previousOption.id)
        logEvent("ChangeAppIconTo", value: option.id)
        logEvent("ChangeAppIconResult", value: error.map(failureDescription) ?? "success")
    }
}

private func failureDescription(_ error: Error) -> String {
    let error = error as NSError
    return "error:\(error.domain):\(error.code)"
}
