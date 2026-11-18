//
//  MoreMenuDeviceRotation.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct MoreMenuDeviceRotation: View {
    @State var orientation: UIInterfaceOrientation = .unknown
    @State var updateOrientationTo: UIInterfaceOrientation? = nil

    var body: some View {
        // Portrait comes first as the default; each icon shows the orientation its button rotates to.
        HStack {
            DeviceRotation(
                image: NoorSystemImage.rotateToPortrait.image,
                accessibilityLabel: l("menu.rotate_to_portrait")
            ) {
                updateOrientationTo = .portrait
            }
            .disabled(orientation.isPortrait)

            DeviceRotation(
                image: NoorSystemImage.rotateToLandscape.image,
                accessibilityLabel: l("menu.rotate_to_landscape")
            ) {
                updateOrientationTo = .landscapeLeft
            }
            .disabled(orientation.isLandscape)
        }
        .background(DeviceOrientationResolver(updateOrientationTo: $updateOrientationTo) { orientation = $0 })
    }
}

private struct DeviceRotation: View {
    let image: Image
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            image
                .imageScale(.large)
                // Neutral, not tinted, and keeps the glass/material vibrancy.
                .foregroundStyle(.primary)
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        // Plain style already dims the disabled (current orientation) button.
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    MoreMenuDeviceRotation()
}

private struct DeviceOrientationResolver: UIViewControllerRepresentable {
    class DeviceOrientationResolverController: UIViewController {
        // MARK: Public

        override func loadView() {
            let view = WindowObservingView()
            view.onMoveToWindow = { [weak self] in self?.reportOrientation() }
            self.view = view
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: nil) { _ in
                self.reportOrientation()
            }
        }

        // MARK: Internal

        var orientationChanged: ((UIInterfaceOrientation) -> Void)?

        // MARK: Private

        /// Reports only a known orientation. The view leaves the window while another page is pushed,
        /// and size transitions that land then must not reset the orientation to `.unknown`.
        private func reportOrientation() {
            guard let orientation = view.window?.windowScene?.interfaceOrientation, orientation != .unknown else {
                return
            }
            // Next runloop, so the state doesn't change during a SwiftUI view update.
            DispatchQueue.main.async {
                self.orientationChanged?(orientation)
            }
        }
    }

    private class WindowObservingView: UIView {
        var onMoveToWindow: (() -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                onMoveToWindow?()
            }
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

        // Not the view controller variant: iPad windows, regular in both size classes, rotate from here too.
        view.requestInterfaceOrientations(newOrientation.isLandscape ? .landscape : .portrait)
    }
}
