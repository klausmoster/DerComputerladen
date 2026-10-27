"""Erzeugt die Hauptpalette: 1 Transparenz + 15 Oberflächenfarben + 240 Szenenfarben per Median-Cut.

Die Szenenfarben kommen aus den freigegebenen Bildern, jedes vorher per Flächenmittel auf seine
Endgröße verkleinert, damit die Palette zu den Mischfarben der Rasterfassung passt. Jedes Bild
zählt gleich viel, egal wie groß es ist. Die Palette wird danach eingefroren: Das Skript
überschreibt eine vorhandene Palette nur mit --neu.

Aufruf vom Repo-Root:  python3 -I tools/raster/make_palette.py
"""
import argparse
import datetime
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pngio  # noqa: E402

# Die 15 Oberflächenfarben aus tokens.json des Style-Guides, in dessen Reihenfolge. Die 16. Farbe
# `lcd` (Feature 005) gehört nicht hinein: Sie kommt in keinem Bild vor, die Oberfläche malt sie
# über das Gehäuse des Communicators.
UI_COLORS = [
    ("tusche", "#1d1916"),
    ("nacht", "#18233b"),
    ("nacht-hell", "#2c3d63"),
    ("gehaeuse-dunkel", "#6f6654"),
    ("gehaeuse", "#bdb39a"),
    ("gehaeuse-hell", "#e4dcc6"),
    ("papier", "#f5f0e2"),
    ("endlos-gruen", "#cfe2c3"),
    ("anzeige-grund", "#0d1716"),
    ("anzeige", "#6ff0cf"),
    ("kassenrot", "#c0392b"),
    ("signalgelb", "#f2bf2f"),
    ("petrol", "#1f6f75"),
    ("holz", "#8b5a34"),
    ("holz-dunkel", "#57351d"),
]
TRANSPARENT = ((255, 0, 255), "Transparenz")
SCENE_COLORS = 240

DEFAULT_SOURCES = [
    "docs/art/leonardo/stilanker-c2.jpg=320x180",
    "docs/art/leonardo/t-01-titelbild.jpg=320x180",
    "docs/art/leonardo/c-01-cover.jpg=300x450",
]


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def median_cut(weights, count):
    """Teilt den Farbraum, bis count Kästen da sind; je Kasten das gewichtete Mittel."""
    def stats(box):
        total = sum(w for _, w in box)
        ranges = [max(c[ch] for c, _ in box) - min(c[ch] for c, _ in box) for ch in range(3)]
        return total, ranges

    boxes = [(list(weights.items()),) + stats(list(weights.items()))]
    while len(boxes) < count:
        candidates = [(max(r) * total ** 0.5, i) for i, (box, total, r) in enumerate(boxes) if len(box) > 1]
        if not candidates:
            break
        _, i = max(candidates)
        box, total, ranges = boxes.pop(i)
        ch = ranges.index(max(ranges))
        box.sort(key=lambda e: e[0][ch])
        half, acc, k = total / 2, 0.0, 0
        while k < len(box) - 1 and acc + box[k][1] < half:
            acc += box[k][1]
            k += 1
        k = max(1, k)
        for part in (box[:k], box[k:]):
            boxes.append((part,) + stats(part))
    result = []
    for box, total, _ in boxes:
        result.append(tuple(round(sum(c[ch] * w for c, w in box) / total) for ch in range(3)))
    return result


def sort_for_display(colors):
    """Graustufen zuerst, dann nach Farbton in 30°-Schritten, je Gruppe von dunkel nach hell."""
    def key(rgb):
        hue, chroma = pngio.hue_and_chroma(rgb)
        lightness = pngio.oklab(rgb)[0]
        group = -1 if chroma < 0.04 else int(hue // 30)
        return (group, lightness)
    return sorted(colors, key=key)


def write_gpl(path, entries, sources):
    today = datetime.date.today().isoformat()
    lines = [
        "GIMP Palette",
        "Name: Computerladen Hauptpalette",
        "Columns: 16",
        f"# Eingefroren am {today}. Neue Szenen werden auf diese Palette gerechnet, nicht umgekehrt.",
        "# Index 0: Transparenz (im indizierten PNG per tRNS durchsichtig).",
        "# Index 1-15: Oberflächenfarben aus dem Style-Guide.",
        "# Index 16-255: Szenenfarben per Median-Cut aus: " + ", ".join(sources),
        "#",
    ]
    for (r, g, b), name in entries:
        lines.append(f"{r:3d} {g:3d} {b:3d}\t{name}")
    open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def write_swatch(path, entries, cell=16, columns=16):
    rows = (len(entries) + columns - 1) // columns
    width, height = columns * cell, rows * cell
    papier, hell = hex_rgb("#f5f0e2"), hex_rgb("#e4dcc6")
    pixels = []
    for y in range(height):
        for x in range(width):
            i = (y // cell) * columns + x // cell
            if i >= len(entries):
                pixels.append((0, 0, 0, 0))
            elif i == 0:
                pixels.append(papier + (255,) if (x // 4 + y // 4) % 2 else hell + (255,))
            else:
                pixels.append(entries[i][0] + (255,))
    pngio.write_png_rgba(path, width, height, pixels)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("quellen", nargs="*", default=DEFAULT_SOURCES,
                        help="Bild=BreitexHöhe, Endgröße in Bildpixeln")
    parser.add_argument("--gpl", default="docs/art/hauptpalette.gpl")
    parser.add_argument("--png", default="docs/art/hauptpalette.png")
    parser.add_argument("--neu", action="store_true", help="vorhandene, eingefrorene Palette überschreiben")
    args = parser.parse_args()

    if os.path.exists(args.gpl) and not args.neu:
        sys.exit(f"{args.gpl} ist eingefroren. Nur mit --neu überschreiben.")

    weights = Counter()
    names = []
    for source in args.quellen:
        path, size = source.rsplit("=", 1)
        target_w, target_h = (int(v) for v in size.lower().split("x"))
        image = pngio.decode(path)
        factor, off_x, off_y = pngio.fit(image[0], image[1], target_w, target_h)
        pixels = pngio.box_average(image, target_w, target_h, factor, off_x, off_y)
        share = 1 / len(pixels)
        for p in pixels:
            weights[p[:3]] += share
        names.append(os.path.basename(path))
        print(f"{os.path.basename(path)}: {image[0]} × {image[1]} → {target_w} × {target_h} (Faktor {factor})")

    scene = sort_for_display(median_cut(weights, SCENE_COLORS))
    entries = [TRANSPARENT] + [(hex_rgb(v), n) for n, v in UI_COLORS]
    entries += [(c, f"szene-{i:03d}") for i, c in enumerate(scene, start=1)]
    write_gpl(args.gpl, entries, names)
    write_swatch(args.png, entries)
    print(f"{len(entries)} Farben: {args.gpl}, Farbtafel {args.png}")


if __name__ == "__main__":
    main()
