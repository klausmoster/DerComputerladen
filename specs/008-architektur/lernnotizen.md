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

### T036a Kleine Behebungen ohne Änderung am Verhalten

Geschrieben vom Godot-Agent.

- **Ein `enum` statt mehrerer Schalter (K2, S2, W4, B3; AR-11).** Zwei Schalter wie `paused` und
  `_ended` in `src/core/game_clock.gd` ergeben vier Kombinationen, von denen eine Unsinn ist:
  „am Ende, aber nicht angehalten“. Ein `enum State { RUNNING, PAUSED, ENDED }` hat genau die drei,
  die es gibt; ein Wechsel ist eine Zuweisung an einer Stelle. Damit Tests und Werkzeuge weiter
  `clock.paused = false` schreiben können, ist `paused` jetzt eine Eigenschaft mit `get:` und
  `set:` ohne eigenen Speicher: Lesen fragt den Zustand, Setzen ändert ihn, am Ende nicht.
  Genauso in `InvadersPage` (keine Partie, läuft, Ergebnis gesperrt, Ergebnis wartet, beendet),
  `StatisticsPanel` (nie gerechnet, rechnet, abgebrochen, fertig) und `SelbsttestLaeufer` (bereit,
  läuft, abgebrochen, geschrieben, beendet). Wo mehrere Zustände dasselbe tun, fasst eine kleine
  Abfrage sie zusammen (`_is_active()`, `_hoert_auf()`), und `match _state:` zeigt, was je Zustand
  geschieht, etwa in `InvadersPage._step()`. Was keine Sammlung ist, bleibt: `_window_focused` ist
  eine eigene Achse, und `_lock_steps` ist ein Zähler im Zustand RESULT_LOCKED.
- **Der Läufer und das kurze ABGEBROCHEN.** Nach dem Schließen läuft `_brich_ab()` in einem Zug
  durch: ABGEBROCHEN, schreiben, GESCHRIEBEN, beenden, BEENDET. Die angehaltene Kette von `await`
  sieht deshalb nie ABGEBROCHEN; sie fragt `_hoert_auf()`, also „nicht mehr LAEUFT“. Früher blieb
  `_abgebrochen` einfach für immer true, jetzt sagt es der Zustand.
- **Obergrenze je Bild (K1; AR-10).** `_process(delta)` sammelt Echtzeit in `_accumulator` und
  rechnet daraus ganze Tage, wie `InvadersPage.advance()` ganze Schritte. Ohne Obergrenze holte die
  Uhr nach einem Hänger von zehn Sekunden zwanzig Tage in einem Bild nach, mit zwanzig Runden
  Signalen an Zeitleiste und später Wirtschaft. `MAX_DAYS_PER_FRAME = 4`: Bis vier Tage bleibt der
  angefangene Tag erhalten, darüber verfällt der Rest. Am Spielverlauf ändert das nichts, denn der
  hängt am Tag, nicht an der Echtzeit.
- **Nähte (K3, W2, B1, B2; AR-08, AR-12).** Eine Naht ist eine Variable, über die ein Test etwas
  von außen einsetzt, ohne den Code zu ändern. `Timeline.rng` ist der eigene Würfel für
  `start_game()` ohne Seed, wie `GameSession.rng`: Ein Test setzt einen mit festem Seed und weiß
  vorher, welcher Seed herauskommt. Der globale Würfel (`randi_range()`) hängt dagegen an allem, was
  sonst würfelt, etwa am Easter Egg. Für Autoloads heißt die Naht `game_window` oder `session`;
  leer heißt das Autoload. In `SelbsttestErgebnis._game_window()` steht dafür der Name
  `GameWindow`, kein `/root/`-Pfad mehr; die Seite läuft nur mit Autoloads. In der Werkstatt bleibt
  der Pfad, weil die Textausgabe sie mit `-s` lädt und GDScript dort den Namen beim Kompilieren
  nicht kennt; dafür steht dort der Kommentar `# Ausnahme AR-02: …` wie in der Tabelle des
  Leitfadens (W1). Die Startszene reicht ihre Naht an Fahrer und Läufer weiter.
