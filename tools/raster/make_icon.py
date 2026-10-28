"""Baut das App-Symbol: der Monitor aus dem Ladenschild, auf dem Bildraster, auf `nacht`.

Der Monitor kommt aus dem gerasterten Logo `src/assets/images/logo_ladenschild.png` (rasterize.py,
Faktor 6). So hat er genau die Pixel des Logos, auch nach dem Aufräumen von Hand: Nach jeder
Änderung am Logo das Skript neu aufrufen. Er wird ganzzahlig vergrößert und mittig auf eine
Fläche von 1024 × 1024 nach Apples Symbolraster für macOS gesetzt: ein abgerundetes Quadrat von
824 × 824 mit 100 Rand. Bei Zoom 32 wird ein Bildpixel in der Symbolgröße 32 × 32 genau ein
Bildschirmpixel, in 64, 128, 256 und 512 ein ganzzahliges Vielfaches.

Für Windows entsteht dazu eine ICO mit 16, 32, 48, 64, 128 und 256 Pixeln (Style-Guide, App-Symbol).
Jede Größe wird eigens aus dem Monitor gerechnet, ganzzahlig und ohne Weichzeichnen: 32 mit ×1,
48 und 64 mit ×2, 128 mit ×4, 256 mit ×8. In 16 passt der Monitor nicht hinein; dort steht er in
halber Größe aus jedem zweiten Bildpixel. Godot würde ein PNG selbst herunterrechnen und dabei die
Pixel verwischen.

Ergebnis:
  src/assets/icon/app_icon.png        das Symbol, 1024 × 1024, RGBA
  src/assets/icon/app_icon.ico        das Symbol für Windows, sechs Größen als PNG-Einträge
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
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pngio  # noqa: E402

CANVAS = 1024
# Abgerundetes Quadrat nach Apples Symbolraster: 824 × 824 mit 100 Rand, Eckenradius 185,4.
BODY = (100, 100, 924, 924)
RADIUS = 185.4
NACHT = (0x18, 0x23, 0x3B)
# Größen der ICO und die Vergrößerung des Monitors in jeder; 0 heißt halbe Größe.
ICO_GROESSEN = ((16, 0), (32, 1), (48, 2), (64, 2), (128, 4), (256, 8))


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


def body_coverage(x, y, size=CANVAS):
    """Wie viel von Pixel (x, y) im abgerundeten Quadrat liegt, 0 bis 1, mit weicher Kante; bei
    [size] kleiner als CANVAS ist das Quadrat im selben Verhältnis kleiner."""
    scale = size / CANVAS
    x0, y0, x1, y1 = (v * scale for v in BODY)
    radius = RADIUS * scale
    cx, cy = x + 0.5, y + 0.5
    # Abstand zum inneren Rechteck, um das die Ecken mit radius herumlaufen
    nx = min(max(cx, x0 + radius), x1 - radius)
    ny = min(max(cy, y0 + radius), y1 - radius)
    distance = math.hypot(cx - nx, cy - ny)
    return min(max(radius + 0.5 - distance, 0.0), 1.0)


def crop(monitor, width, height):
    """Der Monitor ohne leere Ränder: (Pixel, Breite, Höhe)."""
    xs = [i % width for i, p in enumerate(monitor) if p is not None]
    ys = [i // width for i, p in enumerate(monitor) if p is not None]
    x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
    return [monitor[y * width + x] for y in range(y0, y1) for x in range(x0, x1)], x1 - x0, y1 - y0


def ico_image(monitor, width, height, size, zoom):
    """Eine Größe der ICO: der Monitor ×zoom mittig auf dem Quadrat in `nacht`; zoom 0 heißt
    jedes zweite Bildpixel."""
    if zoom == 0:
        monitor = [monitor[y * width + x] for y in range(0, height, 2) for x in range(0, width, 2)]
        width, height, zoom = (width + 1) // 2, (height + 1) // 2, 1
    left, top = (size - width * zoom) // 2, (size - height * zoom) // 2
    pixels = []
    for y in range(size):
        for x in range(size):
            mx, my = (x - left) // zoom, (y - top) // zoom
            rgb = monitor[my * width + mx] if 0 <= mx < width and 0 <= my < height \
                and x >= left and y >= top else None
            pixels.append(rgb + (255,) if rgb is not None
                          else NACHT + (round(body_coverage(x, y, size) * 255),))
    return pixels


def write_ico(path, monitor, width, height):
    """Schreibt die ICO: Kopf, je Größe ein Verzeichniseintrag, dann die PNG-Einträge."""
    images = [(size, pngio.encode_png_rgba(size, size, ico_image(monitor, width, height, size, zoom)))
              for size, zoom in ICO_GROESSEN]
    data = struct.pack("<HHH", 0, 1, len(images))
    offset = 6 + 16 * len(images)
    for size, png in images:
        # Breite und Höhe 0 heißen 256; Farben 0, Ebenen 1, 32 Bit je Pixel.
        data += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(png), offset)
        offset += len(png)
    for _, png in images:
        data += png
    open(path, "wb").write(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--logo", default="src/assets/images/logo_ladenschild.png",
                        help="das gerasterte Logo in Bildpixeln")
    parser.add_argument("--bereich", default="6,6,25,22",
                        help="Monitor im Logo: x0,y0,x1,y1 in Bildpixeln, x1 und y1 ausschließlich")
    parser.add_argument("--zoom", type=int, default=32, help="Vergrößerung je Bildpixel")
    parser.add_argument("--ausgabe", default="src/assets/icon/app_icon.png")
    parser.add_argument("--ico", default="src/assets/icon/app_icon.ico",
                        help="das Symbol für Windows")
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
    knapp, knapp_w, knapp_h = crop(monitor, monitor_w, monitor_h)
    write_ico(args.ico, knapp, knapp_w, knapp_h)

    colors = len({c for c in monitor if c is not None})
    print(f"Monitor {monitor_w} × {monitor_h} Bildpixel aus {args.logo}, {colors} Farben, "
          f"×{zoom} = {monitor_w * zoom} × {monitor_h * zoom} bei {left}/{top}")
    print(f"Symbol → {args.ausgabe}; Ebenen monitor.png und grundfarbe.png → {args.ebenen}/")
    if os.path.isdir(glass_assets):
        print(f"Ebene monitor.png auch → {glass_assets}/")
    groessen = ", ".join(str(size) for size, _ in ICO_GROESSEN)
    print(f"ICO mit {groessen} → {args.ico} (Monitor {knapp_w} × {knapp_h})")


if __name__ == "__main__":
    main()
