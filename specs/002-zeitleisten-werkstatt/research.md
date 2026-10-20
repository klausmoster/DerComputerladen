# Recherche: Zeitleisten-Werkstatt

Grundlage: [spec.md](spec.md), [Verfassung 2.1.0](../../.specify/memory/constitution.md), der
vorhandene Code unter `src/core/` und `src/data/`, die Feature-Docs 01-01 und 01-02. Godot-Stand:
4.7.2. API-Angaben stammen aus der Klassenreferenz 4.7 (docs.godotengine.org/en/4.7); was mit
„Probe“ markiert ist, wurde am 2026-10-20 headless in Godot 4.7.2 ausprobiert.

## R1 Kern ohne Node, Autoload als Hülle

- **Entscheidung:** Die ganze Logik steckt in `TimelineRun`, einer Klasse auf `RefCounted` ohne
  Szene und ohne Uhr. Sie nimmt Katalog und Seed entgegen, legt den Fahrplan an und spielt auf
  Aufruf Tage ab. Jeder Aufruf gibt die Meldungen dieses Abschnitts als Liste zurück. Das
  Autoload `Timeline` verbindet den Kern mit `GameClock.day_passed` und macht aus den Meldungen
  Signale. Werkstatt, Textausgabe, Statistik und Tests benutzen `TimelineRun` direkt.
- **Begründung:** So läuft derselbe Code im Spiel, in den Tests und in der Werkstatt (US5), ohne
  dass die echte Uhr laufen muss. Eine Liste von Meldungen lässt sich in Tests einfach
  vergleichen, Signale müsste man erst abhören. Das Muster heißt „funktionaler Kern, imperative
  Hülle“.
- **Alternativen:** Logik im Autoload wie bisher (nur mit laufender Uhr testbar, die Werkstatt
  bräuchte eine zweite Uhr); Kern als `Node` (braucht einen Szenenbaum, für Statistik über
  1.000 Spiele unnötiger Ballast).

## R2 Datenklassen: RefCounted, Namen bleiben

- **Entscheidung:** `TimelineEvent` und `EventEffect` bleiben als Klassennamen erhalten, werden
  aber von `Resource` auf `RefCounted` umgestellt und bekommen das neue Modell (data-model.md).
  Neu sind `EventCategory`, `FollowUp`, `EventCondition`, `ScheduleEntry`, `ChanceModifier` und
  `TimelineMessage`. Jede Datenklasse hat `static func from_dict()` und `func to_dict()`.
- **Begründung:** Die Signale `event_fired(event: TimelineEvent, …)` und
  `effect_applied(effect: EventEffect, …)` behalten so ihre Signaturen (FR-017). `Resource` lohnt
  sich, wenn Daten als `.tres` gespeichert oder im Inspector bearbeitet werden; beides fällt weg,
  der Katalog ist JSON. `RefCounted` ist leichter und wird nicht versehentlich zur `.tres`
  (dieselbe Begründung wie bei `GameDate` in 01-01).
- **Alternativen:** neue Namen wie `EventDefinition` (klarer, bricht aber den Signalvertrag);
  `Resource` behalten (kein Nutzen, und die `@export`-Anmerkungen versprächen einen Inspector,
  den es nicht gibt).

## R3 Format des Ereigniskatalogs

- **Entscheidung:** Eine Datei `src/data/event_catalog.json`, Format in
  [contracts/ereigniskatalog.md](contracts/ereigniskatalog.md):
  - geschrieben mit `JSON.stringify(daten, "\t", true)`: Tabs, Schlüssel alphabetisch sortiert;
  - Ereignisse nach Kennung sortiert, Kategorien in der Reihenfolge der Zeilen im Zeitstrahl;
  - Schlüssel englisch wie die Felder im Code, Texte deutsch;
  - Datumsangaben als `"JJJJ-MM-TT"`, Tage im Jahr als `"MM-TT"` oder `"MM-ende"`;
  - Wahrscheinlichkeiten und Stärken als Anteil von 0 bis 1 (`0.03` = 3 %), wie bisher in
    `EventDatabase`.
