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
  (Checkliste, CHK008). Offen sind nur noch die Werte.

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
    `%CompareLabel` kürzt mit „…“ und zeigt den Text beim Überfahren ganz.
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

## Erledigt

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
