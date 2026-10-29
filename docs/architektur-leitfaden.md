# Architektur-Leitfaden

Wie „Der Computerladen“ gebaut wird: welche Godot-Prinzipien gelten, welche Muster aus „Game
Programming Patterns“ das Spiel nutzt und nach welchen Spielen die Schichten Adventure und
Wirtschaft aufgebaut werden. Der Leitfaden ist der Maßstab des Architektur-Prüfers
(`.claude/agents/architektur-pruefer.md`), so wie der Style-Guide der Maßstab des Stil-Prüfers ist.
Spec, Plan und Godot-Agent halten sich an ihn.

- **Geltung:** für Skripte, Szenen und Resources des Spiels und der Werkzeuge unter `src/`, außer
  `src/addons/`. Tests gehören nur über AR-01 dazu: Ein Kern muss sich ohne Szene testen lassen.
- **Vorrang:** Die Verfassung (`.specify/memory/constitution.md`) geht vor. Wo der Leitfaden etwas
  aus ihr übernimmt, nennt er den Grundsatz. Widerspricht die Godot-Doku einer Regel, gilt die
  Regel; ihr Grund sagt, warum.
- **Nicht hier:** Aussehen, Texte und Ton regelt der Style-Guide. Typisierung, Namen und Kommentare
  stehen in `docs/spielbeschreibung/architektur.md`, „Code-Stil“. Beides prüft der
  Architektur-Prüfer nicht.
- **Quellen:** `docs/recherche/architektur-quellen.md`, im Folgenden „Quellen“ mit Abschnitt.
- **Stand:** Feature 008, Phase 7. Alle 20 Regeln hat Klaus am 2026-10-28 wie vorgeschlagen
  entschieden; ergänzt nach den Proben (Phase 2), der Bestandsprüfung (Phase 3), der Nachprüfung
  des Codes aus Feature 007 (2026-10-28) und der Phasenprüfung der Behebung (Phase 5,
  2026-10-29), siehe „Geschichte“. Seit Feature 010 gelten auch AR-16 bis AR-20, weil dort die
  Schichten Wirtschaft und Adventure beginnen (Klaus, 2026-10-29).

## So liest man eine Regel

Jede Regel hat eine feste Nummer `AR-NN` (Architektur-Regel). Eine Nummer wird nie neu vergeben,
auch nicht nach einer Streichung. AR-01 bis AR-05 sind die fünf Godot-Prinzipien. Jede Regel hat
acht Teile:

| Teil | Inhalt |
|---|---|
| Aussage | was gilt, an einer Stelle im Code als eingehalten oder verletzt erkennbar |
| Grund | warum, für dieses Spiel |
| Beispiel | eine Stelle im Code mit Pfad, sonst ein ausgedachtes Beispiel aus dem Spiel, als solches gekennzeichnet |
| Gegenbeispiel | wie ein Verstoß aussähe |
| Quelle | Abschnitt der Quellen, Grundsatz der Verfassung oder Klaus mit Datum |
| Schicht | alle, Kern, Oberfläche, Adventure, Wirtschaft, Werkzeuge |
| Prüfweise | „Prüfer“ oder „Test: `test_architektur.gd`, <Funktion>“; was ein Test misst, lässt der Prüfer aus |
| Stand | „Vorschlag“, „gilt seit JJJJ-MM-TT, Klaus“ oder „gilt ab dem ersten Feature der Schicht <Name>“ |

Nur Regeln mit dem Stand „gilt …“ zählen. Eine Regel für eine Schicht, die es noch nicht gibt, prüft
der Prüfer erst, wenn ihr erstes Feature beginnt.

**Schwere eines Befunds** (verletzt eine Stelle zugleich die Verfassung, gilt „kritisch“, auch wenn
die Regel allein „mittel“ wäre; Klaus, 2026-10-28):

| Schwere | Wann | Beispiel |
|---|---|---|
| kritisch | widerspricht der Verfassung | die Zeitleiste ändert selbst einen Preis, statt ihn zu melden |
| hoch | koppelt Systeme, die getrennt sein sollen | ein Baustein ruft den, der ihn einsetzt |
| mittel | verletzt eine Regel innerhalb eines Systems | Werte, die Daten sein sollten, stehen im Code |
| niedrig | Form einer Regel, ohne Folgen für die Kopplung | Ausnahme ohne Zeile in der Tabelle |

**Begründete Ausnahme:** Eine Stelle, die eine Regel bewusst verletzt, trägt den Kommentar
`# Ausnahme AR-NN: <Grund> (Klaus, JJJJ-MM-TT)` und steht in der Tabelle „Ausnahmen“ unten. Hat sie
kein Skript, etwa ein Knoten ohne Skript oder eine Datendatei, reicht die Zeile in der Tabelle mit
Datei und Knoten. Ein Plan nennt eine geplante Ausnahme unter „Ausnahmen vom Leitfaden“, und Klaus
gibt sie mit dem Plan frei.

---

## Godot-Prinzipien

### AR-01 Kern ohne Node

- **Aussage:** Spiellogik und Spielzustand stehen in Klassen, die von `RefCounted` erben (der
  **Kern**). Eine Szene oder ein Autoload ist nur die **Hülle**: Sie hält den Kern, reicht ihm Zeit,
  Seed und Daten hinein und macht aus seinen Ergebnissen Signale und Bilder. Ein Kern greift nicht
  auf den Szenenbaum, auf Autoloads oder auf den globalen Zufall zu.
  Ein Autoload darf kleinen Ablaufzustand halten, etwa das Datum der Uhr oder das laufende
  Spiel; Spielmechanik gehört in einen Kern. Ein Kern darf Dateien lesen und schreiben und die Uhr des
  Rechners nur für Zeitstempel und Rechenbudgets lesen, die das Ergebnis nicht ändern; Spielzeit nie.
  Aus `src/ui/` darf ein Kern nur Klassen mit Konstanten wie `UiPalette` kennen, keine Szenen und
  Bausteine.
  Ein `RefCounted`, das auf den Baum zugreift, ist kein Kern, sondern ein Helfer der Hülle, und sagt
  das im Doku-Kommentar am Kopf, etwa `SelbsttestFahrer`. Ein Kern des Spiels fragt keine Dienste der
  Engine wie `DisplayServer`, `OS` oder `Thread`; in einem Werkzeug darf ein Kern das, etwa
  `SelbsttestSystem`, steht dann aber nicht in der Liste `KERNE` des Tests. Eine programmweite
  `static var` darf ein Kern als Naht haben, wenn nur Werkzeuge und Tests sie setzen und der
  Kommentar das sagt, wie `SaveGame.time_zone_bias`.
- **Grund:** So läuft dieselbe Logik im Spiel, in der Werkstatt und in Tests ohne Fenster und Uhr,
  und ein Lauf ist wiederholbar (AR-08). Die Godot-Doku hält Logik im Skript einer Szene für normal
  und kennt `RefCounted` nur als Werkzeug; der Leitfaden ist hier **bewusst strenger**, weil eine
  Wirtschaftssimulation über 15 Spieljahre ohne wiederholbare Läufe kaum zu prüfen ist.
- **Beispiel:** `TimelineRun` (`src/core/timeline/timeline_run.gd`) rechnet den Fahrplan; das
  Autoload `Timeline` hängt ihn an die Uhr und meldet per Signal. Ebenso `InvadersGame` als Kern und
  `InvadersPage` als Hülle (`src/scenes/title/invaders/`).
- **Gegenbeispiel:** Die Preise des Ladens werden in `_process()` einer Szene `Laden` fortgeschrieben,
  oder ein Kern ruft `GameClock.date` statt den Tag hineingereicht zu bekommen.
- **Quelle:** Quellen 1.6, 1.13, 4.3; Nystrom „Game Loop“ (Quellen 2.2);
  `docs/spielbeschreibung/architektur.md`, „Grundsätze“.
- **Schicht:** Kern, Wirtschaft, Adventure
- **Prüfweise:** Test: `test_architektur.gd`, `kern_verstoesse` (erbt von `RefCounted` oder
  `Resource`, nennt kein Autoload, kein `get_tree()` und kein `Engine.get_main_loop()`, keinen
  globalen Zufall nach der Liste in AR-08); dazu Prüfer: ob Logik in einer Hülle steckt, die in
  einen Kern gehört.
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-02 Signal nach oben, Aufruf nach unten

