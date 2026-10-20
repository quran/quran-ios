//
//  MoreMenuDeviceRotation.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import NoorUI
import SwiftUI
import UIx
import VLogging

struct MoreMenuDeviceRotation: View {
    @State var orientation: UIInterfaceOrientation = .unknown
    @State var updateOrientationTo: UIInterfaceOrientation? = nil

    var body: some View {
        // Portrait comes first as the default; each icon shows the orientation its button rotates to.
        HStack {
            DeviceRotation(image: NoorSystemImage.rotateToPortrait.image) {
                updateOrientationTo = .portrait
            }
            .disabled(orientation.isPortrait)

            DeviceRotation(image: NoorSystemImage.rotateToLandscape.image) {
                updateOrientationTo = .landscapeLeft
            }
            .disabled(orientation.isLandscape)
        }
        .background(
            HStack {
                Divider()
            }
            .background(DeviceOrientationResolver(updateOrientationTo: $updateOrientationTo) { orientation = $0 })
        )
    }
}

private struct DeviceRotation: View {
    let image: Image
    let action: () -> Void
    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        Button(action: action) {
            image
                .imageScale(.large)
                .foregroundColor(isEnabled ? .label : .gray)
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}

#Preview {
    MoreMenuDeviceRotation()
}

private struct DeviceOrientationResolver: UIViewControllerRepresentable {
    class DeviceOrientationResolverController: UIViewController {
        // MARK: Public

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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

    @Binding var updateOrientationTo: UIInterfaceOrientation?
    let orientationChanged: (UIInterfaceOrientation) -> Void

    func makeUIViewController(context: Context) -> DeviceOrientationResolverController {
        let controller = DeviceOrientationResolverController()
        controller.orientationChanged = orientationChanged
        return controller
    }

    func updateUIViewController(_ controller: DeviceOrientationResolverController, context: Context) {
        controller.orientationChanged = orientationChanged

        // Update orientation in the next runloop to prevent state modification during view update.
        if updateOrientationTo != nil {
            DispatchQueue.main.async {
                updateOrientationIfNeeded(of: controller.view)
            }
        }
    }

    private func updateOrientationIfNeeded(of view: UIView) {
        guard let newOrientation = updateOrientationTo else {
            return
        }
        updateOrientationTo = nil

        if #available(iOS 16.0, *) {
            let orientationMask: UIInterfaceOrientationMask = newOrientation.isLandscape ? .landscape : .portrait
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask)) { error in
                logger.error("Error while updating orientation to \(newOrientation.rawValue). Error: \(error)")
            }
        } else {
            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
        }
    }
}
