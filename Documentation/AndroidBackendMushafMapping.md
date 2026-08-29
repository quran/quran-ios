# Android and Backend Mushaf Mapping

This document describes how `quran_android` and `quran.com-users-backend` map
pages and verses between Mushaf layouts and verse-counting systems.

The source revisions reviewed are:

- Android: [`3bc82026962f0bf5e30ee0866915bf6372b1c542`](https://github.com/quran/quran_android/tree/3bc82026962f0bf5e30ee0866915bf6372b1c542)
- Backend: [`925ac438cd5c883545543f68218c760406cce70d`](https://github.com/quran/quran.com-users-backend/tree/925ac438cd5c883545543f68218c760406cce70d)

## Concepts

Page layout and verse counting are separate concerns.

A **page layout** determines which verses appear on each page. Two layouts can
contain the same verse coordinates while having different page counts or page
boundaries.

A **verse-counting system** determines where verse boundaries occur and how
those verses are numbered. A different total does not mean that Quran text is
missing. The same text may be split or joined differently.

The codebases currently contain these verse totals:

| Verse count | Counting system | Current use |
| ---: | --- | --- |
| 6,236 | Kufi | Hafs layouts, including Madani and IndoPak; the backend's only configured verse group |
| 6,214 | Madani | Android mapping support for some Warsh/Qaloon Mushafs |

No other verse totals are configured in either codebase.

## Summary

| Concern | Android | Backend |
| --- | --- | --- |
| Canonical page storage | Madani page coordinates when that provider is available | No single canonical page layout; stores the original page and a page-count group |
| Cross-layout page anchor | Representative middle ayah, plus first and last ayahs | First verse of the source page |
| Page candidate selection | Prefers candidates whose representative ayah maps back to the source page | Takes the first target page returned for the source page's first verse |
| Exact page round trip | Preferred when a candidate permits it, but not guaranteed | Not guaranteed by the mapper; original record identity avoids needing a reverse map for deletion |
| Verse groups | 6,236 and an implemented 6,214 ↔ 6,236 mapper | Only `verses_6236` |
| Non-identity verse mapping | Offset, split, and join operations | Not implemented |

## Android page mapping

### Canonical storage layout

`ReadingBookmarkPageMapper` normally uses the `madani` page provider as its
canonical storage layout. It falls back to another registered provider if
`madani` is unavailable.

The mapper exposes conversions in both directions:

- Current page type → storage page
- Storage page → current page type
- Imported source page type → storage page

See [`ReadingBookmarkPageMapper`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarkPageMapper.kt#L33-L63) and its canonical page-type selection at [lines 152–177](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarkPageMapper.kt#L152-L177).

### Page-selection algorithm

For a source page and destination layout, Android:

1. Clamps the source page to a valid page.
2. Reads the source page's first and last ayah.
3. Calculates a representative ayah at the midpoint of the page's global ayah
   range.
4. Finds the destination pages containing the first, last, and representative
   ayahs.
5. Builds every valid destination page between the minimum and maximum of those
   three pages.
6. Filters the candidates to pages whose own representative ayah maps back to
   the original source page.
7. Uses those round-trip candidates when any exist; otherwise, it uses the full
   candidate list.
8. Chooses the candidate numerically closest to the representative ayah's
   destination page.

The implementation is in [`ReadingBookmarkPageMapper.mapPage`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarkPageMapper.kt#L86-L120).

The round-trip filter is a preference rather than a guarantee. When layouts
have different numbers of pages, multiple source pages can necessarily map to
the same canonical page. No stateless mapper can make every such conversion
bijective.

The page mapper also uses `SuraAyah` coordinates directly; it does not invoke
Android's 6,214 ↔ 6,236 verse mapper. Cross-layout page mapping therefore
assumes compatible verse numbering unless a caller normalizes coordinates
separately.

### Page reading bookmarks

When Android saves a page reading bookmark, it maps the visible page to the
canonical storage page first. When it reads the bookmark, it maps the stored
page into the currently selected page type. Toggling the bookmark also compares
canonical storage pages.

See [`ReadingBookmarksDaoImpl`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarksDaoImpl.kt#L64-L109) and the read conversion at [lines 112–127](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarksDaoImpl.kt#L112-L127).

### Recent pages

Android handles recent pages differently from page reading bookmarks. It stores
a reading session using the first sura/ayah of the current page. When recent
pages are displayed, that stored coordinate is resolved in the current
`QuranInfo` to obtain a page.

See the write path in [`RecentPagesDaoImpl`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/RecentPagesDaoImpl.kt#L115-L129) and the read path at [lines 167–189](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/RecentPagesDaoImpl.kt#L167-L189).

This preserves a Quran position rather than a canonical page number, although
the displayed page can change when the page boundaries change.

## Android verse mapping

### Supported counting systems

Android's standard Hafs data contains 6,236 verse coordinates. The array is in
[`MadaniDataSource`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/pages/data/madani/src/main/kotlin/com/quran/labs/androidquran/pages/data/madani/MadaniDataSource.kt#L105-L114).

Android also contains a Warsh data source whose per-sura counts total 6,214.
See [`WarshDataSource`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/pages/data/warsh/src/main/kotlin/com/quran/labs/androidquran/pages/data/warsh/WarshDataSource.kt#L6-L18).

There is a naming ambiguity in the Android code:

- `MadaniDataSource` describes the standard Madani **page layout**, but uses
  the 6,236 Kufi verse count.
- `MadaniToKufiMapper` uses “Madani” to describe the 6,214 **verse-counting
  system**.

### Mapper shape

`AyahMapper` maps a current-counting coordinate to a list of Kufi coordinates,
and maps a Kufi coordinate back to a list of current-counting coordinates. A
list is necessary because the relationship is not always one-to-one.

See the [`AyahMapper` contract](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/data/src/main/java/com/quran/data/pageinfo/mapper/AyahMapper.kt#L7-L27).

`MadaniToKufiMapper` supports:

- **Range offset:** one verse maps to one verse with a different number.
- **Split:** one 6,214 verse maps to two or three 6,236 verses.
- **Join:** two 6,214 verses map to one 6,236 verse.

The reverse mapping is created by reversing those operations. See
[`MadaniToKufiMapper`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/mapper/src/main/kotlin/com/quran/labs/androidquran/common/mapper/MadaniToKufiMapper.kt#L20-L52) and its operation reversal at [lines 103–145](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/mapper/src/main/kotlin/com/quran/labs/androidquran/common/mapper/MadaniToKufiMapper.kt#L103-L145).

Examples from the mapping table:

| 6,214 Madani coordinate | 6,236 Kufi coordinate(s) |
| --- | --- |
| `1:1` | `1:2` |
| `1:6` | `1:7` |
| `1:7` | `1:7` |
| `2:1` | `2:1`, `2:2` |
| `2:199` | `2:200`, `2:201` |
| `2:253` | `2:255` |
| `2:254` | `2:255` |

The table begins in [`MadaniToKufiMap`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/mapper/src/main/kotlin/com/quran/labs/androidquran/common/mapper/MadaniToKufiMap.kt#L3-L23), with forward and reverse examples covered by [`MadaniToKufiMapperTest`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/mapper/src/test/kotlin/com/quran/labs/androidquran/common/mapper/MadaniToKufiMapperTest.kt#L12-L105).

### Current consumers

The standard Madani application module provides `IdentityAyahMapper`, so Hafs
coordinates pass through unchanged. See [`QuranDataModule`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/pages/madani/src/main/java/com/quran/data/page/provider/QuranDataModule.kt#L52-L58).

`TranslationModelImpl` uses the configured ayah mapper to query Kufi-numbered
translation databases and then map the returned data back to the current
counting system. See [`TranslationModelImpl`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/app/src/main/java/com/quran/labs/androidquran/model/translation/TranslationModelImpl.kt#L24-L52).

The mobile-sync ayah reading bookmark path does not currently call
`AyahMapper`; it stores and reads the supplied sura/ayah directly. See
[`ReadingBookmarksDaoImpl`](https://github.com/quran/quran_android/blob/3bc82026962f0bf5e30ee0866915bf6372b1c542/common/bookmark/src/main/java/com/quran/mobile/bookmark/model/ReadingBookmarksDaoImpl.kt#L73-L79).

## Backend page mapping

### Storage model

The backend does not normalize every page bookmark into one canonical page
layout. It stores:

- A stable bookmark ID
- The original page number in `key`
- A bookmark group
- Whether the record is the singular reading bookmark

See the [`Bookmark` entity](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/packages/database/src/entities/Bookmark.ts#L22-L83).

Page groups are based on page count:

| Group | Mushaf category |
| --- | --- |
| `pages_604` | Default layouts |
| `pages_610` | IndoPak 15-line |
| `pages_548` | IndoPak 16-line |

See [`mushaf.ts`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/utils/mushaf.ts#L3-L35).

The group records a page-count class, not the exact Mushaf ID. Layouts in the
same page-count group are treated as page-compatible and are not mapped.

### Cross-group mapping

When mapping a page between different groups, the backend:

1. Fetches the verses on the source page from the Quran.com content API.
2. Takes the first verse of the source page.
3. Looks up the target page containing that verse.
4. Returns the first target page from the lookup.

See [`mapPage`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/services/mushafMapping.ts#L62-L117).

When bookmarks are read for a target Mushaf, the backend skips mapping if the
stored group equals the target group. Otherwise, it chooses a representative
source Mushaf for the stored group and applies `mapPage` to the returned
bookmark. See [`mapBookmarksToMushaf`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/services/bookmarks.ts#L228-L277).

The mapper itself is lossy and does not attempt round-trip validation. The
backend instead retains a stable bookmark record and deletes bookmarks by ID,
not by reverse-mapping the displayed page. See [`deleteBookmark`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/services/bookmarks.ts#L399-L410).

### Limitations

- Multiple source pages can map to the same target page.
- A target page is selected using only the source page's first verse.
- Grouping by page count assumes that all layouts with the same count are page
  compatible.
- The mapper does not guarantee `source → target → source` equality.

## Backend verse mapping

### Configured verse groups

The backend's default verse count is 6,236, and its exception map is empty.
Every currently supported Mushaf therefore receives the `verses_6236` group.

See [`mushaf.ts`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/utils/mushaf.ts#L3-L20).

The backend Mushaf enum currently contains Hafs-compatible Madani, IndoPak,
Uthmani, and Tajweed variants. It does not contain a Warsh or Qaloon Mushaf.
See [`Mushaf.ts`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/packages/types/src/preferences/Mushaf.ts#L1-L11).

### Current mapping behavior

`mapVerse` currently preserves the source sura and verse numbers. For different
Mushaf IDs, it looks up that same verse key in the target Mushaf to obtain its
page number. It does not perform offsets, splits, or joins.

See [`mapVerse`](https://github.com/quran/quran.com-users-backend/blob/925ac438cd5c883545543f68218c760406cce70d/apps/api/src/services/mushafMapping.ts#L119-L166).

Because every configured Mushaf is in `verses_6236`, the normal bookmark read
path sees the stored and target verse groups as equal and returns the bookmark
without invoking cross-group mapping.

Adding a `verses_6214` group would require more than adding the count to the
configuration map. The backend would also need a semantic mapper capable of
returning multiple target verses for split and join cases, similar to Android's
`MadaniToKufiMapper`.

## Practical comparison

For the Hafs layouts currently supported by iOS—Madani 1405, Madani 1440, and
IndoPak—verse coordinates are compatible 6,236 Kufi coordinates. Verse mapping
between them is therefore identity mapping; only page boundaries require
mapping.

Android has the more sophisticated page-selection algorithm, using midpoint,
boundary, and reverse-candidate checks. The backend has the more stateful
bookmark identity model, retaining an original page group and stable bookmark
ID while using a simpler first-verse display mapping.

Android also has the only implemented non-identity verse mapper. The backend's
verse-group design anticipates additional counting systems, but only 6,236 is
currently configured and mapped.
