# IndoPak local page-location verification

Date: August 28, 2026

Result: **Pass**

Scope: non-sync Core Data page bookmarks and recent pages. The private app was built against the local `quran-ios` package.

| Scenario | Coverage | Result |
| --- | --- | --- |
| Every page in every reading | All 7 readings as source and destination: 4,234 native pages and 29,638 source/destination combinations for bookmarks, repeated for recent pages | No stored page was lost or duplicated; every presented page belonged to the selected reading |
| Exact layout identity | `madani1405 = 0`, `madani1440 = 1`, `indoPak = 2` | Each reading stored its actual metadata layout; legacy rows remained Madani 1405 |
| Ambiguous Madani page number | Madani 1405 page 585 and Madani 1440 page 585 presented in IndoPak | They correctly remained distinct: IndoPak pages 591 and 590 |
| Multiple stored pages shown as one page | IndoPak/Madani collision groups for bookmarks and recent pages | The presented item retained every underlying native page |
| Unbookmark a grouped page | Removed every presented bookmark group in the exhaustive matrix; also tested real Core Data batch deletion | Every underlying page was deleted |
| Update a grouped recent page | Multiple source pages mapped to one displayed page, then moved to a new page | The sources collapsed into one destination row |
| Same page number in every layout | Stored page 300 as Madani 1405, Madani 1440, and IndoPak in real Core Data | They remained separate and could be deleted or updated independently |
| Legacy migration | Opened a temporary V1 SQLite store with the current Core Data model | Existing bookmark and recent-page rows migrated with `mushafID = 0` (Madani 1405) |
| Page mapper | Every page between Madani 1405 (604 pages), Madani 1440 (604 pages), and IndoPak (610 visible pages, numbered 2–611) | All pages mapped successfully; equal-sized layouts also round-tripped exactly |
| Private app smoke test | Built and launched `../quran-ios-private`; checked all 7 Mushaf choices | Five Uthmani readings, Tajweed, and IndoPak were available; IndoPak reported 610 pages |
| Existing recent pages across live switches | Madani 1405 → IndoPak → Madani 1405, followed by Madani 1440 | IndoPak presentation mapped correctly; both Madani layouts restored the original page numbers |

Automated run: **49 tests passed, 0 failed** on iPhone 17 Pro, iOS 26.0 Simulator. The full no-sync annotations target also passed. The private app built and launched on iPhone 17e, iOS 26.5 Simulator.

This verification does not cover iCloud or MobileSync because the change is intentionally limited to local, non-sync Core Data.
