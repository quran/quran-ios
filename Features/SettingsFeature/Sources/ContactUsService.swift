//
//  ContactUsService.swift
//
//
//  Created by Mohamed Afifi on 2023-06-28.
//

import SafariServices
import UIKit

struct ContactUsService {
    // MARK: Internal

    func contactUsController() -> UIViewController {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let device = Self.unameMachine
        let iosVersion = UIDevice.current.systemVersion
        let appDetails = [appVersion, device, iosVersion].joined(separator: "|")
        let decodedAppDetails = appDetails.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = "https://docs.google.com/forms/d/e/1FAIpQLSduPT6DFmx2KGOS0I7khpww4FuvLGEDBlzKBhdw6dgIPU_6sg/viewform?entry.1440014003="
            + decodedAppDetails
        let url = URL(string: urlString)!
        return SFSafariViewController(url: url)
    }

    // MARK: Private

    private static var unameMachine: String {
        var utsnameInstance = utsname()
        uname(&utsnameInstance)
        let optionalString: String? = withUnsafePointer(to: &utsnameInstance.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingUTF8: $0) }
        }
        return optionalString ?? "Unknown"
    }
}
