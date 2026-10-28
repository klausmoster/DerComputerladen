"""Vergleicht die Fotos eines Selbsttest-Laufs Pixel für Pixel mit den Referenzbildern vom Mac.

Feature 007, contracts/vergleich.md; Entscheidungen in research.md R17 bis R19. Nur Standardbibliothek,
PNG über tools/raster/pngio.py. Aufruf vom Repo-Root mit `python3 -I`, weil die Zips von fremden
Rechnern kommen:

    python3 -I tools/selbsttest/vergleich.py build/selbsttest/2026-10-28_14-03-12_windows.zip

Exit 0: alles gleich oder nicht vergleichbar. Exit 1: Abweichungen oder fehlende Bilder.
Exit 2: Eingang unlesbar, ein Zip mit Pfaden aus seinem Ordner hinaus, ein falscher Aufruf oder ein
Bericht, der sich nicht schreiben lässt.
"""
import argparse
import os
import shutil
import stat
import sys
import zipfile

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HIER))
sys.path.insert(0, os.path.join(REPO, "tools", "raster"))
import pngio  # noqa: E402

REFERENZ = os.path.join(HIER, "referenz", "macos")
EINGANG = os.path.join(REPO, "build", "selbsttest")
BELEGE = os.path.join(REPO, "specs", "007-build-export-selbsttest", "belege")
BREITE, HOEHE = 640, 360
# kassenrot aus dem Style-Guide: markiert abweichende Pixel.
KASSENROT = (0xC0, 0x39, 0x2B, 255)

GLEICH = "gleich"
ABWEICHEND = "abweichend"
NICHT_VERGLEICHBAR = "nicht vergleichbar"
REFERENZ_FEHLT = "Referenz fehlt"
FOTO_FEHLT = "Foto fehlt"
ERGEBNISSE = (GLEICH, ABWEICHEND, NICHT_VERGLEICHBAR, REFERENZ_FEHLT, FOTO_FEHLT)


class Unlesbar(Exception):
    """Der Eingang lässt sich nicht lesen oder wird abgelehnt; führt zu Exit 2."""


# --- Eingang -----------------------------------------------------------------------------------

def oeffne(pfad):
    """Gibt den Ordner eines Laufs zurück: ein Ordner bleibt, wie er ist; ein Zip wird nach
    build/selbsttest/<name>/ entpackt."""
    if os.path.isdir(pfad):
        if not os.path.isfile(os.path.join(pfad, "protokoll.txt")):
            raise Unlesbar(f"{pfad}: kein protokoll.txt im Ordner")
        return pfad
    if not zipfile.is_zipfile(pfad):
        raise Unlesbar(f"{pfad}: weder Ordner noch Zip")
    name = os.path.splitext(os.path.basename(pfad))[0]
    ziel = os.path.join(EINGANG, name)
    entpacke(pfad, ziel)
    return ziel


def entpacke(zip_pfad, ziel):
    """Entpackt nach [ziel]. Lehnt das ganze Zip ab, bevor etwas geschrieben ist, wenn ein Eintrag
    aus dem Ordner hinausführt oder ein symbolischer Link ist."""
    basis = os.path.realpath(ziel)
    with zipfile.ZipFile(zip_pfad) as archiv:
        eintraege = archiv.infolist()
        for eintrag in eintraege:
            name = eintrag.filename
            ausserhalb = os.path.realpath(os.path.join(basis, name))
            if (os.path.isabs(name) or ".." in name.replace("\\", "/").split("/")
                    or os.path.commonpath([basis, ausserhalb]) != basis):
                raise Unlesbar(f"{zip_pfad}: abgelehnt, „{name}“ führt aus dem Ordner hinaus.")
            if stat.S_ISLNK(eintrag.external_attr >> 16):
                raise Unlesbar(f"{zip_pfad}: abgelehnt, „{name}“ ist ein symbolischer Link.")
        if os.path.isdir(ziel):
            shutil.rmtree(ziel)
        os.makedirs(ziel)
        archiv.extractall(ziel)
    if not os.path.isfile(os.path.join(ziel, "protokoll.txt")):
        raise Unlesbar(f"{zip_pfad}: kein protokoll.txt im Zip")


