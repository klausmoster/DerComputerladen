# Lernnotizen: Godot- und Spielarchitektur mit Prüf-Agent

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 1

### T001 bis T005 Der Leitfaden: die fünf Prinzipien im eigenen Code

Phase 1 baut keinen Code, sondern den Maßstab dafür (`docs/architektur-leitfaden.md`). Die fünf
Godot-Prinzipien lassen sich alle schon im Spiel ansehen.

- **Kern ohne Node (AR-01).** Ein `Node` lebt im Szenenbaum: Er bekommt `_ready()` und
  `_process()`, kann Kinder haben und Autoloads erreichen. Ein `RefCounted` ist nur ein Objekt im
  Speicher, das verschwindet, sobald niemand mehr darauf zeigt. Es weiß nichts von Baum, Bildern
  oder Uhr. `TimelineRun` (`src/core/timeline/timeline_run.gd`) ist so ein Objekt: Man gibt ihm
  Katalog, Seed und Grad, und `advance_to(day)` gibt die Meldungen bis zu diesem Tag zurück. Dasselbe
  Objekt rechnet im Spiel (über das Autoload `Timeline`), in der Werkstatt (Simulator) und in den
  Tests, jedes Mal gleich. Die **Hülle** `src/core/timeline.gd` ist ein `Node`; sie hängt sich an
  `GameClock.day_passed` und macht aus den Meldungen die Signale `event_fired` und `effect_applied`.
  Die Godot-Doku verlangt das nicht; der Leitfaden schon, weil 15 Spieljahre Wirtschaft nur prüfbar
  sind, wenn sich ein Lauf genau wiederholen lässt.
- **Signal nach oben, Aufruf nach unten (AR-02).** Ein **Signal** ist eine Meldung ohne Empfänger:
  Der Sender ruft `case_key_pressed.emit(index)`, und wer will, hat sich vorher mit `connect()`
  angemeldet. In `src/scenes/title/title_screen.tscn` stehen unten die `[connection …]`-Zeilen: Dort
  meldet sich der Titel bei den Seiten im Communicator an. Der Communicator selbst
  (`src/ui/communicator/communicator.gd`) kennt den Titel nicht; derselbe Communicator könnte morgen
  im Laden hängen. Nach unten dagegen ruft der Titel direkt, etwa `set_entries()` auf einem Blatt.
  Der Merksatz dazu heißt in der Godot-Gemeinde „Call down, signal up“.
- **Autoloads sparsam (AR-03).** Ein **Autoload** ist ein Node, den Godot beim Start einmal anlegt
  und unter einem festen Namen überall erreichbar macht; die Liste steht in `src/project.godot`
  unter `[autoload]`. Praktisch, aber jeder Zugriff von irgendwo ist eine unsichtbare Verbindung.
  Deshalb ist die Liste fest: `GameClock`, `Timeline`, `GameWindow`, `GameSession`. Ein späteres
  Lager wird kein `LagerManager`-Autoload, sondern ein Kern, den `GameSession` besitzt.
- **Die Naht (AR-12).** In `src/scenes/title/title_screen.gd` steht
  `session if session != null else GameSession`. Die Variable `session` ist leer, also gilt das
  Autoload; ein Test setzt vorher eine erfundene Sitzung ein und prüft den Titel, ohne ein echtes
  Spiel zu starten. Das ist Nystroms erster Rat gegen Singletons: die Abhängigkeit hineinreichen.
- **Daten als Resources (AR-04).** Eine **Resource** ist ein Datenobjekt, das Godot als `.tres`
  speichern und im Inspector bearbeiten kann. `MenuEntry` (`src/scenes/title/menu_entry.gd`) ist
  eine: Text, auslösbar ja oder nein, Hinweis. Das Menü liest nur diese Felder. Wichtig: Godot lädt
  eine `.tres`-Datei nur einmal und gibt allen Nutzern dasselbe Objekt. Schreibt einer hinein,
  sehen es alle. Deshalb sind geladene Resources nur zum Lesen da. Der Ereigniskatalog ist JSON statt
  Resource, weil die Werkstatt ihn schreibt; das steht jetzt als begründete Ausnahme im Leitfaden.
