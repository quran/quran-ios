//
//  ContentStatusView.swift
//
//
//  Created by Mohamed Afifi on 2023-02-20.
//

import Localization
import SwiftUI

public struct ContentStatusView: View {
    public enum State {
        case downloading(progress: Double)
        case error(_ error: Error, retry: () -> Void)
    }

    private let state: State
    public init(state: State) {
        self.state = state
    }

    public var body: some View {
        VStack {
            Spacer()
            switch state {
            case .downloading(let progress):
                downloadingView(progress)
            case let .error(error, retry):
                errorView(error, retry: retry)
            }
            Spacer()
            Spacer()
        }
        .padding()
    }

    private func downloadingView(_ progress: Double) -> some View {
        VStack {
            ProgressView(value: progress, total: 1)
            Text(lAndroid("downloading_title"))
        }
    }

    private func errorView(_ error: Error, retry: @escaping () -> Void) -> some View {
        VStack {
            Text(l("unknown_error_message"))
            Text(error.localizedDescription)
                .font(.callout)
                .padding(.bottom)
            Button(action: retry) {
                Text(lAndroid("download_retry"))
            }
        }
    }
}

struct PreparingContent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentStatusView(state: .downloading(progress: 0.4))
            ContentStatusView(state: .error(URLError(.notConnectedToInternet) as NSError, retry: {}))
        }
        .accentColor(.appIdentity)
        .preferredColorScheme(.light)
    }
}
