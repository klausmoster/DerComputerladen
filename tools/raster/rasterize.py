"""Bringt ein Bild aufs Bildraster: Flächenmittel auf die Endgröße, dann auf die Hauptpalette.

Kein Dithering. Ergebnis ist ein indiziertes PNG mit der ganzen Hauptpalette; Index 0 ist die
Transparenz. Ausgeschnitten wird mittig, damit die Endgröße ein ganzzahliger Faktor bleibt.

Aufruf vom Repo-Root, entweder mit Endgröße oder mit Faktor:
  python3 -I tools/raster/rasterize.py docs/art/leonardo/t-01-titelbild.jpg src/assets/images/title_t01.png --groesse 320x180
  python3 -I tools/raster/rasterize.py docs/art/leonardo/logo-ladenschild.png src/assets/images/logo_ladenschild.png --faktor 6
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pngio  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("eingabe")
    parser.add_argument("ausgabe")
    size = parser.add_mutually_exclusive_group(required=True)
    size.add_argument("--groesse", help="Endgröße in Bildpixeln, etwa 320x180")
    size.add_argument("--faktor", type=int, help="ganzzahliger Verkleinerungsfaktor, etwa 6")
    parser.add_argument("--palette", default="docs/art/hauptpalette.gpl")
    parser.add_argument("--alpha", type=int, default=128,
                        help="ab diesem gemittelten Alphawert gilt ein Pixel als sichtbar")
    parser.add_argument("--vorschau", help="zusätzlich eine vergrößerte RGBA-Vorschau schreiben")
    parser.add_argument("--zoom", type=int, default=4, help="Vergrößerung der Vorschau")
    args = parser.parse_args()

    image = pngio.decode(args.eingabe)
    width, height = image[0], image[1]
    if args.groesse:
        target_w, target_h = (int(v) for v in args.groesse.lower().split("x"))
        factor, off_x, off_y = pngio.fit(width, height, target_w, target_h)
    else:
        factor = args.faktor
        target_w, target_h = width // factor, height // factor
        off_x, off_y = (width - target_w * factor) // 2, (height - target_h * factor) // 2

    pixels = pngio.box_average(image, target_w, target_h, factor, off_x, off_y)
    palette = [rgb for rgb, _ in pngio.read_gpl(args.palette)]
    matcher = pngio.Matcher(palette, skip={0})
    indices = [0 if a < args.alpha else matcher.nearest((r, g, b)) for r, g, b, a in pixels]
    transparent = indices.count(0)
    pngio.write_png_indexed(args.ausgabe, target_w, target_h, indices, palette,
                            transparent_index=0 if transparent else None)

    used = len(set(indices) - {0})
    print(f"{os.path.basename(args.eingabe)}: {width} × {height} → {target_w} × {target_h} "
          f"(Faktor {factor}, Ausschnitt ab {off_x}/{off_y}), {used} Palettenfarben, "
          f"{transparent} transparente Pixel → {args.ausgabe}")

    if args.vorschau:
        z = args.zoom
        preview = []
        for y in range(target_h * z):
            row = indices[(y // z) * target_w:(y // z + 1) * target_w]
            for i in row:
                preview.extend([(0, 0, 0, 0) if i == 0 else palette[i] + (255,)] * z)
        pngio.write_png_rgba(args.vorschau, target_w * z, target_h * z, preview)
        print(f"Vorschau ×{z}: {args.vorschau}")


if __name__ == "__main__":
    main()