- **Aussage:** Ein Baustein kennt den nicht, der ihn einsetzt. Er meldet nach oben per Signal; wer
  ihn einsetzt, ruft ihn direkt auf und reicht ihm hinein, was er braucht. Geschwister reden über
  den gemeinsamen Eltern-Node. Kein Skript greift über `get_parent()`, einen Pfad mit `../` oder
  `/root/` nach oben. Signale werden nicht über mehrere Ebenen weitergereicht.
  Ein Baustein darf das Signal eines inneren Teils in ein eigenes
  Signal mit eigener Bedeutung übersetzen; verboten ist nur das bloße Durchreichen.
  Ein `Callable` darf der gemeinsame Eltern-Node hineinreichen; ein Kind hält nie eine
  Referenz auf seinen Eltern-Node. „Nach unten“ heißt: bis zu den eigenen Kindern und deren
  öffentlichen Methoden, nicht in innere Nodes einer eingesetzten Szene. Gemeinsame Hilfen von
  Geschwistern liegen in einer eigenen Klasse; private Funktionen (`_name`) einer fremden Klasse ruft
  niemand. `get_parent()` innerhalb der eigenen Szene ist erlaubt.
- **Grund:** So lässt sich ein Baustein in eine andere Szene setzen, ohne ihn zu ändern, und für
  sich testen. Der Merksatz „Call down, signal up“ stammt aus der Godot-Gemeinde (KidsCanCode); die
  offizielle Doku sagt dasselbe sinngemäß.
- **Beispiel:** `Communicator` meldet `case_key_pressed`, und der Titel hört zu
  (`src/ui/communicator/communicator.gd`, `src/scenes/title/title_screen.tscn`); der Communicator
  kennt den Titel nicht.
- **Gegenbeispiel:** Ein Regal im Laden ruft `get_parent().kasse_aktualisieren()`, oder die Werkstatt
  holt sich ein Autoload über `get_node("/root/GameWindow")`.
- **Quelle:** Quellen 1.3, 5; Nystrom „Observer“ (Quellen 2.2).
- **Schicht:** alle
- **Prüfweise:** Test: `test_architektur.gd`, `wege_nach_oben` (`/root/`, dazu `../` in Knotenpfaden
  der Skripte und in Szenen); dazu Prüfer:
  Aufrufe nach oben, die kein Pfad verrät, etwa über eine hineingereichte Referenz auf den Eltern.
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-03 Autoloads sparsam

- **Aussage:** Es gibt genau diese Autoloads, in dieser Reihenfolge: `GameClock`, `Timeline`,
  `GameWindow`, `GameSession`. Ein neues braucht Klaus' Freigabe im Plan. Ein Autoload darf nur
  sein, was eigene Daten über Szenenwechsel hinweg verwaltet und keine fremden ändert. Kein
  allgemeiner Signalbus und kein „Manager“ als Autoload; Hilfsfunktionen sind `static func` einer
  Klasse mit `class_name`.
  Autoloads dürfen einander über eine Naht und in der Reihenfolge aus `project.godot`
  aufrufen; ein Methodenaufruf ist kein „fremde Daten ändern“. Einstellungen des `SceneTree`, etwa
  `auto_accept_quit`, setzt ein Autoload nur mit Kommentar.
  Reine Rechnungen, die zu einem Autoload gehören, dürfen als `static func` in dessen Skript stehen
  und über `preload` getestet werden, wie `GameWindow.best_factor()`.
- **Grund:** Jedes Autoload ist überall erreichbar und koppelt deshalb alles an alles. Nystrom nennt
  das Singleton das Muster, das meist mehr schadet als nützt. Die Godot-Doku erlaubt Autoloads für
  Systeme mit eigenen Daten; die feste Liste ist **strenger**, damit ein neues Autoload eine
  bewusste Entscheidung bleibt. Ein Lager wird so ein Kern, den `GameSession` besitzt, kein
  `LagerManager`.
- **Beispiel:** `GameSession` hält das laufende Spiel über den Wechsel von Titel zu Spielbildschirm
  (`src/core/game_session.gd`); `UiPalette` ist eine Klasse mit Konstanten, kein Autoload
  (`src/ui/ui_palette.gd`).
- **Gegenbeispiel:** Ein Autoload `Events` mit allen Signalen des Spiels, oder ein Autoload
  `Sound`, das jede Szene direkt ruft.
- **Quelle:** Quellen 1.5, 1.7, 2.1, 5.
- **Schicht:** alle
- **Prüfweise:** Test: `test_architektur.gd`, `autoloads_aus`; dazu Prüfer im Plan: ob ein neues
  Autoload das Kriterium erfüllt.
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-04 Daten als Resources

- **Aussage:** Gepflegte Spieldaten, etwa Produkte, Kundentypen oder Objekte eines Raums, sind
  Datenobjekte und keine Klassen (Muster „Typ-Objekt“). Sie stehen als `Resource`-Klasse mit
  `.tres`-Dateien oder in einer Datendatei, die ein Werkzeug pflegt, nicht als Werte im Code. Eine
  geladene Resource ist nur zum Lesen da, weil Godot sie zwischen allen Nutzern teilt; was sich im
  Spiel ändert, gehört in einen Kern oder in eine Kopie. Spielstände sind ausgenommen (AR-13).
  Spielinhalt heißt hier, was in die game_bible gehört: Produkte,
  Preise, Kunden, Mieten. Die game_bible bleibt dafür die Quelle; Resources entstehen daraus über
  einen Importer, nie von Hand, damit es keine zweite Quelle gibt. Keine Spieldaten in diesem Sinn
  sind Stellschrauben einer Mechanik, etwa Tempi oder Chancen, und Werte, die der Style-Guide
  festlegt: Sie stehen als benannte Konstanten an einer Stelle, wie `UiPalette`. Ebenso stehen die
  Texte eines Bildschirms an einer Stelle als Konstanten, wie `TitleTexts`; Dialoge regelt AR-20.
  Grundgrenzen wie der Spielzeitraum oder der größte Seed stehen einmal in `src/core/` und
  werden von dort gelesen. Texte, die ein Kern liefert, stehen als Konstanten am Kopf des Kerns, wie
  `SaveGame.REASON_*`. Das Theme ist neben `UiPalette` eine erlaubte zweite Stelle für Farben, weil
  Tests beide gleich halten. Vorgaben eines Werkzeugs für eine leere Datendatei dürfen im Code
  stehen.
  Pfade von Szenen, die ein Werkzeug startet, stehen einmal als Konstante. Eine Kopie des Themes für
  ein Werkzeug ist eine weitere erlaubte Stelle für Farben, wenn ein Test sie gleich hält, wie bei
  `selbsttest_theme.tres`.
  Dasselbe gilt für Hilfen: Eine gleiche Funktion als private Kopie in zwei Klassen ist eine Regel
  an zwei Stellen; sie gehört in die gemeinsame Klasse der Geschwister (AR-02), wie `FieldHelpers`
  in der Werkstatt.
- **Grund:** Der Spielinhalt soll sich ohne Code ändern lassen, im Inspector oder in einem
  Werkzeug, wie die Ereignisse in der Werkstatt. Ein Produkt wie „486DX-33“ ist eine Datenzeile,
  keine eigene Klasse.
- **Beispiel:** `MenuEntry` ist eine Resource, und das Menü liest nur ihre Felder
  (`src/scenes/title/menu_entry.gd`). Die Ereignisse stehen in `src/data/event_catalog.json`,
  gepflegt in der Werkstatt; dass sie JSON sind und keine Resource, ist eine begründete Ausnahme
  (siehe „Ausnahmen“).
- **Gegenbeispiel:** `if produkt == "486DX-33": preis = 2499` im Code des Ladens, oder ein Kunde, der
  den Bestand direkt in die geladene Produkt-Resource schreibt.
- **Quelle:** Quellen 1.6, 1.11, 1.13; Nystrom „Type Object“, „Flyweight“ (Quellen 2);
  Verfassung, Grundsatz V.
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-05 Szenen-Komposition

- **Aussage:** Eine Szene wird aus kleineren, eigenständigen Szenen zusammengesetzt. Jede Szene läuft
  für sich, in einer Probeszene oder mit F6, und bekommt, was sie braucht, von außen. Bausteine unter
  `src/ui/` kennen keinen Bildschirm. Ein Kind-Node ist nur, was mit seinem Eltern-Node entsteht und
  verschwindet.
  Was mehrere Bildschirme nutzen, liegt unter `src/ui/`; `src/ui/` verweist nie auf
  `src/scenes/`.
