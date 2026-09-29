#!/bin/bash
#
# Renders an Icon Composer icon into an asset catalog image set, so the icon
# stays the only source of its artwork.
#
# Usage:
#   Tools/export-app-icon-images.sh preview <icon.icon> <name.imageset> <points>
#   Tools/export-app-icon-images.sh artwork <icon.icon> <name.imageset> <pixels>
#
# preview: the icon as the Home Screen draws it, rounded, at <points> @3x. Writes the
#   default appearance, and the dark appearance only when it differs visibly.
# artwork: the icon's default appearance as an opaque square of <pixels>, with its
#   Liquid Glass but without the rounded mask, for artwork such as Now Playing.
#
# Writes 8-bit PNGs in the render's color space, then the image set's Contents.json.
# Needs Xcode 26 or later for ictool.

set -euo pipefail

if [ $# -ne 4 ] || { [ "$1" != "preview" ] && [ "$1" != "artwork" ]; }; then
    echo "Usage: $0 preview|artwork <icon.icon> <name.imageset> <points|pixels>" >&2
    exit 1
fi

mode=$1
icon=$2
imageset=$3
size=$4
name=$(basename "$imageset" .imageset)
ictool=${ICTOOL:-"$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"}

if [ ! -x "$ictool" ]; then
    echo "ictool not found at $ictool. Set ICTOOL or select Xcode 26 or later." >&2
    exit 1
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# render <icon> <rendition> <points> <scale> <output>
render() {
    "$ictool" "$1" --export-image --output-file "$5" --platform iOS --rendition "$2" \
        --width "$3" --height "$3" --scale "$4" > /dev/null
}

# Re-encodes ictool's 16-bit PNGs at 8 bits, which look the same at a fraction of the size.
#   compare <default.png> <dark.png> <default-out.png> <dark-out.png>: prints whether they differ.
#   crop <input.png> <output.png> <pixels>: keeps the centered square, opaque.
pngs() {
    xcrun swift - "$@" <<'SWIFT'
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Draws `rect` of the PNG into an 8-bit bitmap, writes it to `output`, and returns its pixels.
func reencode(_ input: String, to output: String, cropping size: Int? = nil) -> [UInt8] {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: input) as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let width = size ?? image.width
    let height = size ?? image.height
    // Keep the color space of the render (Display P3), so wide-gamut colors survive.
    let alpha = size == nil ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: image.colorSpace!, bitmapInfo: alpha.rawValue
    )!
    let origin = CGPoint(x: (width - image.width) / 2, y: (height - image.height) / 2)
    context.draw(image, in: CGRect(origin: origin, size: CGSize(width: image.width, height: image.height)))
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil
    )!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    let bytes = context.data!.bindMemory(to: UInt8.self, capacity: width * height * 4)
    return Array(UnsafeBufferPointer(start: bytes, count: width * height * 4))
}

let arguments = CommandLine.arguments
switch arguments[1] {
case "compare":
    let light = reencode(arguments[2], to: arguments[4])
    let dark = reencode(arguments[3], to: arguments[5])
    // Rendering noise stays within a couple of levels; real dark artwork differs by more.
    let maxDifference = zip(light, dark).map { abs(Int($0) - Int($1)) }.max() ?? 0
    print(maxDifference > 2 ? "yes" : "no")
default:
    _ = reencode(arguments[2], to: arguments[3], cropping: Int(arguments[4])!)
}
SWIFT
}

mkdir -p "$imageset"
rm -f "$imageset"/*.png
dark_differs=no

if [ "$mode" = "preview" ]; then
    render "$icon" Default "$size" 3 "$scratch/default.png"
    render "$icon" Dark "$size" 3 "$scratch/dark.png"
    dark_differs=$(pngs compare "$scratch/default.png" "$scratch/dark.png" \
        "$imageset/$name.png" "$scratch/dark-8bit.png")
    description="default at ${size}pt @3x"
    if [ "$dark_differs" = "yes" ]; then
        mv "$scratch/dark-8bit.png" "$imageset/$name-dark.png"
        description="default and dark at ${size}pt @3x"
    fi
else
    # ictool always rounds the icon, and lights its rim. Shrinking every layer to two
    # thirds on a canvas half as large again moves both out of the centered square,
    # which then holds the artwork at its usual proportions, glass and all.
    cp -R "$icon" "$scratch/artwork.icon"
    /usr/bin/python3 - "$scratch/artwork.icon/icon.json" <<'PYTHON'
import json
import sys

path = sys.argv[1]
icon = json.load(open(path))
for group in icon["groups"]:
    for layer in group["layers"]:
        position = layer.setdefault("position", {})
        position["scale"] = position.get("scale", 1) * 2 / 3
        position["translation-in-points"] = [
            value * 2 / 3 for value in position.get("translation-in-points", [0, 0])
        ]
json.dump(icon, open(path, "w"), indent=2)
PYTHON
    render "$scratch/artwork.icon" Default $((size * 3 / 2)) 1 "$scratch/artwork.png"
    pngs crop "$scratch/artwork.png" "$imageset/$name.png" "$size"
    description="opaque ${size}px square with Liquid Glass"
fi

dark_image=""
if [ "$dark_differs" = "yes" ]; then
    dark_image=$(cat <<JSON
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "$name-dark.png",
      "idiom" : "universal"
    },
JSON
)
fi

cat > "$imageset/Contents.json" <<JSON
{
  "images" : [
    {
      "filename" : "$name.png",
      "idiom" : "universal"
    }${dark_image:+,
${dark_image%,}}
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "$name: $description"
