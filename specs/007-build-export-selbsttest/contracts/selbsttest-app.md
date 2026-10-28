# Vertrag: Selbsttest-App

Läufer, Fahrer, Eingabe, Fotos, Ausgabe, Ablage und Zusammenfassung (Spec FR-001 bis FR-017).
Entscheidungen in [research.md](../research.md) R1 bis R12 und R20 bis R22, Felder in
[data-model.md](../data-model.md), Abläufe in [ablaeufe.md](ablaeufe.md), Protokoll in
[protokoll.md](protokoll.md). Signaturen sind Vorgaben; Namen privater Hilfen wählt der Agent.

## Dateien

```text
src/tools/selbsttest/
├── selbsttest_start.tscn / .gd     Startszene (Override main_scene.selbsttest): richtet ein, hängt den Läufer an die Wurzel, lädt den Titel
├── selbsttest_laeufer.gd           class_name SelbsttestLaeufer (Node): Abläufe nacheinander, Ergebnis, Abbruch, Fokus, Fenstertitel
├── selbsttest_fahrer.gd            class_name SelbsttestFahrer (RefCounted): Ziele finden, Zustand lesen, Eingaben bauen
├── selbsttest_eingabe.gd           class_name SelbsttestEingabe (RefCounted): Filter am Fenster, Ereignisse mit device 4711
├── selbsttest_lauf.gd              class_name SelbsttestLauf (RefCounted): Lauf, Abläufe, Schritte, Ergebnisse, Summe
├── selbsttest_protokoll.gd         class_name SelbsttestProtokoll (RefCounted): Text für Datei und „Kopieren“, ohne Node
├── selbsttest_system.gd            class_name SelbsttestSystem (RefCounted): Systemdaten mit festen Schlüsseln
├── selbsttest_logger.gd            class_name SelbsttestLogger (Logger): Ausgabe mit Schritt-Kennung, Mutex
├── selbsttest_ablage.gd            class_name SelbsttestAblage (RefCounted): Ordner, Fotos, Dateien, Zip
├── ablaeufe/                       je Ablauf ein Skript, Basisklasse SelbsttestAblauf
│   ├── selbsttest_ablauf.gd
│   ├── ablauf_titel.gd, ablauf_neues_spiel.gd, ablauf_laden.gd, ablauf_loeschen.gd,
│   ├── ablauf_easter_egg.gd, ablauf_bedienung.gd, ablauf_fenster.gd, ablauf_titel_echtzeit.gd
│   └── selbsttest_szenario.gd      class_name SelbsttestSzenario: Rahmen für Szenarien (R27)
├── szenarien/                      leer bis zum ersten Szenario, mit `.gitkeep` (Analyse, U6)
├── selbsttest_ergebnis.tscn / .gd  Zusammenfassung im Look der Werkzeuge
└── selbsttest_texte.gd             class_name SelbsttestTexte: alle Texte des Selbsttests
src/core/save/save_game.gd          geändert: Stellschraube für den Zeitzonenversatz (R7)
src/test/
├── test_selbsttest_protokoll.gd    neu
├── test_selbsttest_lauf.gd         neu
├── test_selbsttest_system.gd       neu
├── test_selbsttest_fahrer.gd       neu: jedes Ziel im echten Titel, fehlendes Ziel
├── test_projekt_einstellungen.gd   neu: Renderer-Ausweichen, Vollbildtasten, Overrides (R3, R13, R15)
├── test_save_game.gd               erweitert: Zeitzonenversatz
└── fixtures/selbsttest/            erwartete Protokolle
```

## Start (`selbsttest_start.gd`)

1. Ablage anlegen (`user://selbsttest/<lauf-id>/`). Scheitert das: gleich zur Zusammenfassung mit
   Meldung und Pfad.
2. Logger anmelden (`OS.add_logger()`), Systemdaten erheben, Treiberinfo in einem Thread.
3. `GameSession` einstellen: `folder = "user://selbsttest/spielstaende/"`, `now` fest, `rng` mit Seed
   4711; `SaveGame` auf festen Zeitzonenversatz.