- **Grund:** Kleine Szenen lassen sich einzeln bauen, testen und wiederverwenden; ein Laden aus
  Theke, Regal und Kunde bleibt überschaubar, ein Laden als eine große Szene nicht.
- **Beispiel:** Der Titel setzt den Communicator als fertige Szene ein und hängt Hauptmenü,
  Gradwahl, Liste und Space Invaders als Seiten hinein (`src/scenes/title/title_screen.tscn`).
  Communicator und Space Invaders laufen auch allein in ihren Probeszenen
  (`src/test/fixtures/communicator_probe.tscn`, `invaders_probe.tscn`).
- **Gegenbeispiel:** Der Spielbildschirm baut die Tasten des Communicators selbst nach, oder eine
  Seite funktioniert nur, wenn der Titel sie lädt.
- **Quelle:** Quellen 1.3, 1.4; Nystrom „Component“ (Quellen 2).
- **Schicht:** Oberfläche, Adventure
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

---

## Weitere Regeln für alle Schichten

### AR-06 Melden statt anwenden

- **Aussage:** Wer ein Ereignis erzeugt, meldet es per Signal und wendet seine Folgen nicht selbst
  an. Was daraus folgt, entscheidet das System, das zuhört.
  Zwischen Kern und Hülle ist ein Rückgabewert eine Meldung; die Hülle macht daraus
  Signale. Die Regel gilt zwischen Systemen.
- **Grund:** So bleibt die Zeitleiste von Wirtschaft, Nachfrage und Ruf getrennt, und jedes System
  lässt sich mit erfundenen Meldungen testen.
- **Beispiel:** `Timeline` meldet `effect_applied` (`src/core/timeline.gd`); niemand ändert dort
  einen Preis.
- **Gegenbeispiel:** Die Zeitleiste senkt bei „Pentium erscheint“ selbst die Preise im Lager.
- **Quelle:** Verfassung, „Technische Rahmenbedingungen“; Nystrom „Observer“ (Quellen 2.2).
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-07 Eine Quelle für Ereignisse

- **Aussage:** Alles, was ein Ereignis auslösen kann, steht in der Zeitleiste. Kein anderes System
  führt einen eigenen Kalender von Ereignissen.
  Ereignis heißt hier ein Eintrag im Katalog. Regelmäßiges wie Miete
  oder Zinsen ist Mechanik eines Kerns; den Monatswechsel reicht ihm die Hülle hinein, etwa aus
  `GameClock.month_passed`. Was ein Kern innerhalb eines Schritts meldet, etwa ein Schuss im Easter
  Egg, ist kein Ereignis in diesem Sinn.
- **Grund:** So lässt sich der Spielverlauf an einer Stelle prüfen und in der Werkstatt simulieren
  (Klaus, 2026-08-13).
- **Beispiel:** Feste und variable Ereignisse stehen im Katalog `src/data/event_catalog.json`,
  auch „Konkurrent eröffnet“.
- **Gegenbeispiel:** *(ausgedacht)* Die Wirtschaft würfelt selbst, ob 1993 eine Rezession kommt.
- **Quelle:** Verfassung, „Technische Rahmenbedingungen“.
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-08 Wiederholbar aus Seed, Grad und Eingriffen

- **Aussage:** Katalog, Seed, Grad und Eingriffe legen ein Spiel vollständig fest. Jeder Zufall kommt
  aus einem eigenen `RandomNumberGenerator`, dessen Startwert nur vom Seed, vom Zweck und von einem
  Schlüssel abhängt; nie aus `randi()`, `randf()` oder `randomize()`. Abgeleitete Werte werden
  entweder gespeichert oder beim Laden genauso neu berechnet wie im Spiel.
  Das gilt für den Spielverlauf, der in den Spielstand geht. Ein
  Spiel ohne Spielstand, etwa das Easter Egg, darf seinen Startwert in der Hülle zufällig wählen; der
  Kern bekommt ihn trotzdem von außen. Ebenso gilt AR-09 nur für Eingriffe in den Spielverlauf.
  Der Seed eines neuen Spiels wird einmal aus einem eigenen Würfel ohne festen Startwert
  gezogen, an einer Stelle: `GameSession.rng`, in Werkzeugen das Seed-Feld. Globaler Zufall sind alle
  Aufrufe ohne eigenen Würfel davor: `randi()`, `randf()`, `randi_range()`, `randf_range()`,
  `randfn()`, `randomize()`, `Array.shuffle()` und `pick_random()`.
  `Timeline.rng` ist nur die Naht für `start_game()` ohne Seed, also für Tests und Werkzeuge; ein
  Spiel bekommt seinen Seed immer von `GameSession`. Auch das Seed-Feld eines Werkzeugs würfelt
  aus einem eigenen Würfel.
- **Grund:** Spielstände bauen darauf, statt den ganzen Zustand zu speichern; ein Fehler lässt sich
  mit demselben Seed nachstellen. Factorio zeigt, wie schon ein anders berechneter Zwischenwert zwei
  Läufe auseinanderlaufen lässt.
- **Beispiel:** `EventDice.make(seed, purpose, key)` (`src/core/timeline/event_dice.gd`); beim
  Fortsetzen spielt `GameSession` den Fahrplan bis zum gespeicherten Tag nach.
- **Gegenbeispiel:** Ein Kunde entscheidet mit `randf() < 0.3`, ob er kauft; oder ein neues System
  zieht Zahlen aus dem Würfel der Zeitleiste und verschiebt so deren Folge.
- **Quelle:** Quellen 4.2, 4.3; `docs/spielbeschreibung/architektur.md`, „Grundsätze“;
  `docs/spielbeschreibung/spielstaende.md`.
- **Schicht:** Kern, Wirtschaft
- **Prüfweise:** Test: `test_architektur.gd`, `kern_verstoesse` (kein globaler Zufall in Kernen;
  Klaus, 2026-10-28); dazu Prüfer: Würfel mit eigenem Startwert, abgeleitete Werte beim Laden.
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-09 Eingriffe als Befehle

- **Aussage:** Jede Handlung des Spielers, die den Spielverlauf ändert, ist ein Datenobjekt mit Tag,
  Art und Werten (Muster „Befehl“). Es lässt sich speichern, nachspielen und im Protokoll zeigen. Die
  Oberfläche erzeugt Befehle, der Kern führt sie aus.
  Ein Befehl darf ein `RefCounted` oder ein `Dictionary` mit festen Schlüsseln sein, wenn ein
  Kern seine Form an einer Stelle prüft, wie `TimelineRun` und `InterventionFile`.
- **Grund:** Nur so gilt „Spielstand = Seed + Grad + Eingriffe“ (AR-08) auch, wenn später Preise
  gesetzt, Waren bestellt und Kunden beraten werden.
- **Beispiel:** Die Eingriffe der Zeitleiste stehen als Einträge im Eingriffsprotokoll
  (`src/core/timeline/intervention_file.gd`) und werden beim Fortsetzen nachgespielt.
- **Gegenbeispiel:** *(ausgedacht)* Der Knopf „Preis ändern“ schreibt den neuen Preis direkt in das
  Produkt und merkt sich nirgends, dass der Spieler es getan hat.
- **Quelle:** Nystrom „Command“ (Quellen 2.2); Quellen 4.3.
- **Schicht:** Kern, Wirtschaft, Oberfläche
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-10 Fester Schritt statt `delta`

- **Aussage:** Ein Kern rechnet in festen Schritten: die Wirtschaft je Spieltag, ein Echtzeitspiel
  je fester Zeitspanne. `delta` aus `_process()` sammelt nur die Hülle und ruft daraus ganze
  Schritte auf, mit einer Obergrenze je Bild.
- **Grund:** Ein variabler Schritt macht das Ergebnis von der Geschwindigkeit des Rechners abhängig
  und den Lauf unwiederholbar (AR-08).
- **Beispiel:** `GameClock.advance_day()` meldet `day_passed` (`src/core/game_clock.gd`);
  `InvadersPage.advance()` rechnet `InvadersGame` in Schritten von `InvadersGame.STEP`, höchstens
  `MAX_STEPS` je Bild (`src/scenes/title/invaders/invaders_page.gd`).
