"""Baut das App-Symbol: der Monitor aus dem Ladenschild, auf dem Bildraster, auf `nacht`.

Der Monitor kommt aus dem gerasterten Logo `src/assets/images/logo_ladenschild.png` (rasterize.py,
Faktor 6). So hat er genau die Pixel des Logos, auch nach dem Aufräumen von Hand: Nach jeder
Änderung am Logo das Skript neu aufrufen. Er wird ganzzahlig vergrößert und mittig auf eine
Fläche von 1024 × 1024 nach Apples Symbolraster für macOS gesetzt: ein abgerundetes Quadrat von
824 × 824 mit 100 Rand. Bei Zoom 32 wird ein Bildpixel in der Symbolgröße 32 × 32 genau ein
Bildschirmpixel, in 64, 128, 256 und 512 ein ganzzahliges Vielfaches.

Ergebnis:
  src/assets/icon/app_icon.png        das Symbol, 1024 × 1024, RGBA
  docs/art/app_icon/monitor.png       Ebene für Icon Composer: der Monitor freigestellt
  docs/art/app_icon/grundfarbe.png    Ebene für Icon Composer: die ganze Fläche in `nacht`
  src/assets/icon/app_icon.icon/Assets/monitor.png
                                      dieselbe Ebene im Liquid-Glass-Symbol, falls es schon da ist

Aufruf vom Repo-Root:
  python3 -I tools/raster/make_icon.py
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pngio  # noqa: E402

CANVAS = 1024
# Abgerundetes Quadrat nach Apples Symbolraster: 824 × 824 mit 100 Rand, Eckenradius 185,4.
BODY = (100, 100, 924, 924)
RADIUS = 185.4
NACHT = (0x18, 0x23, 0x3B)


def is_reddish(rgb):
    """Farben des roten Schildfelds und seines Schattens: rötlich und kräftig oder dunkel."""
    hue, chroma = pngio.hue_and_chroma(rgb)
    lightness = pngio.oklab(rgb)[0]
    return (hue < 50 or hue > 330) and (chroma > 0.08 or (chroma > 0.03 and lightness < 0.5))


def backdrop_mask(pixels, width, height):
    """Was vom Rand aus über rötliche oder durchsichtige Pixel erreichbar ist, ist Hintergrund.

    So fallen das Schildfeld, der Schatten des Monitors darauf und die gemischten Randpixel weg.
    Rötliche Pixel im Monitor bleiben, solange sie nicht mit dem Schildfeld zusammenhängen.
    """
    mask = [False] * (width * height)
    todo = [(x, y) for x in range(width) for y in (0, height - 1)]
    todo += [(x, y) for y in range(height) for x in (0, width - 1)]
    while todo:
        x, y = todo.pop()
        if not (0 <= x < width and 0 <= y < height) or mask[y * width + x]:
            continue
        rgb = pixels[y * width + x]
        if rgb is not None and not is_reddish(rgb):
            continue
        mask[y * width + x] = True
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return mask


def body_coverage(x, y):
    """Wie viel von Pixel (x, y) im abgerundeten Quadrat liegt, 0 bis 1, mit weicher Kante."""
    x0, y0, x1, y1 = BODY
    cx, cy = x + 0.5, y + 0.5
    # Abstand zum inneren Rechteck, um das die Ecken mit RADIUS herumlaufen
    nx = min(max(cx, x0 + RADIUS), x1 - RADIUS)
    ny = min(max(cy, y0 + RADIUS), y1 - RADIUS)
    distance = math.hypot(cx - nx, cy - ny)
    return min(max(RADIUS + 0.5 - distance, 0.0), 1.0)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--logo", default="src/assets/images/logo_ladenschild.png",
                        help="das gerasterte Logo in Bildpixeln")
    parser.add_argument("--bereich", default="6,6,25,22",
                        help="Monitor im Logo: x0,y0,x1,y1 in Bildpixeln, x1 und y1 ausschließlich")
    parser.add_argument("--zoom", type=int, default=32, help="Vergrößerung je Bildpixel")
    parser.add_argument("--ausgabe", default="src/assets/icon/app_icon.png")
    parser.add_argument("--ebenen", default="docs/art/app_icon")
    parser.add_argument("--glas", default="src/assets/icon/app_icon.icon",
                        help="Liquid-Glass-Symbol, dessen Ebene mit erneuert wird")
    args = parser.parse_args()

    width, height, channels, rows = pngio.read_png(args.logo)
    x0, y0, x1, y1 = (int(v) for v in args.bereich.split(","))
    if x1 > width or y1 > height:
        raise SystemExit(f"Bereich {args.bereich} liegt nicht im Logo ({width} × {height})")

    # Der Monitor: der Bereich ohne das Schildfeld drumherum.
    monitor_w, monitor_h = x1 - x0, y1 - y0
    monitor = []
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = tuple(rows[y][x * channels:x * channels + channels])
            alpha = p[3] if channels == 4 else 255
            monitor.append(None if alpha < 128 else p[:3])
    mask = backdrop_mask(monitor, monitor_w, monitor_h)
    monitor = [None if hidden else rgb for rgb, hidden in zip(monitor, mask)]

    # Mittig setzen, die Lage auf ganze Vielfache des Zooms gerundet: Dann fallen die Bildpixel
    # in den kleinen Symbolgrößen auf ganze Bildschirmpixel.
    zoom = args.zoom
    left = (CANVAS - monitor_w * zoom) // 2 // zoom * zoom
    top = (CANVAS - monitor_h * zoom) // 2 // zoom * zoom

    def monitor_at(x, y):
        mx, my = (x - left) // zoom, (y - top) // zoom
        if 0 <= mx < monitor_w and 0 <= my < monitor_h:
            return monitor[my * monitor_w + mx]
        return None

    icon, layer = [], []
    for y in range(CANVAS):
        for x in range(CANVAS):
            rgb = monitor_at(x, y)
            if rgb is not None:
                icon.append(rgb + (255,))
                layer.append(rgb + (255,))
            else:
                icon.append(NACHT + (round(body_coverage(x, y) * 255),))
                layer.append((0, 0, 0, 0))

    os.makedirs(os.path.dirname(args.ausgabe), exist_ok=True)
    os.makedirs(args.ebenen, exist_ok=True)
    pngio.write_png_rgba(args.ausgabe, CANVAS, CANVAS, icon)
    pngio.write_png_rgba(os.path.join(args.ebenen, "monitor.png"), CANVAS, CANVAS, layer)
    pngio.write_png_rgba(os.path.join(args.ebenen, "grundfarbe.png"), CANVAS, CANVAS,
                         [NACHT + (255,)] * (CANVAS * CANVAS))
    glass_assets = os.path.join(args.glas, "Assets")
    if os.path.isdir(glass_assets):
        pngio.write_png_rgba(os.path.join(glass_assets, "monitor.png"), CANVAS, CANVAS, layer)

    colors = len({c for c in monitor if c is not None})
    print(f"Monitor {monitor_w} × {monitor_h} Bildpixel aus {args.logo}, {colors} Farben, "
          f"×{zoom} = {monitor_w * zoom} × {monitor_h * zoom} bei {left}/{top}")
    print(f"Symbol → {args.ausgabe}; Ebenen monitor.png und grundfarbe.png → {args.ebenen}/")
    if os.path.isdir(glass_assets):
        print(f"Ebene monitor.png auch → {glass_assets}/")


if __name__ == "__main__":
    main()
