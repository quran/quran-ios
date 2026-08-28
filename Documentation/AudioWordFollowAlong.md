# Audio Word Follow-Along

While a reciter plays, the word being recited is highlighted and its translation shown in a
popover above it.

> **No published reciter database carries word timings yet, so this does nothing today.**
> It degrades to the behaviour that existed before it. See [What is needed](#what-is-needed).

## Using it

Five things must be true, and four are already the defaults:

1. **Reading is `hafs_1405`** — the only reading with word frames, so the only one where a
   single word can be drawn.
2. **Arabic mushaf mode**, not translation mode.
3. **Word pointer is on** in the ⋯ menu. This is the on/off switch — see [The toggle](#the-toggle).
4. **The selected reciter's timing database carries word segments.**
5. **That database covers the sura being played.**

Outside those conditions nothing breaks; the highlight simply does not appear.

## How the pieces fit together

```
Player                             AVPlayer periodic time observation, 50ms
   |
QueuePlayerActions                 playbackTimeChanged(seconds)
   |
QuranAudioPlayerActions            same, past the QueuingPlayer boundary
   |
RecitationWordFollower             finds the span covering that instant,
   |                               emits only when the word changes
AudioBannerViewModel               listener?.highlightRecitedWord(word)
   |
QuranInteractor                    gated on the word pointer switch
   |-- contentViewModel.highlightRecitedWord(word) -> VerseOverlays.recitedWord
   `-- WordPointerViewController                   -> the translation, in a popover
```

Word timings are read through `ReciterWordSegmentRetriever`, alongside
`ReciterTimingRetriever`, from the reciter's own downloaded database.

The popover lives in `WordPointerFeature` because that feature already owns a `PopoverView`
and the `WordTextService` lookup behind it.

### Why the player's clock

The highlight follows the player's real position rather than a timer started at an ayah
boundary, so **pause, resume, seek, repeat and playback rate all stay correct for free**.
For a gapless reciter each file is one sura, so the position in that file is exactly the
timeline the segments are keyed on.

The observation is installed only while a word is actually being drawn: not when the word
pointer is off, not while the app is backgrounded, and not for a sura with no timings.
`RecitationWordFollower.isFollowing` is the single source for that, and `onFollowingChanged`
reports it.

### Why lookup is by time range, not by position

A word can have **more than one span**, when the reciter repeats or elongates a passage —
191 such extra spans exist in sura 2 alone. So the follower asks which span contains this
instant, by binary search on `start_ms`. Spans must not overlap; overlapping data yields no
match rather than a wrong word.

When no span matches — the pause between two words — the follower **holds the last
highlight** rather than flickering it off.

## The toggle

The **word pointer** switch turns follow-along on and off. There is no separate setting,
because that switch already means "I want to work with individual words" and is hidden for
readings without word positions, which is exactly when follow-along cannot work either.

**Two consequences worth knowing.** The switch is session state seeded `false`
(`QuranInteractor.isWordPointerActive`), so follow-along is **off on every launch**. And the
same switch shows the draggable pointer arrow, so a reader who wants only the passive
highlight gets the arrow too. Both argue for a persisted setting of its own, which needs
More-menu UI and localization and is a product decision.

`AudioBannerViewModel` reads `AudioBannerListener.followsRecitedWord` before any timings are
loaded, so a reader with the switch off pays nothing.

## Colours

`recitedWord` and `pointedWord` are separate fields, so following a recitation and dragging
the pointer never overwrite each other, and each is drawn in its own colour. The recited
word is drawn last, so it wins if the pointer is dragged onto it.

| Layer | Colour |
|---|---|
| Ayah being recited | `recitation` (orange) @ 0.30 |
| Word being recited | `recitedWord` (teal) @ 0.55 |
| Word under the drag pointer | `recitation` (orange) @ 0.30 |
| Popover background | `UIColor.recitedWordPopoverBackground` |

The recited word needs a different hue from its verse, not a darker shade of the same one:
it is drawn on top of its ayah's highlight. When both shared a colour, the word was drawn
correctly and was completely invisible. Both `recitation` and `recitedWord` are fixed, so
the pair keeps its contrast whatever the app icon.

## The data

Word segments live in the reciter's own timing database — the file the app already
downloads and unzips for gapless reciters:

```sql
CREATE TABLE word_segments(sura int, ayah int, position int,
                           start_ms int, end_ms int,
                           primary key(sura, ayah, position, start_ms));
CREATE INDEX seg_idx on word_segments(sura, ayah);
```

`start_ms`/`end_ms` are already in the app's own audio timeline, and are half-open so a word
ends where the next begins. `position` is the mushaf glyph position, i.e. `Word.wordNumber`.
The primary key includes `start_ms` to allow the repeated spans described above.

Nothing is bundled into the app. A database without the table reads as "no timings" rather
than an error, so every existing one keeps working, and any gapless reciter gains
follow-along the moment its database carries the table — with no code change.

That matters for size: a complete table is ~79,000 rows, about **4 MB per reciter**. An
early draft bundled one into `QuranResources` at 460 KB, but that was generated against the
Example app's 39-sura `words.db` and is not what complete data costs.

### Where it comes from

quran.com serves word segments per recitation — id 6 is Al-Husary Murattal:

```
https://api.quran.com/api/qdc/audio/reciters/<id>/audio_files?chapter=N&segments=true
```

It returns 403 without a `User-Agent` header.

That API describes a **different encode** of the same recitation from the one the app plays
— re-trimmed, roughly 0.99x the length. The generator therefore anchors every ayah to the
app's own start/end times from the reciter database's `timings` table and rescales the
segments inside it. Ayah boundaries land exactly, and the sub-1% scale error over a 3-10s
ayah is well under one word.

**Word index to glyph position.** The API counts real words; the mushaf also counts waqf
marks and the ayah-end marker, and `words.db` stores NULL translation for exactly those. So
API word N maps to the Nth glyph position whose `words.db` translation is non-NULL. Verified
exact on 856 of 857 ayahs.

## What is needed

Two things: a reciter database carrying the table, and a `words.db` wide enough to generate
it.

**Upstream segment data is not the limit; gapless-only is.** Timings live in the reciter's
timing database, and only gapless reciters have one, so gapped reciters cannot be followed
at all. Among gapless ones, quran.com serves segments for all 14 of its recitations —
checked sura by sura for the two the Example app ships:

| Source | Coverage |
|---|---|
| quran.com segments, Al-Husary (id 6) | 114 / 114 suras, 79,040 segments |
| quran.com segments, AbdulBaset Mujawwad (id 1) | 114 / 114 suras, 76,307 segments |
| reciter ayah timings (`husary.db`) | all 114 |
| `words.db` bundled with the Example app | 39 (1, 2, 78-114) |

**`words.db` is the cap, for two reasons.** Generating the table needs it, to say which
mushaf glyph positions are real words rather than waqf marks; the popover needs it at
runtime for the translation. It is host-supplied through `AppDependencies.wordsDatabase` —
this engine never downloads it, and `reciters.plist` comes from the host bundle too, so
neither sura coverage nor the reciter list is knowable from this repo.

### Producing a fuller `words.db`

quran.com serves word-by-word translations for the whole Quran, not just the 39 suras the
Example app bundles — `qdc/verses/by_chapter/N?words=true&word_translation_language=en`
returns them for any sura. So the content exists; what has to be reconstructed is the
*mushaf glyph layout*: which positions are real words and which are waqf marks, since
`words.db` stores NULL translations for the latter.

Two routes were tried against the 39 suras there is ground truth for, and neither is good
enough to ship blind:

- **Glyph geometry.** The full glyph universe is already in the app
  (`hafs_1405_ayahinfo.db`, 88,246 glyphs, the same positions `words.db` uses), and each
  ayah's end marker is always its last glyph (857/857). Classifying the *interior* marks by
  glyph width reaches 99.75% (22 wrong of 8,966 glyphs).
- **The Uthmani text.** In `quran.ar.uthmani.v2.db`'s `arabic_text`, waqf marks are trailing
  characters on a word token, and a token ending in one of U+06D6, 06D7, 06D8, 06DA, 06DB,
  06DC or 06E9 takes an extra glyph position. That reproduces 817 of 857 ayahs exactly
  (95.3%).

Both leave errors, and one misclassified glyph shifts every following word in its ayah —
which means highlighting the wrong word of the Qur'an, silently. Neither rate can be
validated on suras 3–77, where there is no ground truth to check against. Use real
word-by-word data rather than either heuristic; they are recorded here only so the next
person does not repeat them.

### Producing a database

The generator lives outside this repo. It takes a `words.db` and a copy of the reciter
database, and writes `word_segments` into the copy:

```bash
cp husary.db husary-with-segments.db
python3 build_word_segments.py words.db husary-with-segments.db
```

With no sura list it attempts all 114 and reports which it could not do. Verify before
publishing — both must return 0:

```sql
select count(*) from word_segments where end_ms <= start_ms;
select count(*) from word_segments a join word_segments b
  on a.sura = b.sura and a.rowid <> b.rowid
 and b.start_ms < a.end_ms and b.start_ms > a.start_ms;   -- overlaps
```

### Known gaps in the generated data

Within the suras it covers, these degrade to "no highlight":

- **2:181** is absent entirely: the mushaf splits `بَعْدَ مَا` across two glyph positions, so
  `words.db` counts 14 words against quran.com's 13. The only such case.
- **2:245** has no span for word 1; **2:249** none for words 25-27.

### Timing accuracy

Measured against the decoded mp3s the app plays:

- **Words 2..n are essentially exact** — median error under 10 ms, and only 1 of 184
  mid-ayah words is off by more than 250 ms.
- **Word 1 of each ayah lights up 170-650 ms early.** Not a rescaling error: upstream, word
  1's span begins at the ayah boundary, so it covers the pause before the ayah. quran.com
  behaves the same way.

> Do not "fix" word 1 with a global offset — that would push the other 8,000+ words, which
> are accurate to a few milliseconds, equally late. Clamp only the first span of each ayah.

Sura 1's first word starts at 5,664 ms because the mp3 opens with a lead-in; nothing
highlights for the first ~5.6 seconds, which is correct.

## Adding another reciter

Nothing to change in the app: generate segments against **that reciter's** timing database
and publish it with the table in it. Any gapless reciter that is also one of quran.com's 14
recitations can be covered this way; one that is not would need segments from elsewhere.

## Tests

| Target | Covers |
|---|---|
| `QuranAudioTests` | `WordSegmentTimeline` — half-open boundaries, silence between words, repeated words, unordered input |
| `AudioTimingPersistenceTests` | reading a real fixture, an uncovered sura, and a database with no `word_segments` table |
| `AudioTimingServiceTests` | the reciter-to-database mapping through the real `localDatabasePath` |
| `AudioBannerFeatureTests` | the follower: sura changes mid-load, stop mid-load, retry after an unreadable database, suspend/resume |
| `QuranAudioKitTests` | the playhead reaching `QuranAudioPlayerActions` |

`DatabaseConnection` pools connections globally by URL, so a test that reuses a reciter path
with different contents is served the earlier database. These tests use a per-test directory.

Not covered, needing more scaffolding than the behaviour is worth: the toggle gate in
`QuranInteractor`, and the background/foreground handling in `AudioBannerViewModel`.