- **„Nur lesen.“ (K4, S5, L13, B8; AR-15).** GDScript kennt kein `readonly` für Felder. Der
  Doku-Kommentar ist die Abmachung: Die Oberfläche liest `SaveSlot.state` oder
  `GameSession.current`, ändert sie aber nur über Methoden des Kerns. Der Kommentar steht auch im
  Tooltip des Editors.
- **Texte an einer Stelle (S3, S4; AR-04).** Untertitel, `STAGE` und die Vorlage der Versionszeile
  stehen jetzt in `TitleTexts`, der Titel setzt sie in `_ready()`. In `title_screen.tscn`,
  `main_menu.tscn` und `save_list.tscn` steht kein Text mehr, und `MainMenu.header_text` ist
  vorgegeben leer: Wer das Menü einsetzt, sagt, was oben steht. Ein Text in der Szene wäre eine
  zweite Quelle, die beim nächsten Umbenennen vergessen wird. Ein Test prüft, dass die Szenen die
  Wörter nicht mehr nennen.
- **Eine Regel an einer Stelle (W3; AR-15).** Bis wohin eine Probe spielen muss, beschrieb
  `WhatIfProbe.until_day`, gerechnet hat es der Simulator. Jetzt rechnet `WhatIfProbe.end_day()`;
  der Simulator ruft es. Öffentlich und ohne Unterstrich, weil Geschwister keine privaten Funktionen
  fremder Klassen rufen (AR-02).
- **Geteilte Resource kopieren (B5; AR-04).** `load()` und eine Szene geben für dieselbe Datei
  dasselbe Objekt; Godot hält es im Cache. Wer `theme.default_font` daran setzt, ändert es für jeden,
  der `selbsttest_theme.tres` lädt, bis das Programm endet. `theme = theme.duplicate()` macht vorher
  eine eigene Kopie, wie in der Werkstatt. Der Test prüft danach, dass die Datei keine Schrift hat.
- **Werte einmal (B6, M8, B7; AR-04).** Eine Konstante darf eine andere lesen, auch aus einer
  Klasse mit `class_name` (`const EIGENER_ORDNER := SelbsttestAblage.BASIS`) oder aus einem
  vorgeladenen Skript (`const RASTER := FENSTER_SCRIPT.BASE_SIZE`; GameWindow hat als Autoload
  keinen `class_name`). Seed und Pfad des Titels stehen beim Fahrer, der den Titel ohnehin kennt;
  Startszene und Läufer lesen sie dort.
- **Der Fahrer als einzige Stelle (M1, M10).** `ablauf_fenster.gd` liest Größe und Lage über
  `fahrer.fenster_rechteck()` und stellt sie mit `fahrer.stelle_fenster()` zurück, ohne `await`:
  Eine Koroutine ohne `await` läuft bis zu ihrem ersten `await` sofort, also sind Größe und Lage
  gleich gesetzt; das Bild danach wartet der nächste Ablauf ohnehin ab. Fahrer und Eingabe sagen im
  Kopf, dass sie Helfer der Hülle sind: ein `RefCounted`, das den Baum anfasst, ist kein Kern.

Fehlerprobe an einer Kopie außerhalb des Repos: je ein Fehler eingebaut, je der passende Test rot
(K1 ohne Obergrenze, K2 `paused` holt aus dem Ende, K3 globaler Zufall, S2 aktiv ohne Partie und
Sperre übersprungen, S3 Untertitel wieder in der Szene, S4 Vorgabe „HAUPTMENÜ“, W3, W4 immer
abgebrochen, B1 Naht übergangen, B5 ohne Kopie, B3 zweimal, M1, `/root/` zurück in
`selbsttest_ergebnis.gd`). Die Naht der Werkstatt (W2) und der Startszene (B2) prüft kein Test:
Die Werkstatt hält GameWindow nur mit echtem Fenster an, und die Startszene startet den ganzen
Selbsttest.

