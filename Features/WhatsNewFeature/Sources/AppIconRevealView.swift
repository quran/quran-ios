//
//  AppIconRevealView.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Localization
import SwiftUI
import UIKit

/// The "Nightfall" reveal of the new app icon. Night rises over the previous icon,
/// the new icon is written in gold from right to left, then the copy rises beneath it.
/// Once it settles, a sheen sweeps across the icon's glass every few seconds,
/// and a double tap on the icon replays the reveal from the start.
///
/// It looks the same whatever the app accent or appearance. It ends on `newIcon`, and reads
/// the rest of its artwork from the main bundle: `previous-app-icon` and the `app-glyph` template.
@MainActor
struct AppIconRevealView: View {
    // MARK: Internal

    /// The icon the reveal ends on, drawn in the same frame as the `app-glyph` template.
    let newIcon: Image
    let onContinue: () -> Void
    let onChooseAnotherIcon: (() -> Void)?
    /// Called with `true` once night covers the top of the screen,
    /// and with `false` when a replay rewinds it.
    let onNightChange: (_ isNight: Bool) -> Void
    /// Called when a double tap on the icon replays the reveal.
    let onReplay: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let layout = AppIconRevealLayout(
                size: geometry.size,
                insets: safeAreaInsets,
                isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
                copyTopSpacing: copyTopSpacing
            )
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .accessibilityHidden(true)