def lies_protokoll(ordner):
    """Liest protokoll.txt: die einfachen Schlüssel und die Schritte als Liste von Dictionaries."""
    try:
        zeilen = open(os.path.join(ordner, "protokoll.txt"), encoding="utf-8").read().splitlines()
    except (OSError, UnicodeDecodeError) as fehler:
        raise Unlesbar(f"{ordner}: protokoll.txt unlesbar ({fehler})")
    werte, schritte, schritt = {}, [], None
    for zeile in zeilen:
        if ": " not in zeile or zeile.startswith("#"):
            continue
        schluessel, wert = zeile.split(": ", 1)
        if schluessel == "schritt":
            schritt = {"schritt": wert}
            schritte.append(schritt)
        elif schritt is not None and "." not in schluessel:
            schritt.setdefault(schluessel, wert)
        else:
            werte.setdefault(schluessel, wert)
    if "lauf.start" not in werte:
        raise Unlesbar(f"{ordner}: protokoll.txt ohne lauf.start")
    return werte, schritte


def lauf_id(werte):
    """„2026-10-28 14:03:12“ → „2026-10-28_14-03-12“, wie der Ordner des Laufs heißt."""
    return werte["lauf.start"].replace(" ", "_").replace(":", "-")


def system_kurz(werte):
    """macos, windows oder linux, für den Ordner der Belege."""
    return werte.get("system.os", "unbekannt").lower().replace(" ", "")


# --- Vergleich ---------------------------------------------------------------------------------

def lies_rgba(pfad):
    """Ein PNG als (breite, hoehe, Liste von (r, g, b, a)); RGB bekommt a = 255."""
    breite, hoehe, kanaele, zeilen = pngio.read_png(pfad)
    pixel = []
    for zeile in zeilen:
        for x in range(breite):
            p = tuple(zeile[x * kanaele:(x + 1) * kanaele])
            pixel.append(p if kanaele == 4 else p + (255,))
    return breite, hoehe, pixel