### T036b Titel, Hilfen der Werkstatt und der Stillstand des Läufers

Geschrieben vom Godot-Agent.

- **Zwei `enum` statt einem (S1; AR-11).** Der Titel hat zwei Fragen, die nichts miteinander zu tun
  haben: *Darf eine Eingabe etwas tun?* (`Phase`: vor den Einträgen, bedienbar, fährt hinaus) und
  *Welches Blatt liegt oben?* (`Layer`: Hauptmenü, Gradwahl, Liste, Löschmodus, Rückfrage, Space
  Invaders). Jede Ebene gibt es in jeder Phase; beim Hinausfahren liegt etwa die Gradwahl oben. Ein
  einziger `enum` müsste jede Kombination aufzählen, achtzehn Werte, die keiner lesen will. Zwei
  Achsen, je ein `enum`, und `_accepts_input()` fragt nur noch `_phase == Phase.ACCEPTING`. Esc
  und die Gehäusetasten entscheiden mit `match _current_layer():`, je Ebene ein Zweig; früher
  war es eine Kette aus `if _invaders.visible`, `if _main_menu.visible` und so weiter.
- **Die Sichtbarkeit folgt aus der Ebene.** Sichtbar ist, was man sieht; die Ebene ist, was der
  Titel weiß. Beides darf nie auseinanderlaufen. Deshalb setzt nur `_show_layer()` die Ebene, und
  im selben Zug zeigt es die Seite über `_page_of()`. Wer eine Seite zeigen will, sagt die Ebene,
  nicht die Seite. Der Selbsttest liest weiter `current_page()` und `is_visible_in_tree()`: Die
  Sichtbarkeit ist die Schnittstelle nach außen, die Ebene der Zustand innen.
- **Den Löschmodus führt die Liste.** `SaveList` schaltet ihn selbst ein, ohne Signal. Ein
  eigener Wert `DELETE_MODE` in `_layer` müsste ihn nachführen und könnte ihr widersprechen. Darum
  speichert der Titel nur `LIST`, und `_current_layer()` fragt die Liste mit `is_delete_mode()`:
  ein Wert, eine Quelle. Space Invaders merkt sich deshalb `_return_layer = _layer`, nicht den
  Löschmodus; der bleibt in der Liste stehen, bis jemand ihn ausschaltet.
- **Hilfen in eine eigene Klasse (L16; AR-02).** `DifficultyPanel` rief `EventForm._reason()` und
  `EventForm._mark_error()`, `EventForm` rief `EventList._category_label()`. Der Unterstrich sagt
  in GDScript nur „privat gemeint“, verhindern kann er nichts. Wer eine private Funktion einer
  anderen Klasse ruft, hängt an deren Innerem: Benennt `EventForm` sie um, bricht das Panel
  daneben. `FieldHelpers` (`src/tools/werkstatt/field_helpers.gd`) sammelt, was die Panels teilen:
  Lesen und Zeigen (`parse_*`, `format_*`), `mark_error()`, `reason()`, `category_label()`. Nur
  `static func` und keine Objekte; `extends RefCounted` steht da, weil `class_name` eine Basis
  braucht. Was nur das Formular braucht (`_same_text()`, `spread_weights()`), bleibt dort.
- **Eine statische Funktion als Callable.** `_line(key, …, FieldHelpers.parse_whole,
  FieldHelpers.format_whole, …)` reicht die Funktion selbst weiter, ohne Klammern. Godot macht
  daraus ein `Callable`, das das Feld später mit `parse.call(text)` ruft. Mit dem Umzug ändert sich
  nur der Name davor. Der Test der Lesefunktionen nimmt `Callable(FieldHelpers, "parse_date")`.
