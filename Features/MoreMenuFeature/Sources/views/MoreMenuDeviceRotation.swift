//
//  MoreMenuDeviceRotation.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import VLogging

struct MoreMenuDeviceRotation: View {
    // MARK: Internal

    var body: some View {
        Toggle(lAndroid("prefs_landscape_orientation_title"), isOn: landscape)
            .padding()
            .background(DeviceOrientationResolver(updateOrientationTo: $updateOrientationTo) { isLandscape = $0.isLandscape })
    }

    // MARK: Private

    @State private var isLandscape = false
    @State private var updateOrientationTo: UIInterfaceOrientation? = nil

    private var landscape: Binding<Bool> {
        Binding(
            get: { isLandscape },
            set: { newValue in
                isLandscape = newValue
                updateOrientationTo = newValue ? .landscapeLeft : .portrait
            }
        )
    }
}

#Preview {
    MoreMenuDeviceRotation()
}

private struct DeviceOrientationResolver: UIViewControllerRepresentable {
    class DeviceOrientationResolverController: UIViewController {
        // MARK: Public

        override func viewIsAppearing(_ animated: Bool) {
            super.viewIsAppearing(animated)
            orientationChanged?(orientation)
        }

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
                updateOrientationIfNeeded(of: controller)
            }
        }
    }

    private func updateOrientationIfNeeded(of controller: DeviceOrientationResolverController) {
        guard let newOrientation = updateOrientationTo else {
            return
        }
        updateOrientationTo = nil

        if #available(iOS 16.0, *) {
            let orientationMask: UIInterfaceOrientationMask = newOrientation.isLandscape ? .landscape : .portrait
            controller.view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask)) { error in
                logger.error("Error while updating orientation to \(newOrientation.rawValue). Error: \(error)")
                DispatchQueue.main.async {
                    controller.orientationChanged?(controller.orientation)
                }
            }
        } else {
            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
        }
    }
}
