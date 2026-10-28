# Vertrag: Vergleich mit Referenzbildern

Werkzeug `[C]` außerhalb von Godot (Spec FR-018 bis FR-020a, US3, SC-008). Entscheidungen in
[research.md](../research.md) R17 bis R19.

## Dateien

```text
tools/selbsttest/
├── vergleich.py          vergleicht einen Lauf mit den Referenzbildern
├── README.md             Aufruf, Eingang, Belege
└── referenz/macos/       je vergleichbarem Schritt ein Referenzbild <kennung>.png, 640 × 360
build/selbsttest/         Eingang, nicht versioniert: Zips von anderen Rechnern, entpackte Läufe
specs/007-build-export-selbsttest/belege/<system>_<lauf-id>/
├── protokoll.txt         Kopie aus dem Lauf
├── vergleich.md          Bericht des Vergleichs
└── abweichungen/         nur abweichende Fotos und ihr Bild mit markierten Pixeln
```

Python 3, nur Standardbibliothek; PNG lesen und schreiben über `tools/raster/pngio.py`. Aufruf vom
Repo-Root mit `python3 -I`, weil die Zips von fremden Rechnern kommen.

## Aufruf

```bash
python3 -I tools/selbsttest/vergleich.py build/selbsttest/2026-10-28_14-03-12_windows.zip
```

- Nimmt ein Zip oder einen entpackten Ordner. Ein Zip entpackt es nach `build/selbsttest/<name>/`;
  Pfade im Zip, die aus diesem Ordner hinausführen, lehnt es ab.
- Liest `protokoll.txt` und daraus `foto_vergleichbar` je Schritt.
- Vergleicht jedes Foto mit `referenz/macos/<kennung>.png` und schreibt `vergleich.md` in den Ordner
  des Laufs.
- `--beleg` kopiert Protokoll, Bericht und Abweichungen nach `specs/007-…/belege/` (FR-020a).
- `--referenz-erneuern <kennung …|alle>` übernimmt Fotos eines Laufs vom Mac als Referenzbilder; nur
  nach Klaus' Abnahme (FR-020). Ohne Kennungen tut es nichts.
- Exit 0, wenn alles `gleich` oder `nicht_vergleichbar` ist; 1 bei Abweichungen oder fehlenden
  Bildern; 2 bei unlesbarem Eingang.

## Vergleich

- Pixel für Pixel in RGBA; ein Pixel weicht ab, wenn irgendein Kanal verschieden ist. Keine Toleranz.
- Größe anders als 640 × 360: `abweichend` mit Vermerk „Größe“.
- Bild mit markierten Abweichungen: das Foto in Graustufen, abweichende Pixel in `kassenrot`.
- Ergebnisse je Schritt wie in [data-model.md](../data-model.md), „Vergleich“.

## Bericht `vergleich.md`

```text
# Vergleich 2026-10-28_14-03-12 (Windows 11, NVIDIA GeForce RTX 3060, D3D12)

gleich: 36 · abweichend: 2 · nicht vergleichbar: 2 · Referenz fehlt: 0 · Foto fehlt: 0

| Schritt | Ergebnis | Pixel | Rechteck |
|---|---|---|---|
| titel.01_start | gleich | 0 | – |
| laden.02_liste | abweichend | 112 | 280,140–420,152 |
```

Die Kopfzeile nimmt System, Grafikkarte und Grafikschnittstelle aus dem Protokoll.

## Prüfung (SC-008)

- Zwei Läufe auf dem Mac: alles `gleich`.
- Ein Foto in einer Kopie um einen Pixel geändert: genau dieser Pixel, Rechteck 1 × 1.
- Ein Foto gelöscht: `foto_fehlt`; ein Referenzbild gelöscht: `referenz_fehlt`.
- Ein Zip mit `../` im Pfad: abgelehnt, Exit 2.