- **Ein Test muss selbst rot werden (Läufer).** `_hoert_auf()` war in Teil 1 nur indirekt geprüft:
  Lief die Kette nach dem Abbruch weiter, fiel das erst im nächsten Test auf, weil dort Reste
  weiterliefen. Der neue Test hält Schritt `titel.02_zwei` an einer von drei `await`-Stellen an
  (Warten auf den Zustand, Eingaben, Foto), schließt das Fenster und lässt die Kette dann frei.
  Danach zählt er Eingaben, Prüfungen und Fotos und vergleicht sie mit dem Stand beim Schließen. Ein
  Lambda hält eine lokale Variable als Kopie; deshalb liegen die Schalter in einem Array
  (`geschlossen := [false]`), dessen Inhalt Lambda und Test teilen. `use_parameters()` lässt
  denselben Test für alle drei Stellen laufen.

Fehlerprobe in einer Kopie außerhalb des Repos, je ein Fehler, je mindestens ein Test rot: Esc in
der Gradwahl ohne Rückweg, Esc in der Rückfrage ins Hauptmenü, Löschmodus nie erkannt, Esc im
Hauptmenü baut neu, Gehäusetasten während Space Invaders, Eingabe beim Hinausfahren, Eingabe vor den
Einträgen, falsche Rückkehr-Ebene, Ebene ohne Seite; in der Werkstatt `parse_date` und
`parse_percent` vertauscht, Datum mit `parse_day_of_year`, Meldung ohne `reason()`, `mark_error()`
am Hinweis, Kategorie ohne `category_label()`; im Läufer `_hoert_auf()` nur in ABGEBROCHEN und je
eine fehlende Abbruchprüfung beim Warten, nach den Eingaben und beim Foto. Esc im Hauptmenü und
Eingaben vor den Einträgen fing zuerst kein Test; die zwei neuen Titeltests prüfen sie jetzt.

### T036d `TimelineRun.format_points()` wird öffentlich

Geschrieben vom Godot-Agent.

- **Wer von außen ruft, braucht einen öffentlichen Namen (AR-02).** `DifficultyPanel` zeigte den
  Wert eines Start-Modifikators mit `TimelineRun._points()`, damit Tabelle und Begründung im
  Fahrplan dieselbe Zahl schreiben, „+5“ oder „-2,5“. Der Wunsch war richtig, nur der Weg nicht: Der
  Unterstrich sagt „Inneres des Kerns“, und der Kern darf es umbenennen, ohne nach der Werkstatt zu
  schauen. Jetzt heißt die Funktion `format_points()`, ohne Unterstrich und mit Doku-Kommentar, der
  sagt, wer sie teilt. Damit ist die Form ein Versprechen des Kerns, kein Zufall seines Inneren.
- **Warum nicht in `FieldHelpers`.** Die Werkstatt ist vom Export ausgeschlossen; der Kern darf
  sie nicht kennen. Die Form gehört dem Kern, weil die Begründung eines Termins sie braucht, und die
  Werkstatt liest sie dort ab, nach unten. Der Name folgt `FieldHelpers.format_date()`, das in
  derselben Zeile des Panels die Tage zeigt.
- **`static func` über den Klassennamen.** `TimelineRun.format_points(0.05)` braucht keinen Lauf;
  `class_name` macht die Klasse überall bekannt. Innerhalb von `timeline_run.gd` reicht der Name
  allein, so in `_modifier_notes()` und `_points_text()`.
- **Fahrpläne prüfen das nicht.** Die Textausgabe zeigt die Begründungen nicht, `cmp` bliebe also
  auch bei einer falschen Form gleich. Die Fehlerprobe zeigt, dass die Tests es fangen:
  `test_timeline_run.gd` vergleicht die Begründung „Abzug -2,5“, `test_difficulty_panel.gd` die
  Zelle der Tabelle.

### T036e Letzte Kopien, ein Kommentar und eine Naht für „Würfeln“

Geschrieben vom Godot-Agent.

- **Eine Hilfe, ein Ort (AR-02).** Der Zeitstrahl hatte mit `_reason()` eine wörtliche Kopie von
  `FieldHelpers.reason()`. Zwei Kopien laufen irgendwann auseinander, etwa wenn sich die Form der
  Meldungen im `CatalogValidator` ändert und nur eine angepasst wird. Jetzt ruft
  `_draw_cursor_texts()` in `timeline_view.gd` die geteilte Hilfe; der Zeitstrahl ist ein Werkzeug
  wie das Formular, er darf `FieldHelpers` kennen.
