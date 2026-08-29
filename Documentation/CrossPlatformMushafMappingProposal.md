# Cross-Platform Mushaf Mapping Proposal

## Meeting goal

Agree on one storage and mapping model for iOS, Android, web, and backend so
bookmarks and reading positions continue to work when a user switches Mushafs.

Suggested 15-minute agenda:

1. Problem and examples — 3 minutes
2. Proposed model — 5 minutes
3. Team responsibilities — 3 minutes
4. Decisions and next steps — 4 minutes

## Concepts and current inventory

A Mushaf combines two independent pieces of metadata:

- **Verse-counting system:** defines verse boundaries and verse numbers.
- **Page layout:** defines page boundaries and page numbers.

The same verse-counting system can be used by layouts with different page
counts.

### Verse-counting systems

| ID | Total verses | Known use |
| --- | ---: | --- |
| `kufi-6236` | 6,236 | All current iOS and backend Mushafs; standard Android Hafs |
| `madani-6214` | 6,214 | Android Warsh data; Android's mapper notes use by some Warsh/Qaloon Mushafs |

The backend also declares a `verses_6348` group, but no supported Mushaf is
assigned to it. We should confirm whether it is legacy or planned before making
it part of the shared model.

### Page layouts

| Proposed ID | Pages | Verse counting | Current or historical use |
| --- | ---: | --- | --- |
| `madani-1405-604` | 604 | Kufi 6,236 | iOS; canonical iOS storage layout |
| `madani-1440-604` | 604 | Kufi 6,236 | iOS |
| `indopak-15-610` | 610 | Kufi 6,236 | iOS and backend catalog |
| `indopak-16-548` | 548 | Kufi 6,236 | Backend catalog |
| `shemerly-521` | 521 | Kufi 6,236 | Historical Android support |
| `warsh-604` | 604 | Madani 6,214 | Android data and tests |

Equal page counts do not prove that two layouts have equal page boundaries.

## Problem

Today, parts of the system store only a page number or only a sura and ayah.
Those values are meaningful only when their original layout or counting system
is known.

### Different verse counting

One verse can become several verses in another counting system:

```text
Madani 6,214: Al-Baqarah 2:1
                     ↓
Kufi 6,236:   Al-Baqarah 2:1 and 2:2
```

A verse mapper must therefore return a list, even when most mappings return one
verse.

### Different page layouts

A page in a 610-page layout can overlap more than one page in a 604-page
layout. Multiple source pages can also map to the same destination page.
Therefore this operation is not always reversible:

```text
source page → displayed page → source page
```

This becomes a user-data bug when deletion tries to identify a bookmark by
reverse-mapping the displayed page.

## Proposal

### 1. Give every Mushaf explicit metadata

Use permanent shared IDs across all platforms:

```json
{
  "id": "hafs-indopak-15",
  "verseCountingSystemId": "kufi-6236",
  "pageLayoutId": "indopak-15-610"
}
```

### 2. Store the original location

Every user record stores its stable ID, source Mushaf, and original location:

```json
{
  "id": "bookmark-123",
  "sourceMushafId": "warsh-madani",
  "kind": "verse",
  "location": { "sura": 2, "ayah": 1 }
}
```

For a page bookmark, `location` contains its original page number. Switching
Mushafs does not rewrite the stored record.

### 3. Map only when presenting in another Mushaf

```text
stored source location
        ↓
selected Mushaf metadata
        ↓
shared verse/page mapping
        ↓
displayed location
```

- When verse-counting IDs match, verse mapping is identity.
- When they differ, return every mapped destination verse.
- When page-layout IDs match, page mapping is identity.
- When they differ, return one primary destination page for navigation.
- A page result may optionally retain all overlapping pages for future UI use.

### 4. Mutate records by stable ID

Delete and update `bookmark-123`; never delete by a mapped page or verse
number. If multiple records appear on the same destination page, the
presentation model must retain every underlying record ID.

## Shared mapping data

All platforms should consume the same versioned data contract:

```text
Verse mapping:
    source counting + source sura/ayah
    destination counting
    → destination sura/ayah list

Page mapping:
    source layout + source page
    destination layout
    → primary destination page
```

Mappings may be generated rather than handwritten, but their published results
must be deterministic and versioned. Tests should cover every verse in every
counting system and every page in every layout.

## Responsibilities

| Owner | Responsibility |
| --- | --- |
| Shared data owner | Maintain Mushaf registry, mapping tables, versions, and completeness tests |
| Backend | Store source Mushaf/location and stable IDs; sync without rewriting locations |
| iOS, Android, web | Resolve stored records for the selected Mushaf and display its local numbers |
| All clients and backend | Use the same mapping version and delete/update only by record ID |

## Decisions needed

1. Who owns and publishes the shared Mushaf registry and mapping data?
2. Do clients resolve mappings locally, does the backend resolve them, or do
   both use the same shared package/data file?
3. Should page results expose only a primary page or also all overlapping
   pages?
4. How do we infer the source Mushaf for existing records that do not store it?
5. Is the unused backend `verses_6348` group still required?

## Proposed first step

Publish the shared Mushaf registry and verified mapping fixtures for the two
known counting systems and the six known page layouts. Then add source Mushaf
IDs and stable-ID mutation to the storage contract before adding another
Mushaf to any client.
