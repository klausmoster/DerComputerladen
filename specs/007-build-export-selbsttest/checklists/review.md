# Anforderungs-Review Checklist: Build & Export mit Selbsttest

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Selbsttest-App, Abläufe, Gleichheit der Fotos, Protokoll und
Zusammenfassung, Vergleich, Export für drei Systeme, Arbeitsweise.
**Created**: 2026-10-28
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-28 für alle Punkte. Die Punkte ab „Aus der Prüfung des
Vertrags“ stammen von Stil- und Text-Prüfer, von Claude nachgeprüft (Verfassung, Grundsatz VI).

## Widersprüche

- [x] CHK001 Steht die Ausnahme von „alles über die Oberfläche“ in der Spec? FR-004 verbietet jeden
  direkten Aufruf, der Plan braucht aber drei: Fenstergröße setzen (Ablauf `fenster`), sieben
  Spielstände für den Mausrad-Schritt anlegen (`bedienung.06`) und den frischen Titel herstellen
  (Ordner leeren, Titel neu laden). [Conflict, Spec §FR-004; ablaeufe.md]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-004 bekommt einen Satz: „Ausgenommen sind das Vorbereiten eines Ablaufs (Ordner,
  Spielstände, frischer Titel) und was das Betriebssystem tut, etwa die Fenstergröße; das Protokoll
  nennt solche Schritte mit `eingaben: Vorbereitung` bzw. `eingaben: Fenster`.“
- [x] CHK002 Was öffnet „Ordner zeigen“? FR-016 sagt den Ordner des Laufs, R11 markiert das Zip im
  übergeordneten Ordner. [Conflict, Spec §FR-016; Plan R11]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Der Knopf zeigt das Zip im Ordner `selbsttest/`, markiert unter Windows und macOS;
  daneben liegt der Ordner des Laufs. So ist mit einem Klick das zu sehen, was Klaus zurückgibt.
  FR-016 entsprechend.
- [x] CHK003 Wann läuft der Selbsttest auf Windows und Linux? Story 5 sagt „Klaus startet ihn auf
  Windows und Linux“ bei jeder Endabnahme, R25 nur „wenn das Feature dort etwas ändert oder es lange
  keinen Lauf gab“. [Conflict, Spec Story 5; Plan R25]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Die Spec lässt es offen und verweist auf die Regel aus Phase 7; dort schlägt Claude
  vor: auf dem Mac bei jeder Endabnahme, auf Windows und Linux bei Features mit Sichtbarem, Fenster
  oder Export, sonst höchstens alle drei Features.

## Vollständigkeit

- [x] CHK004 Nennt die Spec die feste Zeitzone? FR-008 nennt feste Uhrzeit und Seed; R7 braucht
  zusätzlich einen festen Zeitzonenversatz, sonst zeigen die Hinweise auf Rechnern in anderen
  Zeitzonen andere Uhrzeiten. [Gap, Spec §FR-008; Plan R7]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-008 „… mit einer festen Uhrzeit in einer festen Zeitzone, …“ und der Randfall
  „Uhrzeit und Datum des Rechners“ ebenso.
- [x] CHK005 Gibt es Fotos, die nicht verglichen werden? Die Spec kennt nur „jedes Foto mit
  Referenz“; der Plan markiert die zwei Fotos des versteckten Spiels als nicht vergleichbar, weil es
  nach Zeit rechnet. [Gap, Spec §FR-007, §FR-019; Plan R7]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-007 „Ein Schritt, dessen Bild vom Tempo des Rechners abhängt, ist als nicht
  vergleichbar markiert; geprüft wird dort nur der Zustand.“ FR-019 bekommt das Ergebnis „nicht
  vergleichbar“.
- [x] CHK006 Was passiert mit Abläufen, die auf einem gescheiterten aufbauen? FR-009 und die
  Randfälle sagen „der nächste Ablauf beginnt beim frischen Titel“; `laden` und `loeschen` bauen aber
  auf `neues_spiel` auf. [Gap, Spec §FR-009; data-model.md „Ablauf“]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-009 ergänzen: „Baut ein Ablauf auf einem gescheiterten auf, gilt er ganz als
  nicht gelaufen, mit Grund.“