- **Szenen-Komposition (AR-05).** Eine `.tscn` kann eine andere Szene als Kind einsetzen
  (`instance=ExtResource(…)`). Der Titel setzt so den Communicator ein und hängt Hauptmenü,
  Gradwahl, Liste, Rückfrage und Space Invaders als Kinder hinein. Jede dieser Szenen ist für sich
  vollständig; Communicator und Space Invaders laufen sogar allein in ihren Probeszenen unter
  `src/test/fixtures/`.

### Warum Muster und Vorbilder

- Ein **Muster** ist eine bewährte Lösung mit Namen. Nystroms „Befehl“ etwa heißt: Ein Aufruf wird
  zu einem Datenobjekt. Genau so arbeiten die Eingriffe der Zeitleiste
  (`src/core/timeline/intervention_file.gd`): Sie stehen als Einträge im Spielstand und werden beim
  Fortsetzen nachgespielt. Deshalb muss ein Spielstand nicht den ganzen Zustand speichern (AR-08,
  AR-09).
- Der **feste Schritt** (AR-10) steht schon im Easter Egg: `InvadersPage.advance()` sammelt die
  Zeit eines Bildes und rechnet `InvadersGame` in ganzen Schritten zu 1/60 Sekunde, höchstens vier je
  Bild. Ein langsamer Rechner zeigt dann weniger Bilder, aber das Spiel verläuft gleich. Factorio
  macht es mit 60 Takten je Sekunde genauso, die Wirtschaft wird es mit einem Takt je Spieltag tun.
- Die Regeln für Wirtschaft (AR-16, AR-17) und Adventure (AR-18 bis AR-20) gelten erst, wenn diese
  Schichten gebaut werden. Sie stehen jetzt schon da, damit das erste Feature der Schicht nicht ohne
  Vorbild beginnt.

## Phase 2

### T008 bis T011 Ein Prüfer, der nur lesen kann, und wie man ihn misst

Kein Godot, sondern Claude Code; aber es bestimmt, wer künftig deinen Code beurteilt.

- Ein **Subagent** ist eine eigene Claude-Sitzung mit eigener Anweisung, eigenen Werkzeugen und
  frischem Kontext; zurück kommt nur sein Bericht. Die Anweisung steht als Datei in
  `.claude/agents/architektur-pruefer.md`, oben im Kopf zwischen den `---`-Zeilen Name, Beschreibung,
  Werkzeuge und Modell. Der frische Kontext ist der Punkt: Der Prüfer hat weder den Plan geschrieben
  noch den Code gebaut und urteilt deshalb nur nach dem Leitfaden.
- `tools: Read, Grep, Glob` ist eine **Positivliste**. Was nicht darin steht, kann der Agent nicht:
  ohne `Edit`, `Write` und `Bash` keine Datei ändern, ohne `Agent` keine weiteren Agents starten. So
  ist „nur lesen“ keine Bitte, sondern eingebaut. `Grep` braucht er, um „wer wen kennt“ zu beurteilen:
  Wer `case_key_pressed` hört, findet nur eine Suche über ganz `src/`.
- Ein neuer Agent-Typ steht erst in einer neuen Sitzung bereit. Fehler- und Planprobe liefen deshalb
  über einen allgemeinen Agent, der zuerst die Datei des Prüfers las; „nur lesen“ stand dort
  ausdrücklich im Auftrag, weil ein allgemeiner Agent alle Werkzeuge hat.
- Die **Fehlerprobe** (`specs/008-architektur/fehlerprobe/`) misst den Prüfer wie eine Fehlerprobe
  einen Test: absichtlich eingebaute Fehler, die er finden muss. Neben jedem Verstoß steht eine
  ähnliche, erlaubte Stelle, etwa im Regal neben `get_parent().kasse_aktualisieren()` das Signal
  `ware_gewaehlt`. Meldet er auch die erlaubte Stelle, urteilt er nach Geschmack und nicht nach
  Regel. Die Lösung liegt außerhalb des Ordners, damit er sie nicht zufällig liest.
- Die **Planprobe** am Plan von 006 zeigt, ob er einen Plan prüfen kann, bevor gebaut wird; dort
  ist ein Fehler noch eine Zeile, später eine Phase.

### T012 bis T016 Wo der Prüfer in der Arbeitsweise steht

