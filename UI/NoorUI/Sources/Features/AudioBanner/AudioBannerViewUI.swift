//
//  AudioBannerViewUI.swift
//
//
//  Created by Mohamed Afifi on 2024-09-02.
//

import Localization
import SwiftUI
import UIx

public enum AudioBannerState {
    case playing(paused: Bool, rate: Float)
    case readyToPlay(reciter: String)
    case downloading(progress: Double)
}

public struct AudioBannerActions {
    let play: () -> Void
    let pause: () -> Void
    let resume: () -> Void
    let stop: () -> Void
    let backward: () -> Void
    let forward: () -> Void
    let cancelDownloading: AsyncAction
    let reciters: () -> Void
    let more: () -> Void
    let setPlaybackRate: (Float) -> Void

    public init(
        play: @escaping () -> Void,
        pause: @escaping () -> Void,
        resume: @escaping () -> Void,
        stop: @escaping () -> Void,
        backward: @escaping () -> Void,
        forward: @escaping () -> Void,
        cancelDownloading: @escaping AsyncAction,
        reciters: @escaping () -> Void,
        more: @escaping () -> Void,
        setPlaybackRate: @escaping (Float) -> Void
    ) {
        self.play = play
        self.pause = pause
        self.resume = resume
        self.stop = stop
        self.backward = backward
        self.forward = forward
        self.cancelDownloading = cancelDownloading
        self.reciters = reciters
        self.more = more
        self.setPlaybackRate = setPlaybackRate
    }
}

public struct AudioBannerViewUI: View {
    private let state: AudioBannerState
    private let actions: AudioBannerActions
    @ScaledMetric private var maxWidth = 500

    public init(state: AudioBannerState, actions: AudioBannerActions) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            switch state {
            case .playing(let paused, let rate):
                AudioPlaying(paused: paused, currentRate: rate, actions: actions)
            case .readyToPlay(let reciter):
                ReadyToPlay(reciter: reciter, actions: actions)
            case .downloading(let progress):
                Downloading(progress: progress, actions: actions)
            }
        }
        .font(.title2)
        .frame(maxWidth: maxWidth)
        .audioBannerBackground()
    }
}

private struct AudioPlaying: View {
    private enum Control {
        case stop
        case rate
        case backward
        case playPause
        case forward
        case more
    }

    private struct Layout {
        let showsRate: Bool
        let positions: [Control: CGPoint]

        func position(for control: Control) -> CGPoint {
            positions[control, default: .zero]
        }
    }

    let paused: Bool
    let currentRate: Float
    let actions: AudioBannerActions

    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric private var minimumMiddleSpacing = 4.0
    @ScaledMetric private var maximumMiddleSpacing = 16.0
    @State private var controlSizes: [Control: CGSize] = [:]

    private let minimumTapLength = 44.0