- [x] CHK007 Ist festgelegt, welche Ausgabe als Meldung eines Schritts zählt? FR-014 nennt
  „Warnungen oder Fehler, die das Spiel gemeldet hat“; Godot meldet auch Dinge des Selbsttests
  selbst. [Clarity, Spec §FR-014; Plan R10]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Jede Warnung und jeder Fehler aus Godot zählt, gleich von wem; der Selbsttest selbst
  gibt nichts aus außer bei eigenen Fehlern, die dann so markiert sind: `meldung: [selbsttest] …`.
- [x] CHK008 Nennt FR-024 die Export-Templates? Er spricht von „Werkzeugen, etwa für das
  App-Symbol“; nach der Recherche braucht es kein Werkzeug, aber die Templates für Windows und Linux
  fehlen auf Klaus' Mac. [Clarity, Spec §FR-024; Plan R14]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-024 „Was der Export für Windows und Linux braucht, heute die vollständigen
  Export-Templates 4.7.2, MUSS dokumentiert sein; …“

## Messbarkeit

- [x] CHK009 Wie viele Fehler baut die Fehlerprobe ein? SC-004 nennt Bereiche, aber keine Zahl.
  [Measurability, Spec §SC-004]
  → Vorschlag, freigegeben von Klaus (2026-10-28): „mindestens je ein Fehler in Titel, Gradwahl, Liste, Rückfrage, Easter Egg und
  Fenster, also sechs“, mit den Beispielen aus R23.
- [x] CHK010 Was unterscheidet zwei Protokolle nach SC-002? Neben Datum, Uhrzeit und Dauern
  unterscheiden sich auch Ordnerpfad, Lauf-Kennung und, falls es sie gab, Fokusverluste. [Clarity,
  Spec §SC-002]
  → Vorschlag, freigegeben von Klaus (2026-10-28): SC-002 „… nur in Zeiten, Dauern, Pfaden und Fokusverlusten“.
- [x] CHK011 Was heißt „ohne Störung“ in SC-003? [Ambiguity, Spec §SC-003]
  → Vorschlag, freigegeben von Klaus (2026-10-28): „ohne Fokusverlust und ohne Abbruch“.
- [x] CHK012 Stehen die Erfolgskriterien in Reihenfolge? SC-010 steht vor SC-008. [Consistency]
  → Vorschlag, freigegeben von Klaus (2026-10-28): SC-010 ans Ende stellen.
- [x] CHK013 Was bedeutet „Nummer“ je Schritt in FR-013? Das Protokoll kennt nur die Kennung mit
  `nn`. [Clarity, Spec §FR-013; protokoll.md]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-013 „Kennung (mit laufender Nummer im Ablauf)“.

## Abdeckung

- [x] CHK014 Ist der Ablauf `titel_echtzeit` an `titel` gebunden? Die Spec sagt „noch einmal“,
  ablaeufe.md verlangt gleiche Fotos wie `titel`. [Coverage, Spec §FR-011.8]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-011.8 „mit denselben Schritten und denselben Fotos wie `titel`“; so prüft der
  Vergleich nebenbei, dass Zeitraffer nichts am Bild ändert.
- [x] CHK015 Ist bedacht, dass die Zwischenablage unter Linux nach dem Beenden leer sein kann?
  [Edge Case, Plan R11]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Randfall in der Spec; die Zusammenfassung sagt nach „Kopieren“ unter Linux
  „Kopiert. Erst einfügen, dann beenden.“ (Wortlaut beim Text-Prüfer).

## Aus der Prüfung des Vertrags: Stil (Zusammenfassung)

Stil-Prüfer am 2026-10-28 gegen `Werkzeuge.md`, `README.md`, `tokens.json`; 11 Befunde, 11 Lücken
im Style-Guide. Claude hat B1 bis B3 an `werkstatt.gd` (Zeilen 102 f., 917 bis 926) und
`werkstatt_theme.tres` nachgeprüft: bestätigt. Alle übrigen bestätigt; L11 (Fenstertitel) ohne Folgen.

