# Titelbildschirm und Hauptmenü

- **Worum es geht:** was vom Start der App bis zum Spiel auf dem Titelbildschirm passiert: das
  Hauptmenü, die Wahl des Grads, die Liste der Spielstände mit Löschen und die Rückfrage, alle als
  Seiten auf dem Communicator.
- **Laden, wenn:** Titelbildschirm, Hauptmenü, eine Seite, der Hinweis oder Texte im Titel
  geändert werden, oder ein Menüeintrag dazukommt oder verfügbar wird.
- **Code:** `src/scenes/title/` (`title_screen`, `main_menu`, `menu_entry`, `menu_hint`,
  `menu_paper`, `save_list`, `title_texts`); Tests `src/test/test_title_screen.gd`,
  `test_main_menu.gd`, `test_save_list.gd`, `test_menu_hint.gd`, `test_title_texts.gd`
- **Herkunft:** `specs/001-hauptmenue/` (`contracts/titelbildschirm.md`), erweitert durch
  `specs/004-neues-spiel/` (`contracts/titelbildschirm.md`, `data-model.md`, `research.md` R11 bis
  R14) und `specs/005-communicator/` (`contracts/titelbildschirm.md`, `research.md` R8 bis R10)
- **Stand:** Feature 005, 2026-10-27
- **Nachbarn:** der Baustein Communicator in [communicator.md](communicator.md), was beim
  Beginnen und Fortsetzen passiert in [spielablauf.md](spielablauf.md), Spielstände in
  [spielstaende.md](spielstaende.md), Fenster, Farben und Schriften in
  [darstellung.md](darstellung.md)

## Start

Die App startet per Doppelklick im Fenster (bis 2026-10-20 im Vollbild). Bis zum ersten Bild ist
der Grund `anzeige-grund`, ohne Splash-Bild. Hauptszene ist
`res://scenes/title/title_screen.tscn`. Ziel: höchstens 3 s bis zum bedienbaren Titelbildschirm.
Es läuft dabei kein Spiel; eins beginnt erst über das Menü.

Bei jedem Erscheinen, auch nach „Zum Hauptmenü“, steht der Communicator erst draußen. Der Titel
setzt die Einträge des Hauptmenüs und wählt vor, dann fährt das Gerät herein. Bis das Hauptmenü
seine Einträge hat, fängt die Wache `_ready_for_input` jede Eingabe ab, auch Esc. Während der
Fahrt herein lässt sich schon wählen und auslösen.

## Aufbau

```text
TitleScreen (Control, 640 × 360)
├── Background          Titelbild T-02, 640 × 360, genau doppelt aus dem Bildraster
├── LogoBlock           Ladenschild-Logo, darunter „WIRTSCHAFTSSIMULATION · 1985–1999“,
│                       bei (14, 12) bis y 83, mit pixelschatten
├── VersionLine         oben rechts, 16 vom Rand, „V0.1 · PROTOTYP“
└── Communicator        Gehäuse G-03, Endlage (244, 92) bis zum unteren Bildrand
    ├── MainMenu        Seite HAUPTMENÜ        ┐
    ├── DifficultySheet Seite SCHWIERIGKEIT    │ auf der Anzeige (280, 120) bis (600, 280),
    ├── SaveList        Seite SPIELSTÄNDE      │ immer genau eine sichtbar
    └── ConfirmSheet    Seite LÖSCHEN?         ┘
```

Alle Seiten stehen mit `look = LCD` auf der Anzeige des Communicators (siehe
[communicator.md](communicator.md)): dunkle Schrift auf `lcd`, die gewählte Zeile invertiert.
Hauptmenü, Gradwahl und Rückfrage sind Instanzen von `main_menu.tscn` mit `MenuEntry`s, die der
Titelbildschirm zur Laufzeit baut. Die Liste ist eine eigene Szene `save_list.tscn`. Auswahl und
Pfeil malen beide über `MenuPaper`. Der Schatten des Logos ist eine Silhouette des Logos in
`tusche` (`TitleScreen.silhouette()`), 2 Pixel nach rechts unten.