- **Gegenbeispiel:** `kontostand += zinsen * delta` in `_process()`.
- **Quelle:** Nystrom „Game Loop“, „Update Method“ (Quellen 2); Quellen 4.2.
- **Schicht:** Kern, Wirtschaft
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-11 Zustände ausdrücklich

- **Aussage:** Hat etwas mehr als zwei Zustände mit eigenem Verhalten, bekommt es einen
  ausdrücklichen Zustand: einen `enum` mit `match` oder, wenn jeder Zustand viel eigenes Verhalten
  hat, eine Klasse je Zustand (Muster „Zustand“). Keine Sammlung von Wahrheitswerten, die zusammen
  einen Zustand bedeuten.
  Als Sammlung zählen ab zwei eigene Schalter, die zusammen Zustände bilden. Nicht dazu zählen
  Eigenschaften der Engine wie `visible`, Prüfungen auf `null`, unabhängige Achsen wie der Fokus des
  Fensters und ein einzelner Schalter.
  Ein Zustand darf aus dem Baustein abgeleitet werden, der ihn besitzt, etwa der Löschmodus aus
  der Liste der Spielstände (`TitleScreen._current_layer()`); doppelt gespeichert wird er nicht.
- **Grund:** Verstreute Schalter wie `is_waiting` und `is_leaving` können sich widersprechen; ein
  Zustand kann das nicht.
- **Beispiel:** Die Spieluhr läuft, ist angehalten oder steht am Ende (`GameClock.State` in
  `src/core/game_clock.gd`); `paused` ist nur noch aus diesem Zustand abgeleitet. Der Titel führt
  zwei Achsen, Phase der Eingabe und Ebene, als zwei `enum` (`TitleScreen.Phase` und
  `TitleScreen.Layer` in `src/scenes/title/title_screen.gd`).
- **Gegenbeispiel:** `if is_waiting and not is_leaving and has_asked:` an mehreren Stellen.
- **Quelle:** Nystrom „State“ (Quellen 2).
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-12 Autoloads über eine ersetzbare Naht

- **Aussage:** Wer ein Autoload nutzt, nutzt es über eine Variable, die ein Test oder ein Werkzeug
  vorher setzen kann; ist sie leer, gilt das Autoload. Ein Kern bekommt nie ein Autoload, sondern
  nur, was er davon braucht.
- **Grund:** So lassen sich Titel, Spielbildschirm und Zeitleiste mit einer eigenen Uhr oder Sitzung
  testen, ohne das echte Spiel zu starten. Das ist Nystroms erster Rat gegen Singletons: die
  Abhängigkeit hineinreichen.
- **Beispiel:** `session if session != null else GameSession` (`src/scenes/title/title_screen.gd`);
  `clock` in `src/core/timeline.gd`.
- **Gegenbeispiel:** Der Spielbildschirm ruft an zehn Stellen `GameSession.…` direkt.
- **Quelle:** Quellen 2.1; Nystrom „Service Locator“ (Quellen 2.2).
- **Schicht:** Oberfläche, Werkzeuge
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-13 Spielstände mit Version und festen Namen

- **Aussage:** Ein Spielstand hat eine Formatversion und nennt alles über feste Namen oder IDs, nie
  über eine Position in einer Liste oder eine Laufzeit-ID. Eine neue Version des Spiels lädt alte
  Spielstände oder sagt klar, warum nicht. Laufende Abläufe stehen nicht im Spielstand.
- **Grund:** Spielstände überleben Updates; ein Bezug über den Index bricht, sobald ein Produkt oder
  Ereignis dazukommt. So hält es auch Ron Gilbert bei Thimbleweed Park.
- **Beispiel:** `SaveGame` mit Formatversion und Pflichtfeldern wie Katalog, Grad und Tag
  (`src/core/save/save_game.gd`); den Rest spielt das Spiel beim Fortsetzen nach.
- **Gegenbeispiel:** Der Spielstand speichert „Produkt Nr. 17 im Lager“, und nach dem nächsten
  Update ist Nr. 17 ein anderes Produkt.
- **Quelle:** Quellen 1.12, 3.2 („Spielstände ohne laufende Skripte“).
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### AR-14 Das Spiel kennt die Werkzeuge nicht

- **Aussage:** Kein Skript und keine Szene außerhalb von `src/tools/` verweist auf etwas unter
  `src/tools/`. Was Spiel und Werkzeug beide brauchen, liegt im Spiel, etwa in `src/core/`.
  Eine Projekteinstellung mit Feature-Tag, die nur in einem Export gilt, der `src/tools/` enthält,
  ist kein Verweis in diesem Sinn, etwa `run/main_scene.selbsttest`. Werkzeuge dürfen einander
  kennen, solange beide zusammen aus dem Export des Spiels fallen.
  Ein Name aus den Werkzeugen in einem Kommentar ist kein Verweis, etwa „bisher stand das in
  `WhatIfProbe`“: Er bricht im Export nichts, und auch der Test zählt Kommentare nicht.
- **Grund:** Werkzeuge fehlen im exportierten Spiel; ein Verweis darauf bricht erst im Export.
- **Beispiel:** Die Regel für Einträge im Eingriffsprotokoll zog aus `WhatIfProbe` (Werkzeug) nach
  `InterventionFile` (`src/core/timeline/intervention_file.gd`), weil der Spielstand sie braucht.
- **Gegenbeispiel:** Der Spielbildschirm lädt `res://tools/werkstatt/zebra.gd`.
- **Quelle:** Klaus, Feature 004 (`intervention_file.gd`, Kopf); Quellen 3.2 („Werkzeuge sind Teil
  der Architektur“).
- **Schicht:** alle
- **Prüfweise:** Test: `test_architektur.gd`, `verweise_auf_werkzeuge` (Klaus, 2026-10-28)
- **Stand:** gilt seit 2026-10-28, Klaus

---

## Muster

Die Muster aus Robert Nystroms „Game Programming Patterns“, die das Spiel nutzt oder für ein
vorgemerktes System braucht (Quellen 2). Vorgemerkt heißt: Das System steht in
`docs/features/Features.md` und hat Einträge in `docs/features/Feature_Ideas.md`.

| Muster | Kern | In Godot | Wo im Spiel | Regeln |
|---|---|---|---|---|
| Beobachter (Observer) | Ein Subjekt meldet, ohne zu wissen, wer zuhört | Signale | Zeitleiste, Communicator | AR-02, AR-06 |
| Komponente (Component) | Ein Ding setzt sich aus Teilen je Bereich zusammen | Kind-Szenen | Titel mit Communicator und Seiten | AR-05 |
| Typ-Objekt (Type Object) | Ein Typ ist ein Datenobjekt, keine Klasse | `Resource`, `.tres` | Menüeinträge, Ereignisse, später Produkte | AR-04 |
| Fliegengewicht (Flyweight) | Viele teilen sich unveränderliche Daten | geteilte Resources | später Produktdaten | AR-04 |
| Befehl (Command) | Ein Aufruf wird ein Datenobjekt | `RefCounted` oder `Dictionary` mit festen Schlüsseln je Eingriff | Eingriffe, später Preise und Bestellungen | AR-09 |
| Zustand (State) | Verhalten je Zustand | `enum` und `match`, Zustandsklassen | später Kunden, Verkaufsgespräch | AR-11 |
| Spielschleife (Game Loop) | Spielzeit getrennt von Echtzeit | Hülle sammelt `delta` | Spieluhr, Easter Egg | AR-10 |
| Aktualisierungsmethode (Update Method) | Jedes Objekt schreibt sich je Schritt fort | nur als Tagesschritt, nicht `_process()` | später Wirtschaft | AR-10 |

**Nur als Warnung:** Singleton und Dienstlocator (Service Locator). Beide sind in Godot ein Autoload;
dafür gelten AR-03 und AR-12.

**Später, mit dem passenden System:** Ereigniswarteschlange (Ereignisse eines Tages sammeln und am
Abend abarbeiten), Prototyp (Kundentypen aus Vorlagen, Pseudo-Räume), Unterklassen-Sandkasten
(Raumskripte), Schmutzflagge (Bilanzansicht), Doppelpuffer (alle Händler reagieren auf die Werte des
Vortags). Kommt eines davon, wird es hier mit seiner Regel nachgetragen.

**Nicht im Leitfaden:** Bytecode, Datenlokalität, Objektpool, räumliche Aufteilung. Sie lösen
Probleme, die ein Spiel dieser Größe nicht hat.

---

## Schichten

