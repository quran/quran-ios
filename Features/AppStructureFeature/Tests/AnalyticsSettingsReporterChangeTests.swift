//
//  AnalyticsSettingsReporterChangeTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import ReciterService
import ReciterServiceFake
import TranslationService
import WordTextService
import XCTest
@testable import NoorUI

/// Each user-changeable setting logs `setting_changed` with its new value.
extension AnalyticsSettingsReporterTests {
    // MARK: Audio

    func test_playbackRateChange_logsIt() async {
        await assertChange(of: "playback_rate", to: "2.0") {
            AudioPreferences.shared.playbackRate = 2
        }
    }

    func test_audioEndChange_logsIt() async {
        await assertChange(of: "audio_end", to: "page") {
            AudioPreferences.shared.audioEnd = .page
        }
    }

    func test_verseRepeatChange_logsIt() async {
        await assertChange(of: "verse_repeat", to: "inf") {
            AudioPreferences.shared.verseRuns = .indefinite
        }
    }

    func test_rangeRepeatChange_logsIt() async {
        await assertChange(of: "range_repeat", to: "2") {
            AudioPreferences.shared.listRuns = .finite(2)
        }
    }

    func test_versePauseChange_logsIt() async {
        await assertChange(of: "verse_pause", to: "0.0") {
            AudioPreferences.shared.verseDelay = .none
        }
    }

    func test_rangePauseChange_logsIt() async {
        await assertChange(of: "range_pause", to: "10.0") {
            AudioPreferences.shared.repetitionDelay = .tenSeconds
        }
    }

    func test_streamingChange_logsIt() async {
        await assertChange(of: "audio_streaming", to: "off") {
            AudioPreferences.shared.streamingEnabled = false
        }
    }

    func test_dimOtherAyahsChange_logsIt() async {
        await assertChange(of: "dim_other_ayahs", to: "off") {
            QuranContentStatePreferences.shared.dimsOtherAyahs = false
        }
    }

    func test_reciterChange_logsIt() async {
        await assertChange(of: "reciter", to: "reciter1") {
            ReciterPreferences.shared.lastSelectedReciterId = Reciter.gappedReciter.id
        }
    }

    // MARK: Reading

    func test_mushafChange_logsIt() async {
        await assertChange(of: "mushaf", to: "indopak") {
            ReadingPreferences.shared.reading = .indoPak
        }
    }

    func test_quranModeChange_logsIt() async {
        await assertChange(of: "quran_mode", to: "arabic") {
            QuranContentStatePreferences.shared.quranMode = .arabic
        }
    }

    func test_translationsCountChange_logsItsBucket() async {
        await assertChange(of: "translations_count", to: "3+") {
            SelectedTranslationsPreferences.shared.selectedTranslationIds = [1, 2, 3, 4]
        }
    }

    func test_arabicFontSizeChange_logsIt() async {
        await assertChange(of: "arabic_font_size", to: "accessibility5") {
            FontSizePreferences.shared.arabicFontSize = .accessibility5
        }
    }

    func test_translationFontSizeChange_logsIt() async {
        await assertChange(of: "trans_font_size", to: "xxxLarge") {
            FontSizePreferences.shared.translationFontSize = .xxxLarge
        }
    }

    func test_appearanceChange_logsIt() async {
        await assertChange(of: "appearance", to: "light") {
            ThemeService.shared.appearanceMode = .light
        }
    }

    func test_themeStyleChange_logsIt() async {
        await assertChange(of: "theme_style", to: "calm") {
            ThemeService.shared.themeStyle = .calm
        }
    }

    func test_turningWordPointerOff_logsIt() async {
        await assertChange(of: "word_pointer", to: "off") {
            WordTextPreferences.shared.isWordPointerActive = false
        }
    }

    func test_wordPointerTextChange_logsIt() async {
        await assertChange(of: "word_pointer", to: "translation") {
            WordTextPreferences.shared.wordTextType = .translation
        }
    }

    func test_twoPagesChange_logsIt() async {
        await assertChange(of: "two_pages", to: "on") {
            QuranContentStatePreferences.shared.twoPagesEnabled = true
        }
    }

    func test_arabicInTranslationChange_logsIt() async {
        await assertChange(of: "arabic_in_trans", to: "off") {
            QuranContentStatePreferences.shared.showArabicInTranslation = false
        }
    }

    func test_footnotesChange_logsIt() async {
        await assertChange(of: "footnotes", to: "off") {
            QuranContentStatePreferences.shared.showFootnotesInTranslation = false
        }
    }

    #if QURAN_SYNC
    func test_ayahIndicatorsChange_logsIt() async {
        await assertChange(of: "ayah_indicators", to: "reading_bookmark") {
            QuranContentStatePreferences.shared.ayahIndicatorVisibility = .readingBookmark
        }
    }
    #endif
}