`TitleScreen` setzt nur zusammen und verbindet. Seiten und Communicator kennen einander nur so weit,
wie der Communicator sie hinstellt und zeigt: Eine Seite meldet per Signal, der Titelbildschirm
reicht weiter, entscheidet, was ein Eintrag bewirkt, und zeigt mit `Communicator.show_page()` die
nächste Seite. Ein Spiel beginnt oder setzt fort nur über `GameSession`, gelöscht wird nur über deren
`SaveStore`. Alle Texte stehen in `TitleTexts`.

## Wege

```mermaid
flowchart LR
    H["HAUPTMENÜ"] -->|"Neues Spiel"| G["SCHWIERIGKEIT"]
    G -->|"Leicht, Mittel, Schwer"| S(["Spielbildschirm"])
    H -->|"Weiterspielen"| S
    H -->|"Spiel laden"| L["SPIELSTÄNDE"]
    L -->|"fortsetzbare Zeile"| S
    L -->|"Löschen …"| LM["SPIELSTÄNDE<br/>Löschmodus"]
    LM -->|"Zeile"| R["LÖSCHEN?"]
    R -->|"Spiel N löschen"| L
    R -->|"Abbrechen, Esc"| L
    LM -->|"Zurück, Esc"| L
    G -->|"Zurück, Esc"| H
    L -->|"Zurück, Esc"| H
```

Esc führt eine Ebene zurück, im Hauptmenü tut es nichts. Zurück im Hauptmenü steht die Auswahl
auf dem Eintrag, der die Seite geöffnet hat. Ein Seitenwechsel bewegt den Communicator nicht.

**Spielstart:** Erst legt `GameSession` das Spiel an oder setzt es fort. Klappt das, sperrt
`_leaving` jede weitere Eingabe, der Communicator fährt hinaus, und erst `slide_finished(false)`
wechselt zum Spielbildschirm. Scheitert es, fährt nichts.

## Hauptmenü

Die Einträge entstehen aus den Spielständen im Ordner, bei jedem Erscheinen frisch gelesen:

| Eintrag | verfügbar | Wirkung |
|---|---|---|
| Weiterspielen | wenn ein Spielstand fortsetzbar ist | setzt den zuletzt gespielten fort; Hinweis „Weiter mit Spiel 2, Schwer, am 14.03.1986.“ |
| Neues Spiel | immer | öffnet die Gradwahl; „Einen neuen Laden aufmachen. Los geht es am 01.01.1985.“ |
| Spiel laden | wenn es irgendeinen Spielstand gibt, auch beschädigt | öffnet die Liste |
| Einstellungen | nein | „Noch nichts einzustellen. Kommt später.“ |
| Beenden | immer | schließt sofort, ohne Rückfrage und ohne Fahrt hinaus, auch während der Fahrt herein |

Vorgewählt ist „Weiterspielen“, wenn es verfügbar ist, sonst „Neues Spiel“. Nicht verfügbare
Einträge nennen im Hinweis den Grund, etwa „Noch kein Spiel angefangen.“

## Gradwahl

Leicht, Mittel, Schwer und Zurück, vorgewählt bei jedem Öffnen Mittel. Die Hinweise sagen ehrlich,
was ein Grad tut: „Das Glück ist eher auf deiner Seite.“, „Das Glück hält sich raus.“, „Das Glück
ist eher auf der Seite der anderen.“ Ein Grad startet das Spiel und wechselt zum Spielbildschirm.
Scheitert das Anlegen, steht die Meldung an der Zeile, und die Gradwahl bleibt.

## Liste der Spielstände

Je Spielstand eine Zeile mit vier Spalten: Name, Grad, Spieldatum, zuletzt gespielt. Bei einem
nicht fortsetzbaren steht statt Grad und Spieldatum „beschädigt“ oder „neuere Version“. Darunter
immer „Löschen …“ und „Zurück“. Reihenfolge wie in [spielstaende.md](spielstaende.md).

- Höchstens fünf Spielstände sind zu sehen. Die Liste rollt immer um ganze Zeilen; Rollmarken
  zeigen, dass es oben oder unten weitergeht. Sie liest den Ordner bei jedem Öffnen neu.
- Hinweis einer Zeile: „Steht am 14.03.1986. Gespielt am 26.10.2026, 21:40 Uhr.“, bei einem nicht
  fortsetzbaren der Grund.
