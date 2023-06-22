//
//  MoreMenuDeviceRotation.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

struct MoreMenuDeviceRotation: View {
    @State var orientation: UIInterfaceOrientation = .unknown

    var body: some View {
        HStack {
            DeviceRotation(image: NoorImage.rotateToLandscape.image) {
                updateOrientationTo(.landscapeLeft)
            }
            .disabled(orientation.isLandscape)

            DeviceRotation(image: NoorImage.rotateToPortrait.image) {
                updateOrientationTo(.portrait)
            }
            .disabled(orientation.isPortrait)
        }
        .background(
            HStack {
                Divider()
            }
            .background(DeviceOrientationResolver { orientation = $0 })
        )
    }

    func updateOrientationTo(_ orientation: UIInterfaceOrientation) {
        self.orientation = orientation
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
}

private struct DeviceRotation: View {
    let image: Image
    let action: () -> Void
    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        Button(action: action) {
            image
                .foregroundColor(isEnabled ? .label : .gray)
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}

struct MoreMenuDeviceRotation_Previews: PreviewProvider {
    struct Container: View {
        @State var orientation: UIInterfaceOrientation

        var body: some View {
            MoreMenuDeviceRotation()
        }
    }

    // MARK: Internal

    static var previews: some View {
        Previewing.screen {
            VStack {
                Container(orientation: .landscapeLeft)
                Divider()
                Container(orientation: .portrait)
            }
        }
        .previewLayout(.fixed(width: 320, height: 140))
    }
}

private struct DeviceOrientationResolver: UIViewControllerRepresentable {
    class DeviceOrientationResolverController: UIViewController {
        // MARK: Public

        override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: nil) { _ in
                self.orientationChanged?(self.orientation)
            }
        }

        // MARK: Internal

        var orientationChanged: ((UIInterfaceOrientation) -> Void)?

        var orientation: UIInterfaceOrientation {
            view.window?.windowScene?.interfaceOrientation ?? .unknown
        }
    }

    let orientationChanged: (UIInterfaceOrientation) -> Void

    func makeUIViewController(context: Context) -> DeviceOrientationResolverController {
        let controller = DeviceOrientationResolverController()
        controller.orientationChanged = orientationChanged
        return controller
    }

    func updateUIViewController(_ controller: DeviceOrientationResolverController, context: Context) {
        controller.orientationChanged = orientationChanged
    }
}
