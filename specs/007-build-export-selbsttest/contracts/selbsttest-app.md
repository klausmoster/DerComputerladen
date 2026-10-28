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
├── szenarien/                      leer bis zum ersten Szenario
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
const VERSION := 1
signal fertig(lauf: SelbsttestLauf)
func starte(lauf: SelbsttestLauf, ablaeufe: Array[SelbsttestAblauf]) -> void
func schritt_kennung() -> String          # die laufende, für Logger und Fokus
```

- Je Ablauf ohne `baut_auf`: frischer Titel (Ordner leeren, laufendes Spiel ohne Speichern beenden,
  Titel neu laden, warten bis das Hauptmenü steht).
- Je Ablauf: `Engine.time_scale` auf seinen Zeitraffer setzen (R24), danach wieder 1.
- Je Schritt: Fenstertitel setzen, Eingaben über den Fahrer, warten bis `erwartet` wahr ist oder
  5000 ms vorbei, Foto, Ergebnis mit Dauer und Meldungen. Scheitert ein Schritt, gelten die übrigen
  seines Ablaufs und die Abläufe, die darauf aufbauen, als `NICHT_GELAUFEN`.
- Fokus: `NOTIFICATION_APPLICATION_FOCUS_OUT` vermerkt `fokus.verlust` mit Schritt und Zeit.
- Fenster schließen (`NOTIFICATION_WM_CLOSE_REQUEST`): Abbruch vermerken, Protokoll, Ausgabe und Zip
  schreiben, beenden. `GameSession` speichert beim Schließen wie immer, aber in den Ordner des
  Selbsttests.
- Am Ende: Protokoll, Ausgabe, Zip; Eingabe-Filter aus, Logger ab; Szene der Zusammenfassung.

## Ablauf

```gdscript
class_name SelbsttestAblauf extends RefCounted
var kennung: String
var name: String
var baut_auf: String = ""
func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]
# je Schritt: {kennung, beschreibung, eingaben: Callable (await), erwartet: Callable -> String,
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

Der Läufer macht daraus Schritte: neues Spiel mit Grad und Seed, dann je Datum in Reihenfolge die
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
func communicator_steht() -> bool
func spielstaende() -> PackedInt32Array              # Nummern im Ordner des Selbsttests
func ziel_eintrag(seite: StringName, kennung: StringName) -> Rect2   # leer, wenn nicht da
func ziel_zeile(nummer: int) -> Rect2
func ziel_gehaeusetaste(index: int) -> Rect2
func ziel_knopf_hauptmenue() -> Rect2
func fehlt(beschreibung: String) -> String           # „Ziel nicht gefunden: …“
```

Alle Rechtecke im Raster 640 × 360; die Umrechnung in Fensterpixel macht `SelbsttestEingabe`.
Liest nur, was Seiten und Communicator ohnehin anbieten; braucht der Fahrer eine neue Abfrage am
Spiel, ist das eine eigene, kleine Änderung mit Test und steht im Bericht des Agents.

## Eingabe

```gdscript
class_name SelbsttestEingabe extends RefCounted
const DEVICE := 4711
func einschalten(fenster: Window) -> void
func ausschalten() -> void
func maus_zu(punkt_raster: Vector2) -> void               # MouseMotion
func klick(punkt_raster: Vector2, taste := MOUSE_BUTTON_LEFT) -> void   # Bewegung, Drücken, nächstes Bild Loslassen
func rad(punkt_raster: Vector2, richtung: MouseButton) -> void
func taste(keycode: Key, shift := false) -> void          # Drücken, nächstes Bild Loslassen
func taste_halten(keycode: Key, ms: int) -> void
```

Alle Methoden mit Eingaben sind `await`-bar. Echte Ereignisse verwirft der Filter (R4).

## Zusammenfassung (`selbsttest_ergebnis.tscn`)

- Eigene Szene im Look der Werkzeuge, Theme `werkstatt_theme.tres`, Skalierung des Spiels aus,
  Faktor des Bildschirms an (R12). Fenster bleibt in seiner Größe.
- Oben die Zeile `ergebnis:` aus dem Protokoll in Worten, groß; darunter die fehlerhaften und nicht
  gelaufenen Schritte mit Kennung, Beschreibung, Erwartet, Gefunden, scrollbar; darunter der Pfad.
- Knöpfe „Kopieren“, „Ordner zeigen“, „Beenden“. „Kopieren“ bestätigt kurz mit „Kopiert.“
- Scheiterte die Ablage: statt Summe die Meldung mit Pfad; „Kopieren“ legt dann Meldung und
  Systemdaten ab.
- Alle Texte in `SelbsttestTexte`, duzend; Wortlaute legt die Checkliste mit dem Text-Prüfer fest.

## Was sich am Spiel ändert

Nur `SaveGame`: eine statische Stellschraube für den Zeitzonenversatz, Vorgabe „wie der Rechner“.
Ohne Selbsttest verhält sich das Spiel wie vorher; alle bisherigen Tests bleiben grün.
