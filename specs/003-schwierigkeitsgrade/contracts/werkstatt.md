# Vertrag: Schwierigkeitsgrade in der Zeitleisten-Werkstatt

Technischer Vertrag zu [spec.md](../spec.md) (US2 bis US4, FR-015 bis FR-020), Entscheidungen in
[research.md](../research.md), R9 bis R15, Kern in [zeitleiste.md](zeitleiste.md). Er ergänzt
[werkstatt.md von Feature 002](../../002-zeitleisten-werkstatt/contracts/werkstatt.md); was dort
steht und hier nicht geändert wird, gilt weiter. Der Look folgt dem Abschnitt „Werkzeuge“ im
Style-Guide. Neue Bausteine braucht es nicht (R11). Braucht der Agent doch einen, etwa Farben für
die Grade, hält er an und fragt; der Baustein kommt dann zuerst in den Style-Guide (Verfassung,
Grundsatz IV; Review, CHK023).

## Dateien

```text
src/tools/werkstatt/
├── difficulty_panel.tscn / .gd       # neu: class_name DifficultyPanel, Reiter „Schwierigkeitsgrade“
├── werkstatt.tscn / werkstatt.gd     # geändert: vierter Reiter, Verdrahtung, Prüfmeldungen, Löschdialog
├── catalog_editor.gd                 # geändert: Start-Modifikatoren, Verweise, content_key(), Sicherung
├── event_form.gd                     # geändert: Zeile „Je Grad“
├── issues_panel.gd                   # geändert: „Profil Schwer“ in der Spalte „Ereignis“
├── simulator_panel.tscn / .gd        # geändert: Grad, Neubau beim Wechsel, Vergleich, Proben
├── statistics_panel.tscn / .gd       # geändert: Grad oder Vergleich aller drei
└── what_if_probe.gd                  # geändert: Grad

src/test/
├── test_difficulty_panel.gd          # neu
├── test_catalog_editor.gd            # geändert
├── test_event_form.gd                # geändert
├── test_simulator.gd                 # geändert
├── test_what_if_probe.gd             # geändert
├── test_statistics_panel.gd          # geändert
├── test_werkstatt_scene.gd           # geändert
├── test_large_catalog.gd             # geändert: Profile im Speicher
└── test_werkstatt_settings.gd        # geändert: der neue Teiler im Reiter
```

## Reiter und Verdrahtung

```text
Tabs (TabContainer)   „Prüfung“ (IssuesPanel), „Simulator“, „Statistik“, „Schwierigkeitsgrade“ (DifficultyPanel)
```

- Der neue Reiter kommt als viertes Kind in `%Tabs`. Seinen Titel setzt `werkstatt.gd` wie die
  übrigen über `get_tab_idx_from_control()`. Die Plätze der drei bisherigen Reiter bleiben.
- `_ready()` setzt `editor` auch beim `DifficultyPanel`.
- `catalog_changed` und `issues_changed` rufen dort `refresh()` auf.
- `selection_changed` setzt `DifficultyPanel.selected_event_id`.
- **Prüfmeldungen:** `_on_issue_activated(event_id, field)` wechselt bei einem Feld, das mit
  `profiles` beginnt, in den Reiter „Schwierigkeitsgrade“ und ruft
  `DifficultyPanel.focus_field(field)` auf. Die Auswahl des Ereignisses bleibt. Alle anderen
  Meldungen gehen wie bisher an das Formular.
