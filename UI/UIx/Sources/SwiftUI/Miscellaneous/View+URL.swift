//
//  View+URL.swift
//
//
//  Created by Mohamed Afifi on 2024-02-02.
//

import SwiftUI

extension View {
    public func tryOpenURL(_ handler: @escaping (URL) -> OpenURLAction.Result) -> some View {
        environment(\.openURL, OpenURLAction(handler: handler))
    }
}