### Kern

Vorbild sind die Godot-Prinzipien. Regeln: AR-01, AR-06, AR-08, AR-10.

### Oberfläche

Vorbild sind die Godot-Prinzipien; Factorio und Gilbert trennen ebenso streng zwischen dem, was
rechnet, und dem, was zeigt (Quellen 3.2, 4.2). Regeln: AR-02, AR-05, AR-09, AR-12 und:

#### AR-15 Die Oberfläche liest und meldet

- **Aussage:** Die Oberfläche zeigt den Zustand eines Kerns und meldet, was der Spieler will. Sie
  ändert Daten eines Kerns nie an dessen Feldern, sondern über seine Methoden oder als Befehl
  (AR-09).
  Felder eines Kerns, die die Oberfläche nur lesen darf, tragen den
  Doku-Kommentar „Nur lesen.“.
  Das gilt auch für Felder eines Autoloads, die die Oberfläche liest. Ein reines
  Datenobjekt, das nur Werte für eine Datei sammelt, ist kein Kern; seine Felder setzt, wer es
  füllt.
  „Nur lesen.“ bindet die Oberfläche und andere Leser. Schreiben darf, wer das Objekt besitzt oder
  anlegt, etwa `GameSession` die Felder von `SaveGame` oder der Fahrer des Selbsttests beim
  Anlegen von Spielständen.
- **Grund:** Sonst gibt es zwei Stellen, an denen sich der Zustand ändert, und der Kern kann seine
  Regeln nicht durchsetzen.
- **Beispiel:** Der Titel ruft `GameSession.start_new()` und baut den Lauf nicht selbst
  (`src/scenes/title/title_screen.gd`).
- **Gegenbeispiel:** *(ausgedacht)* Die Lagerliste setzt `lager.bestand["486DX-33"] -= 1`, wenn der
  Spieler verkauft.
- **Quelle:** Quellen 4.2, 4.3, 6.2.
- **Schicht:** Oberfläche
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-28, Klaus

### Wirtschaft

Vorbild sind deterministische Simulationen wie Factorio: fester Takt, Zufall nur aus dem Seed,
Simulation getrennt von der Darstellung (Quellen 4). **Übernommen** wird, dass gleicher Seed und
gleiche Eingriffe den gleichen Verlauf ergeben, und die Probe „speichern, laden, vergleichen“.
**Nicht übernommen** wird alles, was ein Netzwerkspiel im Gleichschritt braucht, etwa Prüfsummen je
Takt über mehrere Rechner. Regeln: AR-01, AR-08, AR-09, AR-10 und:

#### AR-16 Geld als ganze Zahl

- **Aussage:** Geldbeträge sind ganze Zahlen in Pfennig, nie `float`. Umgerechnet in „2.499,00 DM“
  wird erst in der Anzeige.
- **Grund:** Kommazahlen runden je nach Rechenweg verschieden; ob Godot auf Windows, macOS und Linux
  bitgleich rechnet, ist ungeprüft (`docs/offene-punkte.md`). Ganze Zahlen sind überall gleich.
- **Beispiel:** *(ausgedacht)* `preis_pf := 249900` für 2.499,00 DM.
- **Gegenbeispiel:** `preis := 2499.0 * 0.7`
- **Quelle:** Quellen 4.2, 4.3.
- **Schicht:** Wirtschaft
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-29, Klaus (Feature 010, erstes Feature der Schicht Wirtschaft); vorher „gilt ab dem ersten Feature der Schicht Wirtschaft“ (Klaus, 2026-10-28)

#### AR-17 Feste Reihenfolge

- **Aussage:** Wo mehrere Dinge im selben Schritt drankommen, etwa Kunden oder Händler, ist die
  Reihenfolge fest: nach einer ID oder nach der Reihenfolge, in der sie entstanden. Sie hängt nie von
  der Reihenfolge der Nodes im Baum oder von einer Hash-Tabelle ab.
- **Grund:** Eine wechselnde Reihenfolge ergibt bei knapper Ware einen anderen Käufer und damit einen
  anderen Verlauf (AR-08).
- **Beispiel:** *(ausgedacht)* Die Kunden eines Tages werden nach ihrer laufenden Nummer bedient.
- **Gegenbeispiel:** Die Kunden werden in der Reihenfolge von `get_children()` bedient, die sich
  ändert, wenn eine Figur neu ins Bild kommt.