- **Probe:** `JSON.stringify` schreibt `int` ohne Nachkomma (`14`), `float` mit (`1.0`, `0.03`);
  `0.03 + 0.05` erscheint als `0.08`. `JSON.parse` liefert jede Zahl als `float` (14 → 14.0). Der
  Katalog wandelt deshalb ganzzahlige Felder beim Lesen mit `int()` um und schreibt sie als `int`.
  Sonst würde aus `14` beim nächsten Speichern `14.0`, und jede Datei hätte einen falschen Diff.
- **Begründung:** Eine Datei ist für die Werkstatt einfach zu lesen und zu schreiben. Sortierte
  Schlüssel und Ereignisse ergeben eine kanonische Form: Gleicher Inhalt ergibt gleiche Datei, eine
  Feldänderung ändert genau eine Zeile (FR-035). Die Datumsform ist im Diff ohne Umrechnung lesbar.
  02-01 hat für die Produkte aus denselben Gründen JSON gewählt.
- **Alternativen:** eine Datei je Ereignis (viele kleine Dateien, Umbenennen heißt Datei
  umbenennen); deutsche Schlüssel (näher an der game_bible, aber zweierlei Namen für dasselbe
  Feld); Tagesindizes statt Datum (im Diff unlesbar); Prozentzahlen (`3` statt `0.03`, wäre
  lesbarer, aber anders als `magnitude` und als jeder bisherige Wert).

## R4 Katalog lesen: Spiel und Werkstatt

- **Entscheidung:** Beide lesen mit `FileAccess.get_file_as_string()` und parsen mit einer
  `JSON`-Instanz. Bei einem Fehler nennen `get_error_line()` und `get_error_message()` die Stelle
  (Probe: kaputte Datei → `ERR_PARSE_ERROR`, „Zeile 3: Expected value“). Strukturfehler wie ein
  fehlendes Feld werden zu Prüfmeldungen. Schwere Fehler schließen im Spiel nur das betroffene
  Ereignis aus, nicht den ganzen Katalog (FR-049).
- **Export:** Die Doku rät, Projektdateien nach dem Export über `ResourceLoader` zu lesen, weil
  importierte Dateien im Paket umgewandelt liegen. JSON wird nicht importiert: `load()` liefert
  die Datei als `JSON`-Ressource (Probe), sie liegt also unverändert im Paket. Ob
  `FileAccess` sie in der exportierten App findet, prüft der Quickstart. Falls nicht, kommt
  `*.json` in den Include-Filter des Presets.
- **Alternativen:** `load()` als `JSON`-Ressource (liefert bei Fehlern nur `null` ohne Zeile und
  legt den Katalog in den Ressourcen-Cache, was die Werkstatt beim Neuladen stört).

## R5 Zufall: ein Seed je Spiel, ein Würfel je Ereignis

- **Entscheidung:**
  - Jedes Spiel hat einen Seed (`int`).
  - Jedes Ereignis bekommt für jeden Zweck einen eigenen `RandomNumberGenerator`. Dessen
    Startwert sind die ersten 8 Byte von SHA-256 über `"<seed>|<zweck>|<kennung>"`
    (`String.sha256_buffer().decode_u64(0)`).
  - Zwecke: `chance` für die Würfelrunden, `preset` für die beim Start gesetzten Termine,
    `follow|<quelle>|<nr>|<tag>` für jede Entscheidung über ein Folgeereignis.
  - Der `chance`-Würfel eines Ereignisses würfelt in jedem der 180 Monate genau zweimal: Wurf und
    Tag. Das geschieht auch dann, wenn das Ereignis in diesem Monat gar nicht in Frage kommt.