    private var stopButton: some View {
        Button(action: actions.stop) {
            NoorSystemImage.stop.image
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    private var rateMenu: some View {
        Menu {
            ForEach(PlaybackSpeed.supportedRates, id: \.self) { value in
                Button(PlaybackSpeed.formatted(value)) { actions.setPlaybackRate(value) }
            }
        } label: {
            Text(PlaybackSpeed.formatted(currentRate))
                .font(.footnote)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    private var backwardButton: some View {
        Button(action: actions.backward) {
            NoorSystemImage.backward.image
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    private var playPauseButton: some View {
        Button(action: paused ? actions.resume : actions.pause) {
            (paused ? NoorSystemImage.play.image : NoorSystemImage.pause.image)
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    private var forwardButton: some View {
        Button(action: actions.forward) {
            NoorSystemImage.forward.image
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    private var moreButton: some View {
        Button(action: actions.more) {
            NoorSystemImage.more.image
                .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                .contentShape(Rectangle())
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = makeLayout(availableWidth: geometry.size.width)

            ZStack {
                stopButton
                    .onSizeChange { updateSize($0, for: .stop) }
                    .position(layout.position(for: .stop))

                if layout.showsRate {
                    rateMenu
                        .position(layout.position(for: .rate))
                }

                backwardButton
                    .onSizeChange { updateSize($0, for: .backward) }
                    .position(layout.position(for: .backward))

                playPauseButton
                    .onSizeChange { updateSize($0, for: .playPause) }
                    .position(layout.position(for: .playPause))

                forwardButton
                    .onSizeChange { updateSize($0, for: .forward) }
                    .position(layout.position(for: .forward))

                moreButton
                    .onSizeChange { updateSize($0, for: .more) }
                    .position(layout.position(for: .more))

                rateMenu
                    .fixedSize()
                    .onSizeChange { updateSize($0, for: .rate) }
                    .hidden()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: measuredHeight)
        .padding()
    }

    private var measuredHeight: CGFloat {
        max(minimumTapLength, controlSizes.values.map(\.height).max() ?? 0)
    }

    private func makeLayout(availableWidth: CGFloat) -> Layout {
        let stopSize = size(for: .stop)
        let rateSize = size(for: .rate)
        let backwardSize = size(for: .backward)
        let playPauseSize = size(for: .playPause)
        let forwardSize = size(for: .forward)
        let moreSize = size(for: .more)

        let middleButtonsWidth = backwardSize.width + playPauseSize.width + forwardSize.width
        let edgeOnlySideWidth = max(stopSize.width, moreSize.width)
        let rateSideWidth = max(
            stopSize.width + rateSize.width + minimumMiddleSpacing * 2,
            moreSize.width
        )
        let minimumWidthWithRate = middleButtonsWidth
            + minimumMiddleSpacing * 2
            + rateSideWidth * 2
        let showsRate = controlSizes[.rate] != nil && availableWidth >= minimumWidthWithRate
        let reservedSideWidth = showsRate ? rateSideWidth : edgeOnlySideWidth
        let availableMiddleSpacing = (
            availableWidth - reservedSideWidth * 2 - middleButtonsWidth
        ) / 2
        let middleSpacing = min(maximumMiddleSpacing, max(0, availableMiddleSpacing))
        let middleWidth = middleButtonsWidth + middleSpacing * 2
        let middleLeading = (availableWidth - middleWidth) / 2
        let centerY = measuredHeight / 2

        var logicalXPositions: [Control: CGFloat] = [
            .stop: stopSize.width / 2,
            .backward: middleLeading + backwardSize.width / 2,
            .playPause: middleLeading + backwardSize.width + middleSpacing + playPauseSize.width / 2,
            .forward: middleLeading
                + backwardSize.width
                + middleSpacing
                + playPauseSize.width
                + middleSpacing
                + forwardSize.width / 2,
            .more: availableWidth - moreSize.width / 2,
        ]
        if showsRate {
            logicalXPositions[.rate] = (stopSize.width + middleLeading) / 2
        }

        let positions = logicalXPositions.mapValues { logicalX in
            let x = layoutDirection == .leftToRight ? logicalX : availableWidth - logicalX
            return CGPoint(x: x, y: centerY)
        }
        return Layout(showsRate: showsRate, positions: positions)
    }

    private func size(for control: Control) -> CGSize {
        controlSizes[control] ?? CGSize(width: minimumTapLength, height: minimumTapLength)
    }

    private func updateSize(_ size: CGSize, for control: Control) {
        guard controlSizes[control] != size else { return }
        controlSizes[control] = size
    }
}

private struct ReadyToPlay: View {
    let reciter: String
    let actions: AudioBannerActions
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius

    var body: some View {
        ZStack {
            HStack {
                Button(action: actions.play) {
                    NoorSystemImage.play.image
                        .padding()
                }
                Spacer()
                Text(reciter)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                Button(action: actions.more) {
                    NoorSystemImage.more.image
                        .padding()
                }
            }
            .background {
                Button(action: actions.reciters) {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(CustomButtonStyle { config in
                    config.label
                        .readyToPlayBackground(isPressed: config.isPressed)
                })
            }
        }
    }
}

private struct Downloading: View {
    let progress: Double
    let actions: AudioBannerActions
    var body: some View {
        HStack {
            AsyncButton(action: actions.cancelDownloading) {
                ZStack {
                    // workaround to have uniform height.
                    NoorSystemImage.more.image
                        .padding()
                        .hidden()
                    NoorSystemImage.cancel.image
                        .padding()
                }
                .overlay(Divider(), alignment: .trailing)
            }

            Spacer()
            VStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())

                Text(l("downloading_title"))
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing)
        }
    }
}

private struct BannerBackground: View {
    let color: Color
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius

    var body: some View {
        color
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
            .shadow(color: .label.opacity(0.33), radius: 2)
    }
}

private extension View {
    @ViewBuilder
    func readyToPlayBackground(isPressed: Bool) -> some View {
        if #available(iOS 26.0, *) {
            background {
                Color.systemFill
                    .opacity(isPressed ? 1 : 0)
                    .clipShape(Capsule())
            }
        } else {
            background(BannerBackground(color: isPressed ? .systemFill : Color.clear))
        }
    }

    @ViewBuilder
    func audioBannerBackground() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(in: .capsule)
                .padding(.horizontal)
        } else {
            background(BannerBackground(color: .clear))
        }
    }
}

#Preview("Compact Playing") {
    let actions = AudioBannerActions(
        play: {},
        pause: {},
        resume: {},
        stop: {},
        backward: {},
        forward: {},
        cancelDownloading: {},
        reciters: {},
        more: {},
        setPlaybackRate: { _ in }
    )
    AudioBannerViewUI(
        state: .playing(paused: false, rate: 1),
        actions: actions
    )
    .frame(width: 300)
    .background(Color.systemGroupedBackground)
}

#Preview {
    struct PreviewView: View {
        let actions = AudioBannerActions(
            play: {},
            pause: {},
            resume: {},
            stop: {},
            backward: {},
            forward: {},
            cancelDownloading: {},
            reciters: {},
            more: {},
            setPlaybackRate: { _ in }
        )

        let readyToPlay = AudioBannerState.readyToPlay(reciter: "Mishary Al-afasy")
        let playing = AudioBannerState.playing(paused: false, rate: 1.0)
        let downloading = AudioBannerState.downloading(progress: 0.7)
        var state: AudioBannerState {
            switch counter % 3 {
            case 0: readyToPlay
            case 1: playing
            default: downloading
            }
        }

        @State var counter: Int = 1

        var body: some View {
            VStack {
                Spacer()
                Button {
                    counter += 1
                } label: {
                    Text("Rotate")
                }
                Spacer()
                Group {
                    AudioBannerViewUI(state: state, actions: actions)
                }
            }
            .background(Color.systemGroupedBackground)
        }
    }

    return PreviewView()
}