4. Eingabe-Filter einschalten, `Input.use_accumulated_input = false`.
5. Läufer mit `get_tree().root.add_child.call_deferred(laeufer)` an die Wurzel hängen, damit er
   Szenenwechsel überlebt; dann `change_scene_to_file()` zum Titel. Der Läufer beginnt, sobald der
   Titel steht.

## Läufer

```gdscript
class_name SelbsttestLaeufer extends Node
const VERSION := 2
signal fertig(lauf: SelbsttestLauf)
func starte(lauf: SelbsttestLauf, ablaeufe: Array[SelbsttestAblauf]) -> void
func schritt_kennung() -> String          # die laufende, für Logger und Fokus
```

- Vorbereitung und Fenster (CHK001): Frischer Titel, angelegte Spielstände und gesetzte
  Fenstergrößen gehen nicht über Eingaben; das Protokoll nennt sie mit `eingaben: Vorbereitung`
  bzw. `eingaben: Fenster`.
- Je Ablauf ohne `baut_auf`: frischer Titel. Läuft ein Spiel, beendet der Läufer es mit
  `GameSession.leave()` (speichert in den Ordner des Selbsttests); dann Ordner leeren, Titel neu
  laden; fertig ist die Vorbereitung, sobald der neue Titel im Baum steht. Hat der erste Schritt
  Eingaben, wartet der Läufer vorher, bis der Communicator steht (Auslegungen aus Phase 2). Keine
  neue Funktion am Spiel (Analyse, I3).
- Je Ablauf: `Engine.time_scale` auf seinen Zeitraffer setzen (R24), danach wieder 1.
- Meldungen (CHK007): Jede Warnung und jeder Fehler aus Godot zählt zum laufenden Schritt; eigene
  Fehler des Selbsttests stehen als `meldung: [selbsttest] …`.
- Je Schritt: Fenstertitel setzen, Eingaben über den Fahrer, warten bis `erwartet` wahr ist oder
  5000 ms vorbei, Foto, Ergebnis mit Dauer und Meldungen. Scheitert ein Schritt, gelten die übrigen
  seines Ablaufs und die Abläufe, die darauf aufbauen, als `NICHT_GELAUFEN`.
- Fokus: `NOTIFICATION_APPLICATION_FOCUS_OUT` vermerkt `fokus.verlust` mit Schritt und Zeit.
- Fenster schließen während des Laufs (`NOTIFICATION_WM_CLOSE_REQUEST`): Abbruch vermerken,
  Protokoll, Ausgabe und Zip schreiben, beenden. Weil `GameSession` beim Schließen selbst beendet,
  solange ein Spiel läuft, setzt der Läufer `GameSession.quit_callback` auf eine eigene Funktion, die
  erst schreibt und dann `get_tree().quit()` ruft (Analyse, U2). `GameSession` speichert dabei wie
  immer, in den Ordner des Selbsttests.
- `dauer_ms` zählt ab der ersten Eingabe, bei Schritten ohne Eingabe ab Beginn des Schritts
  (Analyse, I1).
- Am Ende: Protokoll, Ausgabe, Zip; Eingabe-Filter aus, Logger ab; Szene der Zusammenfassung.

## Ablauf

```gdscript
class_name SelbsttestAblauf extends RefCounted
var kennung: String
var name: String
var baut_auf: String = ""
func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]
# je Schritt: {kennung, beschreibung, eingaben_text, eingaben: Callable (await), erwartet: Callable -> String,
#              erwartet_text, hoechstzeit_ms = 5000, foto_vergleichbar = true}
```

`erwartet` gibt `""` zurück, wenn der Zustand stimmt, sonst den gefundenen Zustand als Text; der
landet in `gefunden`.

## Szenario