- **Begründung:** Damit hängt jede Entscheidung nur von Seed, Ereignis und Zeitpunkt ab (FR-015):
  - Eine Spieleraktion verschiebt nur die Schwelle; der Wurf bleibt gleich.
  - Ein neues Ereignis verschiebt die Würfe der anderen nicht.
  - Dass der Monat immer zwei Würfe kostet, hält die Folge in Takt, egal was vorher geschah.

  Die Doku sagt, ähnliche Startwerte ergäben ähnliche Folgen, und empfiehlt einen Hash davor. Dazu
  dient SHA-256. Spiele mit teilbaren Seeds machen es genauso: Slay the Spire etwa hat getrennte
  Zufallsquellen je Bereich.
- **Probe:** Gleicher Startwert ergibt dieselbe Folge. `rand_weighted([30, 70])` trifft bei
  10.000 Würfen 3.024 zu 6.976.
- **Grenze:** Die Doku nennt PCG32 „ein Implementierungsdetail“. Gleiche Ergebnisse sind deshalb
  nur bei gleicher Godot-Version zugesagt; über Betriebssysteme hinweg gelten sie, denn PCG32 und
  SHA-256 rechnen nur mit ganzen Zahlen. Nach einem Godot-Update werden gespeicherte Textausgaben
  neu erzeugt, falls sich etwas ändert. Für 11-01 heißt das: Spielstände speichern Seed, Fahrplan
  und Eingriffe, nicht den Zustand der Würfel.
- **Alternativen:**
  - Ein gemeinsamer Generator wie bisher (`randomize()`): Jede Kleinigkeit würfelt das
    restliche Spiel neu, und kein Lauf lässt sich wiederholen.
  - SHA-256 für jeden einzelnen Wurf: rein rechnerisch die sauberste Lösung, aber 1.000 Spiele
    würfeln rund 4,5 Millionen Mal, das sprengt SC-004.
  - Godots `hash()`: ist schneller, aber nicht als stabil dokumentiert und nur 32 Bit breit.

## R6 Fahrplan und Tagesablauf

- **Entscheidung:** Beim Anlegen stehen alle fixen, jährlichen und beim Start gesetzten Termine
  im Fahrplan. Jeder Termin hat eine laufende Nummer (`serial`) in der Reihenfolge seines
  Entstehens. Ein Tag läuft in dieser festen Folge ab (FR-016):
  1. Enden: laufende Termine, deren Ende auf diesen Tag fällt, und ihre Wirkungen „während“.
  2. Verzögerte Wirkungen, die heute fällig werden.
  3. Würfelrunde, nur am Monatsersten, Ereignisse in Kennungsreihenfolge.
  4. Beginne: geplante Termine des Tages in der Reihenfolge Herkunft (fix, jährlich, gesetzt,
     gewürfelt, Folge, Eingriff), dann Kennung, dann laufende Nummer. Folgeereignisse ohne
     Verzögerung kommen hinten an und laufen am selben Tag.
- **Stichtage:** `advance_to(tag)` prüft nicht jeden Tag einzeln, sondern springt zum nächsten
  Tag, an dem etwas ansteht: Termin, Ende, fällige Wirkung oder Monatserster. Ein Spiel hat damit
  rund 300 statt 5.478 Schritte. Ob die Uhr Tag für Tag oder in Sprüngen ruft, ändert nichts an
  den Meldungen (SC-002).
- **Begründung:** Eine feste Folge macht das Protokoll wiederholbar und im Fahrplan sichtbar.
  Enden vor Beginnen verlangt die Spec, und so wechselt der Winter am 01.03. sauber zum Frühling.
- **Alternativen:** jeden Tag alle Ereignisse prüfen wie bisher (bei 1.000 Spielen zu langsam);
  eine Prioritätswarteschlange (bei einigen Hundert Terminen kein Gewinn gegenüber Wörterbüchern
  nach Tag).

## R7 Beim Start gesetzte Ereignisse

