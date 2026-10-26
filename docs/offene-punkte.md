# Offene Punkte

Hier steht, was Klaus noch entscheiden oder bestätigen muss (`docs/ki_workflow/ki_dev.md`,
„Entscheidungen nicht stillschweigend treffen“):
- **Offen:** Fragen, die Klaus entscheidet, und Lücken oder Widersprüche in den Dokumenten.
- **Eigene Entscheidungen von Claude:** Festlegungen, die nicht aus den Dokumenten folgten. Sie
  sind umgesetzt, aber noch nicht von Klaus bestätigt.

Jeder Punkt hat Datum, Herkunft und, wo es eine gibt, Claudes Empfehlung. Ist ein Punkt entschieden
oder bestätigt, wandert er nach „Erledigt“, mit Datum und Ergebnis. Die Entscheidung selbst steht
dann dort, wo sie hingehört, etwa in Spec, Verfassung oder `research.md`.

## Offen

### Spec Kit auf 1.2.3 heben (2026-10-26)

- **Nach dem Abschluss von Feature 004** (Klaus, 2026-10-26): Installiert ist 1.2.0, als Kommando
  `specify` und im Projekt (`.specify/init-options.json`). Aktuell ist 1.2.3 vom 2026-10-22; die
  drei Patch-Versionen bringen Fehlerbehebungen an Workflows, Erweiterungen und Presets. Vorher
  zeigt Claude Klaus, welche Dateien im Projekt sich ändern würden, etwa an einer Probe in einem
  leeren Ordner; erst nach seinem OK wird aktualisiert.

### Feature 004, Plan (2026-10-26)

- **Eigener Benutzerordner, später:** Spielstände liegen unter macOS in
  `~/Library/Application Support/Godot/app_userdata/Der Computerladen/`. Mit
  `application/config/use_custom_user_dir` lägen sie unter „Der Computerladen“ ohne „Godot“.
  Empfehlung: vor der ersten Veröffentlichung umstellen, nicht in Feature 004; heute zögen
  Einstellungen und Sicherungskopien der Werkstatt mit um.

### Phase 12 von Feature 002 (2026-10-21)

- **Vier Zeilen in den Tabellen (T101):** Mit der neuen Vorgabe zeigen Statistik mit Warnung und
  Fahrplan je 2 Zeilen statt 1, die Statistik ohne Warnung 5 statt 3. Für 4 Zeilen müsste der
  Zeitstrahl in der Vorgabe 48 px abgeben (378 statt 426 px). Empfehlung: die Vorgabe lassen. Den
  Teiler ziehst du einmal dorthin, wo er dir passt, und die Werkstatt merkt ihn sich (T091).

### Feature 003, Plan (2026-10-21)

- **Startwerte der Profile (R18):** Claudes Vorschlag für die sechs Ereignisse über
  Wahrscheinlichkeit steht in `specs/003-schwierigkeitsgrade/research.md`, R18. Klaus legt die
  Profile zur Abnahme von Phase 3 in der Werkstatt an und stellt sie mit der Statistik nach. Seit
  2026-10-22 steht fest, dass beide Profile zur Gesamtabnahme gefüllt sein müssen
  (Checkliste, CHK008). Offen sind nur noch die Werte. Stand 2026-10-23 (T020): Klaus hat je drei
  Start-Modifikatoren angelegt, alle auf „Großkunde meldet sich“, als vorläufige Werte (Leicht
  zusammen −2, Schwer +3). Er stellt sie später mit der Statistik ein, die mit Phase 5 die Grade
  vergleicht.

### Feature 003, Lückensuche (2026-10-26)

- **Mögliche Schieflage der Würfel (Feature 002, `EventDice`):** Über die Seeds 1 bis 4.000 liegt
  die Reklamationswelle mit 3 % pro Monat im Mittel bei 5,508 statt 5,4 und mit Schwer bei 14,579
  statt 14,4, beides etwa drei Standardabweichungen darüber. SC-003 ist trotzdem klar erfüllt.
  Empfehlung: später einmal die Würfel je Kennung prüfen; für Feature 003 nichts zu tun.

### KI-Workflow und Prüf-Agents (2026-10-22)

Aus dem Konzept, das in `docs/ki_workflow/ki_pruefung.md` aufgegangen ist. Jede Frage kommt
einzeln, wenn ihr Schritt dran ist (dort unter „Stand der Einführung“).
- **Gemeinsames `user://`:** Alle Arbeitsordner teilen sich `user://` von „Der
  Computerladen“, und die Tests schreiben in feste Unterordner wie `user://test_simulator/`. Zwei
  Testläufe zur selben Zeit, etwa im Worktree der Arbeitsweise und in der Sitzung „[003]
  Schwierigkeitsgrade ab dem Plan“, können sich stören. Ein Hook, der von selbst testet, macht das
  wahrscheinlicher.
- **Abnahme des Skills:** `/dcl-phasenpruefung` einmal in einer neuen Sitzung aufrufen, etwa als
  Probelauf am Titelbildschirm (Schritt 6).

### Probelauf des Stil-Prüfers an Feature 001 (2026-10-22)

Der Stil-Prüfer hat Titelbildschirm, Hauptmenü und Hinweis gegen den Style-Guide geprüft, Claude
hat jeden Befund nachgeprüft. Was davon repariert oder in den Style-Guide kommt, entscheidet Klaus,
in einem eigenen Schritt. Zahlen in `docs/ki_workflow/ki_pruefung.md`, „Nachmessen“.
- **Bestätigt:**
  - **Logo ohne `pixelschatten` (mittel):** Das Logo steht halb auf Himmel, halb auf der
    Fassade, also auf unruhigem Grund. Der Style-Guide verlangt dort `pixelschatten` (Logo). Das
    PNG hat keinen, die Szene auch nicht. Empfehlung: Schatten ergänzen, wie beim Hinweis.
  - **Ränder nicht aus dem Raster (mittel):** Logo bei x 14 und y 12, Menü 24 vom rechten Rand,
    Versionszeile 6 vom unteren. `raster-16` ist laut Style-Guide der „Rand zum Bildschirmrand im
    Titel“. Die Werte kommen aus dem Titelscreen-Entwurf und stehen so im Vertrag von Feature 001.
    Empfehlung: auf 16 ziehen; der Entwurf ist älter als die Raster-Regel.
  - **Textschatten von 1 px (niedrig):** Untertitel und Versionszeile haben einen harten Schatten
    in `tusche` um (1, 1). Er steht im Vertrag von Feature 001, im Style-Guide gibt es ihn nicht.
    Empfehlung: als Token in den Style-Guide, denn er hält die Schrift auf dem Bild lesbar.