- **Liste der Prüfung** (`IssuesPanel`): Bei einer Meldung zu einem Profil steht in der Spalte
  „Ereignis“ statt „–“ der Grad (FR-016; Review, CHK009). Entschieden wird nach dem zweiten
  Pfadteil des Felds, bis zum nächsten „[“ oder „.“ (Analyse, U4):
  - `leicht` ergibt „Profil Leicht“, `schwer` „Profil Schwer“;
  - alles andere ergibt „Profile“: `profiles` allein, `profiles.mittel`, ein unbekannter Grad wie
    `profiles.extrem` und auch `profiles.schwerr`.
- **Löschdialog** (`_on_delete_requested()`): Nach den Ereignissen, die darauf verweisen, nennt er
  die Start-Modifikatoren aus `editor.profile_references_to(id)` (FR-017):
  - mit beiden: „Darauf verweisen: „Zeitungsartikel“. In den Profilen: Schwer: Anspruchsvolle
    Kunden. Diese Verweise werden mit entfernt.“
  - nur mit Start-Modifikatoren: „In den Profilen verweisen darauf: Schwer: Anspruchsvolle Kunden.
    Diese Verweise werden mit entfernt.“ (Analyse, I3)

  Danach steht wie bisher „Rückgängig holt alles zurück.“
- **Speichern und Verlauf:** Speichern, Cmd+S, Cmd+Z, „ungespeichert“, die Zahlen in der Toolbar,
  die Rückfrage beim Schließen und die Sicherungskopie gelten für Profile ohne eigene Verdrahtung.
  Alles läuft über denselben `CatalogEditor` (FR-016, R10).
- **Teiler:** Die Werkstatt merkt sich die Lage des neuen Teilers im Reiter von selbst, denn
  `splits()` findet jeden `SplitContainer`. `test_werkstatt_settings.gd` zählt die Teiler einzeln
  auf; dort kommt `…/Tabs/DifficultyPanel/Split` ans Ende der Liste, und die Prüfung der
  Mindestgröße nimmt den neuen Reiter mit. Damit ändern sich dort zwei Zahlen: sieben statt sechs
  gespeicherte Teiler und elf statt acht geprüfte Bereiche (Analyse, B3).

## CatalogEditor

```gdscript
## Profile (FR-015 bis FR-017, R10). level ist LEICHT oder SCHWER, index die Stelle im Profil ab
## 0. Jede ändernde Methode ist genau eine Aktion im Verlauf, mit Namen wie „Neuer
## Start-Modifikator in Schwer“, „Wert von Schwer: reklamationswelle“ oder „Start-Modifikator
## Schwer: reklamationswelle löschen“.

## Legt einen Start-Modifikator mit den Vorgaben aus data-model.md am Ende des Profils an und gibt
## ihn zurück. Leeres event_id heißt: das erste Ereignis über Wahrscheinlichkeit nach Kennung.
## null ohne Aktion, wenn level kein Profil hat oder es kein Ereignis über Wahrscheinlichkeit gibt.
func add_start_modifier(level: Difficulty.Level, event_id: String = "") -> ChanceModifier
## Kopie direkt hinter dem Original, mit einer Kennung, die im Profil frei ist (_2, _3 …).
func duplicate_start_modifier(level: Difficulty.Level, index: int) -> ChanceModifier
func delete_start_modifier(level: Difficulty.Level, index: int) -> void
## field ist &"event_id", &"value", &"reason", &"from_day", &"to_day" oder &"id". Jeder Text und
## jede Zahl wird angenommen; was nicht passt, zeigt die Prüfung (V25 bis V31). Ein Wert, der dem
## alten gleicht, legt keine Aktion an.
func set_start_modifier_field(level: Difficulty.Level, index: int, field: StringName,
		value: Variant) -> void
## Je Start-Modifikator, der auf das Ereignis zeigt, ein Text „Schwer: Anspruchsvolle Kunden“,
## ohne Grund mit der Kennung; in der Reihenfolge Leicht, Schwer und der Stellen.
func profile_references_to(event_id: String) -> PackedStringArray
```

Geändert:
- `delete_event(id)` entfernt im selben Schritt die Start-Modifikatoren, die auf das Ereignis
  zeigen, wie Folgen und Bedingungen. Das gilt, wenn es die Kennung nur einmal gibt (FR-017).
- `rename_event(old_id, new_id)` zieht im selben Schritt deren `event_id` nach, still (R9).
- **Ganze Profile ersetzen** (R10): Jede ändernde Methode oben, dazu `delete_event()` und
  `rename_event()`, ersetzt jedes betroffene `DifficultyProfile` durch eine geänderte Kopie aus
  `duplicate_profile()`. Im Verlauf ist das der Schritt `[&"replace", altes_profil,
  neues_profil]`. `_run()` wählt dafür die Liste `catalog.profiles`, wie sie für Ereignisse
  `catalog.events` wählt. Schritte zum Einfügen oder Entfernen einzelner Start-Modifikatoren gibt
  es nicht, `_inverse()` bleibt, wie es ist. Ein Start-Modifikator wird nie an Ort und Stelle
  geändert.
- `content_key()` nimmt die Profile auf: Nach den Ereignissen folgt eine leere Zeile, dann je
  Profil sein Text aus `_text_of()`, gemerkt je Objekt wie bei Ereignissen. `_text_of()` ruft
  `to_dict()` auf, und `DifficultyProfile.to_dict()` gibt es dafür (zeitleiste.md; Analyse, U1).
  Weil eine Änderung ein neues Profil-Objekt bringt, merken Simulator und Statistik sie sicher
  (R10).
- **Lesemeldungen eines Profils** (R10; Analyse, U2): Ersetzt ein Schritt in `_run()` ein Profil,
  verwirft der Editor die Meldungen V22 aus `_read_issues`, deren Feld zu diesem Profil gehört:
  `profiles.<key>` und alles mit `profiles.<key>[` am Anfang, nach ganzen Pfadteilen. Das gilt
  auch beim Rückgängigmachen und Wiederholen, denn beide laufen durch `_run()`. Stellen können
  sich ab da verschieben, und eine gemerkte Stelle träfe den falschen Start-Modifikator.
  Rückgängig bringt die Meldungen nicht zurück, denn sie gelten der Datei; nach `open()`
  derselben Datei stehen sie wieder da. Meldungen zu anderen Profilen, zu Ereignissen und zum
  Abschnitt, etwa an `profiles.mittel`, bleiben bis zum Speichern, wie in Feature 002.
- Die Sicherungskopie baut ihr `"catalog"` aus `EventCatalog.to_dict()`, mit den Profilen, schon
  mit der Grundlage in Phase 1 (R17). `restore_backup()` liest sie über `from_json()` zurück.
- `new_catalog()` hat zwei leere Profile, denn `EventCatalog.new()` legt sie an.
- `set_event_kind()` lässt Start-Modifikatoren stehen; V26 zeigt sie (R10).

## DifficultyPanel

```gdscript
class_name DifficultyPanel extends VBoxContainer
var editor: CatalogEditor
## Das gewählte Ereignis der Werkstatt; „Neu“ nimmt es, wenn es über Wahrscheinlichkeit kommt.
var selected_event_id: String = ""
## Nach catalog_changed und issues_changed. Baut die Zeilen der Tabelle am Ende des Bilds neu wie
## die Liste (T076 von Feature 002), damit ein Klick die Zeile trifft, die er meint. Die Felder
## bleiben stehen; nur ihre Werte werden neu gesetzt, außer im Feld mit dem Fokus.
func refresh() -> void
## Zeigt einen Grad, ohne Aktion im Verlauf.
func show_difficulty(level: Difficulty.Level) -> void
func shown_difficulty() -> Difficulty.Level
func select_row(index: int) -> void
## Fokus auf das Feld einer Prüfmeldung, etwa „profiles.schwer[2].reason“: Grad und Zeile wählen,
## dann das Feld. Ohne Stelle, etwa bei „profiles.mittel“, nur den Grad, bei „profiles“ allein
## nichts weiter.
func focus_field(field: String) -> void
```

Aufbau:

```text
DifficultyPanel (VBoxContainer)
├── TopBar (HBoxContainer)          „Grad“ %DifficultyOption (Leicht, Mittel, Schwer; Vorgabe Leicht) · %CountLabel „3 Start-Modifikatoren“
├── %MittelNote (Label, MutedLabel, mit Umbruch) nur bei Mittel: „Mittel ist der Katalog ohne Start-Modifikatoren. Seine Chancen sind die Grundchancen der Ereignisse.“
└── %Split (HSplitContainer)        nicht bei Mittel
    ├── links (VBoxContainer)
    │   ├── %Table (Tree)           Ereignis, Wert, von, bis, Grund, Kennung; Zebra; Zeichen „!“ bzw. „?“ wie in der Liste der Ereignisse
    │   └── HBoxContainer           %NewButton „Neu“, %DuplicateButton „Duplizieren“, %DeleteButton „Löschen“
    └── %Fields (GridContainer, 2 Spalten)
            Ereignis   %EventOption
            Wert       %ValueEdit  „Prozentpunkte“
            Beginn     %FromEdit
            Ende       %ToEdit     Platzhalter „TT.MM.JJJJ, unbegrenzt 31.12.1999“
            Grund      %ReasonEdit
            Kennung    %IdEdit
            je Feld darunter ein Fehlerhinweis (ErrorLabel)
```

Tabelle und Felder stehen nebeneinander, weil der Reiter unter dem Zeitstrahl wenig Höhe hat. Bei
Klaus' Fenstergröße 1920 × 925 zeigt der Reiter in der Vorgabe-Teilung mindestens vier Zeilen der
Tabelle und alle Felder ohne Rollen (Review, CHK028). Der Agent belegt es im echten Fenster mit
einem Bildschirmfoto (`docs/ki_dev.md`). Fotografiert wird auf einer Kopie des echten Katalogs mit
mindestens vier Start-Modifikatoren in einem Profil, gestartet mit `-- --katalog <kopie>`; der
echte Katalog bleibt unberührt (Analyse, G10).

Verhalten:
- **Tabelle:**
  - „Wert“ steht in Prozentpunkten mit Vorzeichen und Komma, etwa „+5“ oder „-2,5“, mit dem
    einfachen Minus wie `TimelineRun._points()`. Das Feld „Wert“ zeigt ihn genauso, damit
    `EventForm.parse_percent()` die angezeigte Zahl wieder liest. Tage stehen als TT.MM.JJJJ.
  - „Ereignis“ nennt den Titel, bei einem unbekannten Ziel die Kennung mit „(unbekannt)“.
  - Ein Klick wählt die Zeile und füllt die Felder; ohne Auswahl sind sie gesperrt.
- **Ereignis:**
  - Zur Wahl stehen die Ereignisse über Wahrscheinlichkeit nach Titel. Die Auswahl richtet ihre
    Breite nicht nach dem längsten Eintrag (`fit_to_longest_item = false`) und kürzt lange Titel
    (`clip_text`); mit 250 Ereignissen in `catalog_500.json` bliebe sie sonst nicht im Feld
    (Analyse, U10).
  - Zeigt der Start-Modifikator auf ein unbekanntes oder anderes Ereignis, steht es als eigener
    Eintrag oben, etwa „konkurrent (unbekannt)“ oder „Weihnachtsgeschäft (fix, jährlich)“. So hat
    V25 bzw. V26 ein Feld.
- **Eingaben:**
  - Ein Feld übernimmt seinen Wert beim Verlassen oder mit Enter, Enter gibt den Fokus ab (R15 von
    Feature 002). Solange ein Feld den Fokus hat, gehört Cmd+Z dem Feld, wie im Formular. Zeigt
    es noch den übernommenen Wert, schluckt das Panel die Taste in `gui_input`, sonst leerte sie
    das frisch gesetzte Feld (wie `EventForm`). Den Verlauf des Katalogs erreicht Cmd+Z nach Enter
    oder Verlassen (Analyse, U10).
  - Zahlen nehmen Komma oder Punkt und ein Vorzeichen an (`EventForm.parse_percent()`), Daten
    `TT.MM.JJJJ` auch ohne führende Nullen (`EventForm.parse_date()`).
  - Ist eine Eingabe ungültig, bleibt der alte Wert, und ein Hinweis am Feld sagt warum.
  - Grund und Kennung nehmen jeden Text an; die Prüfung zeigt, was nicht passt.
  - Wechselt Klaus Zeile oder Grad oder klickt er „Neu“, „Duplizieren“ oder „Löschen“, übernimmt
    das Feld mit dem Fokus vorher seine Eingabe, für die bisher gezeigte Zeile. So hält es das
    Formular mit `_commit_focused()` (T095 von Feature 002).
- **Fehler:**
  - Meldungen mit `profiles.<grad>[<i>].<feld>` setzen Kontur und Hinweis am Feld, wie im
    Formular (`ErrorLineEdit`, `ErrorOptionButton`; T081 von Feature 002).
  - Warnungen, also V31, zeigen den Hinweis am Feld in der Warnfarbe wie im Formular
    (`WarningLabel`), ohne Fehlerkontur.
  - Die Zeile bekommt ihr Zeichen, „!“ bei einem Fehler, sonst „?“ bei einer Warnung.
  - Strukturfehler ohne Feld, etwa `profiles.mittel`, stehen nur in der Prüfung.
- **„Neu“:** `add_start_modifier(level, selected_event_id)`, wenn das gewählte Ereignis über
  Wahrscheinlichkeit kommt, sonst mit leerem `event_id`. Danach ist die neue Zeile gewählt und der
  Fokus in „Wert“. Gibt es kein Ereignis über Wahrscheinlichkeit, ist „Neu“ gesperrt, mit dem
  Hinweis „Der Katalog hat kein Ereignis über Wahrscheinlichkeit.“
- **„Duplizieren“ und „Löschen“:** gesperrt ohne gewählte Zeile; „Löschen“ fragt nicht nach,
  Cmd+Z holt den Start-Modifikator zurück (R11).
- **Mittel:** Bei Mittel sind Tabelle, Knöpfe und Felder ausgeblendet, nur die Notiz steht da
  (FR-015).
- **Ohne Editor:** Solange `editor` fehlt, tut `refresh()` nichts. Die Werkstatt setzt ihn erst in
  ihrem `_ready()`, nach dem des Panels; das Simulator-Panel hält es genauso (Analyse, U10).

## EventForm

- Bei einem Ereignis über Wahrscheinlichkeit steht unter „Chance“ die Zeile „Je Grad“ mit drei
  Zeilen in `MutedLabel`, nur zum Lesen (R12):
  `„Leicht “ + DifficultyProfile.describe_periods(chance_periods(event, Leicht))`, ebenso Mittel
  und Schwer.
- Start-Modifikatoren mit einem Fehler zählen nicht: `faulty_indices(editor.issues(), level)`
  liefert die Stellen für `skip`.
- Der Hinweis beim Überfahren der Zeile: „Ändern im Reiter „Schwierigkeitsgrade““.
- Viele Zeitabschnitte haben keine Grenze; die Zeile eines Grads bricht dann um (Review, CHK032).
- Bei anderen Arten gibt es die Zeile nicht.
- Nach jeder Änderung am Katalog baut das Formular neu wie bisher, die Zeile ist also nach einer
  Änderung im Profil sofort aktuell.

## Simulator (SimulatorPanel)

```gdscript
## Der Grad in %DifficultyOption.
func selected_difficulty() -> Difficulty.Level
## Wie eine Wahl durch Klaus: Gibt es einen Lauf, baut der Simulator ihn mit dem neuen Grad neu
## (R13). Eine geladene Probe setzt den Grad ohne Neubau, denn sie baut ihren Lauf selbst.
func select_difficulty(level: Difficulty.Level) -> void
## Ob der Fahrplan mit Mittel ohne Eingriffe vergleicht statt mit demselben Grad ohne Eingriffe.
var compare_with_mittel: bool = false
```

- **Oben:** In `%RunBar` stehen hinter „Würfeln“ ein Text „Grad“ und `%DifficultyOption` mit
  Leicht, Mittel und Schwer, Vorgabe Mittel; dann „Fahrplan erzeugen“.
- **Fahrplan erzeugen** legt `TimelineRun.new(_effective_catalog(), seed, selected_difficulty())`
  an.
- **„Neu starten mit Eingriffen“ und „ohne“** behalten den Grad des Laufs. Vor
  `probe.build_run()` setzt `restart()` dafür `probe.difficulty = run.difficulty`, wie es schon
  `probe.seed` setzt; sonst bliebe dort der Grad einer früher geladenen Probe.
- **Wechsel des Grads** mit einem Lauf (R13):
  - Der Simulator legt eine eigene, kurzlebige `WhatIfProbe` an: `seed = run.seed`, der neue Grad,
    `interventions = run.interventions` (die angewandten), `until_day = run.today`. Ihr
    `build_run(_effective_catalog())` ergibt den neuen Lauf, mit dem aktuellen Katalog wie bei
    jedem Neustart; der Hinweis „Katalog geändert“ verschwindet danach (Review, CHK033).
  - Die gesammelten Eingriffe in `probe.interventions` bleiben unverändert; `probe.difficulty`
    bekommt den neuen Grad.
  - Was nicht anwendbar ist, etwa die Absage eines gewürfelten Termins, den es im neuen Grad
    nicht gibt, nennt `%ProbeNotice` wie nach „Neu starten mit Eingriffen“. Eingriffe, die schon im
    alten Lauf nicht anwendbar waren, versucht der Wechsel nicht neu (Review, CHK029).
  - Ohne Lauf merkt sich die Auswahl den Grad nur für „Fahrplan erzeugen“.
- **Stand:** `%DateLabel` bleibt, wie er ist, etwa „Stand: 01.01.1990 · Seed 4711“. Den Grad zeigt
  die Auswahl daneben; sie stimmt mit dem Lauf immer überein (R13).
- **Vergleich** (FR-018):
  - In der FilterBar stehen neben „nur Unterschiede“ das Häkchen `%CompareMittel` „mit Mittel
    vergleichen“ und der Text `%CompareLabel`: „Vergleich: Schwer ohne Eingriffe“ bzw.
    „Vergleich: Mittel ohne Eingriffe“.
  - `_update_diff()` legt den Vergleichslauf mit `run.seed` an, mit Mittel, wenn das Häkchen
    gesetzt ist, sonst mit `run.difficulty`, und spielt ihn bis `run.today`.
  - Gerechnet wird er, wenn `run.interventions` nicht leer ist, oder wenn das Häkchen gesetzt ist
    und der Grad nicht Mittel ist. Ein Wechsel des Häkchens rechnet ihn neu.
  - Gibt es keinen Vergleichslauf, heißt `%CompareLabel` „Kein Vergleich: Der Lauf hat keine
    Eingriffe.“ Bei Mittel mit Häkchen gilt der Vergleich mit demselben Grad und seine Texte
    (Analyse, A3).
  - Häkchen und Text machen die FilterBar nicht breiter, als sie bisher in der kleinen
    Fenstergröße aus `test_werkstatt_settings.gd` ist. `%CompareLabel` kürzt seinen Text dafür
    mit „…“ (`text_overrun_behavior`) und zeigt ihn beim Überfahren ganz. Der Agent belegt die
    Leiste mit Bildschirmfotos bei 1920 × 925 und in dieser kleinen Größe (Analyse, G10).
  - Umgesetzt in Phase 4 (2026-10-23): Die FilterBar ist ein `HFlowContainer`. In der kleinen
    Größe bricht sie in zwei Zeilen um statt breiter zu werden; bei 1920 × 925 bleibt sie einzeilig.
- **Texte der Markierungen:**
  - Beim Vergleich mit demselben Grad ohne Eingriffe bleiben `DIFF_TIPS`, der Hinweis an
    `%DiffFilter` und der Text „Unterschied: …“ wie in Feature 002, denn jeder Unterschied kommt
    dort von den Eingriffen. `test_simulator.gd` prüft sie unverändert weiter.
  - Beim Vergleich mit Mittel nennen sie den Vergleichslauf, in einer zweiten Reihe von Texten:
    - neu: „Neu gegenüber Mittel ohne Eingriffe; dort gibt es den Termin nicht.“
    - anderer Zustand: „In einem anderen Zustand als bei Mittel ohne Eingriffe.“
    - weggefallen: „Fällt gegenüber Mittel ohne Eingriffe weg; dort stünde der Termin hier.“
    - verschoben: wie bisher, „Ein Eingriff hat den Termin vom %s hierher verschoben.“
    - `%DiffFilter`: „Zeigt nur Termine, die anders sind als bei Mittel ohne Eingriffe.“
- **Protokoll:** Es zeigt die Zeilen „Grad“ ohne Zutun, über `to_line()`.
- **Modifikatoren:**
  - `_fill_modifiers()` zeigt zuerst `run.start_modifiers`, mit dem Grad vor dem Grund:
    „Schwer: Anspruchsvolle Kunden“. Eine eigene Farbe bekommen sie nicht, denn gedämpfter Text
    hält auf Zebra und Auswahl den Kontrast nicht (Analyse, U10). Danach kommen `run.modifiers`
    wie bisher.
  - Ist ein Start-Modifikator gewählt, ist „Entfernen“ gesperrt, mit dem Hinweis
    „Start-Modifikatoren gehören zum Grad und lassen sich im laufenden Spiel nicht entfernen;
    ändern lassen sie sich im Reiter „Schwierigkeitsgrade““ (Analyse, I4).
- **Chance:** `_chance_text()` zeigt die Ereignisse beider Listen. Gelten Start-Modifikatoren,
  nennt die Zeile ihren Anteil: „Reklamationswelle: Grundchance 3 %, Schwer +5, Summe 8 % → 8 %“.
- **Ausgenommen:** `%ExcludedNotice` nennt auch die Start-Modifikatoren aus
  `editor.catalog.skipped_start_modifiers(editor.issues())`, je mit dem Ort aus `place()`, etwa
  „Profil „Schwer“, Start-Modifikator „reklamationswelle““ (FR-013; Analyse, G1, I3).
- **Proben:**
  - `save_probe()` setzt `difficulty = run.difficulty`.
  - `load_probe()` setzt die Auswahl auf den Grad der Probe, ohne Neubau, und baut den Lauf mit
    `build_run()`.
  - Die Liste beim Laden bekommt die Spalte „Grad“ (`PROBE_TITLES`).

## WhatIfProbe

```gdscript
## Der Grad des Durchlaufs (FR-019, R14).
var difficulty: Difficulty.Level = Difficulty.DEFAULT
```

- `write_file()` schreibt zusätzlich `"difficulty": Difficulty.key(difficulty)`, immer, auch bei
  Mittel.
- `read_file()`: Fehlt der Schlüssel, gilt Mittel. Ist er kein Text oder ein unbekannter Grad,
  gibt es `null` und ein `push_error()`: „Die Probe <Pfad> nennt den Schwierigkeitsgrad „extrem“,
  den es nicht gibt.“
- `from_run()` übernimmt `run.difficulty`.
- `build_run()` legt `TimelineRun.new(catalog, seed, difficulty)` an.

## Statistik (StatisticsPanel)

- **Eingaben:** In `%InputBar` stehen hinter der Anzahl ein Text „Grad“ und `%DifficultyOption`:
  Leicht, Mittel, Schwer, „Alle drei vergleichen“. Vorgabe ist Mittel, die Statistik rechnet ohne
  Änderung also wie in Feature 002.
- **Starten:** `start()` legt
  `TimelineStatistics.new(_effective_catalog(), _game_count(), 1, difficulties)` an.
  `difficulties` ist immer ein `Array[int]`: `[gewählter Grad]` oder `[LEICHT, MITTEL, SCHWER]`
  (Analyse, I2). Das Häkchen „Mit
  Modifikatoren und Einplanungen aus dem Simulator“ gilt dann für alle drei Grade gleich
  (FR-020).
- **Texte:** `_result_text()` behält seine Sätze und nennt den Grad vor den Eingriffen, auch bei
  Mittel (R15):
  - fertig: „Ergebnis über 1.000 Spiele, Seeds 1 bis 1.000, Mittel, ohne Eingriffe; gerechnet in
    7,9 s.“;
  - abgebrochen: „Abgebrochen nach 450 von 1.000 Spielen. Das Ergebnis zeigt die 450 fertigen,
    Seeds 1 bis 450, Schwer, ohne Eingriffe.“;
  - beim Vergleich steht statt des Grads „Leicht, Mittel und Schwer“ und hinter „Spiele“ „je
    Grad“.

  Damit ändert sich die Erwartung in `test_statistics_panel.gd` an „Ergebnis über 200 Spiele,
  Seeds 1 bis 200, ohne Eingriffe“.
- **Ein Grad:** Die Tabelle bleibt, wie sie ist.
- **Vergleich:**
  - Die Tabelle hat zehn Spalten: „Ereignis“, „Ø Leicht“, „Ø Mittel“, „Ø Schwer“, „Spanne
    Leicht“, „Spanne Mittel“, „Spanne Schwer“, „ohne Leicht“, „ohne Mittel“, „ohne Schwer“.
  - „Spanne“ ist die kleinste bis größte Anzahl, etwa „0–14“; „ohne“ in Prozent.
  - Jede Spalte hat einen Hinweis beim Überfahren, etwa „Mittelwert bei Schwer: so oft beginnt das
    Ereignis im Schnitt je Spiel“.
  - Die Verteilung auf die Jahre zeigt nichts. Ihr Bereich bleibt mit seiner Mindesthöhe stehen,
    und `%YearTitle` sagt: „Die Verteilung auf die Jahre zeigt die Statistik für einen einzelnen
    Grad.“ (R15; Analyse, U10)
  - Der Fortschritt heißt „45 % · 450 von 1.000 Spielen je Grad · 11,3 s“; bei einem Grad bleibt
    er wie bisher.
  - Bei 1920 × 925 passen in der Vorgabe-Teilung alle zehn Spalten ohne waagerechtes Rollen
    (Review, CHK028). Der Agent belegt es mit einem Bildschirmfoto.
- **Katalog geändert:** Wie bisher, über `_catalog_key()`; mit `content_key()` zählt jetzt auch
  eine Änderung an Profilen.
- **Ausgenommen:** `%ExcludedNotice` nennt wie im Simulator die Start-Modifikatoren aus
  `skipped_start_modifiers()` (FR-013; Analyse, G1).

## Tests

| Datei | Prüft |
|---|---|
| `test_difficulty_panel.gd` | neu: Profile einer Fixture in der Tabelle; Mittel zeigt die Notiz; ohne `editor` kein Fehler; Cmd+Z im frisch gesetzten Feld leert es nicht, wie `test_cmd_z_im_feld_leert_es_nicht` im Formular; „Neu“ mit gewähltem und ohne passendes Ereignis, gesperrt ohne Ereignis über Wahrscheinlichkeit; Felder übernehmen mit Enter und beim Verlassen; ungültige Zahl behält den alten Wert mit Hinweis; „Duplizieren“ und „Löschen“; Zeichen und Kontur bei Fehlern, Hinweis ohne Kontur bei der Warnung V31; `focus_field()` mit Grad, Zeile und Feld; US2, Szenarien 1 bis 3 |
| `test_catalog_editor.gd` | geändert: siehe Liste unten |
| `test_event_form.gd` | geändert: Zeile „Je Grad“ für US2, Szenarien 6 und 7; keine Zeile bei anderen Arten; ein fehlerhafter Start-Modifikator zählt nicht; aktuell nach einer Änderung im Profil |
| `test_simulator.gd` | geändert: siehe Liste unten |
| `test_what_if_probe.gd` | geändert: Grad schreiben und lesen; ohne Schlüssel Mittel; unbekannter Grad ergibt `null` und Fehler; `build_run()` mit Grad; Start-Modifikatoren nie im Eingriffsprotokoll. Der Vergleich der ganzen Datei erwartet die Zeile `"difficulty": "mittel"` als ersten Schlüssel |
| `test_statistics_panel.gd` | geändert: vier Einträge in der Auswahl; Vergleich mit zehn Spalten und den Werten aus `results_for()`; Bereich der Verteilung mit Text; Abbrechen ergibt gleich viele Spiele je Grad; der Ergebnistext nennt den Grad, auch die bisherige Erwartung mit „Mittel“; „Katalog geändert“ nach einer Änderung an einem Profil (G4); `%ExcludedNotice` nennt einen fehlerhaften Start-Modifikator und einen, dessen Ereignis ausgenommen ist (G1) |
| `test_werkstatt_scene.gd` | geändert: vierter Reiter „Schwierigkeitsgrade“; eine Meldung mit Feld `profiles…` wechselt in den Reiter und setzt den Fokus; der Löschdialog nennt Start-Modifikatoren; die Prüfung zeigt „Profil Schwer“ in der Spalte „Ereignis“. Die Erwartungen an `%DateLabel` bleiben |
| `test_werkstatt_settings.gd` | geändert: `…/Tabs/DifficultyPanel/Split` am Ende der Liste der Teiler; sieben statt sechs gespeicherte Teiler; die Mindestgröße auch im neuen Reiter, elf statt acht geprüfte Bereiche (B3) |

`test_catalog_editor.gd` prüft dazu:
- Anlegen, Duplizieren, Löschen und Felder setzen, je ein Schritt mit Namen, rückgängig und
  wiederholbar; „ungespeichert“ nach jeder Änderung;
- SC-006: Wert ändern, speichern, und genau eine Zeile der Datei ist anders;
- `delete_event()` entfernt Start-Modifikatoren mit, und `profile_references_to()` nennt sie;
- Rückgängig nach `delete_event()`: In „Schwer“ zeigen zwei Start-Modifikatoren auf das
  gelöschte Ereignis, ein dritter dazwischen auf ein anderes. Cmd+Z stellt alle drei in ihrer
  Reihenfolge wieder her, und `to_json()` ist wie vorher;
- `rename_event()` zieht nach;
- jede Änderung ersetzt das Profil-Objekt; `content_key()` ändert sich mit dem Profil;
- Sicherungskopie mit Profilen, Rückholen bringt sie wieder;
- `new_catalog()` hat zwei leere Profile;
- eine Meldung V22 zu `profiles.mittel` bleibt bis zum Speichern stehen;
- die Vorgaben von „Neu“: das ganze Spiel, Wert 0, Grund leer, Kennung wie `reklamationswelle`
  und beim zweiten `reklamationswelle_2`; ohne Ereignis über Wahrscheinlichkeit `null` (G5);
- `duplicate_event()` lässt die Profile, wie sie sind; nach `set_event_kind()` stehen die
  Start-Modifikatoren noch da, und V26 meldet sie (G7);
- Lesemeldungen eines Profils, mit `catalog_v22_profil_wert_text.json`: Ein neuer
  Start-Modifikator in Leicht lässt die Meldung an `profiles.schwer[1].value` stehen. Das Löschen
  der Stelle 0 in Schwer verwirft sie, und `faulty_indices()` nennt danach keine Stelle; Cmd+Z
  bringt sie nicht zurück, `open()` derselben Datei schon (U2);
- die Fehlerprobe: Der Agent baut in einer Kopie Fehler ein, etwa einen `content_key()` ohne
  Profile oder ein Rückgängig in falscher Reihenfolge, und zeigt, dass die Tests sie finden.

`test_simulator.gd` prüft dazu:
- die Vorgabe Mittel; „Fahrplan erzeugen“ mit Schwer, im Protokoll die Zeilen „Grad“;
- US3, Szenario 1: Wechsel auf Schwer mit demselben Seed und Tag, angewandte Eingriffe bleiben
  angewandt, ein Lauf ohne Eingriffe bleibt ohne;
- Szenario 2: Start-Modifikatoren im Protokoll von Eingriffen unterscheidbar;
- Szenarien 3 und 4: Probe mit Schwer speichern und laden, Probe ohne Grad gilt als Mittel;
- Szenario 5: Schwer ohne Eingriffe mit Häkchen markiert nur Termine der veränderten Ereignisse
  und ihrer Abhängigen;
- Szenario 6: mit Eingriff und ohne Häkchen markiert nur die Wirkung des Eingriffs, der Text
  nennt den Vergleichslauf;
- Mittel mit Häkchen ändert keine Markierung;
- beim Vergleich mit demselben Grad bleiben die Texte der Markierungen wie in Feature 002;
- „Neu starten mit Eingriffen“ nach dem Laden einer Probe mit Schwer und „Fahrplan erzeugen“
  mit Leicht bleibt bei Leicht;
- Start-Modifikatoren in der Liste, „Entfernen“ gesperrt;
- die Liste der Proben mit fünf Spalten, die bisherige Erwartung bekommt „Mittel“ (B2);
- `%ExcludedNotice` nennt einen fehlerhaften Start-Modifikator und einen, dessen Ereignis
  ausgenommen ist (G1);
- „Katalog geändert, neu starten“ nach einer Änderung an einem Profil; ein Wechsel des Grads
  danach nimmt den aktuellen Katalog (G4);
- `%CompareLabel` ohne Vergleichslauf „Kein Vergleich: Der Lauf hat keine Eingriffe.“ (A3).

Die Tests nutzen `catalog_us1_grade.json` (zeitleiste.md, „Fixtures“).

`test_large_catalog.gd` muss grün bleiben: Prüfung und Änderung samt Prüfung mit 500 Ereignissen
unter 100 ms (SC-011 von Feature 002). Ein neuer Test fügt `catalog_500.json` im Speicher 20
Start-Modifikatoren je Profil hinzu; auch dann bleiben Prüfung und eine Änderung über
`set_start_modifier_field()` samt Prüfung unter 100 ms (Analyse, G9). Die Fixture bekommt in
Phase 1 nur den leeren Abschnitt (zeitleiste.md).
