# Anforderungs-Review Checklist: Ladeneröffnung

**Purpose**: Prüft, ob Spec, Plan und Verträge vollständig, eindeutig, widerspruchsfrei und
messbar sind, bevor die Tasks entstehen. Bereiche: Ablauf im Büro, Geld und Konto, Spielstand,
Spielbildschirm, game_bible und Importer, Figuren.
**Created**: 2026-10-29
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Klaus hat am 2026-10-29 alle 47 Vorschläge freigegeben, auch die Ausnahme zu AR-13,
und alle sind eingearbeitet: in Spec, Plan, research.md, data-model.md und den Verträgen. Die Punkte ab „Aus der Prüfung des
Vertrags“ stammen von Stil-, Text- und Architektur-Prüfer, von Claude nachgeprüft (Verfassung,
Grundsatz VI).

Schon vor der Checkliste behoben (2026-10-29): FR-025, der Vertrag des Spielbildschirms und der
Quickstart nannten für einen negativen Kontostand `kassenrot`; der Baustein Anzeige sagt, die Farbe
bleibt `anzeige`, nur Minus und SOLL kommen dazu.

## Klarheit

- [x] CHK001 Ist das Format von Datum und Kontostand eindeutig? FR-024 nennt „25.680,00 DM“, FR-026
  nur „Spieldatum“; der Baustein Anzeige verlangt `MO 14.10.1991` mit Wochentag. [Clarity, Spec
  §FR-024, §FR-026]
  → Vorschlag: FR-026 sagt „Datum und Kontostand in der Leuchtanzeige nach dem Baustein Anzeige,
  etwa MO 01.01.1985 und 25.680,00 DM“.
- [x] CHK002 Ist „zwei bis drei Tempostufen“ noch offen, obwohl der Plan drei festlegt (1, 2 und 7
  Tage je Sekunde)? [Clarity, Spec §FR-027, research.md R10]
  → Vorschlag: FR-027 sagt „drei Tempostufen (1, 2 und 7 Tage je Sekunde)“.
- [x] CHK003 Welcher Laden ist auf dem Stadtplan vorgewählt? US1, Szenario 1 sagt nur „einer“,
  das Datenmodell „der erste bezahlbare“. [Clarity, Spec §US1]
  → Vorschlag: US1, Szenario 1: „der erste bezahlbare in der Reihenfolge der Läden“.
- [x] CHK004 Ist das Namensfeld leer oder mit einem Vorschlag gefüllt? US2, Szenario 3 lässt beides
  offen. [Ambiguity, Spec §US2]
  → Vorschlag: leer. Einen sinnvollen Vorschlag gibt es nicht, weil das Spiel den Namen des
  Spielers nicht kennt; ein Platzhalter wie „Computer Müller“ würde nur abgetippt.
- [x] CHK005 Wer steht im Mietvertrag als Mieter? FR-015 sagt „noch ohne Ladennamen“, aber der
  Spieler hat im Spiel keinen eigenen Namen. [Clarity, Spec §FR-015]
  → Vorschlag: FR-015: „Mieter: eine leere Zeile mit der Unterschrift des Spielers“; die
  Unterschrift ist ein gezeichneter Schriftzug, kein Name.

## Konsistenz

- [x] CHK006 Widerspricht SC-006 („Ladenname in der Liste vollständig zu lesen“) dem Baustein
  Liste? Die Spalte für den Namen ist 64 Oberflächenpixel breit, zu lange Namen werden mit „…“
  gekürzt. [Conflict, Spec §SC-006]
  → Vorschlag: SC-006: „vollständig auf dem Spielbildschirm, im Hinweis zu Weiterspielen und in der
  Rückfrage; in der Liste gekürzt nach dem Baustein Liste, vollständig im Hinweis der Zeile“.
- [x] CHK007 Ist FR-017 („auf dem Knopf „Zum Hauptmenü““) genau? Der Name steht im Hinweis neben
  dem Knopf, nicht auf ihm. [Consistency, Spec §FR-017]
  → Vorschlag: „im Hinweis zu „Zum Hauptmenü““.