- **Der Kern verspricht die Form, nicht den Leser (AR-14).** `TimelineRun.format_points()` nannte
  im Doku-Kommentar `FieldHelpers.parse_percent()`. Der Code des Kerns hängt davon nicht ab; wer
  die Werkstatt umbaut, müsste aber den Kommentar im Kern mitpflegen. Der Kommentar sagt jetzt nur,
  *dass* die Werkstatt den Wert genauso zeigt und wieder liest, nicht mit welcher Klasse. Verboten
  wäre der Name nicht: Ein Name im Kommentar ist kein Verweis im Sinn von AR-14 (Klaus,
  2026-10-29). Absatz von Claude angeglichen, nachdem diese Regel dazukam.
- **Eine Konstante gehört dem, der sie meint (AR-04).** Der Fahrer kannte den Pfad des
  Spielbildschirms als eigene `SPIELBILDSCHIRM`. Gemeint war immer „wohin der Titel ein Spiel
  führt“, und das steht schon in `TitleScreen.GAME_SCENE`. Zieht die Szene um, ändert sich der
  Pfad nur dort; der Selbsttest wechselt dann von selbst zum richtigen Bildschirm. Über den
  `class_name` ist die Konstante überall lesbar, ohne den Titel zu laden.
- **Auch Werkzeuge würfeln aus einem eigenen Würfel (AR-08).** `roll_seed()` im Simulator zog mit
  `randi_range()` aus Godots globalem Würfel. Den teilen sich alle Skripte: Ruft irgendwo jemand
  `seed()`, würfelt „Würfeln“ plötzlich immer dasselbe, und ein Test kann nicht vorhersagen, was
  im Feld steht. Jetzt hat `SimulatorPanel` eine öffentliche Variable `rng`, wie `Timeline.rng` und
  `GameSession.rng`. Ein neuer `RandomNumberGenerator` startet ohne festen Wert, also bleibt
  „Würfeln“ für Klaus zufällig. Der Test `test_wuerfeln_wuerfelt_aus_rng` in
  `test_werkstatt_scene.gd` setzt einen Würfel mit festem Seed und sagt mit einem zweiten Würfel
  desselben Seeds voraus, was im Feld stehen muss. Das ist die Naht: Der Test ersetzt den Würfel
  von außen, ohne das Panel umzubauen.

Fehlerprobe in einer Kopie außerhalb des Repos: `roll_seed()` wieder mit `randi_range()` macht
`test_wuerfeln_wuerfelt_aus_rng` rot, sonst keinen; `test_architektur.gd` sucht globalen Zufall nur
in Kernen. Die Zeitleiste ohne Abschneiden des Orts fängt kein Test, weder vorher noch jetzt:
`test_timeline_view.gd` prüft `preview_issue()`, aber nicht den gekürzten Text, den
`_draw_cursor_texts()` nur zeichnet.

### T036c Kommentare über die Grenze zu Python

Geschrieben von Claude.

- **Ein Wert, zwei Sprachen.** `tools/selbsttest/vergleich.py` kennt das Raster 640 × 360, die
  Farbe Kassenrot und das Format von `protokoll.txt` ein zweites Mal. Python kann
  `GameWindow.BASE_SIZE` nicht lesen, eine zweite Stelle lässt sich also nicht vermeiden. Der
  Leitfaden gilt nur für `src/` (Abschnitt „Werkzeuge“); über die Grenze hilft ein Kommentar, der
  die Quelle in Godot nennt. Wer das Raster ändert, findet so per Suche nach `BASE_SIZE` auch die
  Stelle im Skript.

## Phase 6

### T039a Die Klassenreferenz der installierten Godot

Geschrieben von Claude.