- **Entscheidung:** Der `preset`-Würfel zieht erst die Anzahl mit
  `rand_weighted(count_weights)`, dann die Termine. Für k Termine mit Mindestabstand g im Fenster
  der Länge L werden k Zahlen gleichverteilt aus 0 bis L − (k − 1) · g gezogen und sortiert; die
  i-te bekommt i · g dazu.
- **Begründung:** Das Verfahren verteilt gleichmäßig über alle erlaubten Anordnungen und hält den
  Mindestabstand immer ein, ohne neu zu würfeln. Die Zahl der Würfe hängt nur von k ab, ist also
  wiederholbar.
- **Alternativen:** würfeln und verwerfen, bis der Abstand passt (Zahl der Würfe schwankt, bei
  engen Fenstern endlos); feste Abstände (keine echte Streuung).

## R8 Würfelrunde für Ereignisse über Wahrscheinlichkeit

- **Entscheidung:** Am Ersten jedes Monats, auch am 01.01.1985, würfelt jedes Ereignis über
  Wahrscheinlichkeit zweimal (R5): Wurf w und Tag t. Ein Termin entsteht, wenn alles zutrifft:
  - Der Monat überschneidet das Zeitfenster.
  - Die Bedingungen sind erfüllt.
  - Die Höchstzahl ist nicht erreicht; dabei zählen alle Termine außer entfallenen und
    abgesagten.
  - Der gewürfelte Tag liegt mindestens den Mindestabstand hinter dem Beginn des letzten Termins.
  - w liegt unter der wirksamen Chance.

  Der Tag ist der t-te Teil der Tage dieses Monats, die im Zeitfenster liegen. Der Termin bekommt
  Würfelwert, Schwelle und die beteiligten Modifikatoren als Begründung.
- **Begründung:** Das Würfeln im Januar 1985 fehlte bisher (offene Frage in 01-02). Ein
  gewürfelter Tag verteilt die Ereignisse über den Monat, statt alle auf den Ersten zu legen.
- **Alternativen:** Ereignis am Monatsersten (alles ballt sich); täglich würfeln (180-mal so
  viele Würfe, Chancen müssten auf Tage umgerechnet werden).

## R9 Dauer und jährliche Ereignisse

- **Entscheidung:**
  - `end_day` eines Termins ist der Tag, an dem sein Ende gemeldet wird: Beginn + Dauer. Ohne
    Dauer ist er gleich dem Beginn, und nichts endet.
  - Jährliche Ereignisse haben Beginn und Ende als Tag im Jahr; „ende“ heißt Monatsende, so
    stimmt der Februar in Schaltjahren.
  - Es entstehen alle Vorkommen, die sich mit dem Spielzeitraum und mit den Jahren von–bis
    überschneiden, auch eines, das vor dem 01.01.1985 begonnen hat. Ein solches Vorkommen beginnt
    im Fahrplan am 01.01.1985 und trägt die Herkunft „jährlich, lief schon vor Spielbeginn“.
  - Jede Wirkung hat `scope` `ONCE` oder `DURING`. `DURING` meldet Beginn und Ende. Eine
    verzögerte `DURING`-Wirkung beginnt später und endet mit dem Ereignis.
  - Ein Ereignis, das noch läuft, beginnt nicht erneut (FR-022); der neue Termin entfällt mit
    Begründung.
- **Begründung:** So deckt ein Modell Weihnachtsgeschäft, Jahreszeiten und Lieferengpass ab, und
  das Ende fällt nie auf einen falschen Tag. Der Winter am ersten Spieltag (US3, Szenario 2)
  ergibt sich ohne Sonderfall.
- **Alternativen:** Dauer nur in Tagen, auch bei jährlichen Ereignissen (Winter wäre in
  Schaltjahren einen Tag zu kurz); Jahreszeiten aus dem Datum berechnen wie bisher (widerspricht
  der Verfassung: alles, was etwas auslösen kann, steht in der Timeline).

## R10 Folgeereignisse und Ketten