- **Verworfen:** `papier`-Text auf dem Titelbild sei kein erlaubtes Farbpaar. Der Abschnitt Logo
  verlangt den Untertitel aber ausdrücklich in `papier`. Das ist eine Lücke, kein Fehler (unten).
- **Lücken im Style-Guide:**
  - **Text auf einem Vollbild:** Die Farbpaare kennen keinen Bildgrund. Ist `papier` auf dem
    Titelbild erlaubt, und mit welchem Schatten?
  - **Kontur am Menü:** „Alles Bedienbare“ hat eine `tusche`-Kontur und Relief, der Baustein Menü
    beschreibt Endlospapier ohne beides. Welche Regel gilt?
  - **Logo im Spiel:** Der Style-Guide nennt das Original mit 850 × 164, im Spiel steht die
    gerasterte Fassung mit 141 × 27 Bildpixeln. Wie groß darf das Logo erscheinen?
  - **Gelbe Zeile:** Nur der Innenbereich wird `signalgelb`, die Lochränder nicht. Der Baustein
    sagt nur „Die gewählte Zeile ist `signalgelb`“.
  - **Vollbild ohne SubViewport:** Für Szenen beschreibt der Style-Guide einen SubViewport mit
    320 × 180. Das Titelbild ist ein TextureRect mit 640 × 360, ganzzahlig doppelt. Reicht das für
    Vollbilder?
  - Verworfen: die Maße der Lochränder. Sie stehen im Baustein Bildrahmen, den Claude dem Prüfer
    nicht mitgegeben hatte, und der Code hält sie ein.

### Probelauf des Text-Prüfers an Feature 001 und der Werkstatt (2026-10-22)

Der Text-Prüfer hat rund 740 Texte und alle 27 Ereignisse des Katalogs gegen den Abschnitt
„Sprache“ und für die Werkstatt gegen „Werkzeuge“ geprüft, Claude hat jeden Befund im Code
nachgesehen. Feature 001: keine Befunde. Alles Weitere betrifft die Werkstatt, an der gerade die
Sitzung „[003] Schwierigkeitsgrade ab dem Plan“ arbeitet; repariert wird also erst nach Feature 003,
wenn Klaus es will.
- **Bestätigt:**
  - **Prozent ohne Leerzeichen (mittel):** Wirkungen stehen als „-30%“
    (`core/timeline/event_effect.gd:85`), verlangt ist „−30 %“ wie „3,5 %“ unter „Werkzeuge“.
  - **Datum als „02-30“ (mittel):** `core/timeline/catalog_validator.gd:165`; zwei Zeilen davor steht
    „29.02.“. Empfehlung: „30.02.“.
  - **Englische Fehlertexte der Engine (mittel):** `error_string()` und `json.get_error_message()`
    enden in deutschen Sätzen auf Englisch, etwa „… lässt sich nicht schreiben: Can't open.“ Sechs
    Stellen. Tritt nur bei Dateifehlern auf.
  - **Ein Feld, drei Namen (mittel):** „Chance“ im Formular, „Grundchance“ im Verlauf und in den
    Prüfregeln; beim Folgeereignis „Chance“ und „Wahrscheinlichkeit“.
  - **Einzahl fehlt (niedrig):** „dauert 1 Tage“, „nach 1 Tagen“, „Rechnet 1 Spiele“ sind möglich
    (Prüfregeln V19 und Nachbarn, Statistik).
  - **Würfel und Chance in verschiedenen Einheiten (niedrig):** „Würfel 0,4120 < 50 %“
    (`core/timeline/schedule_entry.gd:164`).
  - **Tastennamen englisch (niedrig):** „Ctrl+Shift+Z“ und „Enter“; deutsch wären „Strg“ und
    „Eingabetaste“. Die Schreibweise steht so im Vertrag von Feature 002 (R15); Klaus entscheidet.
  - **Beispiel ohne Vorzeichen (niedrig):** „+5, -6 oder 2,5“ in
    `tools/werkstatt/intervention_dialog.tscn:51`, obwohl der Satz Vorzeichen verlangt.
  - **Zwei Namen für Dauer 0 (niedrig):** „0 heißt Augenblick“ neben „ohne Dauer“
    (`tools/werkstatt/event_form.gd`).
  - **Grammatik im Katalog (niedrig):** „Preise müssen umgedacht werden“ (`euro_buchgeld`);
    Vorschlag „umgerechnet“. Den Katalog pflegt Klaus in der Werkstatt.
- **Verworfen:**
  - Seed ohne Tausenderpunkt: Der Seed ist eine Kennnummer, keine Menge (siehe Lücken).
  - Beispieldatum „1.3.1993“: Es zeigt bewusst, dass die kurze Eingabe geht.
  - „High-End“ im Katalog: ein Computerwort der Zeit, das der Abschnitt „Sprache“ erlaubt.
