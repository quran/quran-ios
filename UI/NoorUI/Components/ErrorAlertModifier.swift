//
//  ErrorAlertModifier.swift
//
//
//  Created by Mohamed Afifi on 2023-07-08.
//

import Crashing
import Localization
import SwiftUI

extension View {
    public func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?

    var showError: Binding<Bool> {
        Binding(
            get: {
                if let error {
                    return !error.isCancelled
                } else {
                    return false
                }
            },
            set: { showError in
                if !showError {
                    error = nil
                } else {
                    // Do nothing since the alert cannot show itself.
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content.alert(isPresented: showError) {
            if let error {
                crasher.recordError(error, reason: "ErrorModifier")
                return Alert(
                    title: Text(l("error.title")),
                    message: Text(error.getErrorDescription())
                )
            } else {
                return Alert(
                    title: Text(l("error.title")),
                    message: Text("")
                )
            }
        }
    }
}

struct ErrorAlert_Previews: PreviewProvider {
    struct ErrorView: View {
        @State var error: Error?

        var body: some View {
            NoorList {
                Section {
                    Button {
                        error = URLError(.timedOut)
                    } label: {
                        Text("Show error alert")
                    }
                }
            }
            .errorAlert(error: $error)
        }
    }

    // MARK: Internal

    static var previews: some View {
        ErrorView()
    }
}
