//
//  resource_bundle.swift
//
//
//  Created by Afifi, Mohamed on 8/29/21.
//

import Foundation

private class BundleFinder {}

extension Foundation.Bundle {
    /// SwiftUI Previews stores the resources in a location not accessible by the generated `Bundle.module`
    static var fixedModule: Bundle = {
        let bundleName = "QuranEngine_Localization"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,

            // For SwiftUI Previews
            /* Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/"). */
            Bundle(for: BundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent(),
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named \(bundleName)")
    }()
}
