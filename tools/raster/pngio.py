"""Bilder lesen und schreiben ohne Fremdbibliotheken, dazu die Rechenschritte der Rasterfassung.

Gemeinsam genutzt von make_palette.py und rasterize.py. Nur Standardbibliothek; JPEG und andere
Formate wandelt `sips` (macOS) vorher in PNG um.
"""
import math
import os
import struct
import subprocess
import tempfile
import zlib

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


# --- Lesen ------------------------------------------------------------------

def decode(path):
    """Liest ein Bild als (breite, hoehe, kanaele, zeilen); zeilen sind bytearrays."""
    if path.lower().endswith(".png"):
        return read_png(path)
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "bild.png")
        subprocess.run(["sips", "-s", "format", "png", path, "--out", out],
                       check=True, capture_output=True)
        return read_png(out)


def read_png(path):
    """Liest ein 8-Bit-PNG (RGB, RGBA oder indiziert, ohne Interlacing).

    Ein indiziertes Bild kommt als RGBA zurück, die Durchsichtigkeit aus seinem tRNS-Chunk.
    """
    data = open(path, "rb").read()
    if data[:8] != PNG_SIGNATURE:
        raise ValueError(f"{path}: kein PNG")
    pos, idat, ihdr, plte, trns = 8, bytearray(), None, b"", b""
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"PLTE":
            plte = chunk
        elif kind == b"tRNS":
            trns = chunk
        elif kind == b"IDAT":
            idat += chunk
        elif kind == b"IEND":
            break
        pos += 12 + length
    width, height, depth, ctype, _, _, interlace = ihdr
    channels = {2: 3, 3: 1, 6: 4}.get(ctype)
    if depth != 8 or channels is None or interlace != 0:
        raise ValueError(f"{path}: nicht unterstützt (Tiefe {depth}, Farbtyp {ctype}, Interlace {interlace})")
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(height):
        ftype = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        _unfilter(ftype, line, prev, channels)
        rows.append(line)
        prev = line
    if ctype == 3:
        # Erst nach dem Entfiltern übersetzen: Die Filter rechnen auf den Indizes.
        rgba = [plte[3 * k:3 * k + 3] + bytes([trns[k] if k < len(trns) else 255])
                for k in range(len(plte) // 3)]
        rows = [bytearray(b"".join(rgba[k] for k in line)) for line in rows]
        channels = 4
    return width, height, channels, rows


def _unfilter(ftype, line, prev, bpp):
    n = len(line)
    if ftype == 0:
        return
    if ftype == 1:
        for x in range(bpp, n):
            line[x] = (line[x] + line[x - bpp]) & 255
    elif ftype == 2:
        for x in range(n):
            line[x] = (line[x] + prev[x]) & 255
    elif ftype == 3:
        for x in range(n):
            left = line[x - bpp] if x >= bpp else 0
            line[x] = (line[x] + ((left + prev[x]) >> 1)) & 255
    elif ftype == 4:
        for x in range(n):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
    else:
        raise ValueError(f"unbekannter PNG-Filter {ftype}")


# --- Flächenmittel ----------------------------------------------------------

def fit(width, height, target_w, target_h):
    """Ganzzahliger Faktor und mittiger Ausschnitt, damit das Bild genau auf target passt."""
    factor = min(width // target_w, height // target_h)
    if factor < 1:
        raise ValueError(f"Bild {width} × {height} ist kleiner als das Ziel {target_w} × {target_h}")
    off_x = (width - target_w * factor) // 2
    off_y = (height - target_h * factor) // 2
    return factor, off_x, off_y


def box_average(image, target_w, target_h, factor, off_x, off_y):
    """Verkleinert per Flächenmittel; liefert eine Liste von (r, g, b, a), zeilenweise.

    Farben werden mit dem Alphawert gewichtet, damit transparente Ränder nicht abfärben.
    """
    _, _, channels, rows = image
    n = factor * factor
    out = []
    for ty in range(target_h):
        y0 = off_y + ty * factor
        block_rows = rows[y0:y0 + factor]
        for tx in range(target_w):
            x0 = (off_x + tx * factor) * channels
            x1 = x0 + factor * channels
            sr = sg = sb = sa = 0
            for row in block_rows:
                seg = row[x0:x1]
                if channels == 4:
                    for k in range(0, len(seg), 4):
                        a = seg[k + 3]
                        sr += seg[k] * a
                        sg += seg[k + 1] * a
                        sb += seg[k + 2] * a
                        sa += a
                else:
                    sr += sum(seg[0::3])
                    sg += sum(seg[1::3])
                    sb += sum(seg[2::3])
                    sa += 255 * factor
            if channels == 4:
                if sa == 0:
                    out.append((0, 0, 0, 0))
                    continue
                out.append((round(sr / sa), round(sg / sa), round(sb / sa), round(sa / n)))
            else:
                out.append((round(sr / n), round(sg / n), round(sb / n), 255))
    return out


# --- Farbabstand in OKLab ---------------------------------------------------

def _linear(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def oklab(rgb):
    """sRGB (0–255) nach OKLab; dort entsprechen Abstände dem Farbunterschied fürs Auge."""
    r, g, b = (_linear(v) for v in rgb[:3])
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def hue_and_chroma(rgb):
    _, a, b = oklab(rgb)
    return math.degrees(math.atan2(b, a)) % 360, math.hypot(a, b)


class Matcher:
    """Findet zu jeder Farbe den nächsten Paletteneintrag, ohne Dithering."""

    def __init__(self, palette, skip=()):
        self.entries = [(i, oklab(c)) for i, c in enumerate(palette) if i not in skip]
        self.cache = {}

    def nearest(self, rgb):
        key = rgb[:3]
        hit = self.cache.get(key)
        if hit is None:
            L, A, B = oklab(key)
            hit = min(self.entries, key=lambda e: (e[1][0] - L) ** 2 + (e[1][1] - A) ** 2 + (e[1][2] - B) ** 2)[0]
            self.cache[key] = hit
        return hit


# --- Palette im GIMP-Format -------------------------------------------------

def read_gpl(path):
    """Liest eine GIMP-Palette (.gpl) als Liste von ((r, g, b), name)."""
    entries = []
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith(("GIMP Palette", "Name:", "Columns:", "#")):
            continue
        parts = line.split(None, 3)
        entries.append(((int(parts[0]), int(parts[1]), int(parts[2])), parts[3] if len(parts) > 3 else ""))
    return entries


# --- Schreiben --------------------------------------------------------------

def _chunk(kind, body):
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xffffffff)


def write_png_indexed(path, width, height, indices, palette, transparent_index=None):
    """Schreibt ein indiziertes 8-Bit-PNG; indices zeilenweise, palette als (r, g, b)."""
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw += bytes(indices[y * width:(y + 1) * width])
    png = PNG_SIGNATURE
    png += _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 3, 0, 0, 0))
    png += _chunk(b"PLTE", b"".join(bytes(c) for c in palette))
    if transparent_index is not None:
        png += _chunk(b"tRNS", bytes([255] * transparent_index + [0]))
    png += _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += _chunk(b"IEND", b"")
    open(path, "wb").write(png)


def write_png_rgba(path, width, height, pixels):
    """Schreibt ein 8-Bit-RGBA-PNG; pixels zeilenweise als (r, g, b, a)."""
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for p in pixels[y * width:(y + 1) * width]:
            raw += bytes(p)
    png = PNG_SIGNATURE
    png += _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += _chunk(b"IEND", b"")
    open(path, "wb").write(png)