def vergleiche_bilder(foto_pfad, referenz_pfad):
    """Vergleicht in RGBA ohne Toleranz. Gibt (Zahl abweichender Pixel, Rechteck oder None,
    Liste der abweichenden Indizes, Foto) zurück; bei verschiedener Größe (None, None, None, Foto)."""
    # Schneller Weg für den häufigen Fall: gleiche Bytes in gleicher Form sind gleiche Pixel.
    roh_foto, roh_ref = pngio.read_png(foto_pfad), pngio.read_png(referenz_pfad)
    if roh_foto[:3] == roh_ref[:3] and roh_foto[3] == roh_ref[3]:
        return 0, None, [], None
    foto = lies_rgba(foto_pfad)
    referenz = lies_rgba(referenz_pfad)
    if foto[:2] != referenz[:2]:
        return None, None, None, foto
    breite = foto[0]
    abweichend = [i for i, (a, b) in enumerate(zip(foto[2], referenz[2])) if a != b]
    if not abweichend:
        return 0, None, [], foto
    xs = [i % breite for i in abweichend]
    ys = [i // breite for i in abweichend]
    return len(abweichend), (min(xs), min(ys), max(xs), max(ys)), abweichend, foto


def markiere(foto, abweichend, pfad):
    """Schreibt das Foto in Graustufen, die abweichenden Pixel in kassenrot."""
    breite, hoehe, pixel = foto
    grau = []
    for r, g, b, _ in pixel:
        y = round(0.299 * r + 0.587 * g + 0.114 * b)
        grau.append((y, y, y, 255))
    for i in abweichend:
        grau[i] = KASSENROT
    pngio.write_png_rgba(pfad, breite, hoehe, grau)


def vergleiche_lauf(ordner, schritte, referenz_ordner):
    """Vergleicht alle Fotos eines Laufs. Gibt je Kennung (Ergebnis, Pixel, Rechteck) zurück, in
    der Reihenfolge des Protokolls, danach Referenzen ohne Schritt; legt abweichende Fotos und ihr
    markiertes Bild unter <lauf>/abweichungen/ ab."""
    fotos = os.path.join(ordner, "fotos")
    abw_ordner = os.path.join(ordner, "abweichungen")
    if os.path.isdir(abw_ordner):
        shutil.rmtree(abw_ordner)
    referenzen = sorted(n[:-4] for n in os.listdir(referenz_ordner) if n.endswith(".png")) \
        if os.path.isdir(referenz_ordner) else []
    kennungen = [s["schritt"] for s in schritte]
    kennungen += [k for k in referenzen if k not in kennungen]
    vergleichbar = {s["schritt"]: s.get("foto_vergleichbar", "ja") != "nein" for s in schritte}
    ergebnisse = []
    for kennung in kennungen:
        foto_pfad = os.path.join(fotos, kennung + ".png")
        ref_pfad = os.path.join(referenz_ordner, kennung + ".png")
        hat_foto, hat_ref = os.path.isfile(foto_pfad), os.path.isfile(ref_pfad)
        if not hat_foto:
            if hat_ref:
                ergebnisse.append((kennung, FOTO_FEHLT, None, None))
            continue
        if not vergleichbar.get(kennung, True):
            breite, hoehe, _ = lies_rgba(foto_pfad)
            if (breite, hoehe) == (BREITE, HOEHE):
                ergebnisse.append((kennung, NICHT_VERGLEICHBAR, None, None))
            else:
                ergebnisse.append((kennung, ABWEICHEND, f"Größe {breite} × {hoehe}", None))
            continue
        if not hat_ref:
            ergebnisse.append((kennung, REFERENZ_FEHLT, None, None))
            continue
        zahl, rechteck, abweichend, foto = vergleiche_bilder(foto_pfad, ref_pfad)
        if zahl is None:
            ergebnisse.append((kennung, ABWEICHEND, f"Größe {foto[0]} × {foto[1]}", None))
            os.makedirs(abw_ordner, exist_ok=True)
            shutil.copyfile(foto_pfad, os.path.join(abw_ordner, kennung + ".png"))
        elif zahl == 0:
            ergebnisse.append((kennung, GLEICH, 0, None))
        else:
            ergebnisse.append((kennung, ABWEICHEND, zahl, rechteck))
            os.makedirs(abw_ordner, exist_ok=True)
            shutil.copyfile(foto_pfad, os.path.join(abw_ordner, kennung + ".png"))
            markiere(foto, abweichend, os.path.join(abw_ordner, kennung + "_markiert.png"))
    return ergebnisse


# --- Bericht -----------------------------------------------------------------------------------

def rechteck_als_text(rechteck):
    """„x 280–420, y 140–152“; bei einer Spalte oder Zeile nur die eine Zahl, etwa „x 300, y 200“."""
    x0, y0, x1, y1 = rechteck
    def spanne(a, b):
        return str(a) if a == b else f"{a}–{b}"
    return f"x {spanne(x0, x1)}, y {spanne(y0, y1)}"


def bericht(werte, ergebnisse, gegen=None):
    """Der Text von vergleich.md (contracts/vergleich.md, „Bericht“)."""
    system = " ".join(w for w in (werte.get("system.os"), werte.get("system.os_version")) if w)
    kopf = f"# Vergleich {lauf_id(werte)} ({system}, {werte.get('system.gpu', 'unbekannt')}, " \
           f"{werte.get('system.grafik_api', 'unbekannt')})"
    zeilen = [kopf, ""]
    if gegen:
        zeilen += [f"Verglichen mit dem Lauf {gegen}; seine Fotos gelten hier als Referenz.", ""]
    anzahl = {e: sum(1 for r in ergebnisse if r[1] == e) for e in ERGEBNISSE}
    zeilen += [" · ".join(f"{e}: {anzahl[e]}" for e in ERGEBNISSE), ""]
    zeilen += ["| Schritt | Ergebnis | Pixel | Rechteck |", "|---|---|---|---|"]
    for kennung, ergebnis, pixel, rechteck in ergebnisse:
        pixel_text = "–" if pixel is None else str(pixel)
        rechteck_text = "–" if rechteck is None else rechteck_als_text(rechteck)
        zeilen.append(f"| {kennung} | {ergebnis} | {pixel_text} | {rechteck_text} |")
    return "\n".join(zeilen) + "\n"


def lege_beleg_ab(ordner, werte):
    """Kopiert Protokoll, Bericht und Abweichungen nach specs/007-…/belege/<system>_<lauf-id>/."""
    ziel = os.path.join(BELEGE, f"{system_kurz(werte)}_{lauf_id(werte)}")
    if os.path.isdir(ziel):
        shutil.rmtree(ziel)
    os.makedirs(ziel)
    for datei in ("protokoll.txt", "vergleich.md"):
        shutil.copyfile(os.path.join(ordner, datei), os.path.join(ziel, datei))
    abw = os.path.join(ordner, "abweichungen")
    if os.path.isdir(abw):
        shutil.copytree(abw, os.path.join(ziel, "abweichungen"))
    return ziel


def erneuere_referenz(ordner, werte, schritte, kennungen):
    """Übernimmt Fotos eines Laufs vom Mac als Referenzbilder; „alle“ heißt alle vergleichbaren.
    Gibt die Zahl der übernommenen Bilder zurück."""
    if werte.get("system.os") != "macOS":
        raise Unlesbar("Referenzbilder kommen nur von einem Lauf auf dem Mac.")
    if kennungen == ["alle"]:
        kennungen = [s["schritt"] for s in schritte if s.get("foto_vergleichbar") == "ja"]
    os.makedirs(REFERENZ, exist_ok=True)
    zahl = 0
    for kennung in kennungen:
        quelle = os.path.join(ordner, "fotos", kennung + ".png")
        if not os.path.isfile(quelle):
            raise Unlesbar(f"Foto {kennung}.png fehlt im Lauf.")
        shutil.copyfile(quelle, os.path.join(REFERENZ, kennung + ".png"))
        zahl += 1
    return zahl


# --- Aufruf ------------------------------------------------------------------------------------

def relativ(pfad):
    """Vom Repo-Root aus, wenn der Pfad darin liegt, sonst so, wie er ist."""
    pfad = os.path.abspath(pfad)
    return os.path.relpath(pfad, REPO) if pfad.startswith(REPO + os.sep) else pfad


def main(argumente=None):
    parser = argparse.ArgumentParser(
        description="Vergleicht die Fotos eines Selbsttest-Laufs mit den Referenzbildern vom Mac.")
    parser.add_argument("lauf", help="Zip oder Ordner eines Laufs")
    parser.add_argument("--gegen", metavar="LAUF",
                        help="mit den Fotos eines anderen Laufs vergleichen statt mit den Referenzbildern")
    parser.add_argument("--beleg", action="store_true",
                        help="Protokoll, Bericht und Abweichungen nach specs/007-build-export-selbsttest/belege/ kopieren")
    parser.add_argument("--referenz-erneuern", nargs="*", metavar="KENNUNG",
                        help="Fotos dieses Laufs als Referenzbilder übernehmen, nur nach Klaus' "
                             "Abnahme; „alle“ für alle vergleichbaren")
    args = parser.parse_args(argumente)
    try:
        ordner = oeffne(args.lauf)
        werte, schritte = lies_protokoll(ordner)
        if args.referenz_erneuern is not None:
            if not args.referenz_erneuern:
                print("Keine Kennungen genannt, keine Referenzbilder erneuert.")
            else:
                zahl = erneuere_referenz(ordner, werte, schritte, args.referenz_erneuern)
                print(f"{zahl} {'Referenzbild' if zahl == 1 else 'Referenzbilder'} erneuert in {relativ(REFERENZ)}")
        referenz_ordner, gegen = REFERENZ, None
        if args.gegen:
            anderer = oeffne(args.gegen)
            gegen = lauf_id(lies_protokoll(anderer)[0])
            referenz_ordner = os.path.join(anderer, "fotos")
        ergebnisse = vergleiche_lauf(ordner, schritte, referenz_ordner)
    except (Unlesbar, ValueError, OSError, zipfile.BadZipFile) as fehler:
        print(fehler, file=sys.stderr)
        return 2
    text = bericht(werte, ergebnisse, gegen)
    try:
        open(os.path.join(ordner, "vergleich.md"), "w", encoding="utf-8").write(text)
    except OSError as fehler:
        print(f"vergleich.md lässt sich nicht schreiben: {fehler}", file=sys.stderr)
        return 2
    print(next(z for z in text.splitlines() if z.startswith(GLEICH + ":")))
    print(f"Bericht: {relativ(os.path.join(ordner, 'vergleich.md'))}")
    if args.beleg:
        print(f"Beleg: {relativ(lege_beleg_ab(ordner, werte))}")
    in_ordnung = all(r[1] in (GLEICH, NICHT_VERGLEICHBAR) for r in ergebnisse)
    return 0 if in_ordnung else 1


if __name__ == "__main__":
    sys.exit(main())