- [x] CHK016 Öffnet die Zusammenfassung maximiert? Der Vertrag sagt „Fenster bleibt in seiner
  Größe“; Werkzeuge öffnen maximiert. Scheitert der Ablauf `fenster` vor dem Zurückvergrößern, hätte
  die Seite auf Retina nur rund 320 × 180 logische Pixel. [Conflict, Stil B1, B3, L4]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Die Zusammenfassung maximiert das Fenster und hält `GameWindow` an, genau wie
  `werkstatt.gd`. In R12 und im Vertrag so festhalten; keine Ausnahme im Style-Guide nötig.
- [x] CHK017 Setzt der Vertrag die Schrift der Werkzeuge? `werkstatt_theme.tres` hat keine
  `default_font`; ohne Code erbt die Seite Ark Pixel aus dem Spiel. [Gap, Stil B2]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Vertrag: „Kopie des Themes, `default_font = ThemeDB.fallback_font`, wie die
  Werkstatt“; Knöpfe als Standard-`Button` ohne eigene Styles, damit Überfahren, Drücken und Fokus
  aus dem Theme kommen.
- [x] CHK018 Hat jeder Text eine Größe aus den Tokens? „Groß“ für die Summe hat keines. [Clarity,
  Stil B4, L3]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Überschrift und Summe in `werkzeug-titel` (16), Systemzeile in `werkzeug-klein`
  und `gehaeuse-dunkel`, alles andere `werkzeug-text`. Kein neues Token.
- [x] CHK019 Wie unterscheiden sich in der Liste Fehler und „nicht gelaufen“, und hat „in Ordnung“
  eine Farbe? [Gap, Stil B5, L1, L2]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Fehler bekommen das Feld in `kassenrot` mit „!“ in `papier` (Rolle Fehler).
  Nicht gelaufene Schritte bekommen ein Feld mit `tusche`-Kontur auf `papier` mit „–“, Text in
  `tusche`; so unterscheiden sie sich in Form und Zeichen, ohne gedämpften Text auf
  `endlos-gruen`. „In Ordnung“ hat keine Farbe, nur Wortlaut. Alle drei Regeln kommen vorher in den
  Abschnitt Werkzeuge (Phase 4, Vorarbeit).
- [x] CHK020 Wie sieht die Seite aus, wenn der Ordner nicht beschreibbar ist? [Gap, Stil B6, L8,
  L10]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Überschrift und Systemzeile bleiben; an Stelle von Summe, Liste und Pfad steht die
  Meldung als Feld in `kassenrot` mit Text in `papier` (Theme-Variante `ErrorNoticeLabel`); „Ordner
  zeigen“ ist gesperrt. Gesperrte Knöpfe so, wie das Theme sie hat (`papier`, Kontur `tusche`, Text
  `gehaeuse-dunkel`), als Regel in den Abschnitt Werkzeuge.
- [x] CHK021 Ist der Aufbau der Seite festgelegt? Reihenfolge, Kopf der Liste, leerer Zustand und
  Knopfreihe fehlen. [Gap, Stil B7]
  → Vorschlag, freigegeben von Klaus (2026-10-28): von oben: Überschrift, Systemzeile, Summe, Bereichstitel „Was nicht stimmt“ in
  `werkzeug-titel` auf `papier` (nur wenn es Einträge gibt; bei alles in Ordnung entfällt er mit der
  Liste), Liste, Pfad; unten die Knopfreihe links beginnend: Kopieren, Ordner zeigen, Beenden.
- [x] CHK022 Sind Abstände und Grund festgelegt? [Gap, Stil B8, B9]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Grund `papier` über die ganze Fläche; Rand und Abstand zwischen Bereichen
  `raster-16`, zwischen Einträgen `raster-8`, zwischen Knöpfen `raster-4`.