- **Lücken im Style-Guide:**
  - Gilt „ein Satz pro Meldung“ auch für Dialoge und Tooltips der Werkzeuge? Dort stehen bis zu vier
    Sätze, auch im Beispiel des Abschnitts „Werkzeuge“.
  - Witz in Beispielwerten der Werkzeuge, etwa „etwa Ware vom windigen Händler“?
  - Fachwörter im Werkzeug: Ist „Seed“ erlaubt, und schreibt man Kennnummern mit Tausenderpunkt?
  - Daten in Dateien und auf der Kommandozeile stehen als JJJJ-MM-TT; der Abschnitt regelt nur
    angezeigte Daten.
  - Minuszeichen: „-“ oder „−“? Im Code steht beides.
  - Kategorie „Tech“: ein Anglizismus, sobald sie im Spiel erscheint; deutsch wäre „Technik“.
  - Versionsnummer „V0.1“ mit Punkt statt Komma.
- **Unsicher:** die Mehrzahl „Beginne“ in der Statistik; „Vorkommen“ stünde schon im Kern.

### Ältere Punkte aus Claudes bisherigem lokalem Gedächtnis

- **Spielfenster ragt 6 Pixel in den Bereich des Docks** (Feature 002, Abnahme von Phase 4,
  2026-10-20): beobachtet, von Klaus noch nicht entschieden.
- **Systemmenüs von macOS sind englisch** (Feature 001): Es gibt kein `.lproj`. Ob sie deutsch
  werden, entscheidet Klaus später.
- **Spec Kit oder `/dcl-feature`** (Pilot seit 2026-10-19): Ob Spec Kit `/dcl-feature` dauerhaft
  ersetzt, entscheidet Klaus am Ergebnis des Piloten.
- **Nächstes Feature nach 002:** Empfehlung 02-01 und 02-02, Bible-Importer und Warengruppen.
- **Mac-App unter `build/macos`:** Sie stammt vom Probe-Export vor dem Fensterstart. Neu
  exportieren hat Claude angeboten.

## Eigene Entscheidungen von Claude

### Arbeitsweise (2026-10-21)

- **Lokales Gedächtnis aufgelöst:** Was dort stand, ist nach `docs/ki_dev.md` und hierher
  umgezogen. Danach hat Claude die Dateien im lokalen Memory-Verzeichnis gelöscht.


### Feature 002, Phase 11 (2026-10-21)

Auslegungen des Agents, die Claude angenommen hat. Sie stehen auch in Vertrag, Datenmodell und
Lernnotizen.
- **Statistik und Einträge ohne Tag (R1):** Die Statistik ordnet das ganze Eingriffsprotokoll,
  bevor sie aussucht. Ein Eintrag ohne lesbaren Tag gilt so wie im Simulator hinter seinem
  Vorgänger, auch wenn das eine Absage ist.
- **Tooltips (R2):** „Neu starten mit Eingriffen“ und „Probe speichern …“ sind zweizeilig statt
  rund 120 Zeichen in einer Zeile.
- **Meldungen (R3):** Ganze Zahlen stehen ohne „.0“ da, etwa „die Zahl 5“.
- **Klick in den Zeitstrahl (T077):** „Erst treffen, dann übernehmen“ gilt auch beim Linksklick.
  Gezogen wird nur, wenn an der Stelle nach dem Übernehmen noch dasselbe Ereignis steht.
- **Sicherungskopie (T078):**
  - Gleich behandelt werden `res://`, absolute und relative Pfade derselben Datei, nicht aber
    Verknüpfungen und Groß- und Kleinschreibung.
  - Eine fremde oder unlesbare Datei unter dem eigenen Namen wird nicht angeboten, und die nächste
    Sicherung ersetzt sie.
  - Der Hinweis bei einem Schreibfehler kommt einmal je Fehlerserie.
  - Eine alte Datei `user://werkstatt_sicherung.json` wird nicht übernommen; bei Klaus gibt es
    keine.
- **Fehlerkontur (T081):** auch an der Beschreibung (`ErrorTextEdit`), nicht am Knopf „+“ der
  Bedingungen, denn er ist kein Feld.
- **Abgelehnte Eingriffe (T082):** Die Warnung erscheint, sobald ein Spiel fertig ist. Absagen und
  Verschiebungen gelten weder als gezählt noch als abgelehnt, weil die Statistik sie nie anwendet.
- **Mehr als 20 Anzahlen (T086):** Das Formular zeigt die ersten 20 Gewichte, die Summe über alle
  und bei „bis“ den echten Wert.
- **Einstufung in T092:** Die fehlende Fehlerkontur an Feldern in Dialogen und die abgeschnittene
  Fokuslinie stehen als CRITICAL in Phase 12. Grundsatz IV der Verfassung verlangt, dass alles
  Sichtbare dem Style-Guide folgt, und `/speckit-converge` stuft jeden Verstoß dagegen als
  CRITICAL ein. Zu sehen ist beides nur als Kleinigkeit am Rand.

### Feature 002, Phase 12 (2026-10-21)

- **Tag 00 als V22 (T098):** Der Agent fragte, ob „05-00“ wie „00-00“ eine Meldung bekommt. Claude
  hat entschieden: ja, das Format kennt nur „MM-TT“, „MM-ende“ und „“, und 00 ist kein Tag.
- Auslegungen des Agents, die Claude angenommen hat:
  - **Kontur bei Ablehnung (T093):** Lehnt der Lauf einen Eingriff ab, bekommt das Feld die
    Kontur, das der Grund meint, etwa der Tag einer Einplanung. Gilt der Grund dem Termin selbst,
    etwa bei Windows 95, bekommt kein Feld eine Kontur.
  - **Reihenfolge im Verlauf (T095):** Beim Menü „…“ steht das Ziel im Verlauf vor dem Titel; Cmd+Z
    nimmt also zuerst den Titel zurück. Eine ungültige Eingabe in einem Ereignis, das Klaus gerade
    verlässt, fällt wie bisher ohne Hinweis weg.
  - **Begründung (T097):** Bei entfallenen und abgesagten Terminen sagt sie weiter „Verzögerte
    Wirkungen: entfallen mit dem Termin“.
  - **Monat 13 bis 99 (T098):** jetzt V22 statt V09; „13-ende“ fällt auf „ohne Dauer“ zurück,
    statt erhalten zu bleiben.
  - **Prüfung der Probe (T099):** Wert und Beginn eines Modifikators werden vor Ereignis, Kennung
    und Grund geprüft. Auch ein negativer Seed ist ein Lesefehler.
  - **Mindesthöhe (T101):** Die 80 px, die T091 jedem Bereich zusichert, bleiben.