- [x] CHK008 Was bleibt beim Zurückgehen stehen? Der Edge Case sagt, die Unterschrift bleibt nicht
  stehen; der Vertrag sagt, der eingetippte Name bleibt, wenn der Spieler wiederkommt. Ob der Name
  auch nach dem Wechsel zu einem anderen Laden bleibt, sagt keiner. [Consistency, Spec §Edge Cases,
  contracts/ladenwahl.md]
  → Vorschlag: Edge Case: „Zurück von der Anmeldung nimmt die Unterschrift weg; der eingetippte
  Name bleibt, solange die Eröffnung offen ist, auch bei einem anderen Laden.“
- [x] CHK009 Passen FR-026 und US3 („Ladenname im Bild“) zur Bedienleiste, die außer der Anzeige
  keinen Text erlaubt? Der Plan nennt das als offene Frage an den Style-Guide (R14, Frage 2), die
  Spec nicht. [Conflict, Spec §FR-026]
  → Vorschlag: FR-026 sagt „wo der Name steht, regelt der Style-Guide“, und der Punkt bleibt in
  R14 für Phase 4.

## Vollständigkeit

- [x] CHK010 Was geschieht mit den Ereignissen der Zeitleiste, wenn die Uhr jetzt läuft? Sie
  feuern, aber nichts zeigt sie (das ist 10-04). Die Spec schweigt dazu. [Gap]
  → Vorschlag: Annahme ergänzen: „Die Zeitleiste läuft mit der Uhr und meldet ihre Ereignisse;
  angezeigt werden sie erst mit 10-04. In 010 sieht der Spieler davon nichts.“
- [x] CHK011 Ist akzeptiert, dass ein Absturz alles seit dem letzten Speichern verliert? Gespeichert
  wird nur beim Verlassen und Schließen (FR-027a); bei laufender Uhr können das Jahre sein. [Gap,
  Assumption, Spec §FR-027a]
  → Vorschlag: Annahme ergänzen: „Speichern während des Spiels kommt mit 11-01; bis dahin geht nach
  einem Absturz verloren, was seit dem Fortsetzen geschah.“ Alternative mit Aufwand klein:
  speichern an jedem Monatsersten, also an einem Ruhepunkt (AR-19).
- [x] CHK012 Was tut das Ortsbild in der Bedienleiste? Der Baustein sagt „Ein Klick öffnet den
  Stadtplan“; in 010 gibt es den nur im Büro. [Gap, research.md R10]
  → Vorschlag: In 010 zeigt das Ortsbild nur den Laden mit Tooltip (Anschrift), ohne Klick; das
  kommt als Frage 6 in R14.
- [x] CHK013 Ist Rechtsklick auf anklickbare Stellen im Büro geregelt? Der Style-Guide sagt
  „Rechtsklick zeigt Infos, statt zu handeln“; FR-001a nennt nur Überfahren und Tastatur. [Gap,
  Spec §FR-001a]
  → Vorschlag: FR-001a: „Rechtsklick zeigt die Beschriftung, löst aber nichts aus“, wie im Menü.
- [x] CHK014 In welcher Reihenfolge wählt die Tastatur im Büro? FR-001a sagt „der Reihe nach“.
  [Clarity, Spec §FR-001a]
  → Vorschlag: im Vertrag: Stadtplan, Schreibtisch, Makler; auf dem Stadtplan die Markierungen in
  der Reihenfolge der Läden, dann „Zurück“.
- [x] CHK015 Wie bleibt die game_bible mit den erzeugten Daten im Gleichschritt? FR-008 sagt, Klaus
  ändert dort Mieten und Texte, aber nicht, wann der Importer läuft. Vergisst man ihn, spielt das
  Spiel mit alten Daten. [Gap, Spec §FR-008, contracts/game_bible.md]
  → Vorschlag: `tools/build/baue_alles.sh` ruft vor dem Bau `importiere.py --pruefen` und bricht bei
  einem Unterschied ab; im Vertrag festhalten. Ändert Klaus die game_bible, lässt Claude den
  Importer laufen.
- [x] CHK016 Was zeigt das Spiel am 31.12.1999 nach dem Anhalten? FR-027 sagt nur, die Uhr hält an.
  [Coverage, Spec §FR-027]
  → Vorschlag: nichts weiter; der Tooltip der Uhr nennt den Grund. Spielende und Bilanz kommen mit
  11-05. Als Annahme festhalten.