- Der Prüfer wird an denselben Stellen eingeplant wie Stil- und Text-Prüfer: im Skill
  `dcl-phasenpruefung`, in der Aufgaben-Vorlage unter `.specify/templates/overrides/` und in
  `ki_pruefung.md`. Die Vorlage liegt unter `overrides/`, weil Spec Kit dort zuerst sucht und ein
  Update nur seine eigenen Vorlagen neu einspielt; deshalb bleiben `speckit-*` und die Vorlagen von
  Spec Kit selbst unberührt.
- Der Godot-Agent liest den Leitfaden jetzt vor jeder Aufgabe. Weicht er begründet ab, schreibt er
  `# Ausnahme AR-NN: …` an die Stelle und meldet es; gültig wird die Ausnahme erst mit Klaus' Zeile
  in der Tabelle des Leitfadens.

## Phase 3

### T022 bis T028 Was der Bestand über den Aufbau zeigt

Die Bestandsprüfung hat den Code aus 001 bis 006 gegen den Leitfaden gelesen. Drei Muster ziehen
sich durch.

- **Zustand als Schalter (AR-11).** Der Titel weiß über `_ready_for_input` und `_leaving`, ob er
  Eingaben annimmt, und über die Sichtbarkeit von fünf Seiten, wo der Spieler gerade ist
  (`src/scenes/title/title_screen.gd`). Jede Eingabe fragt diese Kombination neu ab. Mit einem
  `enum` steht der Zustand an einer Stelle, und `match` zeigt für jeden Zustand, was Esc oder eine
  Gehäusetaste tut. Das Gegenstück gibt es schon: `InvadersGame` hat `enum State`, die Seite drum herum
  nicht. Ein einzelner Schalter wie `_close_failed` in `GameSession` ist dagegen kein Zustand; die
  Regel greift erst, wenn zwei Schalter zusammen etwas bedeuten.
- **Der feste Schritt mit Obergrenze (AR-10).** `GameClock._process()` sammelt `delta` und ruft je
  vollem Tag `advance_day()`, ohne Obergrenze. Hängt das Spiel 10 Sekunden, holt die Uhr im nächsten
  Bild 20 Tage auf einmal nach. `InvadersPage.advance()` begrenzt das mit `MAX_STEPS`; dieselbe Grenze
  bekommt die Uhr.
- **Wer was kennt.** Fast alles hält sich schon an „Signal nach oben“: kein `get_parent()` nach oben
  im Spiel, kein Verweis auf die Werkstatt, Autoloads nur über Nähte. Die Abweichungen liegen an den
  Rändern: Die Werkstatt hält `GameWindow` über `/root/GameWindow` an, weil GDScript den Namen eines
  Autoloads nicht kennt, wenn ein Skript mit `-s` startet. Das ist jetzt eine begründete Ausnahme:
  Kommentar an der Stelle und Zeile in der Tabelle des Leitfadens. Und Panels der Werkstatt rufen
  private Funktionen anderer Panels, etwa `EventForm._reason()`. Ein Unterstrich heißt in GDScript nur
  „intern“, die Sprache verbietet den Aufruf nicht; der Leitfaden tut es jetzt.

### Warum zwei Features statt alles in 008

Klaus hat für 008 entschieden: behoben wird, was in einem Ordner bleibt und keine Schnittstelle nach
außen ändert. `MAX_SEED` steht fünfmal im Code, in `core/` und in der Werkstatt; eine Stelle dafür
zu schaffen, berührt beide. `MenuHint` liegt im Ordner des Titels, obwohl der Communicator unter
`src/ui/` es nutzt; es umzuziehen, berührt drei Ordner. Solche Umbauten stehen als 11-09 und 11-10 in
`docs/features/Feature_Ideas.md`. So bleibt 008 ein Feature über den Maßstab und den Prüfer, und ein
Umbau über mehrere Systeme bekommt seine eigene Spec.

## Phase 4

### T031 `test_architektur.gd`: Regeln, die jeder Testlauf misst

Geschrieben vom Godot-Agent, hier gekürzt.

- **Text lesen statt Skript laden.** `load(pfad).get_instance_base_type()` würde die Basisklasse
  direkt liefern, aber jedes Skript kompilieren und an erfundenen Dateien nicht gehen. Deshalb nimmt
  jede Prüffunktion einen `String`, wie in `test_bilder.gd`: Dieselbe Funktion läuft am echten Code,
  an den kleinen Texten der Fehlerproben und an einer Kopie außerhalb des Repos.