### Feature 003, Klärung der Spec (2026-10-21)

- **Chance je Zeitabschnitt (FR-015):** Gilt ein Start-Modifikator nur für einen Teil des Spiels,
  nennt die Anzeige im Ereignisformular die Chance je Abschnitt, etwa „Schwer 3 % bis 31.12.1994,
  6 % ab 01.01.1995“. Das folgt aus zwei Antworten von Klaus, Zeitraum und Anzeige nur zum Lesen;
  die Form hat Claude gewählt.

### Feature 003, Plan (2026-10-21)

Festlegungen, die nicht aus den Dokumenten folgten. Einzelheiten und verworfene Alternativen
stehen in `specs/003-schwierigkeitsgrade/research.md`.
- **Aufbau des Abschnitts (R2):** Die Katalogdatei hat den Abschnitt `"profiles"` mit `"leicht"`
  und `"schwer"`. Ein Start-Modifikator hat dieselben Schlüssel wie ein Modifikator in einer
  Probe. Die Listen behalten ihre Reihenfolge und werden nicht sortiert.
- **Formatnummer (R3):** Sie bleibt 1, Dateien aus Feature 002 laden weiter.
- **Profil für Mittel oder einen unbekannten Grad (R4):** ein Strukturfehler V22, wie jeder
  unbekannte Schlüssel.
- **Kennungen (R5):** Start-Modifikatoren und Eingriffe stehen im Lauf in zwei Listen, die
  Kennungen sind je Liste eindeutig. Eine Vorsilbe in der Kennung braucht es nicht.
- **V30 (R8):** Die Regel prüft auch eine leere Kennung und falsche Zeichen, über FR-012 hinaus.
- **Ganze Profile im Verlauf (R10):** Jede Änderung an einem Start-Modifikator ersetzt in der
  Werkstatt das ganze Profil durch eine Kopie. So stimmt Rückgängig auch, wenn ein Löschen zwei
  Start-Modifikatoren eines Profils mitnimmt.

### Feature 003, Analyse (2026-10-22)

Klaus hat alle 41 Befunde nach Empfehlung freigegeben. Zwei hat Claude beim Einarbeiten anders
gelöst als im Bericht vorgeschlagen, mit demselben Ziel; bei sechs weiteren ließ der Bericht
Einzelheiten offen, die Claude festgelegt hat. Alles steht in
`specs/003-schwierigkeitsgrade/plan.md`, „Änderungen nach der Analyse“, und an den genannten
Stellen.
- **Anders gelöst:**
  - **Text eines Profils (U1, R10):** `DifficultyProfile.to_dict()` statt
    `JSON.stringify(to_list())` als Sonderfall. `_text_of()` ruft es wie bei Ereignissen und
    Kategorien.
  - **FilterBar im Simulator (G10, R13):** Sie bricht nicht um und wird nicht breiter als bisher;
    `%CompareLabel` kürzt mit „…“ und zeigt den Text beim Überfahren ganz. Gilt bis Phase 4;
    seither bricht sie in der kleinen Größe um (siehe „Feature 003, Phase 4, Oberfläche“).
- **Festgelegt, wo der Bericht offen ließ:**
  - **Kein Vergleichslauf (A3, R13):** „Kein Vergleich: Der Lauf hat keine Eingriffe.“ Bei
    Mittel mit Häkchen gelten die Texte von Feature 002.
  - **„Neu“ ohne gewähltes Ereignis (A4, FR-015):** das erste Ereignis über Wahrscheinlichkeit
    nach Kennung.
  - **V31 (U7, R8):** Beginn und Ende werden einzeln geprüft. Liegt im Zeitraum kein
    Monatserster, gibt es nur eine Warnung an `from_day`, „wirkt nie“; gilt V27 oder V28, prüft
    V31 nicht.
  - **Felder (U4, R8):** Ein unbekannter Grad hat das Feld `profiles.<schlüssel>`. Die Prüfung
    zeigt „Profil Leicht“ und „Profil Schwer“ nur bei genau diesen Pfadteilen, sonst „Profile“.
  - **Start-Modifikatoren im Simulator (U10, R13):** ohne eigene Farbe, denn gedämpfter Text hält
    auf Zebra und Auswahl den Kontrast nicht.
  - **Weggelassene Start-Modifikatoren nennen (G1, R8):** `by_event` kennzeichnet die, die ohne
    eigene Meldung nur wegen ihres Ereignisses wegfallen. Zeitleiste und Textausgabe nennen aus
    der Hilfe nur diese, so steht keiner doppelt da. Die Textausgabe hängt an Meldungen zu
    Start-Modifikatoren „Der Start-Modifikator fehlt in der Ausgabe.“

### Feature 003, Phase 1 (2026-10-22)

Auslegungen des Agents, die Claude angenommen hat. Sie stehen auch im Datenmodell, „Prüfregeln“.
- **Texte von V25 bis V30:** vom Agent formuliert, etwa „Das Ereignis „x“ gibt es im Katalog
  nicht.“ (V25); vorgegeben waren nur V29 und V31.
- **Ort der Meldungen zum Abschnitt:** „Katalog“, wie bei den übrigen Schlüsseln der obersten
  Ebene; ist ein Profil keine Liste, das Profil selbst.
- **V26 bei doppelter Kennung:** Es meldet, sobald eines der Ereignisse mit dieser Kennung nicht
  über Wahrscheinlichkeit kommt, wie V16.
- **`catalog_alle_arten.json`:** Leicht −2 gilt das ganze Spiel, Schwer +5 nur 1990 bis 1994, damit
  die Rundreise auch andere Daten abdeckt.