## Messbarkeit

- [x] CHK017 Wie wird SC-001 („höchstens 60 Sekunden“) gemessen? [Measurability, Spec §SC-001]
  → Vorschlag: SC-001 nennt den Weg: Selbsttest-Ablauf `ladenwahl` misst die Zeit von der Gradwahl
  bis zum Spielbildschirm mit festen Eingaben; die 0,2 s je Blatt misst ein Test.
- [x] CHK018 Ist SC-002 („auf Schwer mindestens einer zu teuer“) nach der Entscheidung zum
  Kapitalnachweis noch richtig formuliert? FR-021 sagt jetzt genau: die Fußgängerzone. [Clarity,
  Spec §SC-002]
  → Vorschlag: SC-002: „Auf Schwer ist genau die Fußgängerzone grau, auf Mittel und Leicht keiner;
  geprüft mit den Daten aus der game_bible.“

## Abhängigkeiten und Annahmen

- [x] CHK019 Ist festgehalten, dass Phase 6 und 7 auf den Style-Guide warten? Die Spec nennt den
  Style-Guide in der Annahme „Schauplatz“, aber nicht, was davon abhängt. [Dependency, Spec
  §Annahmen]
  → Vorschlag: reicht im Plan (Phase 4 vor 5 bis 7); in der Spec nichts ändern.
- [x] CHK020 Ist geklärt, woher das Referenzbild des Ladenbesitzers kommt? FR-001c verlangt es,
  das Figurenblatt F-01 nennt der Style-Guide, aber nicht seinen Pfad. [Gap, Spec §FR-001c]
  → Vorschlag: In Phase 2 sucht Claude F-01 im Prompt-Log und unter `docs/art/`; fehlt die Datei,
  bleibt `bild_referenz` leer mit Vermerk, und Klaus entscheidet, ob F-01 nachgeholt wird.

## Aus der Prüfung des Vertrags

Text-, Stil- und Architektur-Prüfer haben am 2026-10-29 Spec, Plan und Verträge gelesen. Claude hat
jeden Befund nachgeprüft; hier stehen die bestätigten, zusammengelegt, wo zwei Prüfer dasselbe
fanden. Verworfen wurde keiner. Doppelt zu Claudes Punkten: Stil A1 = CHK006, Stil A8 = CHK013,
Text B5 = CHK001.

### Texte

- [x] CHK021 Passt der Hinweis zu „Anmelden“ in zwei Zeilen? Mit 24 Zeichen Name und
  „14.400,00 DM“ sind es rund 96 Zeichen, etwa vier Zeilen. [Text B1, Stil A12, hoch,
  contracts/ladenwahl.md]
  → Vorschlag: „Meldet {Name} an. Die Kaution geht ab.“ Den Betrag nennt der Mietvertrag.
- [x] CHK022 Stehen alle Beträge in Spieltexten mit zwei Nachkommastellen? Das Beispiel im
  Überblick sagt „43.200 DM“ und „30.000 DM“. [Text B2, Spec §Überblick]
  → Vorschlag: „43.200,00 DM“, „30.000,00 DM“, ebenso „4.320,00 DM“.
- [x] CHK023 Sagt der Grund für ein unerlaubtes Zeichen, was erlaubt ist? „Dieses Zeichen nimmt das
  Gewerbeamt nicht.“ ist ein Witz an einer Stelle der Bedienung. [Text B3, data-model.md §ShopName]
  → Vorschlag: „Nur Buchstaben, Ziffern und einfache Satzzeichen.“
- [x] CHK024 Nennen Tooltips Funktion und Tastenkürzel? „{n} Tage je Sekunde.“, „Stadtplan“,
  „{Name des Maklers}“, „{Viertel}, {Miete} im Monat“ und „{Anschrift}“ nennen nur eine Angabe.
  [Text B4, Stil A7, contracts/ladenwahl.md, contracts/spielbildschirm.md]
  → Vorschlag: Tooltips als Handlung mit Taste, etwa „Stadtplan ansehen.“, „Exposé öffnen:
  Wohngebiet, 1.440,00 DM im Monat.“, „Mit {Makler} reden.“; die Tasten erst nach Phase 4.