- **Entscheidung:** Beginnt ein Ereignis, entscheidet je Folgeereignis ein eigener Würfel über
  ob (Wahrscheinlichkeit) und wann (Tag aus der Verzögerungsspanne). Eine Kette am selben Tag
  bricht nach `MAX_CHAIN = 16` Gliedern ab und meldet das. Die Prüfung im Katalog sucht Kreise
  über Kanten mit 100 % und Verzögerung 0 und meldet sie als Fehler.
- **Begründung:** Die Kettenbremse ersetzt den fehlenden Schutz vor Endlosschleifen aus 01-02.
  16 Glieder sind weit mehr, als ein sinnvoller Spieltag braucht. Der Würfel je Entscheidung hält
  FR-015 ein.
- **Alternativen:** Kreise nur im Katalog verbieten (Kreise mit Zufall oder Verzögerung sind
  erlaubt und können trotzdem lang werden); Folgeereignisse als Wirkungsart `SPAWN` wie bisher
  (vermischt Meldung und Ablauf).

## R11 Eingriffe

- **Entscheidung:**
  - **Modifikatoren:** Wert als Anteil, `+0.05` heißt +5 Prozentpunkte. Beginn und Ende sind
    Tagesindizes, das Ende ist Pflicht. Ob ein Modifikator gilt, wird beim Würfeln geprüft;
    abgelaufene werden nicht aufgeräumt, sondern übersprungen (wie 01-07 entschieden). Die
    wirksame Chance ist Grundchance plus Summe, begrenzt auf 0 bis 1.
  - **Termine:** Absagen, Verschieben und Einplanen gehen nur für Tage nach dem zuletzt
    abgespielten Tag und nur für Termine, die nicht fix oder jährlich sind. Jeder Eingriff erzeugt
    eine Meldung `INTERVENTION` im Protokoll.
  - Abgelehnte Eingriffe geben einen `Error` zurück, den Grund auf Deutsch in `last_refusal`.
- **Statistik mit Eingriffen:** Modifikatoren und Einplanungen beziehen sich auf Ereignisse und
  Tage und lassen sich auf jeden Seed übertragen. Absagen und Verschiebungen beziehen sich auf
  einen Termin eines bestimmten Seeds und lassen sich nicht übertragen. Die Statistik nimmt
  deshalb nur Modifikatoren und Einplanungen mit; FR-045 ist entsprechend präzisiert.
- **Alternativen:** Chance im Katalog überschreiben (verboten durch FR-025); Eingriffe in die
  Vergangenheit (würden das Protokoll umschreiben).

## R12 Meldungen und Signale

- **Entscheidung:**
  - `Timeline` behält `event_fired(event, date)` und `effect_applied(effect, source, date)`
    (FR-017). Neu sind `event_ended(event, date)`, `effect_ended(effect, source, date)` und
    `entry_skipped(entry, date)`.
  - `start_game(seed)` legt einen neuen Lauf an. Bis es „Neues Spiel“ gibt, ruft das Autoload es
    per `call_deferred()` am Ende des ersten Bilds auf, also nach dem `_ready()` der Hauptszene.
    So hören Abnehmer in der Szene den ersten Spieltag schon mit.
  - Für spätere Abnehmer gibt es außerdem `running_entries()`: Sie fragen damit beim Einstieg den
    Stand ab.
- **Begründung:** Ein Abnehmer, der erst später dazukommt (etwa nach dem Laden), braucht den
  Zustand und nicht nur die Änderungen. Das ist das übliche Paar aus Abfrage und Meldung.
- **Alternativen:** Spielbeginn direkt in `_ready()` des Autoloads (die Meldungen des ersten Tags
  gingen ins Leere).

## R13 Die Werkstatt als Szene im Projekt