- **Datum lesen:** `ChanceModifier._read_day()` wiederholt die zehn Zeilen von
  `TimelineEvent._read_day()`, damit Phase 1 `TimelineEvent` nicht anfasst.
- **Fund für Phase 2:** `catalog_issue.gd` nennt in Kommentaren noch „V01 bis V24“; der Agent zieht
  das in Phase 2 mit nach. Erledigt in Phase 2.

### Feature 003, Phase 2 (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Doppelte Kennung im Profil beim Spielstart:** Alle Start-Modifikatoren mit dieser Kennung
  fallen durch, nicht nur der zweite, wie V30 jeden meldet. Sonst hinge es an der Reihenfolge,
  welcher gilt.
- **Texte, die der Vertrag offenließ,** etwa in der Textausgabe „Den Schwierigkeitsgrad „extrem“
  gibt es nicht; erlaubt sind leicht, mittel und schwer.“ und im Lauf „Der Start-Modifikator
  braucht einen Grund.“
- **Zusatz „Das Ereignis fehlt in der Ausgabe.“** nur an Meldungen mit einer Ereigniskennung, auch
  in der Textausgabe, wie U5 es für die Zeitleiste verlangt. Eine Meldung V01 zu einer leeren
  Kennung steht damit ohne Zusatz da.
- **Neuer Test `test_fahrplan_ausgabe.gd`:** Die Fehlerprobe zeigte, dass kein Test die
  Textausgabe selbst prüfte. Er startet Godot als eigenen Prozess und kostet rund 6 Sekunden.
- **Textausgabe und `start_refusals`:** Sie gibt die Liste nicht aus; nach `without_faulty()` und
  der Prüfung des Grads ist sie dort immer leer.

### Feature 003, Phase 3, Teil 1 (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Ungültige Aufrufe:** Duplizieren, Löschen und Felder setzen mit Mittel oder einer Stelle, die es
  nicht gibt, melden es mit `push_error()` und tun nichts, wie bei einer unbekannten
  Ereigniskennung. `add_start_modifier()` gibt dann still null, wie der Vertrag sagt.
- **Namen im Verlauf:** etwa „Wert von Schwer: reklamationswelle“, „Start-Modifikator Schwer:
  reklamationswelle duplizieren“; ohne Kennung „Schwer: Nr. 3“.
- **Kennung beim Duplizieren:** wie bei Ereignissen mit Anhang, also `reklamationswelle_2` und
  davon `reklamationswelle_2_2`.
- **Löschdialog ohne Grund:** Fehlt der Grund, nennt er die Kennung, sonst „Schwer: Nr. 3“.
- **Werte mit mehr als vier Nachkommastellen** werden bei der nächsten Änderung im selben Profil
  gerundet; geschrieben wird ohnehin gerundet.
- **Regelverstoß, behoben:** Für eine kurze Probe lag einige Sekunden eine Datei
  `src/zz_probe_kanon.gd` im Repo; sie ist gelöscht, `git status` zeigt nur die drei Dateien von
  T014.

### Feature 003, Phase 3, Teil 2 (2026-10-23)

- **Höhe bei 1280 × 720 (Claudes Entscheidung):** Mit einem langen Hinweis V31 bricht er in der
  schmalen Feldspalte auf sechs Zeilen um, und die Werkstatt wird 23 px höher als ihr Fenster. Ohne
  Hinweis passt alles, bei 1920 × 925 sowieso, und der Simulator ist in dieser Größe schon vorher
  98 px zu hoch. Claude lässt es so; ein ScrollContainer um `%Fields` wiche vom Vertrag ab.
- Auslegungen des Agents, die Claude angenommen hat:
  - Bei 1280 × 720 rollt die Tabelle waagerecht, statt Spalten zu quetschen, wie im Simulator.
  - Nach „Löschen“ ist keine Zeile gewählt.
  - Ein Start-Modifikator ohne Ereignis heißt in Tabelle und Auswahl „– kein Ereignis –“.
  - Die Auswahl „Ereignis“ zeigt nur Titel; die Kennung steht im Hinweis des Eintrags.
  - Nach „Neu“ ist der Wert „+0“ markiert, damit Klaus gleich die Zahl tippt.
  - Zusätzliche Hinweise beim Überfahren an „Duplizieren“, „Löschen“, Wert und Kennung.
  - Die linke Seite des Teilers heißt `TableBox`; der Pfad `…/Tabs/DifficultyPanel/Split` stimmt.

### Feature 003, Phase 4, Kern (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **`write_file()` lehnt einen unbekannten Grad ab,** etwa 7, mit `ERR_INVALID_PARAMETER`, wie eine
  ungültige Kennung. Sonst entstünde `"difficulty": ""`, eine Datei, die `read_file()` nicht liest.
- **Meldung bei einem Wert, der kein Text ist:** `"difficulty": 1` ergibt „… nennt den
  Schwierigkeitsgrad 1, den es nicht gibt.“; ein Text steht in „…“.
- **Erst das Format, dann der Grad:** Eine Datei mit `"format": 2` meldet das Format.
- **Übergang bis T025:** Bis der Simulator den Grad kennt, speichert er Proben immer als Mittel.

### Feature 003, Phase 4, Oberfläche (2026-10-23)

- **FilterBar als `HFlowContainer` (Claudes Entscheidung, angenommen vom Agent):** Kürzen des
  Texts allein reichte nicht, das Häkchen braucht 176 px. In 1280 × 720 bricht die Leiste jetzt in
  zwei Zeilen um, statt aus dem Fenster zu ragen; bei 1920 × 925 bleibt sie einzeilig. Steht im
  Vertrag.
- **Entschieden von Klaus (T027, 2026-10-23): stört nicht.** Mit Schwer wird die Zeile zur Chance
  bei 1920 × 925 vier statt zwei Zeilen hoch; der Simulator wächst um 46 px, die dem Zeitstrahl
  fehlen. Mit Mittel bleibt alles.
