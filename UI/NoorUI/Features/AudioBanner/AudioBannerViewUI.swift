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
    case playing(paused: Bool)
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
    public init(play: @escaping () -> Void, pause: @escaping () -> Void, resume: @escaping () -> Void, stop: @escaping () -> Void, backward: @escaping () -> Void, forward: @escaping () -> Void, cancelDownloading: @escaping AsyncAction, reciters: @escaping () -> Void, more: @escaping () -> Void) {
        self.play = play
        self.pause = pause
        self.resume = resume
        self.stop = stop
        self.backward = backward
        self.forward = forward
        self.cancelDownloading = cancelDownloading
        self.reciters = reciters
        self.more = more
    }
}

public struct AudioBannerViewUI: View {
    private let state: AudioBannerState
    private let actions: AudioBannerActions
    public init(state: AudioBannerState, actions: AudioBannerActions) {
        self.state = state
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            switch state {
            case .playing(let paused):
                AudioPlaying(paused: paused, actions: actions)
            case .readyToPlay(let reciter):
                ReadyToPlay(reciter: reciter, actions: actions)
            case .downloading(let progress):
                Downloading(progress: progress, actions: actions)
            }
        }
        .font(.title2)
        .background(
            BannerBackground(color: .clear)
                .shadow(color: .label.opacity(0.33), radius: 2)
        )
    }
}

private struct AudioPlaying: View {
    let paused: Bool
    let actions: AudioBannerActions

    var body: some View {
        HStack {
            Button(action: actions.stop) {
                NoorSystemImage.stop.image
                    .padding()
            }
            Spacer()

            Button(action: actions.backward) {
                NoorSystemImage.backward.image
                    .padding()
            }
            Group {
                if paused {
                    Button(action: actions.resume) {
                        NoorSystemImage.play.image
                    }
                } else {
                    Button(action: actions.pause) {
                        NoorSystemImage.pause.image
                    }
                }
            }
            .padding()
            Button(action: actions.forward) {
                NoorSystemImage.forward.image
                    .padding()
            }

            Spacer()
            Button(action: actions.more) {
                NoorSystemImage.more.image
                    .padding()
            }
        }
    }
}

private struct ReadyToPlay: View {
    let reciter: String
    let actions: AudioBannerActions
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
                        .background(
                            BannerBackground(color: config.isPressed ? .systemFill : Color.clear)
                        )
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

                Text(lAndroid("downloading_title"))
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing)
        }
    }
}

private struct BannerBackground: View {
    let color: Color

    var body: some View {
        color
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
    }
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
            more: {}
        )

        let readyToPlay = AudioBannerState.readyToPlay(reciter: "Mishary Al-afasy")
        let playing = AudioBannerState.playing(paused: false)
        let downloading = AudioBannerState.downloading(progress: 0.7)
        var state: AudioBannerState {
            switch counter % 3 {
            case 0: readyToPlay
            case 1: playing
            default: downloading
            }
        }

        @State var counter: Int = 0

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
        }
    }

    return PreviewView()
}
