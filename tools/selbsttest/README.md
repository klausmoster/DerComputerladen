# Vergleich des Selbsttests

`vergleich.py` vergleicht die Fotos eines Selbsttest-Laufs Pixel für Pixel mit den Referenzbildern
vom Mac. So zeigt sich, ob „Der Computerladen“ auf einem anderen Rechner, etwa unter Windows oder
Linux, genauso aussieht. Nur Python 3 mit Standardbibliothek, PNG über `tools/raster/pngio.py`. Vertrag:
`specs/007-build-export-selbsttest/contracts/vergleich.md`.

## Aufruf

Immer vom Repo-Root und mit `python3 -I`, weil die Zips von fremden Rechnern kommen:

```bash
python3 -I tools/selbsttest/vergleich.py build/selbsttest/2026-10-28_14-03-12_windows.zip
```

- Der Eingang ist das Zip eines Laufs oder ein entpackter Ordner mit `protokoll.txt` und `fotos/`.
- Ein Zip wird nach `build/selbsttest/<name>/` entpackt. Führt ein Pfad im Zip aus diesem Ordner
  hinaus oder ist er ein symbolischer Link, wird das ganze Zip abgelehnt.
- Der Bericht `vergleich.md` landet im Ordner des Laufs, abweichende Fotos und ihr markiertes Bild
  unter `abweichungen/`.

| Zusatz | Wirkung |
|---|---|
| `--gegen <lauf>` | vergleicht mit den Fotos eines anderen Laufs statt mit den Referenzbildern, etwa 2 Läufe auf dem Mac |
| `--beleg` | kopiert Protokoll, Bericht und Abweichungen nach `specs/007-build-export-selbsttest/belege/<system>_<lauf-id>/` |
| `--referenz-erneuern <kennung …>` | übernimmt Fotos eines Laufs vom Mac als Referenzbilder, nur nach Klaus' Abnahme; `alle` für alle vergleichbaren; ohne Kennung bleiben die Referenzbilder, wie sie sind |

Exit 0, wenn alles gleich oder nicht vergleichbar ist; 1 bei Abweichungen oder fehlenden Bildern;
2 bei unlesbarem oder abgelehntem Eingang, falschem Aufruf oder einem Bericht, der sich nicht
schreiben lässt.

## Ergebnisse

| Ergebnis | Bedeutung |
|---|---|
| gleich | Foto und Referenzbild sind Pixel für Pixel gleich |
| abweichend | Zahl der abweichenden Pixel und das Rechteck um sie, etwa „x 280–420, y 140–152“; oder „Größe …“, wenn das Foto nicht 640 × 360 groß ist |
| nicht vergleichbar | der Schritt ist im Protokoll so markiert, etwa die beiden Schritte mit Invaders; nur die Größe wird geprüft |
| Referenz fehlt | zum Foto gibt es kein Referenzbild |
| Foto fehlt | zum Referenzbild gibt es kein Foto, etwa weil der Schritt nicht lief |

Verglichen wird in RGBA, ohne Toleranz: Ein Pixel weicht ab, wenn ein Kanal verschieden ist. Das
markierte Bild zeigt das Foto in Graustufen, die abweichenden Pixel in `kassenrot`.

## Eingang und Belege

- **Ablage für Zips:** `build/selbsttest/`, nicht versioniert. Dorthin kommen Zips von anderen Rechnern.
- **Referenzbilder:** `tools/selbsttest/referenz/macos/<kennung>.png`, versioniert. Erneuert werden
  sie nur nach Klaus' Abnahme eines Laufs; die alten bleiben in der Versionsgeschichte.
- **Belege:** `specs/007-build-export-selbsttest/belege/`, versioniert, je Lauf Protokoll, Bericht und
  nur die abweichenden Fotos mit Markierung.

## Ein Lauf auf dem Mac als Referenz

```bash
python3 -I tools/selbsttest/vergleich.py <zip> --referenz-erneuern alle
```

Danach einen zweiten Lauf dagegen vergleichen: alles gleich oder nicht vergleichbar.
