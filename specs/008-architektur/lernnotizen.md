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