- Eine fortsetzbare Zeile auslösen setzt fort. Eine nicht fortsetzbare lässt sich wählen, löst
  aber nichts aus.
- **Löschmodus:** „Löschen …“ schaltet ihn ein, die Kopfzeile heißt dann „WELCHES LÖSCHEN?“. Die
  dann ausgelöste Zeile führt zur Rückfrage. „Zurück“ und Esc beenden nur den Modus.

## Rückfrage

Seite „LÖSCHEN?“ mit „Abbrechen“ (vorgewählt) und „Spiel 2 löschen“. Die Hinweise nennen Name,
Grad und Spieldatum, etwa „Spiel 2 ist danach weg: Schwer, 14.03.1986. Für immer.“ Nach dem Löschen
zeigt die Liste die Zeile, die an die Stelle rückt; ist keiner mehr da, das Hauptmenü auf „Neues
Spiel“. Scheitert das Löschen, steht „Löschen ging nicht. Der Spielstand ist noch da.“ an seiner
Zeile.

## Bedienung

Die Auswahl ist Godots Fokus: Gewählt ist die Zeile, deren Button den Fokus hat. So gibt es genau
eine Auswahl, egal ob Maus oder Tastatur sie ändert.

| Eingabe | Wirkung |
|---|---|
| Maus über einer Zeile, Rechtsklick | wählt die Zeile, zeigt ihren Hinweis; Rechtsklick löst nie aus |
| Pfeil runter, Tab / Pfeil hoch, Shift+Tab | nächste / vorige Zeile, am Ende geht es am anderen Ende weiter |
| Mausrad | rollt die Liste der Spielstände |
| Enter, Leertaste, Linksklick | löst die gewählte Zeile aus, wenn sie verfügbar ist, sonst nichts |
| Esc | eine Ebene zurück |
| Maus verlässt die Seite | Auswahl und Hinweis bleiben |

Nicht verfügbare Einträge stehen in `gehaeuse-dunkel`, lassen sich aber wählen und zeigen ihren
Hinweis. Der Mauszeiger ist eine Hand nur, wo ein Klick etwas tut.

**Signale:** `MainMenu.entry_activated(id)` nur für verfügbare Einträge,
`selection_changed(entry, row_rect)` bei jedem Wechsel. `SaveList` meldet `resume_requested(slot)`,
`delete_requested(slot)`, `back_requested` und `selection_changed(hint, row_rect)`.

**Hinweis (`MenuHint`):** gehört zum Communicator; der Titel ruft `Communicator.show_hint()`,
`show_warning()` und `hide_hint()`. Er erscheint sofort, für Maus und Tastatur gleich, links neben
dem Gehäuse, oben bündig mit der Zeile, die rechte Kante bei x 240, also 4 vor dem Gehäuse,
höchstens 160 breit, mit Umbruch. Er fährt mit dem Gerät. Godots Tooltip passt nicht, er erscheint
nur für die Maus und mit Verzögerung. Mit `show_warning()` wird er zur Meldung (Theme-Variante
`WarningPanel`); sie bleibt, bis etwas anderes gewählt oder ausgelöst wird. Alle Hinweise und
Meldungen passen in höchstens zwei Zeilen, das prüft `test_title_texts.gd`.

## Versionszeile

Oben rechts im Himmel des Titelbilds, rechtsbündig, 16 vom Rand, mit `pixelschatten`.
`"V%s · %s" % [version, "PROTOTYP"]`. Die Nummer kommt aus `application/config/version` in
`project.godot` (heute `0.1`) und wird nur dort gepflegt. Ist sie leer, steht nur „PROTOTYP“ da.

## Für Tests

`scene_callback` und `quit_callback` ersetzen den Szenenwechsel und `get_tree().quit()`; ungültig
heißt der echte Aufruf. Tests stellen `Communicator.animate` auf `false` oder takten die Fahrt Bild
für Bild. Sie prüfen auch, dass Logo, Untertitel und Versionszeile weder Gehäuse noch Anzeige noch
Hinweis überschneiden und zwischen Logoblock und Gehäuse mindestens `raster-8` frei bleibt, gemessen
am Kasten des Logoblocks.