- [x] CHK025 Fehlen Wortlaute? Keine für die Knöpfe zum Blättern (FR-014), den Hotspot
  Schreibtisch, die Tooltips zu „Zurück“ auf den Blättern und den Vermerk als Stempel. [Text,
  Unsicher, Gap]
  → Vorschlag: im Vertrag ergänzen: „Voriges Exposé“, „Nächstes Exposé“ (Pfeiltasten),
  „Schreibtisch“ → „Papiere ansehen.“, „Zurück“ → „Zurück zum Stadtplan. Esc geht auch.“ je nach
  Blatt; Stempel „ZU TEUER“ in Versalien, darunter der Satz des Vermerks.
- [x] CHK026 Was gilt für Ladennamen im Satz, die klein beginnen oder auf „!“ oder „?“ enden, etwa
  „Weiter mit Hallo!, Schwer, am …“? [Text, Lücke, data-model.md §ShopName]
  → Vorschlag: „!“ und „?“ fallen aus `ALLOWED`; Kleinschreibung bleibt erlaubt, der Name gilt als
  Name.
- [x] CHK027 Passen die Sätze aus Feature 004 mit einem 24 Zeichen langen Namen noch? Sie sind für
  „Spiel 9999“ bemessen: `HINT_LEAVE`, `HINT_CONTINUE`, `HINT_CONFIRM_*` und „{Name} löschen“ auf
  der Anzeige des Communicators. [Text, Unsicher; Stil A1]
  → Vorschlag: `test_title_texts.gd` misst mit dem breitesten erlaubten Namen; passt es nicht, sinkt
  `ShopName.MAX_LENGTH`, nicht die Schrift (R7).

### Darstellung

- [x] CHK028 Wie kommt das Ortsbild (120 × 56 Oberflächenpixel, also 60 × 28 Bildpixel) aus dem
  Foto mit 312 × 144? Kein ganzzahliger Faktor führt dahin. [Stil A2, hoch, research.md R11]
  → Vorschlag: je Laden ein eigener Ausschnitt `<id>_ort.png` mit 60 × 28 Bildpixeln, ohne
  Skalierung aus dem Foto geschnitten; Größe in data-model.md. Die Größe des Fotos auf dem Exposé
  regelt Phase 4 (R14, Frage 5).
- [x] CHK029 Welche Schrift hat das Kleingedruckte, wenn `text` mit 10 schon die kleinste ist?
  [Stil A3, hoch, Spec §FR-011]
  → Vorschlag: Fließtext der Blätter in `menue` (12), Kleingedrucktes in `text` (10); in FR-011
  „kleiner als der Text des Blatts“, die Schriften im Style-Guide.
- [x] CHK030 Darf eine graue Markierung das Exposé öffnen, wenn „gedämpft“ im Style-Guide „löst
  nichts aus“ heißt? Grau ist zudem keine Farbe des Guides. [Stil A4, Spec §FR-010, §FR-013]
  → Vorschlag: Klaus' Entscheidung bleibt (das Exposé sagt, warum). Der Style-Guide bekommt für
  die Markierung einen eigenen Zustand „nicht mietbar“, der kein „gedämpft“ ist, mit Farbe aus der
  Palette (Frage für Phase 4).
- [x] CHK031 Wer zeigt Gründe an gesperrten Knöpfen? Ein Knopf „Aus“ reagiert nicht beim
  Überfahren, der Vertrag gibt der Uhr am Ende aber einen Tooltip. [Stil A5,
  contracts/spielbildschirm.md]
  → Vorschlag: Die Uhr ist am Ende aus, ohne Tooltip; das Ende sieht man am Datum. „Anmelden“ bleibt
  aus, der Grund steht als Text des Formulars unter dem Feld (CHK033).
- [x] CHK032 Hinweis oder Tooltip? Der Hinweis ersetzt den Tooltip nur bei einem Knopf, der allein
  steht; auf den Blättern und im neuen Spielbildschirm steht keiner allein. [Stil A6]
  → Vorschlag: Im Büro und im Spielbildschirm Tooltips; „Zum Hauptmenü“ verliert den Hinweis neben
  sich und bekommt einen Tooltip mit demselben Satz. Der Vertrag sagt „Tooltip“ statt „Hinweis“.
