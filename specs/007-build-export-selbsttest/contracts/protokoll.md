# Vertrag: Protokoll eines Laufs

Form von `protokoll.txt` und vom Text für „Kopieren“ (Spec FR-013, FR-014, FR-014a, FR-015, SC-010).
Felder in [data-model.md](../data-model.md). Beide Texte entstehen aus demselben Lauf über dieselbe
Funktion; sie dürfen sich nur darin unterscheiden, dass „Kopieren“ die Schritte mit `OK` weglässt.

## Regeln

- UTF-8 ohne BOM, Zeilenende `\n` auf allen Systemen.
- Jede Zeile ist entweder leer, eine Überschrift `# …` oder eine Angabe `schlüssel: wert`. Werte stehen
  in einer Zeile; Zeilenumbrüche in Werten werden zu `⏎`.
- Schlüssel sind fest, klein, ASCII, mit Punkten gegliedert. Ihre Reihenfolge ist fest. Ein Schlüssel
  fehlt nie; ein unbekannter Wert heißt `unbekannt`.
- Ein Schritt ist ein Block, der mit `schritt: <kennung>` beginnt. Kennungen sind in jedem Lauf und
  auf jedem System gleich (data-model.md, „Schritt“).
- Für Menschen steht oben eine Zeile in Worten; alles andere ist so geschrieben, dass Klaus es lesen
  und Claude es ohne Werkzeug zeilenweise auswerten kann.

## Aufbau

```text
# Der Computerladen Selbsttest
ergebnis: 35 von 37 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.

# Lauf
lauf.start: 2026-10-28 14:03:12
lauf.dauer_ms: 84213
lauf.feste_zeit: 2026-10-26 21:40 UTC+01:00
lauf.zeitraffer: 8
lauf.abbruch: keiner
selbsttest.version: 1
selbsttest.gebaut: 2026-10-28 13:58
computerladen.version: 0.1
godot.version: 4.7.2.stable.official

# System
system.os: macOS
system.os_version: 26.0.0
…                                    alle Schlüssel aus data-model.md, „Systemdaten“

# Fokus
fokus.verluste: 0
                                     je Verlust eine Zeile: fokus.verlust: <kennung> <ms>

# Schritte
schritt: titel.01_start
ablauf: titel
beschreibung: Start, der Communicator fährt herein
eingaben: keine
erwartet: Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine
status: OK
dauer_ms: 1712
zeitraffer: 8
foto: titel.01_start.png
foto_vergleichbar: ja

schritt: neues_spiel.01_gradwahl
ablauf: neues_spiel
beschreibung: Enter auf „Neues Spiel“
eingaben: Maus über „Neues Spiel“, Enter
erwartet: Menü steht: SCHWIERIGKEIT, Mittel
status: FEHLER
gefunden: Zeit abgelaufen, zuletzt: Menü steht: SCHWIERIGKEIT, Leicht
dauer_ms: 5003
zeitraffer: 8
foto: neues_spiel.01_gradwahl.png
foto_vergleichbar: ja
meldung: WARNING: … (je Meldung eine Zeile, in der Reihenfolge des Auftretens)

schritt: neues_spiel.02_zurueck_esc
ablauf: neues_spiel
status: NICHT_GELAUFEN
gefunden: Fehler in Schritt neues_spiel.01_gradwahl

# Summe
summe.ok: 35
summe.fehler: 1
summe.nicht_gelaufen: 1
summe.gesamt: 37
```

- Bei `NICHT_GELAUFEN` stehen nur `schritt`, `ablauf`, `status` und `gefunden` mit dem Grund.
- `gefunden` steht nur bei `FEHLER` und `NICHT_GELAUFEN`.
- `meldung` kann fehlen oder mehrfach stehen; eigene Fehler des Selbsttests während eines Schritts
  als `meldung: [selbsttest] …` (Review CHK007). Die Meldung bei nicht beschreibbarem Ordner gehört
  zu keinem Schritt und steht ohne `[selbsttest]` (Phasenprüfung Phase 1, L4).
- Bleibt ein Schritt durch einen Fehler im Läufer offen, gilt er als `NICHT_GELAUFEN` mit
  `gefunden: unbekannt` (Phasenprüfung Phase 1, L3).
- Die Maschinenform gilt nur für Messwerte: Systemdaten, Zeiten, Dauern. Texte aus den Abläufen in
  `beschreibung:`, `eingaben:` und `erwartet:` bleiben deutsch, Maße mit „ד, etwa „Fenster auf
  1317 × 741“ (Phasenprüfung Phase 1, L1).
- Werte stehen ohne Schlusspunkt, nur `ergebnis:` ist ein Satz. Zeiten, Maße und Zahlen in
  Maschinenform: `2026-10-28 14:03:12`, `3024x1964`, `2.0` (Review CHK034, CHK039).
- Ergebniszeile: `Alles in Ordnung: {n} von {n} Schritten.` oder
  `{ok} von {n} Schritten in Ordnung, {f} Fehler, {ng} nicht gelaufen.`; der erste Teil steht immer
  (Review CHK033). Wortlaute in [selbsttest-app.md](selbsttest-app.md), „Texte“.

## Text für „Kopieren“

Derselbe Aufbau, mit diesen Unterschieden:
- Unter `# Schritte` stehen nur Schritte mit `FEHLER` oder `NICHT_GELAUFEN`.
- Am Ende steht `ordner: <absoluter Pfad des Laufs>`.
- Ist der Ordner nicht beschreibbar, besteht der Text aus Kopf, `# Lauf`, `# System` und
  `meldung: Kein Protokoll: In <pfad> lässt sich nicht schreiben`; ohne Schritte und Summe (Analyse,
  U5). Erwartung in `src/test/fixtures/selbsttest/kopieren_nicht_beschreibbar.txt`.

So erkennt Claude im Chat Systemdaten, Ergebnis und jeden Fehler ohne Rückfrage; für die Fotos braucht
es das Zip.

## Ausgabe (`ausgabe.txt`)

Jede Zeile, die Godot oder das Spiel während des Laufs ausgibt, mit vorangestellter Schritt-Kennung:
`[neues_spiel.01_gradwahl] WARNING: …`. Vor dem ersten Schritt steht `[start]`, nach dem letzten
`[ende]`. Fehler und Warnungen eines Schritts stehen zusätzlich als `meldung:` im Protokoll.

## Prüfung

Ein GUT-Test schreibt einen erfundenen Lauf mit je einem Schritt `OK`, `FEHLER`, `NICHT_GELAUFEN` und
vergleicht `protokoll.txt` und den Text für „Kopieren“ Byte für Byte mit gespeicherten Erwartungen
unter `src/test/fixtures/selbsttest/`.