```gdscript
class_name SelbsttestSzenario extends SelbsttestAblauf
var grad: Difficulty.Level
var seed: int
func entscheidungen(fahrer: SelbsttestFahrer) -> Array[Dictionary]   # {datum, eingaben: Callable}
func pruefpunkte(fahrer: SelbsttestFahrer) -> Array[Dictionary]      # {kennung, datum, erwartet: Callable, erwartet_text}
```

`SelbsttestSzenario.schritte()` macht daraus Schritte, der Läufer spielt sie wie jeden Ablauf: neues Spiel mit Grad und Seed, dann je Datum in Reihenfolge die
Uhr im Zeitraffer bis dahin laufen lassen, Entscheidung eingeben oder Prüfpunkt prüfen und
fotografieren. Wie die Uhr läuft, sagt der Fahrer; heute kann er es nicht und meldet das als Fehler.
`test_selbsttest_lauf.gd` prüft den Rahmen mit einem erfundenen Szenario ohne Fenster.

## Fahrer

```gdscript
class_name SelbsttestFahrer extends RefCounted
func titel() -> TitleScreen                          # null, wenn kein Titel steht
func spielbildschirm() -> GameScreen
func sichtbare_seite() -> Control
func gewaehlter_eintrag() -> StringName              # Kennung der Zeile mit Fokus
func hinweis_text() -> String
func communicator_steht() -> bool                    # Endlage und keine Fahrt; über slide_finished verfolgt
func spielstaende() -> PackedInt32Array              # Nummern im Ordner des Selbsttests
func ziel_eintrag(seite: StringName, kennung: StringName) -> Rect2   # leer, wenn nicht da
func ziel_zeile(nummer: int) -> Rect2
func ziel_gehaeusetaste(index: int) -> Rect2
func ziel_knopf_hauptmenue() -> Rect2
func fehlt(beschreibung: String) -> String           # „Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel““
```

Alle Rechtecke im Raster 640 × 360; die Umrechnung in Fensterpixel macht `SelbsttestEingabe`.
Ob der Communicator steht, verfolgt der Fahrer über das Signal `slide_finished`: `is_in()` ist schon
während der Fahrt herein wahr (Analyse, I3). Liest nur, was Seiten und Communicator ohnehin anbieten; braucht der Fahrer eine neue Abfrage am
Spiel, ist das eine eigene, kleine Änderung mit Test und steht im Bericht des Agents.

## Eingabe

```gdscript
class_name SelbsttestEingabe extends RefCounted
const DEVICE := 4711
func einschalten(fenster: Window) -> void
func ausschalten() -> void                               # reicht danach alles durch (Analyse, U3)
func maus_zu(punkt_raster: Vector2) -> void               # MouseMotion
func klick(punkt_raster: Vector2, taste := MOUSE_BUTTON_LEFT) -> void   # Bewegung, Drücken, nächstes Bild Loslassen
func rad(punkt_raster: Vector2, richtung: MouseButton) -> void
func taste(keycode: Key, shift := false) -> void          # Drücken, nächstes Bild Loslassen
func taste_halten(keycode: Key, ms: int) -> void
```

Alle Methoden mit Eingaben sind `await`-bar. Echte Ereignisse verwirft der Filter (R4).

## Zusammenfassung (`selbsttest_ergebnis.tscn`)

Nach Abschnitt „Werkzeuge“ im Style-Guide, mit den Ergänzungen aus Phase 4 (Review CHK016 bis
CHK028).

**Fenster und Schrift**
- Wie `werkstatt.gd`: `GameWindow` anhalten (`set_process(false)`,
  `set_process_input(false)`, seit Phase 6 fängt `GameWindow` das Kürzel in `_input()`), `content_scale_mode = DISABLED`,
  `content_scale_factor = DisplayServer.screen_get_scale()`. Das Fenster behält Größe und Lage aus
  dem Lauf und wird nicht maximiert (Klaus, Phase 4: eine reproduzierbare Fenstergröße für den
  Selbsttest; die Zusammenfassung steht einfach darin; ersetzt das Maximieren aus CHK016).