                AppIconRevealNight(
                    size: geometry.size,
                    isRisen: isNightRisen,
                    isHorizonGlowVisible: isHorizonGlowVisible
                )
                .opacity(finalLayoutOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                content(layout)
            }
        }
        .ignoresSafeArea()
        // Outside the full-screen reader, which sees no safe area.
        .background(safeAreaReader)
        .task(id: playback) { await run() }
    }

    // MARK: Private

    private enum Presentation {
        /// The full "Nightfall" animation.
        case animated
        /// A crossfade into the final layout, for Reduce Motion and VoiceOver.
        case crossfade
    }

    private typealias Palette = AppIconRevealPalette
    private typealias Timeline = AppIconRevealTimeline

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var isTitleFocused: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var copyTopSpacing = 28.0
    @ScaledMetric(relativeTo: .body) private var copySpacing = 12.0
    @ScaledMetric(relativeTo: .body) private var copyRise = 14.0
    @ScaledMetric(relativeTo: .headline) private var actionVerticalPadding = 14.0
    @ScaledMetric(relativeTo: .body) private var actionsSpacing = 8.0
    @ScaledMetric(relativeTo: .body) private var actionsBottomPadding = 20.0
    @ScaledMetric(relativeTo: .body) private var scrollFadeHeight = 20.0

    /// Design heights; the buttons grow beyond them with their text.
    private let continueMinHeight: CGFloat = 52
    private let secondaryActionMinHeight: CGFloat = 44

    /// Chosen once when the reveal starts, so turning on Reduce Motion or VoiceOver
    /// midway can't hide the final layout.
    @State private var presentation: Presentation?
    /// Counts the replays; changing it restarts the timeline.
    @State private var playback = 0
    /// The playback whose timeline has started, so reappearing doesn't restart it.
    @State private var startedPlayback: Int?
    @State private var isNightRisen = false
    @State private var isHorizonGlowVisible = true
    @State private var isPreviousIconVisible = true
    @State private var isTileVisible = false
    @State private var glyphProgress: CGFloat = 0
    @State private var isPenLit = false
    @State private var isPenDone = false
    @State private var sheenProgress: CGFloat = 0
    @State private var isNewIconVisible = false
    @State private var isIconGlowVisible = false
    @State private var isLifted = false
    @State private var isTitleVisible = false
    @State private var isBodyVisible = false
    @State private var areActionsVisible = false
    @State private var areActionsEnabled = false
    @State private var isFinalLayoutVisible = false
    @State private var safeAreaInsets = EdgeInsets()

    /// Hides the night, the new icon, and the copy until the animation starts or the crossfade shows them.
    private var finalLayoutOpacity: Double {
        presentation == .animated || isFinalLayoutVisible ? 1 : 0
    }

    /// The animated reveal replays once it settles; the crossfade doesn't.
    private var canReplay: Bool {
        presentation == .animated && areActionsEnabled
    }

    // MARK: Layout

    private var safeAreaReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { safeAreaInsets = proxy.safeAreaInsets }
                .onChange(of: proxy.safeAreaInsets) { safeAreaInsets = $0 }
        }
    }

    private func content(_ layout: AppIconRevealLayout) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Room for the lifted icon, which scrolls with the copy.
                    Color.clear
                        .frame(height: layout.copyTop)

                    copy

                    if layout.scrollsActions {
                        actions
                            .padding(.bottom, max(layout.insets.bottom, actionsBottomPadding))
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: AppIconRevealLayout.contentMaxWidth)
                .padding(.leading, layout.insets.leading)
                .padding(.trailing, layout.insets.trailing)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    icons(layout)
                }
            }
            // Content coordinates match the screen, so the icon starts where the previous one was.
            .ignoresSafeArea()
            .mask(scrollFade(layout))
            .modifier(RevealScrollBehavior(flashesIndicators: layout.scrollsActions && areActionsEnabled))

            if !layout.scrollsActions {
                actions
                    .padding(.horizontal)
                    .padding(.bottom, actionsBottomPadding)
                    .frame(maxWidth: AppIconRevealLayout.contentMaxWidth)
                    .padding(.leading, layout.insets.leading)
                    .padding(.trailing, layout.insets.trailing)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
    }

    private func icons(_ layout: AppIconRevealLayout) -> some View {
        ZStack {
            AppIconRevealIcon(
                newIcon: newIcon,
                isTileVisible: isTileVisible,
                glyphProgress: glyphProgress,
                isPenLit: isPenLit,
                isPenDone: isPenDone,
                sheenProgress: sheenProgress,
                isNewIconVisible: isNewIconVisible,
                isGlowVisible: isIconGlowVisible
            )
            // Only the icon, not its glow, takes the double tap.
            .contentShape(AppIconRevealIcon.shape)
            .onTapGesture(count: 2, perform: replay)
            .allowsHitTesting(canReplay)
            .scaleEffect(isLifted ? layout.liftedScale : 1)
            .offset(y: isLifted ? layout.liftOffset : 0)
            .opacity(finalLayoutOpacity)

            AppIconRevealPreviousIcon(
                isVisible: isPreviousIconVisible,
                hidesWithMotion: presentation == .animated
            )
            .allowsHitTesting(false)
        }
        .position(layout.restingCenter)
        .accessibilityHidden(true)
    }

    /// Fades scrolled content under the status bar and at the bottom edge.
    private func scrollFade(_ layout: AppIconRevealLayout) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: layout.insets.top)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: layout.scrollsActions ? layout.insets.bottom : scrollFadeHeight)
        }
    }

    private var copy: some View {
        VStack(spacing: copySpacing) {
            Text(l("new.app_icon.title"))
                .font(.largeTitle.bold())
                .foregroundStyle(Color.white)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)
                .revealRising(isVisible: isTitleVisible, distance: copyRise)

            Text(l("new.app_icon.body"))
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.76))
                .revealRising(isVisible: isBodyVisible, distance: copyRise)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(finalLayoutOpacity)
    }

    private var actions: some View {
        VStack(spacing: actionsSpacing) {
            Button(action: onContinue) {
                Text(l("new.action"))
                    .font(.headline)
                    .foregroundStyle(Palette.continueText)
                    .padding(.horizontal)
                    .padding(.vertical, actionVerticalPadding)
                    .frame(maxWidth: .infinity, minHeight: continueMinHeight)
                    .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)

            if let onChooseAnotherIcon {
                Button(action: onChooseAnotherIcon) {
                    Text(l("new.app_icon.choose_another"))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.gold)
                        .padding(.vertical, actionVerticalPadding / 2)
                        .frame(maxWidth: .infinity, minHeight: secondaryActionMinHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top)
        .revealRising(isVisible: areActionsVisible, distance: copyRise)
        .opacity(finalLayoutOpacity)
        .allowsHitTesting(areActionsEnabled)
    }

    // MARK: Timeline

    private func run() async {
        if startedPlayback == playback {
            // The view reappeared after this playback started: finish it without replaying it.
            settleFinalLayout()
            withoutAnimation {
                isPreviousIconVisible = false
                isFinalLayoutVisible = true
            }
            onNightChange(true)
            finishReveal()
        } else if startedPlayback == nil {
            startedPlayback = playback
            if reduceMotion || voiceOverEnabled {
                presentation = .crossfade
                crossfadeToFinalLayout()
                await play([
                    (Timeline.crossfade.end, {
                        onNightChange(true)
                        finishReveal()
                    }),
                ])
                return
            }
            presentation = .animated
            await playNightfall()
        } else {
            startedPlayback = playback
            await rewind()
            guard !Task.isCancelled else {
                return
            }
            await playNightfall()
        }
        await shineRepeatedly()
    }

    private func playNightfall() async {
        animateNightfall()
        await play([
            (Timeline.nightfall, { onNightChange(true) }),
            (Timeline.newIcon.end, { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }),
            (Timeline.actions.start, finishReveal),
        ])
    }

    private func animateNightfall() {
        animate(Timeline.nightRise, .timingCurve(0.7, 0, 0.25, 1, duration: Timeline.nightRise.duration)) {
            isNightRisen = true
        }
        animate(Timeline.horizonGlowFade, .easeOut(duration: Timeline.horizonGlowFade.duration)) {
            isHorizonGlowVisible = false
        }
        animate(Timeline.previousIconFade, .easeInOut(duration: Timeline.previousIconFade.duration)) {
            isPreviousIconVisible = false
        }
        animate(Timeline.tileFade, .easeInOut(duration: Timeline.tileFade.duration)) {
            isTileVisible = true
        }
        animate(Timeline.glyphWrite, .timingCurve(0.35, 0, 0.25, 1, duration: Timeline.glyphWrite.duration)) {
            glyphProgress = 1
        }
        animate(Timeline.penIn, .easeOut(duration: Timeline.penIn.duration)) {
            isPenLit = true
        }
        animate(Timeline.penOut, .easeIn(duration: Timeline.penOut.duration)) {
            isPenDone = true
        }
        animate(Timeline.iconGlow, .easeOut(duration: Timeline.iconGlow.duration)) {
            isIconGlowVisible = true
        }
        animate(Timeline.sheen, .easeInOut(duration: Timeline.sheen.duration)) {
            sheenProgress = 1
        }
        animate(Timeline.newIcon, .easeInOut(duration: Timeline.newIcon.duration)) {
            isNewIconVisible = true
        }
        animate(Timeline.lift, .timingCurve(0.65, 0, 0.35, 1, duration: Timeline.lift.duration)) {
            isLifted = true
        }
        let copyCurve = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: Timeline.title.duration)
        animate(Timeline.title, copyCurve) { isTitleVisible = true }
        animate(Timeline.body, copyCurve) { isBodyVisible = true }
        animate(Timeline.actions, copyCurve) { areActionsVisible = true }
    }

    /// Settles every layer in its final state under the crossfade, then fades it in.
    private func crossfadeToFinalLayout() {
        settleFinalLayout()
        animate(Timeline.crossfade, .easeInOut(duration: Timeline.crossfade.duration)) {
            isFinalLayoutVisible = true
            isPreviousIconVisible = false
        }
    }

    /// Puts the night, the new icon, and the copy in their final state without animation.
    private func settleFinalLayout() {
        withoutAnimation {
            isNightRisen = true
            isHorizonGlowVisible = false
            isTileVisible = true
            glyphProgress = 1
            sheenProgress = 1
            isNewIconVisible = true
            isIconGlowVisible = true
            isLifted = true
            isTitleVisible = true
            isBodyVisible = true
            areActionsVisible = true
        }
    }

    /// Returns every layer to where the reveal starts, so it can play again.
    private func rewind() async {
        areActionsEnabled = false
        onNightChange(false)
        // The pen and the sheen would streak back across the icon, so they jump.
        withoutAnimation {
            isPenLit = false
            isPenDone = false
            sheenProgress = 0
        }
        withAnimation(.easeInOut(duration: Timeline.rewind)) {
            isNightRisen = false
            isHorizonGlowVisible = true
            isPreviousIconVisible = true
            isTileVisible = false
            glyphProgress = 0
            isNewIconVisible = false
            isIconGlowVisible = false
            isLifted = false
            isTitleVisible = false
            isBodyVisible = false
            areActionsVisible = false
        }
        await sleep(Timeline.rewind)
    }

    /// Sweeps the sheen across the icon's glass every few seconds until the timeline stops.
    private func shineRepeatedly() async {
        guard presentation == .animated else {
            return
        }
        while !Task.isCancelled {
            // Moves the sheen back to its hidden start; the pause keeps this apart from the sweep.
            withoutAnimation { sheenProgress = 0 }
            await sleep(Timeline.sheenRepeatDelay)
            guard !Task.isCancelled else {
                return
            }
            guard !reduceMotion else {
                continue
            }
            withAnimation(.easeInOut(duration: Timeline.sheen.duration)) {
                sheenProgress = 1
            }
            await sleep(Timeline.sheen.duration)
        }
    }

    private func replay() {
        guard canReplay else {
            return
        }
        onReplay()
        playback += 1
    }

    /// Enables the actions and moves VoiceOver to the title.
    private func finishReveal() {
        areActionsEnabled = true
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        isTitleFocused = true
    }

    private func animate(_ beat: AppIconRevealTimeline.Beat, _ animation: Animation, changes: () -> Void) {
        withAnimation(animation.delay(beat.start), changes)
    }

    private func withoutAnimation(_ changes: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, changes)
    }

    private func sleep(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Runs the effects that aren't animations at their times, in order.
    private func play(_ effects: [(time: TimeInterval, effect: () -> Void)]) async {
        var elapsed: TimeInterval = 0
        for (time, effect) in effects {
            await sleep(time - elapsed)
            guard !Task.isCancelled else {
                return
            }
            elapsed = time
            effect()
        }
    }
}

/// Keeps the reveal still when it fits, and flashes the scroll indicators when the actions scroll
/// off-screen, where the system supports it.
private struct RevealScrollBehavior: ViewModifier {
    let flashesIndicators: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicatorsFlash(trigger: flashesIndicators)
        } else if #available(iOS 16.4, *) {
            content.scrollBounceBehavior(.basedOnSize)
        } else {
            content
        }
    }
}

#Preview {
    AppIconRevealView(
        newIcon: Image(systemName: "app.fill"),
        onContinue: {},
        onChooseAnotherIcon: {},
        onNightChange: { _ in },
        onReplay: {}
    )
}