- Auslegungen des Agents, die Claude angenommen hat:
  - `%ExcludedNotice` nennt weggelassene Start-Modifikatoren aller Profile, mit dem Grad im Ort.
  - „Katalog geändert“ merkt auch, wenn nur eine Lesemeldung zu einem Profil verschwindet.
  - Spalten der Proben: Name, Seed, Grad, Stand, Eingriffe.
  - Derselbe Grad noch einmal gewählt baut nicht neu.

### Feature 003, Phase 5, Kern (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Grade nacheinander:** Ein Seed läuft erst ganz in Leicht, dann in Mittel, dann in Schwer. Weil
  die Würfel nur an Seed, Zweck und Kennung hängen, ändert das kein Ergebnis.
- **Doppelte oder unbekannte Grade in der Liste** filtert die Statistik nicht; das Panel gibt nur
  gültige weiter (FR-011).
- **Grund einer Ablehnung:** Er kommt aus dem ersten Grad. R15 ist dazu präzisiert.
- **Laufzeit der Tests:** Die Suite braucht jetzt rund 46 statt 31 Sekunden, weil SC-003 drei Grade
  mit je 1.000 Spielen rechnet.

### Feature 003, Phase 5, Oberfläche (2026-10-25)

- **„Katalog geändert“ in der Statistik (Claudes Entscheidung):** Sie nimmt wie der Simulator die
  Stellen weggelassener Start-Modifikatoren in den Schlüssel auf, damit beide Werkzeuge im selben
  Moment „Katalog geändert“ zeigen. Der Vertrag sagte „wie bisher“.
- Auslegungen des Agents, die Claude angenommen hat:
  - Der Text während der Rechnung nennt den Grad, etwa „Rechnet 1.000 Spiele je Grad …“.
  - Während einer Rechnung ist die Auswahl des Grads gesperrt, wie Anzahl und Häkchen.
  - Beim Vergleich hat jede Zelle einen eigenen Hinweis, nicht nur jede Spalte.
  - Ob die Tabelle vergleicht, entscheidet die Rechnung, die dasteht, nicht die Auswahl.
  - In 1280 × 720 rollt die Vergleichstabelle waagerecht.
- **Bilder:** Am Rechner hing beim Fotografieren nur der eingebaute Bildschirm; die Bilder
  entstanden bei Faktor 1 in 1920 × 924. Die Breiten sind dieselben wie bei Faktor 2; die Schrift
  prüft Klaus in T031 am großen Monitor.

### Feature 003, Lückensuche (2026-10-26)

15 Befunde aus T033, alle von Claude am Code bestätigt. Vier gehen als T036 bis T039 an den Agent
(tasks.md, Phase 7). Den Rest hat Claude in der Doku nachgezogen oder hier eingetragen:
- **Weggelassene Start-Modifikatoren nennen (K1):** Jede Meldung steht einmal da; ein
  Start-Modifikator mit zwei Fehlern also zweimal, wie ein Ereignis. Datenmodell und R8 sind
  präzisiert.
- **`start_modifiers` im Lauf (K2, Claudes Entscheidung):** unveränderlich per Vereinbarung, wie
  `modifiers` aus Feature 002; kein Schreibschutz im Code.
- **Doppelte V31-Hinweise im Reiter (W2):** Klaus, 2026-10-26: so lassen, wie beim Simulator. Mit
  Beginn und Ende mitten im Monat wird der Reiter bei 1920 × 925 um 47 px höher, der Zeitstrahl
  entsprechend kleiner.
- Zusätze der Agents, die Claude angenommen hat:
  - `select_difficulty()` im Simulator übergeht einen unbekannten Grad still (S4).
  - Zeilen mit Start-Modifikatoren im Simulator haben einen Hinweis „Start-Modifikator von
    Schwer: … · Kennung …“ (S4).
  - „Je Grad“ setzt vor „%“ ein geschütztes Leerzeichen, damit Zahl und Zeichen nicht getrennt
    umbrechen (W4).
  - Im Reiter: Hinweise an der Gradauswahl, an „Neu“ und an den Zellen Ereignis, Grund und
    Kennung; Platzhalter „TT.MM.JJJJ“ auch an „Beginn“ (W5).
  - Ein Start-Modifikator ohne Kennung bekommt beim Duplizieren eine Kennung aus seinem Ereignis,
    ersatzweise `start_modifikator` (W5).
  - Ein Feld, das mit `profiles[` beginnt, gilt als Profilfeld (W5).
  - Der Test `test_im_kleinen_fenster_passt_jeder_reiter_in_die_breite` (W5).
- Auslegungen des Agents in Phase 7, die Claude angenommen hat:
  - **T036:** Nach dem Übernehmen einer Sicherungskopie gelten die Lesemeldungen beider Profile
    nicht mehr, ohne Vergleich des Inhalts; das Profil kommt dann aus der Kopie.
  - **T037:** Der Löschdialog zählt die Kennung selbst (`_has_twin()`), dieselbe Regel wie
    `delete_event()`; ein Test hält beide zusammen. „zweiten Ereignis“ gilt auch bei dreien.

### Feature 003, Quickstart automatisiert (2026-10-26)

- **Automatischer Durchlauf statt Prüfung von Hand (Klaus, 2026-10-26):** Klaus bat, T034
  automatisiert durchzutesten, weil die Tabellen für ihn schwer nachzuvollziehen sind. Zwei Agents
  haben beide Quickstarts Zeile für Zeile Tests zugeordnet oder im echten Fenster nachgespielt.
  Feature 003: 61 von 64 Zeilen bestanden, Rest von Hand oder entfällt. Feature 002: 92 von 98
  bestanden, drei nicht.
- **Drei Funde, Klaus, 2026-10-26: alle vor der Abnahme beheben** (tasks.md, Phase 8): Tab bleibt
  in der Beschreibung hängen (T094); Cmd+Q wirkt nicht bei offenem Dialog zur Sicherungskopie
  (T096); unter 1440 × 900 ist der Simulator höher als das Fenster. Im kleinen Fenster darf der
  Reiter rollen, bei 1920 × 925 bleibt alles, wie es ist.