- **Der kleine Leser `_lies()`** trennt Code, Zeichenketten und Kommentare. Sonst wäre
  `## Fragt GameSession …` ein Verstoß. Er macht daraus drei Fassungen desselben Textes, in denen
  Kommentare oder Zeichenketten durch Leerzeichen ersetzt sind; die Zeilenumbrüche bleiben, deshalb
  hat eine Fundstelle in jeder Fassung dieselbe Zeile. Er springt mit `RegEx.search(text, ab)` von
  einem `"`, `'` oder `#` zum nächsten; der Anker `\G` heißt „genau hier beginnen“. Das läuft in C++,
  rund 900 KB Quelltext brauchen Sekundenbruchteile.
- **Welche Fassung welche Regel liest:** Autoloads, `get_tree()` und Zufall zählen nur im Code;
  Knotenpfade stehen immer in Zeichenketten (`get_node("…")`, `^"…"`, `$"…"`, `NodePath("…")` in
  `.tscn`); `res://tools/` zählt in Code und Zeichenketten. `TimelineRun` ist kein `Timeline`, weil
  der Wortrand `(?<![\p{L}\p{N}_])` davor und danach keinen Buchstaben erlaubt.
- **Eigener Würfel oder globaler Zufall:** Steht direkt vor `randf(` ein Punkt, wie bei
  `_rng.randf()`, ist es ein eigener Würfel.
- **Der Leitfaden liegt außerhalb von `res://`.** `ProjectSettings.globalize_path("res://")` liefert
  den echten Ordner von `src/`, dazu `..`, wie `_palettenpfad()` in `test_bilder.gd`.
- **Test gegen Leichen:** Wird die Stelle in `werkstatt.gd` einmal behoben, wird
  `test_listen_ohne_leichen` rot und erinnert daran, den Eintrag zu streichen. So veraltet die Liste
  nicht still.

## Phase 5

### T035 `wege_nach_oben`: Knotenpfad oder Dateipfad

Geschrieben vom Godot-Agent.

- **Dasselbe `../`, zwei Bedeutungen.** In einem Knotenpfad heißt `../` „zum Eltern-Node“, also
  genau der Griff nach oben, den AR-02 verbietet. In einem Dateipfad heißt es „ein Ordner höher“:
  `path_join("../Resources")` in `selbsttest_system.gd` geht im App-Paket von `Contents/MacOS/` nach
  `Contents/Resources/` und berührt keinen Node. Beides ist für den Test nur eine Zeichenkette;
  ohne Unterschied meldet er einen Fehlalarm, und ein Test, der oft falsch rot ist, wird bald
  übergangen.
- **Der Code vor dem Anführungszeichen entscheidet.** `_lies()` merkt sich je Zeichenkette, wo ihr
  öffnendes Anführungszeichen steht (`"oeffnet"`). `_knotenpfad` sucht in der Fassung `code`, in
  der Zeichenketten leer, ihre Anführungszeichen aber stehen geblieben sind, jedes Anführungszeichen
  direkt nach `^` oder `$` oder nach `NodePath(`, `get_node(`, `get_node_or_null(` und `has_node(`.
  Diese Stellen kommen in ein Dictionary, das hier als Menge dient (GDScript hat keinen eigenen
  Typ dafür); nur eine Zeichenkette, deren Anführungszeichen darin steht, zählt mit `../`.
  `/root/` zählt weiter in jeder Zeichenkette ohne `://`, weil es im Spiel nichts anderes meint.
- **Szenen brauchen das nicht.** In einer `.tscn` ist jeder Pfad ohne `://` ein Knotenpfad. Eine
  Szene erkennt die Funktion am Kopf `[gd_scene`, so bleibt die Signatur aus dem Vertrag gleich, und
  die Fehlerprobe zeigt mit demselben Text ohne Kopf, dass der Kopf entscheidet.
- **Grenze:** `var ziel := "../Kasse"` und später `get_node(ziel)` misst der Test nicht; das sieht
  der Prüfer. Der Test misst die Schreibweisen, die man direkt hinschreibt.
