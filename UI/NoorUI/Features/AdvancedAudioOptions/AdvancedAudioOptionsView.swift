//
//  AdvancedAudioOptionsView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/24/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import SwiftUI
import UIx

public struct AdvancedAudioOptionsView<Sura: AdvancedAudioUISura>: View {
    // MARK: Lifecycle

    public init(dataObject: AdvancedAudioUI.DataObject<Sura>, actions: AdvancedAudioUI.Actions) {
        _dataObject = ObservedObject(initialValue: dataObject)
        self.actions = actions
    }

    // MARK: Public

    public var body: some View {
        Form {
            Section {
                ReciterView(name: dataObject.reciterName, image: nil, action: actions.reciterTapped)
            }

            Section(header: Text(l("audio.adjust-end-verse-to-the-end.label"))) {
                HStack {
                    LastVerseButton(label: lAndroid("quran_page"), action: actions.lastPageTapped)
                    Spacer()
                    LastVerseButton(label: l("surah"), action: actions.lastSuraTapped)
                    Spacer()
                    LastVerseButton(label: lAndroid("quran_juz2"), action: actions.lastJuzTapped)
                }
            }

            Section(header: Text(l("audio.playing-verses.label"))) {
                // From
                VerseStaticView(label: lAndroid("play_from"), verse: dataObject.fromVerse, action: actions.fromVerseTapped)
                // To
                VerseStaticView(label: lAndroid("play_to"), verse: dataObject.toVerse, action: actions.toVerseTapped)
            }

            Section(header: Text(lAndroid("play_each_verse").replacingOccurrences(of: ":", with: ""))) {
                RepeatView(items: AdvancedAudioUI.AudioRepeat.sorted, selection: $dataObject.verseRepeat)
            }

            Section(header: Text(lAndroid("play_verses_range").replacingOccurrences(of: ":", with: ""))) {
                RepeatView(items: AdvancedAudioUI.AudioRepeat.sorted, selection: $dataObject.listRepeat)
            }
        }
    }

    // MARK: Internal

    @ObservedObject var dataObject: AdvancedAudioUI.DataObject<Sura>

    // MARK: Private

    private let actions: AdvancedAudioUI.Actions
}

private struct LastVerseButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    RoundedActiveBackground(cornerRadius: 100)
                )
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

private struct RoundedActiveBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.appIdentity.opacity(0.8))
            .shadow(color: .systemGray3, radius: 2)
    }
}

private struct RepeatView: View {
    let items: [AdvancedAudioUI.AudioRepeat]
    @Binding var selection: AdvancedAudioUI.AudioRepeat

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(items, id: \.self) { item in
                Text(item.localizedDescription)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

private struct VerseStaticView<Verse: AdvancedAudioUIVerse>: View {
    let label: String
    let verse: Verse
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text(verse.localizedNameWithSuraNumber)
                    Image(systemName: "chevron.right")
                        .flipsForRightToLeftLayoutDirection(true)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

private struct ReciterView: View {
    let name: String
    let image: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let image {
                    Image(image)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.systemGray, lineWidth: 0.5)
                        )
                }

                Text(name)
                    .layoutPriority(1)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension AdvancedAudioUI.AudioRepeat {
    var localizedDescription: String {
        switch self {
        case .none: return lAndroid("repeatValues1")
        case .once: return lAndroid("repeatValues2")
        case .twice: return lAndroid("repeatValues3")
        case .indefinite: return lAndroid("repeatValues4")
        }
    }
}

struct AdvancedAudioOptionsView_Previews: PreviewProvider {
    struct PreviewSura: AdvancedAudioUISura {
        var localizedName: String
        var verses: [PreviewVerse]
    }

    struct PreviewVerse: AdvancedAudioUIVerse {
        var localizedName: String
        var localizedNameWithSuraNumber: String
    }

    struct Container: View {
        static let actions = AdvancedAudioUI.Actions(
            reciterTapped: {},
            lastPageTapped: {},
            lastSuraTapped: {},
            lastJuzTapped: {},
            fromVerseTapped: {},
            toVerseTapped: {}
        )

        @ObservedObject var dataObject = AdvancedAudioUI.DataObject(
            suras: [PreviewSura(
                localizedName: "Sura-1",
                verses: [PreviewVerse(localizedName: "1-1", localizedNameWithSuraNumber: "1-2")]
            )],
            fromVerse: PreviewVerse(
                localizedName: "An-Nas, Ayah 1",
                localizedNameWithSuraNumber: "114. An-Nas, Ayah 1"
            ),
            toVerse: PreviewVerse(
                localizedName: "An-Nas, Ayah 3",
                localizedNameWithSuraNumber: "114. An-Nas, Ayah 3"
            ),
            verseRepeat: .none,
            listRepeat: .twice,
            reciterName: "Mishary"
        )

        var body: some View {
            AdvancedAudioOptionsView(dataObject: dataObject, actions: Self.actions)
        }
    }

    // MARK: Internal

    static var previews: some View {
        Container()
    }
}