- **Entscheidung:**
  - **Ort und Start:** `src/tools/werkstatt/werkstatt.tscn`. Gestartet wird im Editor mit F6
    („Aktuelle Szene starten“) oder mit
    `Godot --path src res://tools/werkstatt/werkstatt.tscn`.
  - **Fenster:** In `_ready()` setzt die Werkstatt `content_scale_mode` des Fensters auf
    `CONTENT_SCALE_MODE_DISABLED` und schaltet das Fenster auf `MODE_MAXIMIZED`, außer es läuft
    eingebettet im Editor (`Engine.is_embedded_in_editor()`). Sie schaltet die Verarbeitung von
    `GameWindow` ab, damit dessen Ganzzahl-Größe das Fenster nicht zurücksetzt.
  - **Headless:** Läuft Godot ohne Fenster, lässt die Werkstatt das Fenster in Ruhe; das braucht
    der Rauchtest.
  - **Export:** Der Export schließt `tools/*` aus wie heute `test/*`.
- **Begründung:** Die Werkstatt soll viel Text auf einen großen Bildschirm bringen (FR-029),
  das Spielraster 640 × 360 ist dafür zu klein. Die Eigenschaften lassen sich zur Laufzeit setzen
  (öffentliche Setter in der Klassenreferenz). Ob das Umschalten aus dem Vollbild unter macOS
  sauber aussieht, prüft der Quickstart.
- **Alternativen:** Editor-Plugin (von Klaus verworfen, siehe Spec); eigene Projekteinstellungen
  für die Werkstatt (Godot kennt nur ein Set je Projekt).

## R14 Look der Werkstatt

- **Entscheidung:** Eigenes Theme `werkstatt_theme.tres` auf dem Wurzelknoten der Werkstatt. Es
  verdeckt für alles darunter das Projekt-Theme. Die Farben kommen aus `UiPalette`, ihre Rollen
  (Grund, Fläche, Text, Auswahl, Fehler, Warnung) legt der neue Abschnitt „Werkzeuge“ im
  Style-Guide fest. Als Schrift schlägt der Plan Godots eingebaute Schrift
  (`ThemeDB.fallback_font`) vor, gesetzt per Code als `default_font`; dafür braucht es keine neue
  Datei und keine Lizenz. Die endgültige Wahl trifft der Style-Guide-Abschnitt.
- **Wichtig:** Das Theme muss `default_font` selbst setzen. Ohne eigene Schrift fällt Godot auf
  das Projekt-Theme zurück, und dort steht Ark Pixel.
- **Kategorienfarben:** Im Katalog stehen Token-Namen der Palette (`"petrol"`). `UiPalette`
  bekommt dafür `static func by_token(token: StringName) -> Color`.
- **Alternativen:** Godots Standard-Theme (von Klaus verworfen, Option „nüchternes Werkzeug“);
  Pixelschriften der Spieloberfläche (bei voller Auflösung winzig).

## R15 Bearbeiten und Rückgängig

- **Entscheidung:** Alle Änderungen am Katalog laufen über `CatalogEditor`, eine Klasse ohne
  Oberfläche, mit einem `UndoRedo`:
  - Jede Änderung ist eine Aktion mit `add_do_method`/`add_undo_method`.
  - Ein Ziehen auf dem Zeitstrahl wird erst beim Loslassen zu einer Aktion, ein Cmd+Z nimmt also
    das ganze Ziehen zurück.
  - Ob es ungespeicherte Änderungen gibt, sagt der Vergleich von `get_version()` mit dem Stand
    beim Speichern; laut Doku ist sie genau dafür da.
- **Kürzel:** `InputEventKey` mit `command_or_control_autoremap = true`: Cmd auf dem Mac, Ctrl
  unter Windows und Linux. Belegt sind S, Z und Shift+Z.
- **Schließen:** `get_tree().auto_accept_quit = false`; `_notification()` fängt
  `NOTIFICATION_WM_CLOSE_REQUEST` ab und fragt bei ungespeicherten Änderungen nach. Ob Cmd+Q unter
  macOS dieselbe Meldung schickt, prüft der Quickstart.
- **Fremde Änderung:** Beim Öffnen merkt sich die Werkstatt `FileAccess.get_modified_time()`. Hat
  sich der Wert vor dem Speichern geändert, fragt sie nach.