- [x] CHK023 Welcher Knopf hat beim Öffnen den Fokus, und was tun Tasten? [Gap, Stil B11]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Fokus auf „Kopieren“; Tab und Umschalt+Tab wechseln zwischen den Knöpfen, Enter und
  Leertaste lösen aus, Esc tut nichts. So beendet ein versehentliches Enter nichts.
- [x] CHK024 Wie sieht eine mehrzeilige Liste aus? [Gap, Stil L5]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Die zweite Farbe `endlos-gruen` wechselt je Eintrag, nicht je Textzeile; Einträge
  sind nicht anklickbar und haben kein Überfahren. In den Abschnitt Werkzeuge.
- [x] CHK025 Wo und wie lange steht „Kopiert.“? [Gap, Stil L6]
  → Vorschlag, freigegeben von Klaus (2026-10-28): rechts neben der Knopfreihe in `werkzeug-text`, bis zum nächsten Klick. In den
  Abschnitt Werkzeuge als „Bestätigung“.
- [x] CHK026 Haben die Knöpfe Tooltip und Handzeiger? Die Oberfläche verlangt es für jede
  anklickbare Stelle, die Werkstatt hat es. [Gap, Stil L7]
  → Vorschlag, freigegeben von Klaus (2026-10-28): ja, wie in der Werkstatt. Tooltips: „Legt das Ergebnis als Text in die
  Zwischenablage.“, „Zeigt das Zip dieses Laufs im Dateimanager.“, „Beendet den Selbsttest.“ In den
  Abschnitt Werkzeuge: Tooltip und Handzeiger gelten für alle Werkzeuge.
- [x] CHK027 Was passiert mit langen Pfaden und Werten? [Gap, Stil L9]
  → Vorschlag, freigegeben von Klaus (2026-10-28): umbrechen, Pfade nach einem Trenner; nicht kürzen, damit der Pfad vollständig zu
  lesen ist. In den Abschnitt Werkzeuge.
- [x] CHK028 Hört der Läufer auf der Zusammenfassung noch auf das Schließen des Fensters? Sonst
  vermerkte er nach dem fertigen Protokoll einen Abbruch. [Gap, Stil, Unsicher]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Nach dem Schreiben hört er nicht mehr zu; Schließen auf der Zusammenfassung beendet
  einfach. Vertrag „Läufer“.

## Aus der Prüfung des Vertrags: Text

Text-Prüfer am 2026-10-28 gegen `Sprache.md` und `Werkzeuge.md`; 18 Befunde, 6 Lücken im
Style-Guide. Claude hat die Kennungen in den Beispielen nachgeprüft (B15): Sie passen nicht zu den
Tabellen. Alle Befunde bestätigt.

- [x] CHK029 Heißt die Version des Programms „Spiel“? `spiel.version` widerspricht der Regel „Das
  Programm heißt nicht ‚das Spiel‘“. [Terminology, Text B1]
  → Vorschlag, freigegeben von Klaus (2026-10-28): `computerladen.version`.
- [x] CHK030 Gilt die Wortliste der Zeit für Werkzeuge? „App startet“ steht im Beispiel; „App“ ist
  auf der Liste „Nie“. [Ambiguity, Text B2, L1]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Beschreibung „Start, der Communicator fährt herein“. Im Abschnitt Werkzeuge
  klarstellen: Werkzeuge folgen Anrede und Ton, die Wortliste der Zeit gilt für Texte im Spiel;
  in sichtbaren Texten der Werkzeuge trotzdem kein „App“.
- [x] CHK031 Ist die Form der Spalte „Erwartet“ einheitlich und ohne Verweise? Grade in
  Anführungszeichen, „Spiel nicht zu sehen“, „wie in 01“, „(FR-012)“, „2 × 640 + 37 mal …“,
  `best_factor()` und falsche Kennungen im Beispiel. [Consistency, Text B3, B10, B15, B16, B17, L3]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Form `Menü steht: SCHWIERIGKEIT, Mittel`; Grade ohne, Menüeinträge mit
  Anführungszeichen (sonst ist „Neues Spiel“ im Satz mehrdeutig); ausgeschrieben statt Verweis;
  `Seite Invaders nicht sichtbar, Menü steht: HAUPTMENÜ, „Spiel laden“`; `Fenster auf 1317 × 741`;
  `best_factor()` als „größter ganzzahliger Faktor, der passt“. Beispiele in `protokoll.md` und
  `data-model.md` mit den Kennungen der Tabellen.