- Theme `werkstatt_theme.tres` als Kopie mit `default_font = ThemeDB.fallback_font` (CHK017).
- Grund `papier` über die ganze Fläche (CHK022).
- Knöpfe als Standard-`Button` ohne eigene Styles; Überfahren, Drücken, Fokus und gesperrt kommen
  aus dem Theme. Tooltip und Handzeiger wie in der Werkstatt (CHK026).

**Aufbau von oben** (CHK021), Rand und Abstand zwischen Bereichen `raster-16`, zwischen dem Text
zweier Einträge `raster-8` (je `raster-4` Innenabstand oben und unten; die Streifen in `endlos-gruen` liegen ohne
Lücke aneinander), zwischen Knöpfen `raster-8`, vom Bereichstitel zur Liste `raster-8`, von der Knopfreihe zur
Bestätigung `raster-16` (CHK022; Style-Guide „Werkzeuge“, Version 60):

| Bereich | Schrift | Farbe |
|---|---|---|
| Überschrift | `werkzeug-titel` | `tusche` |
| Systemzeile | `werkzeug-klein` | `gehaeuse-dunkel` |
| Summe | `werkzeug-titel` | `tusche`; keine Farbe für „in Ordnung“ (CHK019) |
| Bereichstitel „Was nicht stimmt“, nur wenn es Einträge gibt | `werkzeug-titel` | `tusche` auf `papier` |
| Liste, scrollbar | `werkzeug-text` | zweite Farbe `endlos-gruen` je Eintrag (CHK024) |
| Pfad | `werkzeug-text` | `tusche`, umbrochen nach einem Trenner, nie gekürzt (CHK027) |
| Knopfreihe unten, links beginnend: Kopieren, Ordner zeigen, Beenden; rechts daneben die Bestätigung | `werkzeug-text` | Bestätigung in `tusche`, bis zum nächsten Klick (CHK025) |

**Einträge der Liste** (CHK019, CHK034): nicht anklickbar, ohne Überfahren.
- Fehler: Feld in `kassenrot` mit „!“ in `papier`, daneben `{kennung} · {beschreibung}`, darunter
  `Erwartet: {erwartet}` und `Gefunden: {gefunden}`.
- Nicht gelaufen: Feld mit `tusche`-Kontur auf `papier` mit „–“, daneben
  `{kennung} · {beschreibung}`, darunter `Nicht gelaufen: {grund}`.
- Lange Werte umbrechen (CHK027).

**Tasten** (CHK023): Fokus beim Öffnen auf „Kopieren“; Tab und Umschalt+Tab wechseln zwischen den
Knöpfen, Enter und Leertaste lösen aus, Esc tut nichts.

**Ordner nicht beschreibbar** (CHK020): Überschrift und Systemzeile bleiben; an Stelle von Summe,
Liste und Pfad steht die Meldung als Feld (Theme-Variante `ErrorNoticeLabel`, `kassenrot` mit Text
in `papier`). „Ordner zeigen“ ist gesperrt. „Kopieren“ legt Meldung und Systemdaten ab.

**Schließen:** Nach dem Schreiben hört der Läufer nicht mehr auf das Schließen des Fensters;
Schließen auf der Zusammenfassung beendet einfach (CHK028).

## Texte

Alle in `SelbsttestTexte`, freigegeben mit der Checkliste (CHK029 bis CHK039). `{…}` sind
Platzhalter. Zahlwörter nach dem Fall: „von 1 Schritt“, „von 2 Schritten“; „1 Fehler“, „2 Fehler“.

