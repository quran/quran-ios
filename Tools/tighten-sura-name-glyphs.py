#!/usr/bin/env python3
#
# Makes every decorated sura name glyph in surah_names.ttf sit flush in its box: both side bearings
# become 0, like the right side bearing almost was, instead of a 3.0–7.4 pt left bearing at 16 pt.
# The glyphs then behave like regular text: alignment and centering follow the ink, and the gaps come from
# the spacing around them.
#
# It also lowers the glyphs onto the system font's Arabic writing line. Measured as the centre of the
# stroke the letters sit on, the calligraphy's line was a median 149 units (of 1024) above the font's
# baseline, with no glyph-to-glyph pattern worth following, while the system font's Arabic sits its line
# 0.109 em above its own baseline. Beside text at the sizes MultipartText pairs them, 16/13, 19/15, 20/17
# and 24/20 pt, lowering every sura glyph by 58 units leaves the two lines at most 0.07 pt apart.
# DecoratedSuraNameGlyphTests measures this.
#
# Only the sura glyphs' outlines and horizontal metrics change; the font has no kerning, GPOS or hinting
# to update. The head and hhea extents and OS/2 xAvgCharWidth are recalculated; ascent and descent stay.
# Both moves target absolute positions, so running it again changes nothing.
#
# Usage:
#   python3 -m venv /tmp/fonttools && /tmp/fonttools/bin/pip install fonttools==4.68.0
#   /tmp/fonttools/bin/python Tools/tighten-sura-name-glyphs.py UI/NoorFont/Sources/Resources/surah_names.ttf

import statistics
import sys

from fontTools.ttLib import TTFont

# QuranReference.decoratedSuraNameCodePoints: 0xE900–0xE972 except 0xE903, an unused glyph left as it is.
SURA_CODE_POINTS = set(range(0xE900, 0xE973)) - {0xE903}

# The sura glyphs' median bottom once lowered: their tails' median was -44 units, and they move down 58.
MEDIAN_Y_MIN = -102


def tighten(path):
    font = TTFont(path, recalcTimestamp=False)
    unknown = set(font.keys()) - {
        "GlyphOrder", "OS/2", "cmap", "gasp", "glyf", "head", "hhea", "hmtx", "loca", "maxp", "name", "post",
    }
    if unknown:
        sys.exit(f"Unexpected tables that may need updating: {sorted(unknown)}")

    glyf = font["glyf"]
    hmtx = font["hmtx"]
    names = [name for code_point, name in font.getBestCmap().items() if code_point in SURA_CODE_POINTS]
    if len(names) != 114:
        sys.exit(f"Expected 114 sura glyphs, found {len(names)}")

    for name in names:
        glyph = glyf[name]
        if glyph.isComposite() or (hasattr(glyph, "program") and glyph.program.getBytecode()):
            sys.exit(f"{name} is composite or hinted")
        glyph.recalcBounds(glyf)

    # All glyphs move together, so neighbors in a list of names keep their relative heights.
    vertical_move = MEDIAN_Y_MIN - statistics.median_low(glyf[name].yMin for name in names)
    for name in names:
        glyph = glyf[name]
        width = glyph.xMax - glyph.xMin
        glyph.coordinates.translate((-glyph.xMin, vertical_move))
        glyph.recalcBounds(glyf)
        hmtx[name] = (width, 0)

    font["OS/2"].recalcAvgCharWidth(font)
    font.save(path)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} <surah_names.ttf>")
    tighten(sys.argv[1])
