//
//  NavigationHighlighter.swift
//
//
//  Created by Mohamed Afifi on 2026-10-29.
//

import AnnotationsService
import Combine
import CombineSchedulers
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIKit

/// Scrolls content to the verse the reader navigated to and briefly paints it, so the verse's saved highlight
/// shows afterward.
///
/// Content consumes the navigation target once it scrolls there. The navigated verse is remembered until the
/// reader leaves its page or takes over, so rebuilt content can scroll to it again.
///
/// Never call this while `VerseOverlayService` publishes: it emits before storing, so a nested write is lost.
@MainActor
final class NavigationHighlighter {
    // MARK: Lifecycle

    init(overlayService: VerseOverlayService, scheduler: AnySchedulerOf<DispatchQueue> = .main) {
        self.overlayService = overlayService
        self.scheduler = scheduler

        overlayService.$overlays
            .sink { [weak self] in self?.overlaysUpdated($0) }
            .store(in: &cancellables)
    }

    // MARK: Internal

    /// How long the highlight stays after content scrolls to the navigation target.
    static let visibleDuration: DispatchQueue.SchedulerTimeType.Stride = .seconds(1.5)

    /// How long a navigation target waits for content to scroll to it, such as content that fails to load.
    static let targetTimeout: DispatchQueue.SchedulerTimeType.Stride = .seconds(10)

    /// Scrolls content to `ayah` and highlights it.
    func navigate(to ayah: AyahNumber?) {
        navigatedVerse = ayah
        pendingHide = nil
        update {
            $0.navigationTarget = ayah
            $0.navigationHighlight = ayah
        }
        scheduleTargetTimeout()
    }

    /// Scrolls rebuilt content to the navigated verse again, without highlighting it.
    func rearm() {
        guard let navigatedVerse, overlayService.overlays.navigationTarget != navigatedVerse else {
            return
        }
        update { $0.navigationTarget = navigatedVerse }
        scheduleTargetTimeout()
    }

    /// Forgets the navigation once the reader takes over, such as by dragging or selecting verses.
    func hide() {
        forgetNavigation(animated: true)
    }

    /// Forgets the navigation once the reader leaves the navigated verse's page.
    func visiblePagesChanged(to pages: [Page]) {
        guard let navigatedVerse, !pages.contains(navigatedVerse.page) else {
            return
        }
        forgetNavigation(animated: false)
    }

    // MARK: Private

    private let overlayService: VerseOverlayService
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private var cancellables: Set<AnyCancellable> = []
    private var navigatedVerse: AyahNumber?
    private var pendingHide: AnyCancellable?
    private var pendingTargetTimeout: AnyCancellable?

    private static var animation: Animation? {
        UIView.areAnimationsEnabled && !UIAccessibility.isReduceMotionEnabled ? NoorAnimation.standard : nil
    }

    private func forgetNavigation(animated: Bool) {
        navigatedVerse = nil
        pendingTargetTimeout = nil
        let overlays = overlayService.overlays
        guard overlays.navigationTarget != nil || overlays.navigationHighlight != nil else {
            return
        }
        withAnimation(animated && overlays.navigationHighlight != nil ? Self.animation : nil) {
            update {
                $0.navigationTarget = nil
                $0.navigationHighlight = nil
            }
        }
    }

    private func fadeHighlight() {
        guard overlayService.overlays.navigationHighlight != nil else {
            return
        }
        withAnimation(Self.animation) {
            update { $0.navigationHighlight = nil }
        }
    }

    private func scheduleTargetTimeout() {
        guard let target = overlayService.overlays.navigationTarget else {
            pendingTargetTimeout = nil
            return
        }
        pendingTargetTimeout = Just(())
            .delay(for: Self.targetTimeout, scheduler: scheduler)
            .sink { [weak self] in self?.targetTimedOut(target) }
    }

    private func targetTimedOut(_ target: AyahNumber) {
        pendingTargetTimeout = nil
        guard overlayService.overlays.navigationTarget == target else {
            return
        }
        // Content never scrolled to it; stop holding the scroll anchor and the highlight.
        update {
            $0.navigationTarget = nil
            $0.navigationHighlight = nil
        }
    }

    /// Writes the overlays once, so subscribers see one coherent change.
    private func update(_ change: (inout VerseOverlays) -> Void) {
        var overlays = overlayService.overlays
        change(&overlays)
        guard overlays != overlayService.overlays else {
            return
        }
        overlayService.overlays = overlays
    }

    private func overlaysUpdated(_ overlays: VerseOverlays) {
        guard overlays.navigationHighlight != nil else {
            pendingHide = nil
            return
        }
        // Content consumes the target once it scrolls there, so slow loads keep the highlight until then.
        guard overlays.navigationTarget == nil, pendingHide == nil else {
            return
        }
        pendingHide = Just(())
            .delay(for: Self.visibleDuration, scheduler: scheduler)
            .sink { [weak self] in self?.fadeHighlight() }
    }
}
