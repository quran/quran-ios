#if QURAN_SYNC
import QuranAnnotations
import QuranKit

public enum NoteEditorMode: Equatable {
    case create(verses: [AyahNumber])
    case edit(Note)
}
#endif