- [x] CHK032 Heißt „Ordner“ zwei Dinge? „Ordner: 1“ meint Spielstände, „Ordner zeigen“ den Lauf.
  [Terminology, Text B4]
  → Vorschlag, freigegeben von Klaus (2026-10-28): `Spielstände: Spiel 1`, `Spielstände: keine`.
- [x] CHK033 Gibt es genau eine Form der Ergebniszeile? [Consistency, Text B5, B6, B11]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Eine Form mit Punkt, auf dem Bildschirm und in `ergebnis:`: „Alles in Ordnung: 40
  von 40 Schritten.“ oder „38 von 40 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.“ Der erste Teil
  steht immer, nur Fehler und nicht gelaufen entfallen bei 0. Dativ: „von 1 Schritt“, „von 2
  Schritten“.
- [x] CHK034 Sind Gründe und Zustände einheitlich? Zwei Wortlaute für „nicht gelaufen“,
  „gescheitert“ neben „Fehler“, „Gefunden:“ für Zustand und Grund, uneinheitliche Satzzeichen.
  [Consistency, Text B7, B8, B14, L4]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Werte im Protokoll ohne Schlusspunkt, nur `ergebnis:` ist ein Satz. Bei `FEHLER`:
  `Zeit abgelaufen, zuletzt: {zustand}`, `Ziel nicht gefunden: {ziel}`. Bei `NICHT_GELAUFEN`:
  `Fehler in Schritt {kennung}`, `Fehler in Ablauf {kennung}`, `Fenster geschlossen`. In der Liste
  bei nicht gelaufenen Schritten statt „Erwartet“ und „Gefunden“ nur `Nicht gelaufen: {grund}`.
- [x] CHK035 Zählt der Fenstertitel Schritte oder Selbsttests? [Ambiguity, Text B9]
  → Vorschlag, freigegeben von Klaus (2026-10-28): `Selbsttest · Schritt {n} von {gesamt}: {ablauf}`.
- [x] CHK036 Heißt die App überall gleich? [Consistency, Text B12]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Kopf des Protokolls `# Der Computerladen Selbsttest`.
- [x] CHK037 Ist der Ablauf „Laden“ mit dem Laden zu verwechseln? [Terminology, Text B13]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Name „Spiel laden“, wie der Menüeintrag; Kennung `laden` bleibt.
- [x] CHK038 Hat `lauf.abbruch` einen Wert? [Consistency, Text B18]
  → Vorschlag, freigegeben von Klaus (2026-10-28): `keiner`, auch im Datenmodell.
- [x] CHK039 In welchen Formen stehen Daten, Maße und Tasten? [Gap, Text L2, L5, L6; Stil B10]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Im Protokoll eine feste Maschinenform, ausgenommen von den Regeln für Texte wie
  Testausgaben: `2026-10-28 14:03:12`, `3024x1964`, `2.0`. Auf dem Bildschirm deutsch: „28.10.2026,
  14:03 Uhr“, Maße „640 × 360“. Tasten in Beschreibungen: Enter, Esc, Tab, Umschalt+Tab,
  Leertaste, Pfeil runter. Beides als Regel in den Abschnitt Werkzeuge.

## Ergebnis

Zusammen 39 Punkte: 15 von Claude, 13 vom Stil-Prüfer, 11 vom Text-Prüfer (aus 18 Befunden, einige
zusammengefasst). Für den Style-Guide sammeln sich die Ergänzungen im Abschnitt Werkzeuge
(CHK019, CHK020, CHK024 bis CHK027, CHK030, CHK039); sie sind die Vorarbeit von Phase 4.