- **Umsetzung in Phase 8, Auslegungen des Agents, die Claude angenommen hat:**
  - Für Cmd+Q bei offenem Dialog sind die Dialoge nicht mehr `exclusive`, und die Werkstatt sperrt
    selbst. Das gilt für alle 15 Dialoge: Der offene Dialog geht zu wie mit „Abbrechen“, dann läuft
    das Schließen weiter. Bei „Trotzdem speichern“ und der fremden Änderung entfällt das Speichern.
  - Neu ist: Nach einem Klick neben einen Dialog hat der Dialog sofort wieder den Fokus.
  - Im rollenden Reiter folgt die Ansicht der Tab-Taste nicht; `follow_focus` ließe beim Klick in
    eine hohe Tabelle die Ansicht springen.
  - Bei 1024 × 600 ist die Werkstatt zu breit; gemessen nur zur Information, nicht Teil von T043.

### Feature 004, Plan (2026-10-26)

Festlegungen in `specs/004-neues-spiel/research.md`, die nicht aus Spec und Klärung folgen. Noch
nicht umgesetzt; Klaus kann sie bei jeder Abnahme ändern. Die übrigen hat Klaus mit der Checkliste
und mit dem Style-Guide (T002) bestätigt (unter „Erledigt“).
- **Zurück aus einem Blatt** wählt im Hauptmenü den Eintrag, der es geöffnet hat
  (`data-model.md`).

### KI-Workflow, Schritte 1 und 2 (2026-10-22)

- **Phasenprüfung als Punkt 8:** In `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“, steht sie
  am Ende statt zwischen Punkt 4 und 5. So bleiben die Nummern, auf die Specs und Aufträge
  verweisen, etwa „Punkt 6“ für die Lückensuche.
- **Musterbericht nachgeschärft:** Drei ausgedachte Befunde widersprachen dem Style-Guide. 2 px
  Abstand ist erlaubt (`raster-2`), jetzt sind es 3 px; Preise stehen als „499,00 DM“; „googeln“
  gab es bis 1999 nicht, auch nicht ab 1998.

## Erledigt

- **Style-Guide für Feature 004 (T001, T002):** Klaus, 2026-10-26, freigegeben: Version 22 mit
  „Blätter im Titel“ und „Rückfrage“ beim Menü, den Bausteinen Liste und Meldung, dem allein
  stehenden Knopf mit Hinweis und der Fokuslinie in `papier` auf dunklem Grund, dem Spielbildschirm
  als Platzhalter. Damit gelten auch die Lage der Blätter, die Spalten der Liste und der
  Spielbildschirm aus „Feature 004, Plan“ als bestätigt.
- **Analyse von Feature 004:** Klaus, 2026-10-26: alle 44 Befunde nach Empfehlung einarbeiten.
  Eingearbeitet in Spec (Clarifications „Analyse 2026-10-26“, Edge Case „Zwei Fenster“, FR-016),
  Plan („Änderungen nach der Analyse“), research.md, Datenmodell, Verträge, Quickstart und Tasks.
  Wo Claude anders gelöst hat als der Prüfer vorschlug: Spalten 0, 64, 108, 172 und Papier 304
  statt nur die 6 px Rest zu benennen (F9, B4), Rollmarken in Kopfzeile und „Löschen …“ statt in
  Zeilen der Spielstände, Werte im Vertrag als Verweis auf den Style-Guide statt als Zahl (D1).
- **Review-Checkliste von Feature 004:** Klaus, 2026-10-26: alle 36 Vorschläge freigegeben
  (`specs/004-neues-spiel/checklists/review.md`), eingearbeitet in Spec, Plan, research.md,
  Datenmodell, Verträge und Quickstart. Damit bestätigt sind auch diese Festlegungen des Plans, die
  jetzt in der Spec stehen: Ordnung und Rollen der Liste, „Löschen …“ im Löschmodus nicht
  verfügbar, die Sätze zu den Graden im Hinweis, „Abbrechen“ als Zurück der Rückfrage, Speichern
  beim Fortsetzen, Schließen bei gescheitertem Speichern, ein Eingriff mit falschem Datum macht den
  Spielstand beschädigt, Katalog beim Start der App gelesen.
- **Sätze zu den Graden (Feature 004, R18):** Klaus, 2026-10-26, nach Empfehlung Vorschlag A:
  Leicht „Das Glück ist eher auf deiner Seite.“, Mittel „Das Glück hält sich raus.“, Schwer „Das
  Glück ist eher auf der Seite der anderen.“ Steht in `specs/004-neues-spiel/research.md`, R18, und
  im Vertrag `titelbildschirm.md`; der Text-Prüfer prüft sie in Phase 4.
- **Fünf Festlegungen aus der Spec von Feature 004:** Klaus, 2026-10-26, alle bestätigt: Esc auf
  dem Spielbildschirm löst nichts aus (FR-020); „Spiel N“ mit N = größte Nummer + 1 (FR-009); der
  Löschmodus mit seinen Enden und „Abbrechen“ vorgewählt (FR-017, FR-017a); nur beschädigte
  Spielstände machen „Spiel laden“ verfügbar (FR-002); kein Speichern während des Spiels, solange
  die Uhr steht (Annahmen).
- **Eine Sitzung je Feature von specify an:** Klaus, 2026-10-26: Ein Feature läuft von
  `/speckit-specify` bis zur Gesamtabnahme in einer Sitzung; Claude bietet keine eigene Sitzung ab
  dem Plan mehr an. Steht in `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“, Punkt 7.
- **Merge von Feature 003 und KI-Workflow nach `main`:** Klaus, 2026-10-26, nach Empfehlung, vor
  dem Start von Feature 004: erst Feature 003 (`6e5ea67`), dann der Branch des KI-Workflows
  (`342e0d1`). So sind Prüfer und Skill im Pilot von Feature 004 dabei.