- **Probe:** `UndoRedo.new()` funktioniert außerhalb des Editors: Aktion ausgeführt, `undo()` nimmt
  sie zurück, `get_version()` zählt hoch.
- **Hinweis:** `UndoRedo` erbt von `Object`, nicht von `RefCounted`. `CatalogEditor` muss es
  beim Abräumen selbst freigeben (`NOTIFICATION_PREDELETE`).
- **Alternativen:** eigener Verlauf mit Kopien des ganzen Katalogs (einfach, aber bei jedem
  Tastendruck eine Kopie); `EditorUndoRedoManager` (nur in Editor-Plugins).

## R16 Zeitstrahl

- **Entscheidung:** Ein eigenes `Control` (`TimelineView`):
  - **Zeichnen:** `_draw()` zeichnet Jahresachse, eine Zeile je Kategorie, fixe Ereignisse als
    Punkt oder Balken, Zeitfenster als Rahmen und Wahrscheinlichkeiten als Band mit Prozentzahl.
  - **Maus:** `_gui_input()` übernimmt Ziehen, Doppelklick und Rechtsklick (dann ein
    `PopupMenu`). Hinweise liefert `_get_tooltip(at_position)`; sie erscheinen, solange
    `mouse_filter` nicht `IGNORE` ist.
  - **Zoom:** mit dem Mausrad bei gedrückter Cmd- bzw. Ctrl-Taste, um die Mausposition herum.
  - **Verschieben:** Mausrad, Shift+Mausrad oder Ziehen auf leerer Fläche.
  - **Genauigkeit:** Ab der Monatsansicht sind Tage als Striche zu sehen. Beim Ziehen steht das
    Datum tagesgenau neben dem Mauszeiger.
- **Begründung:** Eigenes Zeichnen ist für eine Achse mit Hunderten Marken das Übliche und
  schnell. Zugleich lernt Klaus dabei, was er für Spielansichten braucht: `_draw`, Eingaben,
  Tooltips.
- **Alternativen:** je Ereignis ein eigenes Control in einem Container (viele Nodes, Zoom wird
  zäh); `GraphEdit` (für Knotengraphen gedacht, nicht für Zeitachsen).

## R17 Statistik ohne Ruckeln

- **Entscheidung:** `TimelineStatistics` rechnet die Spiele in Häppchen: Die Werkstatt ruft je
  Bild `run_batch(25)` auf und wartet dazwischen mit `await get_tree().process_frame`. Abbrechen
  setzt ein Flag; das Ergebnis der fertigen Spiele bleibt stehen. Mit Stichtagen (R6) dauert ein
  Spiel mit dem heutigen Katalog wenige Millisekunden, 1.000 Spiele also Sekunden (SC-004).
- **Begründung:** Häppchen im Hauptthread sind einfach zu verstehen und brauchen keinen Schutz
  vor gleichzeitigem Zugriff.
- **Alternativen:** `Thread` oder `WorkerThreadPool` (schneller auf vielen Kernen, aber Katalog
  und Ergebnis müssten gegen gleichzeitigen Zugriff geschützt werden, für einen Lernenden ein
  Minenfeld); alles in einem Zug (die Werkstatt friert ein, Abbrechen ginge nicht).

## R18 Textausgabe auf der Konsole

