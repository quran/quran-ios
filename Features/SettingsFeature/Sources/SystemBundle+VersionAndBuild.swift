//
//  SystemBundle+VersionAndBuild.swift
//
//
//  Created by Mohamed Afifi on 2026-11-16.
//

import SystemDependencies

extension SystemBundle {
    /// The version and build, such as `2.4.0 (310)`, so a bug report can name the exact build.
    /// `nil` when the bundle has no version.
    var versionAndBuild: String? {
        guard let version = infoValue(forKey: "CFBundleShortVersionString") as? String else {
            return nil
        }
        guard let build = infoValue(forKey: "CFBundleVersion") as? String else {
            return version
        }
        return "\(version) (\(build))"
    }
}
