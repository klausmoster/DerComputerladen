"""Räumt ein gerastertes Bild grob auf: Farbreste und Einzelpixel, nach festen Regeln.

Der grobe Feinschliff nach rasterize.py, als Regel statt von Hand:
- Farbreste: Eine Farbe mit höchstens --rest Pixeln im Bild wird durch die nächste häufigere
  Farbe ersetzt, wenn diese ähnlich ist (OKLab-Abstand bis --rest-abstand).
- Einzelpixel: Ein Pixel, dessen Farbe keiner seiner acht Nachbarn hat, bekommt die häufigste
  Farbe seiner Nachbarn, wenn er ihr ähnlich ist (OKLab-Abstand unter --naehe). Kräftige
  Einzelheiten wie Lichter, Kanten und Schrift bleiben so stehen.
Durchsichtige Pixel bleiben, wie sie sind. Das Bild bleibt indiziert auf der Hauptpalette, Name
und Größe bleiben gleich.

Aufruf vom Repo-Root:
  python3 -I tools/raster/cleanup.py src/assets/images/title_t01.png
  python3 -I tools/raster/cleanup.py src/assets/images/logo_ladenschild.png
"""
import argparse
import math
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pngio  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("bild", help="indiziertes PNG auf der Hauptpalette, wird überschrieben")
    parser.add_argument("--palette", default="docs/art/hauptpalette.gpl")
    parser.add_argument("--rest", type=int, default=3, help="Farben mit höchstens so vielen Pixeln gelten als Rest")
    parser.add_argument("--rest-abstand", type=float, default=0.10, help="größter OKLab-Abstand für einen Farbrest")
    parser.add_argument("--naehe", type=float, default=0.05, help="OKLab-Abstand, unter dem ein Einzelpixel angeglichen wird")
    parser.add_argument("--vorschau", help="zusätzlich vorher und nachher nebeneinander, vergrößert")
    parser.add_argument("--zoom", type=int, default=4)
    args = parser.parse_args()

    palette = [rgb for rgb, _ in pngio.read_gpl(args.palette)]
    lab = [pngio.oklab(rgb) for rgb in palette]
    index_of = {}
    for i, rgb in enumerate(palette):
        if i:
            index_of.setdefault(rgb, i)

    width, height, channels, rows = pngio.read_png(args.bild)
    before = []
    for row in rows:
        for x in range(width):
            p = tuple(row[x * channels:x * channels + channels])
            if channels == 4 and p[3] < 128:
                before.append(0)
            elif p[:3] in index_of:
                before.append(index_of[p[:3]])
            else:
                raise SystemExit(f"{args.bild}: Farbe {p[:3]} steht nicht in der Hauptpalette")

    # Farbreste: auf die nächste häufigere Farbe, wenn sie nah genug ist.
    counts = Counter(i for i in before if i)
    common = [i for i, n in counts.items() if n > args.rest]
    remap = {}
    for i, n in counts.items():
        if n <= args.rest and common:
            nearest = min(common, key=lambda c: math.dist(lab[i], lab[c]))
            if math.dist(lab[i], lab[nearest]) <= args.rest_abstand:
                remap[i] = nearest
    pixels = [remap.get(i, i) for i in before]
    rest_changed = sum(1 for a, b in zip(before, pixels) if a != b)

    # Einzelpixel: Entscheidungen auf dem Stand vor diesem Schritt, damit nichts nachrutscht.
    result = list(pixels)
    for y in range(height):
        for x in range(width):
            i = pixels[y * width + x]
            if not i:
                continue
            neighbors = [pixels[ny * width + nx]
                         for ny in range(max(0, y - 1), min(height, y + 2))
                         for nx in range(max(0, x - 1), min(width, x + 2))
                         if (nx, ny) != (x, y) and pixels[ny * width + nx]]
            if not neighbors or i in neighbors:
                continue
            ranking = Counter(neighbors).most_common()
            top = ranking[0][1]
            # Bei Gleichstand gewinnt die Farbe, die dem Pixel am ähnlichsten ist.
            majority = min((c for c, n in ranking if n == top), key=lambda c: math.dist(lab[i], lab[c]))
            if math.dist(lab[i], lab[majority]) < args.naehe:
                result[y * width + x] = majority
    single_changed = sum(1 for a, b in zip(pixels, result) if a != b)

    transparent = result.count(0)
    pngio.write_png_indexed(args.bild, width, height, result, palette,
                            transparent_index=0 if transparent else None)
    print(f"{args.bild}: {len(counts)} → {len({i for i in result if i})} Farben, "
          f"{rest_changed} Pixel aus Farbresten, {single_changed} Einzelpixel angeglichen")

    if args.vorschau:
        z, gap = args.zoom, 4
        out_w = (2 * width) * z + gap
        preview = []
        for y in range(height * z):
            for image in (before, result):
                for i in image[(y // z) * width:(y // z + 1) * width]:
                    preview.extend([(0, 0, 0, 0) if i == 0 else palette[i] + (255,)] * z)
                if image is before:
                    preview.extend([(48, 48, 48, 255)] * gap)
        pngio.write_png_rgba(args.vorschau, out_w, height * z, preview)
        print(f"Vorschau vorher | nachher ×{z}: {args.vorschau}")


if __name__ == "__main__":
    main()