- **Entscheidung:** Ein SceneTree-Skript `src/tools/werkstatt/fahrplan_ausgabe.gd`:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --bis 1999-12-31
  ```

  - Optionen nach `--`, gelesen mit `OS.get_cmdline_user_args()`: `--katalog` mit einem Pfad zu
    einem anderen Katalog, `--protokoll` für alle Meldungen statt nur der Termine.
  - Die Zeilen baut `ScheduleText`. Dieselbe Klasse nutzen die Tests, die die Ausgabe vergleichen.
  - Bei Katalogfehlern stehen sie auf stderr, Exit-Code 1.
- **Begründung:** Die Doku nennt `-s` mit `extends SceneTree` als Weg für Skripte ohne Szene. Eine
  Textausgabe lässt sich mit `diff` vergleichen (SC-002).
- **Alternativen:** eine Szene mit `--quit-after` (startet unnötig die Oberfläche); ein
  EditorScript (nur im Editor, nicht im Terminal).

## R19 Übernahme der vorhandenen Ereignisse

- **Entscheidung:** In zwei Schritten, bevor der alte Code fällt:
  1. **Schnappschuss:** Ein Einmal-Skript außerhalb des Repos erzeugt mit dem alten
     `EventDatabase` die Datei `src/test/fixtures/historische_ereignisse.txt`. Darin steht je
     fixes Ereignis eine Zeile mit Datum, Kennung und Wirkungen.
  2. **Katalog:** Ein zweites Einmal-Skript schreibt aus denselben Daten
     `src/data/event_catalog.json`:
     - Kategorie-Enum → Kategorie-Kennung (`hardware` …).
     - `earliest_year`/`latest_year` → Zeitfenster 01.01. bis 31.12.
     - `cooldown_days` → `min_gap_days`.

  Danach werden `event_database.gd`, die alten Tests und `timeline_demo` gelöscht. Neu dazu
  kommen Kalender-Ereignisse, Kategorie „Kalender“ und die Kategorienfarben.
- **Startwerte der Kalender-Ereignisse** (Klaus stellt in der Werkstatt nach):

  | Ereignis | Termin | Wirkung |
  |---|---|---|
  | Weihnachtsgeschäft | 01.11. bis Ende Dezember | „Kundenstrom alles +30 %“, während |
  | Frühling, Sommer, Herbst, Winter | je 1. März, Juni, September, Dezember bis zum Monatsende vor der nächsten | keine |
  | CeBIT | 15. bis 21. März, ab 1986 | Pressemeldung mit Ziel `messe`, einmal |
- **Begründung:** Der Schnappschuss belegt SC-005 („wie vor dem Umbau“) auch dann noch, wenn der
  alte Code weg ist. Ein Skript überträgt 25 Ereignisse fehlerfrei; von Hand abzuschreiben wäre
  fehleranfällig.
- **Alternativen:** von Hand abschreiben; den alten Code als Prüfreferenz behalten (toter Code,
  den 01-01 ausdrücklich nicht will).

## R20 Tests

- **Entscheidung:** GUT-Tests je Klasse unter `src/test/`. Sie arbeiten mit Test-Katalogen unter
  `src/test/fixtures/`, nie mit dem echten Katalog. Davon ausgenommen ist
  `test_shipped_catalog.gd`, der genau den echten Katalog prüft: fehlerfrei, die 19 historischen
  Ereignisse wie im Schnappschuss, die Kalender-Ereignisse vorhanden.
  - Jede Prüfregel bekommt eine kaputte Fixture (SC-006).
  - Der Rauchtest lädt die Werkstatt headless und prüft, dass sie ohne Fehler aufbaut.
  - Zeitstrahl, Formulare, Fenster und Look prüft Klaus von Hand nach dem Quickstart.
- **Begründung:** Abnahme unabhängig vom Spielinhalt (Annahme in der Spec); der echte Katalog
  ändert sich laufend in der Werkstatt.

## R21 Größe des Katalogs

- **Entscheidung:** Ausgelegt wird für bis zu 500 Ereignisse. Die Zielzeiten aus SC-004 gelten für
  den übernommenen Katalog. Mit 500 Ereignissen dürfen Statistik und Werkstatt langsamer werden,
  bleiben aber bedienbar: Die Statistik läuft in Häppchen, und die Prüfung läuft nach jeder
  Änderung in unter 100 ms.
- **Begründung:** Die Ideensammlung („Zeitgeschehen in der Zeitung“) kann einige Hundert reine
  Meldungen bringen; mehr ist nicht absehbar.
