#!/usr/bin/env python3
#
# Makes every decorated sura name glyph in surah_names.ttf sit flush in its box: both side bearings
# become 0, like the right side bearing almost was, instead of a 3.0–7.4 pt left bearing at 16 pt.
# The glyphs then behave like regular text: alignment and centering follow the ink, and the gaps come from
# the spacing around them.
#
# It also lowers the glyphs, all by the same amount, so the calligraphy's writing line meets the system
# font's Arabic writing line beside it at the sizes MultipartText pairs them: 15/12, 16/13, 19/15, 20/17
# and 24/20 pt. DecoratedSuraNameGlyphTests measures both lines.
#
# Then it fits the line box to the ink: the ascent reaches the tallest sura glyph's ink, so nothing draws
# above the line, and the descent puts the line box's middle on the glyphs' median ink centre, so a view
# that centres a glyph centres what you see. hhea, OS/2 typo and OS/2 win metrics all get these values,
# with no line gap; win metrics also cover the font's head bounds, as Windows clips to them.
#
# Only the sura glyphs' outlines, horizontal metrics and the line metrics change; the font has no kerning,
# GPOS or hinting to update. The head and hhea extents and OS/2 xAvgCharWidth are recalculated. Everything
# targets absolute positions measured from the outlines, so running it again changes nothing.
#
# Usage:
#   python3 -m venv /tmp/fonttools && /tmp/fonttools/bin/pip install fonttools==4.68.0
#   /tmp/fonttools/bin/python Tools/tighten-sura-name-glyphs.py UI/NoorFont/Sources/Resources/surah_names.ttf

import math
import statistics
import sys

from fontTools.pens.boundsPen import BoundsPen
from fontTools.ttLib import TTFont

# QuranReference.decoratedSuraNameCodePoints: 0xE900–0xE972 except 0xE903, an unused glyph left as it is.
SURA_CODE_POINTS = set(range(0xE900, 0xE973)) - {0xE903}

# The sura glyphs' median ink bottom once lowered: it was -44 units, and they move down 58.
# A median, so if a glyph change moves it, running this again moves every glyph to put it back.
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
    # Distinct glyphs, so one that several code points share isn't moved twice.
    names = sorted({name for code_point, name in font.getBestCmap().items() if code_point in SURA_CODE_POINTS})
    if len(names) != 114:
        sys.exit(f"Expected 114 distinct sura glyphs, found {len(names)}")

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

    fit_line_box(font, names)
    font["OS/2"].recalcAvgCharWidth(font)
    font.save(path)


def fit_line_box(font, names):
    glyph_set = font.getGlyphSet()
    ink = []
    for name in names:
        pen = BoundsPen(glyph_set)
        glyph_set[name].draw(pen)
        ink.append(pen.bounds)
    ascent = math.ceil(max(y_max for _, _, _, y_max in ink))
    median_center = statistics.median((y_min + y_max) / 2 for _, y_min, _, y_max in ink)
    descent = round(2 * median_center) - ascent

    glyf = font["glyf"]
    outlines = [glyf[name] for name in font.getGlyphOrder() if glyf[name].numberOfContours]
    for glyph in outlines:
        glyph.recalcBounds(glyf)
    font_y_min = min(glyph.yMin for glyph in outlines)
    font_y_max = max(glyph.yMax for glyph in outlines)

    hhea = font["hhea"]
    hhea.ascent, hhea.descent, hhea.lineGap = ascent, descent, 0
    os2 = font["OS/2"]
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = ascent, descent, 0
    os2.usWinAscent = max(ascent, font_y_max)
    os2.usWinDescent = max(-descent, -font_y_min)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} <surah_names.ttf>")
    tighten(sys.argv[1])