- **Feature 003 abgenommen:** Klaus, 2026-10-26 (T035). Alle Phasen 1 bis 8 sind abgenommen
  oder geprüft und committet; T034 lief automatisiert mit wenigen Handgriffen von Klaus. Über den
  Merge nach `main` entscheidet Klaus; diese Sitzung wechselt den Branch nicht.
- **Pilot und Merge des KI-Workflows** (Schritt 9): Klaus, 2026-10-22, nach Empfehlung: Der Pilot
  läuft im nächsten Feature nach 003, in der ersten Phase mit Sichtbarem oder Texten. Ab dem Pilot
  gelten die Prüfer, auch für Werkzeuge. Der Branch geht nach `main`, sobald Feature 003 dort ist.
- **Hook nach dem Godot-Agent** (Schritt 8 des KI-Workflows): Klaus, 2026-10-22, nach Empfehlung:
  vorerst keiner, Schritt 8 entfällt. Die Tests laufen beim Agent und danach zweimal bei Claude.
  Liefert der Agent zweimal rote Tests ab, ohne es zu melden, kommt ein Hook bei `SubagentStop`
  mit dem Matcher `godot-entwickler`. Steht in `docs/ki_workflow/ki_pruefung.md`.
- **Text-Leitfaden als Abschnitt „Sprache“ im Style-Guide** (Schritt 4 des KI-Workflows): Klaus,
  2026-10-22, nach Empfehlung. Den Ton hat er in vier Fragen entschieden, jeweils nach Empfehlung:
  trocken-ironisch wie „Das Amt“; kein Witz in der Bedienung; maßvoll aus der Zeit; das Spiel duzt
  den Spieler, Kunden, Bank und Ämter siezen den Ladenbesitzer wie damals üblich. Der Abschnitt
  steht im Style-Guide (Version 19), die drei Textregeln unter „Schrift“ verweisen jetzt dorthin.
- **KI-Workflow in eigenem Ordner:** Klaus, 2026-10-22: Konzept freigegeben, mit der Änderung an
  `CLAUDE.md` (Pfad `docs/ki_workflow/`). Umgesetzt in den Schritten 1 und 2: `ki_dev.md` ist
  umgezogen, dazu kommen der Einstieg `README.md` und `ki_pruefung.md` mit Schaubildern; die beiden
  Konzepte sind darin aufgegangen.
- **Analyse von Feature 003:** Klaus, 2026-10-22: alle 41 Befunde nach Empfehlung einarbeiten.
  Eingearbeitet in Spec, Plan, research.md, Datenmodell, Verträge, Quickstart, Checkliste und
  tasks.md, jetzt mit T001 bis T035. Zusammengefasst im Plan unter „Änderungen nach der Analyse“;
  Claudes eigene Festlegungen dabei stehen oben unter „Feature 003, Analyse“.
- **Eigene Festlegungen des Plans von Feature 003, bestätigt im Review:** Klaus hat am
  2026-10-22 die Vorschläge der Checkliste freigegeben und damit diese Festlegungen bestätigt:
  - der Reiter mit „Neu“ ohne Dialog und „Löschen“ ohne Rückfrage (R11, CHK016);
  - der Wechsel des Grads im Simulator, „so, wie er war“ (R13, CHK011, CHK029, CHK033);
  - der Stand im Simulator ohne Grad und die Texte der Markierungen (R13, CHK017);
  - die unlesbare Probe bei einem unbekannten Grad (R14, CHK031);
  - „Spanne“ und keine Verteilung beim Vergleich, der Grad im Ergebnistext (R15, CHK015,
    CHK017);
  - die Kopfzeile der Textausgabe mit Grad (R16, CHK017);
  - das einmalige Speichern des echten Katalogs in Phase 1 (R3, CHK037).

  Steht in `specs/003-schwierigkeitsgrade/checklists/review.md`.
- **Verfassung, Grundsatz V und die Profile (Feature 003):** Klaus, 2026-10-22, nach Empfehlung:
  so lassen. Die Ausnahme Ereigniskatalog gilt der Datei und ihrer Pflege in der Werkstatt, also
  auch den Profilen darin; die Verfassung bleibt bei 2.1.1. Steht in
  `specs/003-schwierigkeitsgrade/checklists/review.md`, CHK022.
- **Verweise beim Umbenennen (Feature 003, FR-017):** Klaus, 2026-10-21, im Plan:
  Start-Modifikatoren ziehen still mit wie Folgen und Bedingungen; genannt wird nur beim Löschen.
  Steht in der Spec und in `specs/003-schwierigkeitsgrade/research.md`, R9.
- **`CLAUDE.md` verweist auf `docs/ki_dev.md`** (Claudes Ergänzung nach Klaus' Satz „ki_dev ist in
  claude.md“): Klaus hat den Absatz „Arbeitsweise“ mit dem Merge von Feature 002 nach `main`
  freigegeben (2026-10-21).
- **Noch eine Lückensuche nach Phase 12?** Klaus, 2026-10-21: nein, weiter mit T072. Punkt 6 in
  `docs/ki_dev.md` bleibt, wie er ist; für Phase 12 gilt diese Ausnahme.
- **Phase 11 und 12 zusammen abnehmen** (Claudes Vorschlag): Klaus hat am 2026-10-21 beide mit
  T103 abgenommen; sie stehen in einem Commit.
- **Wirkungen abgesagter und entfallener Termine (T097):** Klaus, 2026-10-21: nicht zeigen, sie
  kommen nie. Umgesetzt in Phase 12.
- **Zwei Termine eines Ereignisses am selben Tag (T100):** Klaus, 2026-10-21: nichts bauen, die
  Grenze festhalten. Steht im Datenmodell unter „Neu abspielen“ und in R22.
- **Vorgabe-Teilung der Tabellen (T101):** Klaus, 2026-10-21: Die Tabelle bekommt Vorrang.
  Umgesetzt in Phase 12.