- [x] CHK033 Wo stehen Grund und Meldung auf der Gewerbeanmeldung? Der Grund soll unter dem Feld
  stehen, Hinweis und Meldung stehen laut Style-Guide links neben ihrer Stelle. [Stil A9]
  → Vorschlag: Der Grund ist Text des Formulars unter dem Feld, kein Hinweis; die Meldung
  „Speichern ging nicht …“ steht als Baustein Meldung links neben „Anmelden“. Im Style-Guide beim
  Blatt festhalten.
- [x] CHK034 Blinkt die Anzeige bei 7 Tagen je Sekunde dauernd? Der Baustein Anzeige lässt jeden
  geänderten Wert 200 ms blinken. [Stil A10]
  → Vorschlag: Bei laufender Uhr blinkt das Datum nicht; der Kontostand blinkt bei jeder Buchung.
  Im Baustein Anzeige ergänzen.
- [x] CHK035 Ist die Leertaste doppelt belegt? Sie hält die Uhr an, löst aber auch den Knopf mit
  Fokus aus. [Stil A11, contracts/spielbildschirm.md]
  → Vorschlag: Die Knöpfe des Spielbildschirms nehmen keinen Fokus durch die Leertaste; die
  Leertaste gehört dort immer der Uhr. Frage für Phase 4.
- [x] CHK036 Platzhalter mit Beschriftung im PNG widersprechen „kein Text im Szenenbild“. [Stil A13,
  niedrig, research.md R11]
  → Vorschlag: In R11 als gewollte Übergangslösung festhalten; Phase 8 ersetzt alle, ein Test prüft
  vor der Gesamtabnahme, dass keiner mehr da ist.
- [x] CHK037 Fehlen weitere Fragen an den Style-Guide? R14 nennt fünf; die Prüfer fanden mehr.
  [Stil, Lücken; Text, Lücken]
  → Vorschlag: R14 um diese ergänzen: Ortsbild ohne Klick (CHK012); Lage von „Zum Hauptmenü“
  neben Rahmen und Leiste; Größe von `anzeige-ziffern` und das fehlende Token `zeile-klein`;
  Übergang beim Heranholen und Blättern; Preise im Exposé in `kassenrot`; Hover und Fokus eines
  Hotspots auf einem Bild; Markierung wie Menü oder wie Knopf; Blatt mit oder ohne Lochrand,
  Schrift der Papiere; Stempel ungedreht und seine Farbe; Unterschrift; Eingabefeld mit
  Schreibmarke und Fehler; Sprechblase und Porträt in der Leiste; Ton der Papiere der Spielwelt;
  Minus als „-“ oder „−“ (die Schriften haben nicht jedes Zeichen).

### Aufbau

- [x] CHK038 Braucht die Formatversion 1 trotz zweier neuer Pflichtteile eine Ausnahme von AR-13?
  Die Version unterscheidet die Formate nicht mehr, und ein alter Stand erfährt nicht, dass er alt
  ist. [Architektur B1, mittel, research.md R5, plan.md]
  → Vorschlag: unter „Ausnahmen vom Leitfaden“ eintragen: AR-13, `SaveGame.FORMAT`, „vor der
  ersten Herausgabe keine Rücksicht auf alte Spielstände (Klaus, 2026-10-29)“. Klaus gibt sie mit
  dieser Checkliste frei.
- [x] CHK039 Nutzt der Spielbildschirm die Uhr über eine Naht? Er liest `GameClock.date` und stellt
  Pause und Tempo, hat aber nur die Naht `session`. [Architektur B2, AR-12]
  → Vorschlag: `GameScreen.clock` mit Rückfall auf `GameClock`; das Tempo setzt eine Methode
  `GameClock.set_speed()`, nicht das Feld.