- **Quelle:** Quellen 4.2 (FFF #340), 4.3.
- **Schicht:** Wirtschaft
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-29, Klaus (Feature 010, erstes Feature der Schicht Wirtschaft); vorher „gilt ab dem ersten Feature der Schicht Wirtschaft“ (Klaus, 2026-10-28)

### Adventure

Vorbild sind SCUMM mit Monkey Island und Thimbleweed Park von Ron Gilbert (Quellen 3). **Übernommen**
wird die Trennung von Bausteinen und Inhalt, Räume und Dialoge als Daten, lineare Abläufe und das
Speichern nur an Ruhepunkten. **Nicht übernommen** wird eine eigene Skriptsprache (GDScript mit
`await` reicht) und ein eigener Raumeditor (das macht der Godot-Editor). Regeln: AR-04, AR-05,
AR-11 und:

#### AR-18 Bausteine ohne Inhalt

- **Aussage:** Die Bausteine des Adventures, also Raum, anklickbare Stelle, Verb, Inventar und
  Dialog, kennen keinen Spielinhalt. Was in einem Raum liegt und was ein Satz bewirkt, steht in
  Daten und in den Skripten des Raums.
- **Grund:** So entsteht ein neuer Ort, ohne die Bausteine anzufassen; Gilbert trennt Engine und
  Spiel aus genau diesem Grund.
- **Beispiel:** *(ausgedacht)* Der Baustein weiß, wie „Benutze Diskette mit Laufwerk“ geprüft wird,
  aber nicht, dass im Lager eine Diskette liegt.
- **Gegenbeispiel:** Im Skript des Verbs „Nimm“ steht `if objekt == "diskette":`.
- **Quelle:** Quellen 3.2, 3.3.
- **Schicht:** Adventure
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-29, Klaus (Feature 010, erstes Feature der Schicht Adventure); vorher „gilt ab dem ersten Feature der Schicht Adventure“ (Klaus, 2026-10-28)

#### AR-19 Abläufe linear, gespeichert an Ruhepunkten

- **Aussage:** Abläufe in einem Raum, etwa eine kurze Szene mit einem Kunden, stehen linear mit
  `await` im Skript des Raums, nicht als Zustandsautomat über viele Rückrufe. Gespeichert wird nur an
  Ruhepunkten, etwa vor einem Dialog, nie mitten in einem Ablauf.
- **Grund:** Linear geschrieben ist ein Ablauf lesbar wie ein Drehbuch. Ein laufendes `await` lässt
  sich nicht speichern; Gilbert löst das genauso.
- **Beispiel:** *(ausgedacht)* `await kunde.geht_zur_theke()`, dann `await dialog.zeige("kunde_486")`.
- **Gegenbeispiel:** Der Spielstand versucht, die Stelle in einem laufenden Ablauf zu speichern.
- **Quelle:** Quellen 3.2, 3.3.
- **Schicht:** Adventure
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-29, Klaus (Feature 010, erstes Feature der Schicht Adventure); vorher „gilt ab dem ersten Feature der Schicht Adventure“ (Klaus, 2026-10-28)

#### AR-20 Dialoge als Daten

- **Aussage:** Dialoge stehen als Daten mit benannten Knoten, Antworten, Bedingungen und Variablen,
  nicht als verschachtelte `if` im Code. Bedingungen lesen Spielvariablen über einen klaren Zugang.
- **Grund:** Texte schreiben und ändern geht dann ohne Code, und der Text-Prüfer findet alle Sätze an
  einer Stelle.
- **Beispiel:** *(ausgedacht)* Knoten `kunde_486`: „Was kostet der 486er?“ mit drei Antworten, eine
  davon nur, wenn der Spieler ihn auf Lager hat.
- **Gegenbeispiel:** `if antwort == 2 and lager.hat("486DX-33"): sage("…")` im Skript der Figur.
- **Quelle:** Quellen 3.2 („Dialoge als reiner Text“), 3.3.
- **Schicht:** Adventure
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-10-29, Klaus (Feature 010, erstes Feature der Schicht Adventure); vorher „gilt ab dem ersten Feature der Schicht Adventure“ (Klaus, 2026-10-28)

### Werkzeuge

Werkstatt und Selbsttest (aus Feature 007) sind keine eigene Schicht mit Vorbild. Für sie gelten
dieselben Regeln, mit diesen Unterschieden:
- Ein Werkzeug darf Datendateien des Spiels lesen und schreiben, etwa die Werkstatt den
  Ereigniskatalog.
- Ein Werkzeug darf Kerne des Spiels direkt nutzen und Autoloads über eine Naht (AR-12) anhalten oder
  steuern, wenn es dafür einen Grund im Kommentar nennt.
- AR-14 gilt nur in eine Richtung: Werkzeuge dürfen das Spiel kennen, nicht umgekehrt.
- Ein Werkzeug darf seine Texte je Panel als Konstanten am Kopf halten; ein Werkzeug aus vielen
  Teilen wie der Selbsttest bekommt eine eigene Textklasse (`SelbsttestTexte`). Ein Werkzeugfenster
  ist kein Bildschirm im Sinne von AR-04.
- Ein Werkzeug darf das Spiel von außen über die Namen innerer Knoten bedienen, aber nur an einer
  Stelle, wie der Fahrer des Selbsttests (`selbsttest_fahrer.gd`); alles andere im Werkzeug geht über
  diese Stelle. Die Knotennamen werden damit zur Schnittstelle: Wer sie umbenennt, ändert den Fahrer
  mit.
- Ein Werkzeug darf Godots globalen Würfel mit `seed()` stellen, wenn es den Grund im Kommentar
  nennt, etwa damit das versteckte Spiel im Selbsttest in jedem Lauf gleich spielt.
- Der Leitfaden gilt für `src/`. Ein Werkzeug außerhalb, etwa `tools/selbsttest/vergleich.py`, nennt
  im Kommentar die Stelle in Godot, deren Wert oder Format es ein zweites Mal kennt.

---

## Was bisher woanders stand

| Grundsatz | Wo | Hier |
|---|---|---|
| Kern ohne Node, Hülle als Autoload | `docs/spielbeschreibung/architektur.md`, „Grundsätze“ | AR-01 |
| Melden statt anwenden | Verfassung, „Technische Rahmenbedingungen“; `architektur.md` | AR-06 |
| Alles, was ein Ereignis auslösen kann, steht in der Timeline | Verfassung, „Technische Rahmenbedingungen“ | AR-07 |
| Wiederholbar | `architektur.md`, „Grundsätze“ | AR-08 |
| Daten statt Code | `architektur.md`, „Grundsätze“; Verfassung, Grundsatz V | AR-04 |
| Ein Look | `architektur.md`; Verfassung, Grundsatz IV | nicht hier: Style-Guide |
| Nur Desktop | Verfassung, Grundsatz I | nicht hier: Verfassung |
| Systeme reden über Signale | `.claude/agents/godot-entwickler.md`, „Godot“ | AR-02, AR-06 |

---

## Ausnahmen

| Ort | Regel | Grund | Freigabe |
|---|---|---|---|
| `src/data/event_catalog.json` | AR-04 | Gepflegte Spieldaten als JSON statt Resource: Die Werkstatt liest und schreibt die Datei, Grundsatz V der Verfassung sieht sie als Datei vor, und Git zeigt jede Änderung lesbar. Eine Datendatei ohne Skript, deshalb nur diese Zeile | Klaus, 2026-10-28 |
| `src/tools/werkstatt/werkstatt.gd`, `_set_up_window()` | AR-02 | Die Werkstatt hält GameWindow über den Pfad `/root/GameWindow` an. Mit `-s` geladen, etwa von der Textausgabe, kennt GDScript den Namen des Autoloads beim Kompilieren nicht; der Pfad ist der einzige Weg. Die Naht nach AR-12 bleibt davon unberührt | Klaus, 2026-10-28 |

---

## Geschichte

Ergänzt nach der Fehler- und der Planprobe in Phase 2 von Feature 008 (Klaus, 2026-10-28), weil
der Architektur-Prüfer acht Lücken gemeldet hatte (`docs/offene-punkte.md`, „Feature 008, Lücken im
Leitfaden“). Der bisherige Wortlaut gilt weiter; ergänzt wurde je ein Absatz am Ende der Aussage:

| Regel | Ergänzt um | Wortlaut der Aussage bis 2026-10-28 |
|---|---|---|
| AR-02 | Übersetzen eines Signals ist erlaubt (L5) | Ein Baustein kennt den nicht, der ihn einsetzt. Er meldet nach oben per Signal; wer ihn einsetzt, ruft ihn direkt auf und reicht ihm hinein, was er braucht. Geschwister reden über den gemeinsamen Eltern-Node. Kein Skript greift über `get_parent()`, einen Pfad mit `../` oder `/root/` nach oben. Signale werden nicht über mehrere Ebenen weitergereicht. |
| AR-04 | was Spielinhalt ist, game_bible als Quelle, Stellschrauben, Texte (L1, L2, L8) | Gepflegte Spieldaten, etwa Produkte, Kundentypen oder Objekte eines Raums, sind Datenobjekte und keine Klassen (Muster „Typ-Objekt“). Sie stehen als `Resource`-Klasse mit `.tres`-Dateien oder in einer Datendatei, die ein Werkzeug pflegt, nicht als Werte im Code. Eine geladene Resource ist nur zum Lesen da, weil Godot sie zwischen allen Nutzern teilt; was sich im Spiel ändert, gehört in einen Kern oder in eine Kopie. Spielstände sind ausgenommen (AR-13). |
| AR-07 | was ein Ereignis ist (L4) | Alles, was ein Ereignis auslösen kann, steht in der Zeitleiste. Kein anderes System führt einen eigenen Kalender von Ereignissen. |
| AR-08 | Spiele ohne Spielstand (L6) | Katalog, Seed, Grad und Eingriffe legen ein Spiel vollständig fest. Jeder Zufall kommt aus einem eigenen `RandomNumberGenerator`, dessen Startwert nur vom Seed, vom Zweck und von einem Schlüssel abhängt; nie aus `randi()`, `randf()` oder `randomize()`. Abgeleitete Werte werden entweder gespeichert oder beim Laden genauso neu berechnet wie im Spiel. |
| AR-15 | Kommentar „Nur lesen.“ (L7) | Die Oberfläche zeigt den Zustand eines Kerns und meldet, was der Spieler will. Sie ändert Daten eines Kerns nie an dessen Feldern, sondern über seine Methoden oder als Befehl (AR-09). |

Dazu die Regel für die Schwere bei einem Verstoß gegen die Verfassung (L3), unter „So liest man eine
Regel“.

Ergänzt nach der Bestandsprüfung in Phase 3 von Feature 008 (Klaus, 2026-10-28), weil der
Architektur-Prüfer 21 Lücken gemeldet hatte, zusammengefasst zu 19
(`specs/008-architektur/bestandsbericht.md`, „Lücken im Leitfaden“). Der bisherige Wortlaut gilt
weiter; ergänzt wurde je ein Absatz am Ende der Aussage, dazu die Tabelle „Muster“ beim Befehl und der
Abschnitt „Werkzeuge“ um die Texte (L14):

| Regel | Ergänzt um | Wortlaut der Aussage vor dieser Ergänzung |
|---|---|---|
| AR-01 | Autoloads mit Ablaufzustand, Engine-Dienste, Kern und `src/ui/` (L1, L2, L4) | Spiellogik und Spielzustand stehen in Klassen, die von `RefCounted` erben (der **Kern**). Eine Szene oder ein Autoload ist nur die **Hülle**: Sie hält den Kern, reicht ihm Zeit, Seed und Daten hinein und macht aus seinen Ergebnissen Signale und Bilder. Ein Kern greift nicht auf den Szenenbaum, auf Autoloads oder auf den globalen Zufall zu. |
| AR-02 | Callables, Tiefe nach unten, Hilfen von Geschwistern, eigene Szene (L15, L16, L17, L19) | Ein Baustein kennt den nicht, der ihn einsetzt. Er meldet nach oben per Signal; wer ihn einsetzt, ruft ihn direkt auf und reicht ihm hinein, was er braucht. Geschwister reden über den gemeinsamen Eltern-Node. Kein Skript greift über `get_parent()`, einen Pfad mit `../` oder `/root/` nach oben. Signale werden nicht über mehrere Ebenen weitergereicht. Ein Baustein darf das Signal eines inneren Teils in ein eigenes Signal mit eigener Bedeutung übersetzen; verboten ist nur das bloße Durchreichen. |
| AR-03 | Autoloads untereinander (L11) | Es gibt genau diese Autoloads, in dieser Reihenfolge: `GameClock`, `Timeline`, `GameWindow`, `GameSession`. Ein neues braucht Klaus' Freigabe im Plan. Ein Autoload darf nur sein, was eigene Daten über Szenenwechsel hinweg verwaltet und keine fremden ändert. Kein allgemeiner Signalbus und kein „Manager“ als Autoload; Hilfsfunktionen sind `static func` einer Klasse mit `class_name`. |
| AR-04 | Grundgrenzen, Texte aus Kernen, Theme, Vorgaben für leere Dateien (L6, L9, L10, L18) | Gepflegte Spieldaten, etwa Produkte, Kundentypen oder Objekte eines Raums, sind Datenobjekte und keine Klassen (Muster „Typ-Objekt“). Sie stehen als `Resource`-Klasse mit `.tres`-Dateien oder in einer Datendatei, die ein Werkzeug pflegt, nicht als Werte im Code. Eine geladene Resource ist nur zum Lesen da, weil Godot sie zwischen allen Nutzern teilt; was sich im Spiel ändert, gehört in einen Kern oder in eine Kopie. Spielstände sind ausgenommen (AR-13). Spielinhalt heißt hier, was in die game_bible gehört: Produkte, Preise, Kunden, Mieten. Die game_bible bleibt dafür die Quelle; Resources entstehen daraus über einen Importer, nie von Hand, damit es keine zweite Quelle gibt. Keine Spieldaten in diesem Sinn sind Stellschrauben einer Mechanik, etwa Tempi oder Chancen, und Werte, die der Style-Guide festlegt: Sie stehen als benannte Konstanten an einer Stelle, wie `UiPalette`. Ebenso stehen die Texte eines Bildschirms an einer Stelle als Konstanten, wie `TitleTexts`; Dialoge regelt AR-20. |
| AR-05 | geteilte Bausteine (L5) | Eine Szene wird aus kleineren, eigenständigen Szenen zusammengesetzt. Jede Szene läuft für sich, in einer Probeszene oder mit F6, und bekommt, was sie braucht, von außen. Bausteine unter `src/ui/` kennen keinen Bildschirm. Ein Kind-Node ist nur, was mit seinem Eltern-Node entsteht und verschwindet. |
| AR-06 | Rückgabewert als Meldung (L7) | Wer ein Ereignis erzeugt, meldet es per Signal und wendet seine Folgen nicht selbst an. Was daraus folgt, entscheidet das System, das zuhört. |
| AR-08 | Seed eines neuen Spiels, Liste des globalen Zufalls (L3) | Katalog, Seed, Grad und Eingriffe legen ein Spiel vollständig fest. Jeder Zufall kommt aus einem eigenen `RandomNumberGenerator`, dessen Startwert nur vom Seed, vom Zweck und von einem Schlüssel abhängt; nie aus `randi()`, `randf()` oder `randomize()`. Abgeleitete Werte werden entweder gespeichert oder beim Laden genauso neu berechnet wie im Spiel. Das gilt für den Spielverlauf, der in den Spielstand geht. Ein Spiel ohne Spielstand, etwa das Easter Egg, darf seinen Startwert in der Hülle zufällig wählen; der Kern bekommt ihn trotzdem von außen. Ebenso gilt AR-09 nur für Eingriffe in den Spielverlauf. |
| AR-09 | Form eines Befehls (L12) | Jede Handlung des Spielers, die den Spielverlauf ändert, ist ein Datenobjekt mit Tag, Art und Werten (Muster „Befehl“). Es lässt sich speichern, nachspielen und im Protokoll zeigen. Die Oberfläche erzeugt Befehle, der Kern führt sie aus. |
| AR-11 | was eine Sammlung von Schaltern ist (L8) | Hat etwas mehr als zwei Zustände mit eigenem Verhalten, bekommt es einen ausdrücklichen Zustand: einen `enum` mit `match` oder, wenn jeder Zustand viel eigenes Verhalten hat, eine Klasse je Zustand (Muster „Zustand“). Keine Sammlung von Wahrheitswerten, die zusammen einen Zustand bedeuten. |
| AR-15 | Felder eines Autoloads, Datenobjekte (L13) | Die Oberfläche zeigt den Zustand eines Kerns und meldet, was der Spieler will. Sie ändert Daten eines Kerns nie an dessen Feldern, sondern über seine Methoden oder als Befehl (AR-09). Felder eines Kerns, die die Oberfläche nur lesen darf, tragen den Doku-Kommentar „Nur lesen.“. |

Ergänzt nach der Nachprüfung des Codes aus Feature 007 in Phase 5 von Feature 008 (T035; Klaus,
2026-10-28), weil der Architektur-Prüfer elf Lücken gemeldet hatte
(`specs/008-architektur/bestandsbericht.md`, „Nachprüfung des Codes aus Feature 007“). Der bisherige
Wortlaut gilt weiter; ergänzt wurde je ein Absatz am Ende der Aussage, dazu der Abschnitt
„Werkzeuge“ um die Punkte zu Knotennamen (M1), globalem Würfel (M6) und Werkzeugen außerhalb von
`src/` (M11). Die Prüfweise von AR-02 zählt `../` in Skripten nur noch in Knotenpfaden, weil ein
Dateipfad wie `"../Resources"` nicht nach oben greift.

| Regel | Ergänzt um | Wortlaut der Aussage vor dieser Ergänzung |
|---|---|---|
| AR-01 | Helfer der Hülle, Dienste der Engine, statische Naht (M3, M10) | Spiellogik und Spielzustand stehen in Klassen, die von `RefCounted` erben (der **Kern**). Eine Szene oder ein Autoload ist nur die **Hülle**: Sie hält den Kern, reicht ihm Zeit, Seed und Daten hinein und macht aus seinen Ergebnissen Signale und Bilder. Ein Kern greift nicht auf den Szenenbaum, auf Autoloads oder auf den globalen Zufall zu. Ein Autoload darf kleinen Ablaufzustand halten, etwa das Datum der Uhr oder das laufende Spiel; Spielmechanik gehört in einen Kern. Ein Kern darf Dateien lesen und schreiben und die Uhr des Rechners nur für Zeitstempel und Rechenbudgets lesen, die das Ergebnis nicht ändern; Spielzeit nie. Aus `src/ui/` darf ein Kern nur Klassen mit Konstanten wie `UiPalette` kennen, keine Szenen und Bausteine. |
| AR-03 | reine Rechnungen eines Autoloads (M4) | Es gibt genau diese Autoloads, in dieser Reihenfolge: `GameClock`, `Timeline`, `GameWindow`, `GameSession`. Ein neues braucht Klaus' Freigabe im Plan. Ein Autoload darf nur sein, was eigene Daten über Szenenwechsel hinweg verwaltet und keine fremden ändert. Kein allgemeiner Signalbus und kein „Manager“ als Autoload; Hilfsfunktionen sind `static func` einer Klasse mit `class_name`. Autoloads dürfen einander über eine Naht und in der Reihenfolge aus `project.godot` aufrufen; ein Methodenaufruf ist kein „fremde Daten ändern“. Einstellungen des `SceneTree`, etwa `auto_accept_quit`, setzt ein Autoload nur mit Kommentar. |
| AR-04 | Szenenpfade, Kopie des Themes (M8, M9) | Gepflegte Spieldaten, etwa Produkte, Kundentypen oder Objekte eines Raums, sind Datenobjekte und keine Klassen (Muster „Typ-Objekt“). Sie stehen als `Resource`-Klasse mit `.tres`-Dateien oder in einer Datendatei, die ein Werkzeug pflegt, nicht als Werte im Code. Eine geladene Resource ist nur zum Lesen da, weil Godot sie zwischen allen Nutzern teilt; was sich im Spiel ändert, gehört in einen Kern oder in eine Kopie. Spielstände sind ausgenommen (AR-13). Spielinhalt heißt hier, was in die game_bible gehört: Produkte, Preise, Kunden, Mieten. Die game_bible bleibt dafür die Quelle; Resources entstehen daraus über einen Importer, nie von Hand, damit es keine zweite Quelle gibt. Keine Spieldaten in diesem Sinn sind Stellschrauben einer Mechanik, etwa Tempi oder Chancen, und Werte, die der Style-Guide festlegt: Sie stehen als benannte Konstanten an einer Stelle, wie `UiPalette`. Ebenso stehen die Texte eines Bildschirms an einer Stelle als Konstanten, wie `TitleTexts`; Dialoge regelt AR-20. Grundgrenzen wie der Spielzeitraum oder der größte Seed stehen einmal in `src/core/` und werden von dort gelesen. Texte, die ein Kern liefert, stehen als Konstanten am Kopf des Kerns, wie `SaveGame.REASON_*`. Das Theme ist neben `UiPalette` eine erlaubte zweite Stelle für Farben, weil Tests beide gleich halten. Vorgaben eines Werkzeugs für eine leere Datendatei dürfen im Code stehen. |
| AR-14 | Projekteinstellung mit Feature-Tag, Werkzeuge untereinander (M5, M7) | Kein Skript und keine Szene außerhalb von `src/tools/` verweist auf etwas unter `src/tools/`. Was Spiel und Werkzeug beide brauchen, liegt im Spiel, etwa in `src/core/`. |
| Werkzeuge, Texte | eigene Textklasse erlaubt (M2) | Texte stehen je Panel als Konstanten am Kopf, nicht in einer eigenen Textklasse; ein Werkzeugfenster ist kein Bildschirm im Sinne von AR-04 (Klaus, 2026-10-28). |

Ergänzt nach der Phasenprüfung von Phase 5 in Feature 008 (T038; Klaus, 2026-10-29), weil der
Architektur-Prüfer fünf Lücken gemeldet hatte (`specs/008-architektur/bestandsbericht.md`,
„Phasenprüfung Phase 5“). Der bisherige Wortlaut gilt weiter; ergänzt wurde je ein Absatz am Ende
der Aussage. Zur Lücke bei AR-14 (ein Kern nennt eine Werkzeugklasse im Kommentar) nennt der
Kommentar von `format_points()` sie nicht mehr; weil 14 ältere Kommentare in Kernen Werkzeuge nennen,
bekam AR-14 dazu einen Satz (Klaus, 2026-10-29).

| Regel | Ergänzt um | Wortlaut der Aussage vor dieser Ergänzung |
|---|---|---|
| AR-04 | private Kopien gleicher Hilfen | Gepflegte Spieldaten, etwa Produkte, Kundentypen oder Objekte eines Raums, sind Datenobjekte und keine Klassen (Muster „Typ-Objekt“). Sie stehen als `Resource`-Klasse mit `.tres`-Dateien oder in einer Datendatei, die ein Werkzeug pflegt, nicht als Werte im Code. Eine geladene Resource ist nur zum Lesen da, weil Godot sie zwischen allen Nutzern teilt; was sich im Spiel ändert, gehört in einen Kern oder in eine Kopie. Spielstände sind ausgenommen (AR-13). Spielinhalt heißt hier, was in die game_bible gehört: Produkte, Preise, Kunden, Mieten. Die game_bible bleibt dafür die Quelle; Resources entstehen daraus über einen Importer, nie von Hand, damit es keine zweite Quelle gibt. Keine Spieldaten in diesem Sinn sind Stellschrauben einer Mechanik, etwa Tempi oder Chancen, und Werte, die der Style-Guide festlegt: Sie stehen als benannte Konstanten an einer Stelle, wie `UiPalette`. Ebenso stehen die Texte eines Bildschirms an einer Stelle als Konstanten, wie `TitleTexts`; Dialoge regelt AR-20. Grundgrenzen wie der Spielzeitraum oder der größte Seed stehen einmal in `src/core/` und werden von dort gelesen. Texte, die ein Kern liefert, stehen als Konstanten am Kopf des Kerns, wie `SaveGame.REASON_*`. Das Theme ist neben `UiPalette` eine erlaubte zweite Stelle für Farben, weil Tests beide gleich halten. Vorgaben eines Werkzeugs für eine leere Datendatei dürfen im Code stehen. Pfade von Szenen, die ein Werkzeug startet, stehen einmal als Konstante. Eine Kopie des Themes für ein Werkzeug ist eine weitere erlaubte Stelle für Farben, wenn ein Test sie gleich hält, wie bei `selbsttest_theme.tres`. |
| AR-08 | `Timeline.rng` als Naht, Seed-Feld mit eigenem Würfel | Katalog, Seed, Grad und Eingriffe legen ein Spiel vollständig fest. Jeder Zufall kommt aus einem eigenen `RandomNumberGenerator`, dessen Startwert nur vom Seed, vom Zweck und von einem Schlüssel abhängt; nie aus `randi()`, `randf()` oder `randomize()`. Abgeleitete Werte werden entweder gespeichert oder beim Laden genauso neu berechnet wie im Spiel. Das gilt für den Spielverlauf, der in den Spielstand geht. Ein Spiel ohne Spielstand, etwa das Easter Egg, darf seinen Startwert in der Hülle zufällig wählen; der Kern bekommt ihn trotzdem von außen. Ebenso gilt AR-09 nur für Eingriffe in den Spielverlauf. Der Seed eines neuen Spiels wird einmal aus einem eigenen Würfel ohne festen Startwert gezogen, an einer Stelle: `GameSession.rng`, in Werkzeugen das Seed-Feld. Globaler Zufall sind alle Aufrufe ohne eigenen Würfel davor: `randi()`, `randf()`, `randi_range()`, `randf_range()`, `randfn()`, `randomize()`, `Array.shuffle()` und `pick_random()`. |
| AR-11 | abgeleiteter Zustand aus dem besitzenden Baustein | Hat etwas mehr als zwei Zustände mit eigenem Verhalten, bekommt es einen ausdrücklichen Zustand: einen `enum` mit `match` oder, wenn jeder Zustand viel eigenes Verhalten hat, eine Klasse je Zustand (Muster „Zustand“). Keine Sammlung von Wahrheitswerten, die zusammen einen Zustand bedeuten. Als Sammlung zählen ab zwei eigene Schalter, die zusammen Zustände bilden. Nicht dazu zählen Eigenschaften der Engine wie `visible`, Prüfungen auf `null`, unabhängige Achsen wie der Fokus des Fensters und ein einzelner Schalter. |
| AR-14 | Namen aus Werkzeugen in Kommentaren | Kein Skript und keine Szene außerhalb von `src/tools/` verweist auf etwas unter `src/tools/`. Was Spiel und Werkzeug beide brauchen, liegt im Spiel, etwa in `src/core/`. Eine Projekteinstellung mit Feature-Tag, die nur in einem Export gilt, der `src/tools/` enthält, ist kein Verweis in diesem Sinn, etwa `run/main_scene.selbsttest`. Werkzeuge dürfen einander kennen, solange beide zusammen aus dem Export des Spiels fallen. |
| AR-15 | wen „Nur lesen.“ bindet | Die Oberfläche zeigt den Zustand eines Kerns und meldet, was der Spieler will. Sie ändert Daten eines Kerns nie an dessen Feldern, sondern über seine Methoden oder als Befehl (AR-09). Felder eines Kerns, die die Oberfläche nur lesen darf, tragen den Doku-Kommentar „Nur lesen.“. Das gilt auch für Felder eines Autoloads, die die Oberfläche liest. Ein reines Datenobjekt, das nur Werte für eine Datei sammelt, ist kein Kern; seine Felder setzt, wer es füllt. |

Nachgezogen nach der Lückensuche von Feature 008 (T040; Klaus, 2026-10-29), ohne eine Aussage zu
ändern: die Kopfzeile „Stand“; das Beispiel von AR-07 nennt den Pfad des Katalogs; AR-11 hat statt
des ausgedachten Kunden ein Beispiel aus dem Code (`GameClock.State`, `TitleScreen.Phase` und
`TitleScreen.Layer`); die Prüfweise von AR-01 nennt den ganzen Umfang von `kern_verstoesse`.

Mit Feature 010 beginnen die Schichten Wirtschaft und Adventure (Klaus, 2026-10-29,
`specs/010-ladeneroeffnung/spec.md`, „Plan 2026-10-29“). Der Stand von AR-16 und AR-17 (Wirtschaft)
sowie AR-18 bis AR-20 (Adventure) ist seitdem „gilt seit 2026-10-29“; vorher galten sie „ab dem
ersten Feature der Schicht“. Keine Aussage hat sich geändert.