| Wo | Text |
|---|---|
| Fenstertitel im Lauf | `Selbsttest · Schritt {n} von {gesamt}: {ablauf}` |
| Fenstertitel danach | `Der Computerladen Selbsttest` |
| Namen der Abläufe | Titel, Neues Spiel, Spiel laden, Löschen, Easter Egg, Bedienung, Fenster, Titel in Echtzeit |
| Überschrift | `Selbsttest vom {datum}, {uhrzeit} Uhr`, etwa „Selbsttest vom 28.10.2026, 14:03 Uhr“ |
| Systemzeile | `{system} {version} · {grafikkarte} · {grafik_api}` |
| Summe, alles in Ordnung (auch `ergebnis:`) | `Alles in Ordnung: {n} von {n} Schritten.` |
| Summe sonst (auch `ergebnis:`) | `{ok} von {n} Schritten in Ordnung, {f} Fehler, {ng} nicht gelaufen.`; der erste Teil steht immer, Fehler und nicht gelaufen entfallen bei 0 |
| Bereichstitel | `Was nicht stimmt` |
| Eintrag Fehler | `{kennung} · {beschreibung}` / `Erwartet: {erwartet}` / `Gefunden: {gefunden}` |
| Eintrag nicht gelaufen | `{kennung} · {beschreibung}` / `Nicht gelaufen: {grund}` |
| Pfad | `Protokoll und Fotos liegen hier: {pfad}` |
| Knöpfe | `Kopieren`, `Ordner zeigen`, `Beenden` |
| Tooltips | „Legt das Ergebnis als Text in die Zwischenablage.“, „Zeigt das Zip dieses Laufs im Dateimanager.“, „Beendet den Selbsttest.“; „Ordner zeigen“ gesperrt: „Kein Zip: Im Ordner lässt sich nicht schreiben.“ |
| Bestätigung | `Kopiert.`; unter Linux `Kopiert. Erst einfügen, dann beenden.` |
| Ordner nicht beschreibbar | `Kein Protokoll: In {pfad} lässt sich nicht schreiben.` |
| `gefunden` bei FEHLER | `Zeit abgelaufen, zuletzt: {zustand}` / `Ziel nicht gefunden: {ziel}` / der gefundene Zustand |
| Grund bei NICHT_GELAUFEN | `Fehler in Schritt {kennung}` / `Fehler in Ablauf {kennung}` / `Fenster geschlossen` |
| Szenario ohne Bedienung der Uhr | `Die Uhr lässt sich im Spielbildschirm noch nicht bedienen` |
| Kopf des Protokolls | `# Der Computerladen Selbsttest` |

Werte im Protokoll stehen ohne Schlusspunkt, nur `ergebnis:` ist ein Satz (CHK034). Formen
(CHK039): Im Protokoll Maschinenform (`2026-10-28 14:03:12`, `3024x1964`, `2.0`), ausgenommen von den
Regeln für Texte wie Testausgaben; auf dem Bildschirm deutsch („28.10.2026, 14:03 Uhr“,
„640 × 360“). Tasten in Beschreibungen: Enter, Esc, Tab, Umschalt+Tab, Leertaste, Pfeil runter.
Zustände in der Form der Tabellen in [ablaeufe.md](ablaeufe.md) (CHK031, CHK032).

## Was sich am Spiel ändert

- `SaveGame`: eine statische Stellschraube für den Zeitzonenversatz, Vorgabe „wie der Rechner“
  (Phase 1).
- `GameWindow`: Das Fenster steht samt Titelleiste mittig im nutzbaren Bereich,
  `centered_position()` (Klaus, Phase 3); das Vollbild-Kürzel mit F11 und Alt+Enter fängt
  `_input()` mit `exact_match` ab (Phase 6). Die Werkstatt schaltet dafür `set_process_input` ab.
- `InvadersPage` fragt das Kürzel mit `exact_match` ab, sonst rutschte das Loslassen von Enter
  durch (Phase 6).
- Nur lesend: `SaveList.shows_scroll_mark_above()` für die Rollmarke (Phase 3).
- `project.godot`: kein Ausweichen auf OpenGL (R13), Symbol für Windows aus der ICO.

Sonst verhält sich das Spiel ohne Selbsttest wie vorher; alle bisherigen Tests bleiben grün.