- [x] CHK040 Stehen Mietbeginn und mietfreier Monat an einer Stelle? `LEASE_START_DAY = 0`
  wiederholt `TimelineRun.FIRST_DAY`, und `opened()` setzt `rent_paid_through = 0` neben
  `RENT_FREE_MONTHS`. [Architektur B3, AR-04]
  → Vorschlag: `LEASE_START_DAY` aus `TimelineRun.FIRST_DAY`, `rent_paid_through` beim Öffnen aus
  `RENT_FREE_MONTHS` berechnet.
- [x] CHK041 Kennt der Importer Werte, die auch Godot kennt (Anlässe des Maklers, Stufen,
  Bildpfade), ohne die Stelle zu nennen? [Architektur B4, Leitfaden „Werkzeuge“]
  → Vorschlag: Anlässe und Stufen als Konstanten an einer Stelle in Godot (`FigureData.OCCASIONS`,
  `ShopOffer.Level`), Bildpfade als Funktion in `ShopOffer`; der Kopf des Importers nennt sie.
- [x] CHK042 Misst `test_architektur.gd` die neuen Kerne? `KERNORDNER` enthält nur
  `core/timeline/` und `core/save/`. [Architektur, Hinweis, AR-01]
  → Vorschlag: `res://core/shop/` dazu, als Aufgabe in Phase 3.
- [x] CHK043 Wo zählt der „nächste Satz der Reihe nach“? In `FigureData` verstieße er gegen AR-04,
  weil geladene Resources nur zum Lesen da sind. [Architektur, Hinweis, research.md R9]
  → Vorschlag: im Büro (Hülle) als Zähler je Anlass; ein Kern ist dafür nicht nötig, weil nichts
  davon gespeichert wird.
- [x] CHK044 Wer schlägt einen Laden nach seiner ID nach? Spielstand und Spielbildschirm sollen
  beide `res://data/laeden/<id>.tres` laden. [Architektur, Hinweis, AR-04]
  → Vorschlag: eine Funktion `ShopOffer.load_by_id(id)` in `src/core/shop/`; beide nutzen sie.
- [x] CHK045 Was bekommen Blätter und Leiste hineingereicht? [Architektur, Hinweis, AR-02, AR-05]
  → Vorschlag: im Vertrag: Das Büro reicht den Blättern `ShopOpening` hinein, nie über
  `GameSession`; die Leiste bekommt Bild, Texte und Zustand der Uhr und meldet per Signal, ohne
  `GameClock` oder `ShopLease` zu kennen.
- [x] CHK046 Was tut `begin_opening()`, während ein Spiel läuft, und gibt es das Konto doppelt?
  [Architektur, Hinweis, AR-11]
  → Vorschlag: `begin_opening()` gibt bei laufendem Spiel `ERR_ALREADY_IN_USE`. Das Konto lebt nur
  in `GameSession.account`; `SaveGame` hält nur die Werte für die Datei und bekommt sie beim
  Speichern, wie Tag und Eingriffe.
- [x] CHK047 Rundet der Importer DM in Pfennig sauber? Aus YAML kann ein Kommawert kommen.
  [Architektur, Hinweis, contracts/game_bible.md]
  → Vorschlag: Der Importer lehnt Beträge ab, die keine ganzen Pfennige ergeben, und rechnet mit
  Ganzzahlen.

### Lücken im Leitfaden (für `docs/offene-punkte.md`)

- AR-08/AR-09: Ist die Wahl des Ladens ein Eingriff an Tag 0 oder ein eigener Pflichtteil des
  Spielstands? Empfehlung: eigener Pflichtteil; ein Eingriff ändert den Verlauf der Zeitleiste, die
  Ladenwahl tut das nicht (R15).
- AR-19 gegen AR-11: Ein Weg, den der Spieler steuert und auf dem er zurückgehen kann, ist kein
  linearer Ablauf. Empfehlung: AR-19 gilt für Abläufe, die das Spiel abspielt; vom Spieler
  gesteuerte Wege sind Zustände nach AR-11.
- AR-20: Zählen feste Sätze je Anlass als Dialog? Empfehlung: ja, als einfachster Fall; die Wahl
  des Anlasses darf in der Hülle liegen.
- AR-13: Dürfen alte Spielstände vor der ersten Herausgabe anders behandelt werden? Empfehlung:
  ja, als Satz in AR-13 statt als Ausnahme je Feature.
