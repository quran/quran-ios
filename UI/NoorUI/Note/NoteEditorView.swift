//
//  NoteEditorView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import SwiftUI
import UIx

public struct NoteEditorView: View {
    public init(note: EditableNote, done: @escaping () -> Void, delete: @escaping () -> Void) {
        _note = ObservedObject(initialValue: note)
        self.done = done
        self.delete = delete
    }

    @ObservedObject var note: EditableNote

    let done: () -> Void
    let delete: () -> Void

    public var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                HStack {
                    Spacer()
                    ForEach(NoteColor.sortedColors, id: \.self) { color in
                        Button(
                            action: { note.selectedColor = color },
                            label: { NoteCircle(color: color.color, selected: color == note.selectedColor) }
                        )
                    }
                    Spacer()
                }

                Button(action: delete, label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.systemBackground)
                                .shadow(color: Color.primary.opacity(0.5), radius: 1)
                        )
                })
            }
            HStack {
                Spacer()
                Text(note.ayahText)
                    .lineLimit(3)
                    .font(.quran(ofSize: .small))

                    .padding(.leading)
                    .overlay(HStack {
                        Rectangle().fill(note.selectedColor.color)
                            .frame(width: 4)
                        Spacer()
                    })
                    .environment(\.layoutDirection, .rightToLeft)
            }

            TextView($note.note, editing: $note.editing)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .frame(maxHeight: .infinity)
                .onTapGesture { } // to prevent from tapping text view dismissing the keyboard
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            note.editing = false
        }
        .onAppear {
            note.editing = note.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

// swiftlint:disable line_length
struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.screen {
            Group {
                NoteEditorView(
                    note: EditableNote(
                        ayahText: "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ",
                        modifiedSince: "3 hours ago",
                        selectedColor: .blue,
                        note: "A good note! What about a very very very long note where it will reach today is Sunday 1st of Jan today"
                    ),
                    done: {},
                    delete: {}
                )
                NoteEditorView(
                    note: EditableNote(
                        ayahText: "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ",
                        modifiedSince: "10 seconds ago",
                        selectedColor: .blue,
                        note: "A good note!"
                    ),
                    done: {},
                    delete: {}
                )
            }
        }
    }
}

// swiftlint:enable line_length