- **Was `--doctool` liefert.** `Godot --doctool <ordner>` schreibt für jede Klasse, die die
  laufende Engine kennt, eine XML-Datei: Erbfolge, Methoden mit Parametern und Standardwerten,
  Eigenschaften, Signale, Konstanten und Enums. Das kommt aus der `ClassDB` der Engine selbst und
  passt deshalb genau zur installierten Version 4.7.2. Für die Frage „gibt es `get_node_or_null()`
  und welche Parameter hat es?“ ist das die verlässlichste Quelle, die es gibt.
- **Was es nicht liefert.** Die Beschreibungstexte stehen nicht in der Engine, sondern im Quellcode
  von Godot unter `doc/classes/`. `--doctool` mischt sie nur hinein, wenn sie im Zielordner schon
  liegen; aus einem leeren Ordner kommen leere `<description>`. Deshalb die eigene Aufgabe T039d.
- **Warum das Skript das Ergebnis prüft.** `--doctool` endet auch mit Exit 0, wenn der Ordner fehlt
  und nichts geschrieben wurde. Das Skript sieht deshalb nach, ob `Node.xml`, `RegEx.xml` und
  `@GDScript.xml` da sind. Ein Exit-Code allein beweist nichts.
- **Warum die Version geprüft wird.** Die Referenz soll genau zu der Godot passen, mit der das
  Projekt gebaut wird. `config/features` in `src/project.godot` nennt „4.7“; meldet die
  installierte Godot etwas anderes, bricht das Skript ab, statt eine Referenz zu einer falschen
  Version zu schreiben.
- **Warum nicht im Repo.** Die 1076 Dateien (6,7 MB) lassen sich in unter einer Sekunde neu
  erzeugen, und jedes Update von Godot brächte einen riesigen Diff. Der Ordner steht deshalb in
  `.gitignore` (Klaus, 2026-10-29); in jedem Worktree läuft das Skript einmal.
- **Flach statt verschachtelt.** Godot verteilt die Dateien auf `doc/classes/` und rund 30 Ordner
  unter `modules/` und `platform/`. Wer `RegEx` sucht, müsste wissen, dass es ein Modul ist. Die
  Namen sind eindeutig, also legt das Skript alle in `klassen/` zusammen.

### T039b und T039d Texte und Handbuch, einmal je Rechner

Geschrieben von Claude.

- **Ein Teil-Klon lädt nur, was gebraucht wird.** `git fetch --depth 1 --filter=blob:none` holt
  einen einzigen Stand ohne Geschichte und zunächst ohne Dateiinhalte; `git sparse-checkout` mit
  Mustern wie `/doc/classes/*.xml` legt fest, welche Dateien ausgecheckt werden, und erst deren
  Inhalte kommen über das Netz. Aus dem Godot-Quellcode mit vielen hundert MB werden so 9,4 MB.
- **Der Tag passt zur installierten Godot.** `Godot --version` endet auf `ed1daf0bf`, und der Tag
  `4.7.2-stable` zeigt auf genau diesen Commit. Das Skript bildet den Tag aus der Version, also
  passen Texte und Signaturen immer zusammen.
- **`--doctool` mischt.** Liegt der Klon im Zielordner, liest `--doctool` dessen Texte, gleicht sie
  mit der Engine ab und schreibt sie zurück. Zwei Klassen mehr als ohne Texte (`CSharpScript`,
  `TextServerFallback`) stammen aus dem Quellcode und gehören zu Teilen, die diese Godot nicht
  enthält.
- **Ein Muster, das nicht ausschloss.** `!/classes/` schloss im Handbuch den Ordner nicht aus, weil
  `*.rst` die Dateien darin schon einzeln einschloss; erst `!/classes/**` trifft die Dateien selbst.
  Geladen waren da schon rund 33 MB statt 15; die Seiten sind wieder entfernt, und Klaus weiß davon.
- **Cache statt Download je Worktree.** Jedes Feature hat einen eigenen Worktree. Die Klone liegen
  deshalb in `~/.cache/der-computerladen/`, je Version ein Ordner; ein Worktree kopiert von dort.
