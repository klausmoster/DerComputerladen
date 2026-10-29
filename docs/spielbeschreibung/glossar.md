# Glossar

- **Worum es geht:** die Begriffe des Spiels und der Doku und wie sie im Code heißen.
- **Laden, wenn:** ein Begriff unklar ist oder Spec, Doku und Code gegeneinander übersetzt
  werden.
- **Stand:** Feature 007, 2026-10-28

Doku und Oberfläche sind deutsch, der Code englisch. Werte in Dateien sind deutsch, wo sie
Spielinhalt sind (`"preis"`, `"leicht"`), sonst englisch (`"fixed"`, `"once"`).

| Begriff | Im Code | Bedeutung | Mehr in |
|---|---|---|---|
| Abnehmer | — | System, das sich an Signale der Zeitleiste hängt, später etwa Wirtschaft | [zeitleiste.md](zeitleiste.md) |
| Ablauf (Selbsttest) | `SelbsttestAblauf`, Skripte in `src/tools/selbsttest/ablaeufe/` | feste Folge von Schritten durch das Spiel, etwa `neues_spiel`; kann auf einem anderen aufbauen (`baut_auf`) | [selbsttest.md](selbsttest.md) |
| Art (eines Ereignisses) | `TimelineEvent.Kind` | fix, fix jährlich, beim Start gesetzt, über Wahrscheinlichkeit, nur als Folge | [zeitleiste.md](zeitleiste.md) |
| Anzeige | `Communicator.display_rect`, `Display` | die LCD-Fläche des Communicators in `lcd`, 320 × 160; darauf stehen die Seiten | [communicator.md](communicator.md) |
| Ausnehmen | `without_faulty()` | Fehlerhaftes aus einer Kopie des Katalogs entfernen, bevor gerechnet wird | [ereigniskatalog.md](ereigniskatalog.md) |
| Bedingung | `EventCondition` | „X ist schon / noch nicht eingetreten“ als Voraussetzung eines Termins | [zeitleiste.md](zeitleiste.md) |
| Bildpixel | — | ein Pixel des Bildrasters, gezeigt als 2 × 2 Oberflächenpixel; auch Maß des versteckten Spiels | [darstellung.md](darstellung.md) |
| Bildraster | — | 320 × 180, Raster der Szenen und Bilder | [darstellung.md](darstellung.md) |
| Blatt | `MainMenu`, `SaveList` mit `look = PAPER` | Seite als Endlospapier; bis Feature 004 der Look des Titels, heute auf keinem Bildschirm | [communicator.md](communicator.md) |
| Communicator | `Communicator`, `src/ui/communicator/` | Baustein: Taschengerät, das von unten ins Bild fährt und auf seiner Anzeige Seiten zeigt | [communicator.md](communicator.md) |
| Chance, Grundchance | `monthly_chance` | Wahrscheinlichkeit pro Monat aus dem Katalog | [zeitleiste.md](zeitleiste.md) |
| Chance, wirksame | `chance_info()["effective"]` | Grundchance plus Modifikatoren, begrenzt auf 0–1 | [zeitleiste.md](zeitleiste.md) |
| Easter Egg | `KeySequence`, `InvadersPage` | verstecktes Spiel oder Ding, das nur durch Ausprobieren zu finden ist; bisher das versteckte Spiel auf der Anzeige | [easter-egg.md](easter-egg.md) |
| Effekte (Kanal) | Bus `Effekte` in `default_bus_layout.tres` | Tonkanal für jeden Ton des Spiels, −10 dB, mündet in `Master` | [ton.md](ton.md) |
| Endlage | Lage des Communicators in der Szene | wo der Communicator nach der Fahrt herein steht; im Titel (244, 92) | [communicator.md](communicator.md) |
| Eingriff | `add_modifier()`, `cancel_entry()`, `move_entry()`, `schedule_event()` | Änderung am laufenden Spiel von außen, mit Grund | [zeitleiste.md](zeitleiste.md) |
| Eingriffsprotokoll | `TimelineRun.interventions` | alle angenommenen Eingriffe mit Tag, zum Nachspielen | [zeitleiste.md](zeitleiste.md) |
| Ereignis | `TimelineEvent` | was passieren kann, Eintrag im Katalog | [zeitleiste.md](zeitleiste.md) |
| Ereigniskatalog, Katalog | `EventCatalog`, `event_catalog.json` | alle Ereignisse, Kategorien und Profile | [ereigniskatalog.md](ereigniskatalog.md) |
| Ergebnisanzeige | `InvadersPage._draw_result()`, `TitleTexts.INVADERS_*` | drei Zeilen auf der Anzeige am Ende des versteckten Spiels; keine Meldung | [easter-egg.md](easter-egg.md) |
| Fahrer | `SelbsttestFahrer` | findet im Selbsttest Ziele über ihre Bedeutung, liest den Zustand und schickt Eingaben; einzige Stelle, die Titel und Spielbildschirm kennt | [selbsttest.md](selbsttest.md) |
| Fahrplan | `TimelineRun.entries` | alle Termine eines Spiels, zugleich seine Geschichte | [zeitleiste.md](zeitleiste.md) |
| Fahrt | `slide_in()`, `slide_out()`, `slide_finished` | Bewegung des Communicators herein oder hinaus, 200 ms | [communicator.md](communicator.md) |
| Feature-Tag | `custom_features` im Preset, `OS.has_feature()`, Override `einstellung.tag` in `project.godot` | Kennzeichen einer gebauten App; heute nur `selbsttest`, der Name und Hauptszene ersetzt | [selbsttest.md](selbsttest.md) |
| Folgeereignis | `FollowUp` | Ereignis, das mit einer Wahrscheinlichkeit nach einem anderen kommt | [zeitleiste.md](zeitleiste.md) |
| Folge (Gehäusetasten) | `KeySequence`, `TitleScreen.EASTER_EGG_KEYS` | Reihenfolge von Gehäusetasten, die etwas startet; im Titel links, Mitte, rechts | [titel-und-hauptmenue.md](titel-und-hauptmenue.md) |
| Fortsetzen | `GameSession.resume()`, `Timeline.resume_game()` | ein gespeichertes Spiel neu aufbauen und still bis zum Spieldatum vorspielen | [spielablauf.md](spielablauf.md) |
| Gehäuse | `Case`, `organizer_1991.png` | Bild des Communicators, heute G-03 | [communicator.md](communicator.md) |
| Gehäusetaste | `Communicator.case_keys`, `CaseKey`, `case_key_pressed` | drückbare Taste im Gehäusebild; zählt beim Loslassen über ihr; im Titel die drei grauen Tasten | [communicator.md](communicator.md) |
| Grad, Schwierigkeitsgrad | `Difficulty.Level` | Leicht, Mittel, Schwer | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Herkunft | `ScheduleEntry.Origin` | warum ein Termin im Fahrplan steht | [zeitleiste.md](zeitleiste.md) |
| Kategorie | `EventCategory` | Gruppe von Ereignissen mit Farbe, eine Zeile im Zeitstrahl | [ereigniskatalog.md](ereigniskatalog.md) |
| Kettenbremse | `TimelineRun.MAX_CHAIN` | höchstens 16 Glieder einer Folgekette am selben Tag, der Auslöser mitgezählt | [zeitleiste.md](zeitleiste.md) |
| Knopf | `Knopf`, `src/ui/knopf.gd` | Baustein Knopf aus dem Style-Guide | [darstellung.md](darstellung.md) |
| Lauf | `TimelineRun` | ein Spiel der Zeitleiste aus Katalog, Seed und Grad | [zeitleiste.md](zeitleiste.md) |
| Lauf (Selbsttest) | `SelbsttestLauf`, Kennung wie `2026-10-28_14-03-12` | ein Durchgang der Selbsttest-App vom Start bis zur Zusammenfassung, mit Ergebnis je Schritt | [selbsttest.md](selbsttest.md) |
| Läufer | `SelbsttestLaeufer` | Node an der Wurzel, der die Abläufe nacheinander durchspielt, wartet, fotografiert und das Ergebnis schreibt | [selbsttest.md](selbsttest.md) |
| Laufendes Spiel | `GameSession.current` | das Spiel, das gerade gespielt wird; auf dem Titelbildschirm keins | [spielablauf.md](spielablauf.md) |
| Look | `MainMenu.Look`, `SaveList.Look` | ob eine Seite als Papier oder auf der Anzeige erscheint | [communicator.md](communicator.md) |
| Löschmodus | `SaveList.set_delete_mode()` | Zustand der Liste, in dem eine Zeile zur Rückfrage „Löschen?“ führt | [titel-und-hauptmenue.md](titel-und-hauptmenue.md) |
| Meldung | `TimelineMessage` | was an einem Tag geschah; wird im Spiel zum Signal | [zeitleiste.md](zeitleiste.md) |
| Meldung (Oberfläche) | `MenuHint.show_warning()`, Variante `WarningPanel` | Hinweis mit roter Kontur, wenn etwas scheiterte, etwa das Speichern | [spielablauf.md](spielablauf.md) |
| Modifikator | `ChanceModifier` | verschiebt die Chance eines Ereignisses in einem Zeitraum um Prozentpunkte | [zeitleiste.md](zeitleiste.md) |
| Oberflächenraster | — | 640 × 360, Raster der Bedienung | [darstellung.md](darstellung.md) |
| Probe | `WhatIfProbe` | gespeicherte Was-wäre-wenn-Rechnung des Simulators: Seed, Grad, Eingriffe | [werkstatt.md](werkstatt.md) |
| Profil | `DifficultyProfile` | Liste der Start-Modifikatoren eines Grads | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Protokoll | `TimelineRun.protocol` | alle Meldungen eines Laufs | [zeitleiste.md](zeitleiste.md) |
| Prüfmeldung | `CatalogIssue` | Fehler oder Warnung zu einer Regel V01–V31 | [ereigniskatalog.md](ereigniskatalog.md) |
| Renderer | `rendering/renderer/rendering_method` in `project.godot`, zur Laufzeit `RenderingServer.get_current_rendering_method()` | der Teil von Godot, der das Bild malt; heute Compatibility (`gl_compatibility`) auf allen drei Systemen, bis 2026-10-29 Forward+ | [darstellung.md](darstellung.md) |
| Referenzbild | `tools/selbsttest/referenz/macos/<kennung>.png` | Foto eines Schritts von einem abgenommenen Mac-Lauf; `vergleich.py` vergleicht jeden Lauf Pixel für Pixel damit | [selbsttest.md](selbsttest.md) |
| Schritt (Selbsttest) | Dictionary aus `SelbsttestAblauf.neuer_schritt()`, Kennung `<ablauf>.<nn_kurz>` | Eingaben, erwarteter Zustand, Foto; Ergebnis `OK`, `FEHLER` oder `NICHT_GELAUFEN` | [selbsttest.md](selbsttest.md) |
| Seed | `TimelineRun.seed` | Zahl 0–2.147.483.647, aus der alle Zufallsentscheidungen eines Spiels folgen | [zeitleiste.md](zeitleiste.md) |
| Seite | Control unter dem Communicator, etwa `MainMenu`, `SaveList` | was die Anzeige zeigt, immer genau eine: im Titel Hauptmenü, Gradwahl, Spielstände, Rückfrage, das versteckte Spiel | [titel-und-hauptmenue.md](titel-und-hauptmenue.md) |
| Selbsttest | Presets `Selbsttest …`, `src/tools/selbsttest/` | eigene App, die das gebaute Spiel auf dem echten Rechner von selbst durchspielt und ein Protokoll mit Fotos schreibt | [selbsttest.md](selbsttest.md) |
| Spielbildschirm | `scenes/game/game_screen.tscn` | Ziel nach Beginnen oder Fortsetzen; heute nur „Zum Hauptmenü“ | [spielablauf.md](spielablauf.md) |
| Spiel, verstecktes | `InvadersGame`, `InvadersPage` | das Easter Egg im Titel: ein Spiel auf der Anzeige des Communicators | [easter-egg.md](easter-egg.md) |
| Spieldatum | `SaveGame.day` | Tag, an dem ein Spielstand steht | [spielstaende.md](spielstaende.md) |
| Spielstand | `SaveGame`, `spiel_<N>.json` | gespeichertes Spiel: Seed, Grad, Katalogkopie, Eingriffe, Spieldatum | [spielstaende.md](spielstaende.md) |
| Spielstand, Eintrag der Liste | `SaveSlot` | ein Spielstand mit Zustand fortsetzbar, beschädigt oder neuere Version | [spielstaende.md](spielstaende.md) |
| Spieluhr | `GameClock` | treibt die Spielzeit voran | [spielzeit.md](spielzeit.md) |
| Start-Modifikator | `ChanceModifier` im Profil, `TimelineRun.start_modifiers` | Modifikator, den ein Grad beim Spielstart setzt | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Stichtag | — | Tag, an dem der Lauf etwas zu tun hat; dazwischen springt er | [zeitleiste.md](zeitleiste.md) |
| Style-Guide | `docs/style-guide/`, `UiPalette` | verbindliche Quelle für Look und Sprache | [darstellung.md](darstellung.md) |
| Tagesindex | `int`, `GameDate.to_day_index()` | Tage seit 01.01.1985 (= 0), bis 5477 | [spielzeit.md](spielzeit.md) |
| Termin | `ScheduleEntry` | ein Vorkommen eines Ereignisses im Fahrplan | [zeitleiste.md](zeitleiste.md) |
| Textausgabe | `fahrplan_ausgabe.gd`, `ScheduleText` | Fahrplan oder Protokoll auf der Konsole | [werkstatt.md](werkstatt.md) |
| Token | `StringName` wie `&"petrol"` | Name einer Farbe aus dem Style-Guide | [darstellung.md](darstellung.md) |
| Unterschiede | `ScheduleDiff` | Vergleich zweier Läufe | [werkstatt.md](werkstatt.md) |
| Weiterspielen | Eintrag `continue` im Hauptmenü | setzt den zuletzt gespielten Spielstand fort | [titel-und-hauptmenue.md](titel-und-hauptmenue.md) |
| Werkstatt | `Werkstatt`, `src/tools/werkstatt/` | Entwicklungswerkzeug für Katalog, Simulator, Statistik | [werkstatt.md](werkstatt.md) |
| Wirkung | `EventEffect` | was ein Ereignis meldet: Preis, Nachfrage, Ruf, Kundenstrom, Presse | [zeitleiste.md](zeitleiste.md) |
| Würfel | `EventDice` | eigener Zufallsgenerator je Zweck und Ereignis | [zeitleiste.md](zeitleiste.md) |
| Würfelrunde | `_roll_month()` | am Monatsersten würfeln alle Ereignisse über Wahrscheinlichkeit | [zeitleiste.md](zeitleiste.md) |
| Zeitraffer | `Engine.time_scale`, `SelbsttestAblauf.zeitraffer` | im Selbsttest läuft die Zeit im Spiel achtfach, außer in `fenster` und `titel_echtzeit` | [selbsttest.md](selbsttest.md) |
| Zeitstrahl | `TimelineView` | grafische Ansicht des Katalogs in der Werkstatt | [werkstatt.md](werkstatt.md) |
| Zustand | `ScheduleEntry.State` | geplant, läuft, eingetreten, beendet, entfallen, abgesagt | [zeitleiste.md](zeitleiste.md) |
| Zwischendatei | `spiel_<N>.json.neu`, `.alt` | Datei beim sicheren Schreiben; gilt nach einem Abbruch | [spielstaende.md](spielstaende.md) |
