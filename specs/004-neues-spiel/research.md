# Recherche: Neues Spiel starten

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md).

Wer entschieden hat, steht an jeder Entscheidung. „Claude, 2026-10-26“ heißt: eigene Festlegung,
eingetragen in `docs/offene-punkte.md`, Abschnitt „Feature 004, Plan“; Klaus kann sie bei der
Checkliste oder jeder Abnahme ändern.

Gemessen ist mit den Schriften des Spiels in Godot 4.7.2: Ark Pixel 12 für Einträge, Ark Pixel 10
für Hinweise, Doto für Kopfzeilen. Klaus' Fenster mit 1920 × 925 bekommt von `GameWindow` den Faktor
2, also 1280 × 720 mit schwarzen Rändern; maßgeblich ist damit allein das Oberflächenraster mit
640 × 360. Alle Maße unten sind Oberflächenpixel.

## R1 Ein Spielstand ist eine JSON-Datei je Spiel

**Entscheidung:** Jeder Spielstand ist eine Datei `spiel_<N>.json` im Ordner
`user://spielstaende/`, etwa `spiel_2.json` für „Spiel 2“. Geschrieben wird kanonisch wie Katalog
und Proben: Schlüssel alphabetisch, Tabs, ein Zeilenumbruch am Ende.

**Grund:** Der Katalog und die Proben der Werkstatt sind schon JSON nach denselben Regeln; Lesen,
Prüfen und Fehlermeldungen kennt das Projekt. Klaus kann einen Spielstand im Texteditor öffnen,
wenn etwas klemmt. Die Nummer im Dateinamen macht Namen und Datei eindeutig: Ein neues Spiel kann
keine vorhandene Datei treffen (FR-009).

**Verworfen:**
- `ConfigFile` oder `var_to_str()`: Godot-eigene Formate, schlechter lesbar, und die Prüfung mit
  verständlichen Gründen müsste neu entstehen.
- `store_var()` als Binärdatei: nicht lesbar, und ein Fehler zeigt sich nur als „kaputt“ ohne
  Grund (FR-013 verlangt den Grund).
- Eine Resource (`.tres`) mit `ResourceSaver`: Beim Laden kann eine Resource Skripte ausführen; eine
  von außen veränderte Datei wäre ein Einfallstor. Außerdem hängt das Format an Klassennamen.
- Name als Dateiname („Spiel 2.json“): Leerzeichen und spätere Ladennamen mit Umlauten machen
  Dateinamen unsicher.

## R2 Inhalt: alles, was den Fahrplan festlegt, dazu eine Kopie des Katalogs

**Entscheidung:** Der Spielstand hält Formatversion, Nummer, Name, Grad, Seed, Spieldatum, angelegt
und zuletzt gespielt, die Spielversion, den Katalog des Spiels und das Eingriffsprotokoll
(FR-007). Der Katalog steht unter `"catalog"` genau so, wie `EventCatalog.to_dict()` ihn liefert,
also mit Kategorien, Ereignissen und den Profilen der Grade (FR-022). Gespeichert wird der Katalog,
mit dem das Spiel lief: der geprüfte Katalog der Zeitleiste ohne die fehlerhaften Ereignisse.

**Grund:** Seed, Grad, Katalog und Eingriffe ergeben zusammen genau einen Fahrplan (Feature 002, R5;
Feature 003, R7). Der Fahrplan selbst muss also nicht in die Datei: Beim Fortsetzen baut ihn der
Lauf neu auf und spielt ihn still bis zum Spieldatum ab, wie die Proben der Werkstatt (R5).
Beispiel: Klaus beginnt „Spiel 2“ auf Schwer mit Seed 4711. Danach erhöht er in der Werkstatt die
Chance von „Konkurrent eröffnet“. Spiel 2 läuft mit seiner Kopie weiter, als wäre nichts geschehen;
erst „Spiel 3“ bekommt die neue Chance.

Den geprüften Katalog statt der Datei zu speichern, hat einen Grund: Würden spätere Versionen die
Prüfregeln verschärfen, fiele beim Fortsetzen vielleicht ein Ereignis weg, das vorher galt, und der
Fahrplan änderte sich. Beim Fortsetzen wird die Kopie trotzdem geprüft; was dann fehlerhaft ist,
fällt weg wie beim Katalog des Spiels (Edge Case „fehlerhafter eigener Katalog“, Feature 002,
FR-049).

**Verworfen:**
- Den Fahrplan speichern: groß, und er müsste mit jeder Änderung am Lauf neu gelesen werden können.
  Seed und Eingriffe reichen.
- Nur einen Verweis auf den Katalog, etwa eine Prüfsumme: Ein geänderter Katalog ließe das Spiel
  dann nicht mehr fortsetzen. Klaus hat sich für die Kopie entschieden (Spec, Clarifications).
- Den Katalog in eine zweite Datei je Spielstand: Zwei Dateien müssten gemeinsam und sicher
  geschrieben werden (R3). Eine Datei ist einfacher; mit dem heutigen Katalog (rund 20 KB) ist sie
  rund 25 KB groß.

## R3 Sicher speichern: neu schreiben, prüfen, dann tauschen

**Entscheidung:** Gespeichert wird in fünf Schritten, alle im Ordner der Spielstände:
1. eine übrig gebliebene `spiel_2.json.neu` löschen, dann den neuen Stand vollständig nach
   `spiel_2.json.neu` schreiben und schließen;
2. `spiel_2.json.neu` wieder lesen und prüfen: Der Text ist Zeichen für Zeichen gleich
   `to_json()`. Sonst Abbruch mit Meldung, und nichts am alten Stand ist berührt;
3. eine übrig gebliebene `spiel_2.json.alt` löschen, dann den alten Stand `spiel_2.json` in
   `spiel_2.json.alt` umbenennen, falls es ihn gibt;
4. `spiel_2.json.neu` in `spiel_2.json` umbenennen;
5. `spiel_2.json.alt` löschen.

Schlägt das Löschen in Schritt 1 oder 3 fehl, bricht das Speichern ab, wie bei jedem anderen
Schritt. Ein Ordner an der Stelle einer Zwischendatei lässt sich nur löschen, wenn er leer ist; die
Tests nehmen deshalb einen Ordner mit Inhalt (Analyse, C5).

**Lesen:** Je Nummer gilt (Analyse, B2):
- Ist `spiel_2.json` fortsetzbar oder **zu neu**, gilt sie. Ein zu neuer Spielstand fällt nie auf
  eine ältere Zwischendatei zurück; sonst überschriebe das nächste Speichern den neueren Stand.
- Ist `spiel_2.json` beschädigt oder fehlt sie, gilt die erste fortsetzbare von `spiel_2.json.neu`
  und `spiel_2.json.alt`. Das ist der Fall nach einem Absturz in Schritt 3 bis 5; das nächste
  Speichern schreibt dann eine neue `spiel_2.json`.
- Ist keine fortsetzbar, gilt der Zustand von `spiel_2.json`, ohne sie der von `.alt`. Eine allein
  stehende `.neu`, die nicht fortsetzbar ist, ergibt keinen Spielstand (data-model.md).

„Lesbar“ heißt in diesem Abschnitt immer „fortsetzbar“ im Sinn von R10.

**Grund:** FR-011 und die Edge Cases verlangen: Ein Abbruch mittendrin lässt den vorigen Stand
lesbar, und es entsteht nie eine halb geschriebene Datei an seiner Stelle. Was jeder Abbruch
hinterlässt:
- in Schritt 1 oder 2, etwa weil der Datenträger voll ist: `spiel_2.json` ist unberührt, die halbe
  `.neu` ist unlesbar und wird übergangen;
- zwischen 3 und 4: Es gibt keine `spiel_2.json`, aber die geprüfte `.neu`; sie wird gelesen;
- nach 4: Die neue `spiel_2.json` gilt. Hat ein Stromausfall sie noch nicht ganz auf die Platte
  gebracht, ist sie unlesbar, und `.alt` liefert den vorigen Stand, solange Schritt 5 nicht lief.

Der Tausch über `.alt` vermeidet, dass `rename` eine vorhandene Datei ersetzen muss. Ob Godot das
unter Windows in einem Zug tut, hängt von der Version ab; so ist es egal. Godot bietet kein
`fsync`; Schritt 2 und die `.alt` gleichen das aus, so gut es ohne geht.

**Verworfen:**
- Direkt in `spiel_2.json` schreiben: Ein Abbruch hinterließe genau die halbe Datei, die die Spec
  ausschließt.
- Nur `.neu` und dann `rename` über die alte Datei: Unter Windows löscht Godot je nach Version
  erst das Ziel und benennt dann um; dazwischen gäbe es keinen lesbaren Stand. Gegen den
  Stromausfall nach dem Umbenennen hilft es auch nicht.
- Eine feste Sicherungskopie je Spielstand, die stehen bleibt: doppelter Platz, und die Liste
  müsste erklären, welche gilt.

## R4 Name und Nummer

**Entscheidung:** Die Nummer kommt aus dem Dateinamen; der Name steht zusätzlich in der Datei,
„Spiel 2“. Die nächste Nummer ist die größte Nummer unter allen Dateien des Ordners, die zu einem
Spielstand gehören, plus 1, auch unter beschädigten, zu neuen und übrig gebliebenen `.neu` oder
`.alt`. Ohne solche Dateien ist es 1 (FR-009).

Ein neues Spiel schreibt nur unter einer Nummer, zu der es noch keine Datei gibt; findet es dort
eine, nimmt es die nächste. So weicht ein zweites Fenster einer schon angelegten Nummer aus
(Checkliste, CHK002).

Das ist eine Prüfung vor dem Schreiben, kein atomarer Vorgang: Legen zwei Fenster im selben
Augenblick ein Spiel an, können beide die Prüfung bestehen. Das Ausweichen verringert den
Zusammenstoß, schließt ihn aber nicht aus; zwei Fenster gleichzeitig sind kein Fall für dieses
Feature (Analyse, F10).

**Grund:** Zählen auch beschädigte und zu neue Spielstände mit, überschreibt ein neues Spiel nie
einen davon (FR-013). Der Name in der Datei ist der, den die Liste zeigt: Hat der Laden später
einen eigenen Namen (05 Standort), steht dort dieser, und die Nummer bleibt die Kennung.

**Verworfen:**
- Die kleinste freie Nummer: Nach dem Löschen von „Spiel 2“ hieße das nächste wieder „Spiel 2“,
  und wer sich an die Nummer erinnert, verwechselt die beiden.
- Ein Zähler in einer eigenen Datei: noch eine Datei, die stimmen muss; der Ordner zeigt die
  Nummern ohnehin.

## R5 Eingriffe teilen sich Spielstand und Probe

**Entscheidung:** Das Nachspielen des Eingriffsprotokolls und die Umrechnung der Tage für die Datei
wandern aus `WhatIfProbe` in den Kern:
- `TimelineRun.replay(records, until_day)` spielt die Einträge nach `in_replay_order()` nach und
  dann bis `until_day`; zurück kommen die Einträge, die sich nicht anwenden ließen, mit Grund.
- `InterventionFile` (neu, `src/core/timeline/intervention_file.gd`) rechnet Tage in Einträgen um,
  Tagesindex in „JJJJ-MM-TT“ und zurück, und erkennt ein falsches Datum. Mit ihm ziehen die Hilfen
  um, die dafür nötig sind, `is_whole_number()` und `shown()`; `WhatIfProbe` ruft auch sie dort
  auf, statt eigene zu behalten (Analyse, C12).

`WhatIfProbe.build_run()` und `read_file()`/`write_file()` rufen diese Hilfen auf. Was die Werkstatt
zeigt und schreibt, bleibt Zeichen für Zeichen gleich; die Tests der Proben laufen unverändert.

**Grund:** Die Werkstatt liegt unter `tools/` und wird nicht exportiert (`export_presets.cfg`,
`exclude_filter`). Das Spiel kann `WhatIfProbe` also nicht benutzen. Eine Kopie der Regeln im Spiel
liefe auseinander, sobald eine Seite sich ändert; dieselbe Regel steht dann an einer Stelle, wie
schon `in_replay_order()` (Spec, Annahmen: „der Plan prüft, was sich teilen lässt“).

**Verworfen:**
- Die Regeln in den Spielstand kopieren: zwei Stellen für dasselbe.
- `WhatIfProbe` nach `core/` verschieben: Die Probe ist ein Werkzeug mit Namen, Ordner im Projekt
  und Liste nach Name; im Spiel hat sie nichts zu suchen.

## R6 Die Zeitleiste startet nicht mehr von selbst

**Entscheidung:** `Timeline._ready()` liest weiter den Katalog und hängt sich an die Uhr, ruft aber
`start_game()` nicht mehr auf. Ein Spiel beginnt nur über `GameSession` (R7) und endet mit
`Timeline.stop_game()`. Neu sind:
- `Timeline.resume_game(game_catalog, seed, difficulty, interventions, day)`: prüft die Kopie des
  Katalogs, legt den Lauf darauf an, spielt die Eingriffe nach und den Lauf **still** bis `day`;
  Signale gibt es erst für die Tage danach.
- `Timeline.stop_game()`: Danach läuft kein Spiel mehr.
- `GameClock.set_date(date)`: setzt die Uhr ohne Signale auf ein Datum, etwa beim Fortsetzen auf
  den 14.03.1986.

**Grund:** FR-003: Ohne begonnenes Spiel läuft keins. Die Tage vor dem Spieldatum sind beim
Fortsetzen schon geschehen; wer sich später anhängt, etwa die Wirtschaft, holt sich ihren Stand aus
dem Spielstand und fragt laufende Termine mit `running_entries()` ab (Feature 002, R12). Meldete
die Zeitleiste die Vergangenheit noch einmal, zahlte der Laden die Miete von 1985 ein zweites Mal.

Den Katalog liest die Zeitleiste wie bisher einmal beim Start der App; ein neues Spiel nimmt ihn
von dort. Ändert Klaus ihn in der Werkstatt, gilt das für neue Spiele, sobald das Spiel neu
gestartet ist (Claude, 2026-10-26). Den Katalog vor jedem neuen Spiel neu zu lesen, brächte nur
etwas, solange Spiel und Werkstatt gleichzeitig offen sind.

Die Uhr bleibt in diesem Feature stehen (FR-019): `GameClock.paused` ist schon `true` und wird nie
umgeschaltet. Ein Spiel bleibt also an seinem Datum.

**Verworfen:**
- Beim Fortsetzen alle vergangenen Meldungen senden: siehe Miete.
- Den Lauf selbst speichern: R2.
- Die Uhr beim Fortsetzen Tag für Tag vorspulen: Sie sendete jeden Tag ein Signal, und die
  Zeitleiste meldete alles noch einmal.

## R7 Das laufende Spiel: Autoload `GameSession`

**Entscheidung:** Ein neues Autoload `GameSession` hält das laufende Spiel: den Spielstand, zu dem
es gehört, und die Wege hinein und hinaus. `start_new()`, `resume()`, `save()` und `leave()`
setzen Uhr und Zeitleiste und schreiben über `SaveStore` (R3). Es kennt Uhr, Zeitleiste und Ordner
über Felder, die Tests vorher setzen, wie `Timeline.clock` heute.

Beim Anlegen würfelt `GameSession` den Seed selbst, schreibt erst den Spielstand und ruft dann
`Timeline.start_game(seed, difficulty)` auf (Analyse, C6). Scheitert das Speichern, hat die
Zeitleiste so keine Meldung für ein Spiel gesendet, das es nie gab. Die Meldungen des 01.01.1985
kommen damit noch während der Titel zu sehen ist; Abnehmer, die erst mit dem Spielbildschirm
entstehen, fragen laufende Termine mit `running_entries()` ab (Feature 002, R12). Gewürfelt wird mit
einem eigenen `RandomNumberGenerator` als Feld, den Tests mit festem Seed setzen (Analyse, C4).

**Grund:** Das Spiel wechselt zwischen zwei Szenen, Titel und Spielbildschirm. Was das laufende
Spiel ist, muss den Wechsel überleben; das tut ein Autoload. Außerdem muss das Spiel beim Schließen
des Fensters speichern, egal welche Szene gerade läuft (R8). Die Szenen bleiben schlank: Sie
fragen `GameSession` und wechseln nur die Szene.

**Verworfen:**
- Den Spielstand als Parameter an die nächste Szene geben: Godot hat dafür keinen Weg ohne
  globales Objekt, und das Schließen des Fensters bliebe Sache jeder Szene.
- Alles in `Timeline`: Die Zeitleiste ist der Kern der Ereignisse (Verfassung,
  „Technische Rahmenbedingungen“). Spielstände, Dateien und Namen gehören nicht hinein.

## R8 Speichern beim Beenden

**Entscheidung:** Solange ein Spiel läuft, setzt `GameSession` `get_tree().auto_accept_quit` auf
`false` und fängt `NOTIFICATION_WM_CLOSE_REQUEST` ab. Diese Benachrichtigung kommt beim Schließen
des Fensters und unter macOS bei Cmd+Q (so schon in der Werkstatt, Feature 002, R15). Sie speichert
und beendet dann. Scheitert das Speichern, bleibt das Fenster offen, und die Meldung sagt, dass ein
zweites Schließen ohne Speichern beendet (Claude, 2026-10-26). Ohne laufendes Spiel bleibt
`auto_accept_quit` unberührt; „Beenden“ im Hauptmenü beendet wie bisher.

**Grund:** FR-010 verlangt Speichern auch bei Cmd+Q und beim Schließen. FR-011 verlangt, dass der
Spieler ein Scheitern erfährt und das Spiel weiterläuft. Ohne den zweiten Weg käme er bei vollem
Datenträger nur mit „Sofort beenden“ aus dem Spiel. Verloren geht dabei nichts außer dem, was seit
dem letzten Speichern geschah; in diesem Feature ist das nichts, denn die Uhr steht.

**Verworfen:**
- Bei Fehler trotzdem beenden: Der Spieler erführe es nicht (FR-011).
- Eine Rückfrage „Ohne Speichern beenden?“: ein Baustein mehr für einen seltenen Fall. Die Meldung
  sagt dasselbe.

## R9 Wann gespeichert wird

**Entscheidung:** Gespeichert wird beim Anlegen, beim Fortsetzen, beim Verlassen über „Zum
Hauptmenü“ und beim Schließen der App (FR-010). Das Speichern beim Fortsetzen ist eine eigene
Festlegung (Claude, 2026-10-26).

**Grund:** Fortsetzen setzt „zuletzt gespielt“ auf jetzt (FR-016) und bringt einen älteren
Spielstand in die aktuelle Formatversion (FR-014). Stürzt die App danach ab, stimmt die Ordnung der
Liste trotzdem, und „Weiterspielen“ nimmt das richtige Spiel.

**Verworfen:** „zuletzt gespielt“ erst beim Verlassen setzen: Nach einem Absturz stünde das Spiel
in der Liste weiter unten, obwohl es zuletzt gespielt wurde.

## R10 Wann ein Spielstand nicht fortsetzbar ist

**Entscheidung:** Die Liste liest jede Datei ganz und prüft sie. Ein Spielstand ist:
- **zu neu**, wenn `"format"` eine ganze Zahl größer als 1 ist; weiter wird dann nichts geprüft;
- **beschädigt**, wenn die Datei kein gültiges JSON-Objekt ist, `"format"` fehlt oder kleiner als 1
  ist, ein Pflichtfeld fehlt oder den falschen Typ hat (alle Schlüssel aus data-model.md,
  „SaveGame“; ein leerer Name zählt wie ein fehlender), der Grad unbekannt ist, der Seed außerhalb
  von 0 bis 2.147.483.647 liegt, das Spieldatum außerhalb vom 01.01.1985 bis 31.12.1999, ein
  Zeitpunkt nicht lesbar ist, ein Eingriff ein falsches Datum hat oder sich der Katalog gar nicht
  lesen lässt;
- sonst **fortsetzbar**. Ereignisse mit Fehlern im Katalog machen ihn nicht beschädigt; sie fallen
  beim Fortsetzen weg (R2).

Jeder Grund ist ein kurzer deutscher Satz für den Hinweis, höchstens zwei Zeilen, ohne Englisch der
Engine und ohne Werte aus der Datei, etwa „Der Schwierigkeitsgrad ist unbekannt.“ Ein Wert aus der
Datei könnte beliebig lang sein und den Hinweis sprengen (Analyse, B4). Die genaue Stelle und der
Wert, etwa die Zeile im JSON oder „extrem“, kommen zusätzlich mit `push_warning()` ins Protokoll.

**Grund:** FR-013 und die Edge Cases. Ein Eingriff mit falschem Datum ist anders als bei Proben ein
Schaden: Die Probe ist ein Werkzeug, das Klaus von Hand bearbeitet; einen Spielstand schreibt nur
das Spiel, und ein fehlender Eingriff änderte das Spiel still. Der Text-Prüfer fand im Probelauf
englische Fehlertexte der Engine in deutschen Sätzen (`docs/offene-punkte.md`); deshalb steht hier
keiner.

**Verworfen:**
- Nur die Kopfdaten lesen, den Katalog erst beim Fortsetzen: Dann erschiene ein Spielstand mit
  kaputtem Katalog erst als fortsetzbar und scheiterte beim Klick. Gemessen wird trotzdem (SC-002,
  R16). Reicht die Sekunde nicht, prüft die Liste vom Katalog nur, ob er ein Objekt mit Format 1
  ist, und den Rest erst das Fortsetzen; das entscheidet die Messung in Phase 2.
- Falsche Eingriffe weglassen wie bei Proben: siehe oben.

## R11 Die Blätter auf dem Titelbildschirm

**Entscheidung:** Gradwahl, Liste und Rückfrage sind Blätter Endlospapier an der Stelle des
Hauptmenüs (FR-023). Es ist immer genau ein Blatt zu sehen. Alle hängen oben bei y 150 wie das
Hauptmenü und schließen rechts bei x 616 ab; der Hinweis steht wie bisher links neben der gewählten
Zeile (Claude, 2026-10-26). Die Maße hier sind Messungen für den Platz; maßgeblich werden sie erst,
wenn T001 sie in den Style-Guide einträgt und Klaus sie freigibt. Verträge und Tasks verweisen dann
auf den Style-Guide (Verfassung, Grundsatz IV; Analyse, D1). Gemessen:

| Blatt | Kopfzeile | Einträge | Breite | Höhe | Lage |
|---|---|---|---|---|---|
| Hauptmenü | HAUPTMENÜ | Weiterspielen, Neues Spiel, Spiel laden, Einstellungen, Beenden | 144 | 120 | x 472–616, y 150–270 |
| Gradwahl | SCHWIERIGKEIT (90 breit) | Leicht, Mittel, Schwer, Zurück | 144 | 100 | x 472–616, y 150–250 |
| Spielstände | SPIELSTÄNDE, im Löschmodus WELCHES LÖSCHEN? (111) | bis zu 6 Spielstände, Löschen …, Zurück | 304 | bis 180 | x 312–616, y 150–330 |
| Rückfrage | LÖSCHEN? | Abbrechen, Spiel 2 löschen | 144 | 60 | x 472–616, y 150–210 |

Die Zeilen tragen Text ab 24 vom Rand des Papiers (Lochrand 8, Abstand 4, Pfeil 12) und lassen
rechts 12 frei. Im Hauptmenü sind also 108 für Text da; der längste Eintrag „Weiterspielen“ ist 73
breit, „Spiel 9999 löschen“ 103. Das Blatt Spielstände reicht links bis x 312 und bleibt damit 16
rechts vom Logo (bis x 296), genau `raster-16`. Die Unterkante samt Schatten liegt bei 332; die
Versionszeile steht links und stört nicht. Ein Hinweis mit zwei Zeilen ist 38 hoch; neben der
untersten Zeile („Zurück“ bei y 310) endet er samt Schatten bei 350, innerhalb der 360.

**Grund:** Ein Blatt an derselben Stelle wirkt wie ein neuer Ausdruck aus demselben Drucker; der
Blick muss nicht wandern. Das breite Blatt braucht die Breite für vier Spalten (R12).

**Verworfen:**
- Das Blatt Spielstände so hoch wie möglich, oben ab y 16: zeigte 14 Spielstände, aber das Blatt
  spränge beim Wechsel nach oben.
- Die Gradwahl breiter, mit dem Satz unter jedem Grad (R13).

## R12 Die Liste der Spielstände

**Entscheidung:** Jede Zeile hat vier Spalten mit festen Anfängen, gemessen in Ark Pixel 12: Name
(bis „Spiel 9999“, 57, Spalte 64), Grad (bis „Schwer“, 38, Spalte 44), Spieldatum („14.03.1986“, 56,
Spalte 64) und zuletzt gespielt („26.10.2026 21:40“, 90). Die Spalten beginnen also bei 0, 64, 108
und 172 ab dem Text der Zeile; zusammen 262. Mit 24 links, 6 Luft und 12 rechts ergibt das 304
(Analyse, F9, B4). Nummern ab 10.000 passen nicht mehr in die Spalte; der Name wird dann mit „…“
gekürzt. Der Hinweis der Zeile nennt „zuletzt gespielt“ ausgeschrieben: „Zuletzt gespielt am
26.10.2026 um 21:40 Uhr.“ (Claude, 2026-10-26).

Weitere Regeln:
- **Ordnung:** fortsetzbare nach „zuletzt gespielt“, das jüngste oben; bei Gleichstand die höhere
  Nummer zuerst. Darunter die nicht fortsetzbaren nach Nummer absteigend (Claude, 2026-10-26).
- **Nicht fortsetzbar:** Name wie immer, in den Spalten Grad und Spieldatum zusammen „beschädigt“
  oder „neuere Version“ (81 breit, Platz 108), alles gedämpft wie ein nicht verfügbarer Eintrag. Der
  Hinweis nennt den Grund (R10). Wählen geht, fortsetzen nicht; im Löschmodus lässt sich die Zeile
  löschen (FR-017a).
- **Rollen:** Zu sehen sind höchstens 6 Spielstände. Gibt es mehr, rollt die Liste mit der Auswahl
  und mit dem Mausrad zeilenweise; „Löschen …“ und „Zurück“ bleiben immer unten stehen. Ein kleines
  Dreieck rechts in der Kopfzeile zeigt, dass oben mehr steht, eins rechts in der Zeile „Löschen …“,
  dass unten mehr steht. Dort stört es keine Spalte (Analyse, F9); Maß und Farbe legt der
  Style-Guide fest (T001).
  Gebaut wird das als Fenster aus sechs Zeilen, deren Inhalt wechselt, nicht als `ScrollContainer`:
  So bleiben das Zebra der Zeilen und jede Zeile ganz, ohne Rollbalken.
- **Löschmodus:** „Löschen …“ schaltet ihn ein. Die Kopfzeile lautet dann WELCHES LÖSCHEN?, der
  Hinweis jeder Zeile „Spiel 2 wird gelöscht. Vorher fragt das Spiel nach.“ „Löschen …“ ist im Modus
  nicht verfügbar; sein Hinweis sagt, wie es weitergeht (Claude, 2026-10-26). „Zurück“ beendet im
  Löschmodus nur den Modus, wie Esc, und sein Hinweis lautet dann „Nicht löschen. Esc geht auch.“
  (Analyse, F3). Der Modus endet wie in FR-017a.

**Grund:** FR-015 verlangt alle vier Angaben je Spielstand. Spalten machen sie vergleichbar; in
einer Proportionalschrift stehen sie nur mit festen Anfängen untereinander. Die Liste hat keine
Spaltenköpfe (Baustein Menü: keine Unterüberschriften). Spieldatum und „zuletzt gespielt“
unterscheiden sich durch Jahr und Uhrzeit, und der Hinweis sagt es ausdrücklich. Sechs Zeilen
halten das Blatt so hoch, dass es neben dem Hauptmenü nicht springt (R11).

**Verworfen:**
- „zuletzt gespielt“ nur im Hinweis: Dann zeigte die Liste es nicht je Spielstand, wie FR-015 es
  verlangt.
- Eine kurze Form wie „heute 21:40“: Für ältere Spielstände braucht es ohnehin ein Datum, und dann
  stünden zwei Arten nebeneinander.
- Ein Rollbalken: ein Baustein mehr, und in der Pixelschrift wirkt ein halb sichtbarer Eintrag
  wie ein Fehler.

## R13 Die Sätze zu den Graden stehen im Hinweis

**Entscheidung:** Der Satz zu einem Grad ist der Hinweis seiner Zeile. Weil Mittel vorgewählt ist,
steht sein Satz sofort da; mit der Auswahl wechselt er (Claude, 2026-10-26). Die Vorschläge für die
Sätze stehen in R18.

**Grund:** Der Hinweis gehört zum Baustein Menü und erklärt die gewählte Zeile; einen neuen
Baustein braucht es nicht. Die Gradwahl bleibt so schmal wie das Hauptmenü.

**Verworfen:** Alle drei Sätze gleichzeitig, je unter dem Grad: Die Zeilen müssten zweizeilig und
das Blatt 300 breit werden. Das wäre ein neuer Baustein, und ein Satz mit zwei Zeilen passt ohnehin
nicht in eine Zeile des Menüs.

## R14 Rückfrage als Blatt

**Entscheidung:** Die Rückfrage ist ein Blatt mit der Kopfzeile LÖSCHEN? und den Einträgen
„Abbrechen“ (vorgewählt) und „Spiel 2 löschen“. Die Hinweise nennen Name, Grad und Spieldatum:
„Spiel 2, Schwer, 14.03.1986, bleibt. Esc geht auch.“ und „Spiel 2, Schwer, 14.03.1986, ist danach
weg. Für immer.“ (Checkliste, CHK031) Bei einem nicht fortsetzbaren Spielstand steht statt Grad und
Spieldatum sein Zustand, „beschädigt“ oder „neuere Version“: „Spiel 3, beschädigt, bleibt. Esc geht
auch.“ und „Spiel 3, neuere Version, ist danach weg. Für immer.“ (Analyse, C9; alle gemessen auf
zwei Zeilen). „Abbrechen“ übernimmt die Rolle von „Zurück“ aus FR-023; Esc wirkt genauso
(Claude, 2026-10-26).

**Grund:** FR-017 verlangt die Rückfrage mit Name, Grad und Spieldatum und „Abbrechen“ vorgewählt;
FR-023 verlangt ein Blatt mit einem Eintrag, der eine Ebene zurückführt. Da immer eine Zeile
gewählt ist, steht immer ein Hinweis mit allen drei Angaben da. Der Name steht zusätzlich im
Eintrag, damit niemand das falsche Spiel löscht. Eine Kopfzeile wie „SPIEL 999 LÖSCHEN?“ wäre mit
125 breiter als die 120 im Blatt.

**Verworfen:**
- Ein drittes Wort „Zurück“ neben „Abbrechen“: zwei Einträge, die dasselbe tun.
- Ein Bestätigungsfenster wie im Baustein Knopf: Klaus hat Blätter auf dem Titelbildschirm
  entschieden (Spec, Clarifications).

## R15 Spielbildschirm und Knopf

**Entscheidung:** Der Spielbildschirm ist ein Vollbild in `nacht`. In der Mitte steht der Knopf
„Zum Hauptmenü“ nach dem Baustein Knopf, mit Fokus von Anfang an. Links neben ihm steht der
Hinweis wie im Menü: „Speichert Spiel 2 und führt ins Hauptmenü.“ Enter und Leertaste lösen aus,
Esc nichts (FR-020). Der Knopf wird ein eigener, wiederverwendbarer Baustein `Knopf` unter
`src/ui/` (Claude, 2026-10-26).

Knopf mit Innenabstand 8 links und rechts, Kontur 1 auf jeder Seite und Text „Zum Hauptmenü“
(83) ist 8 + 83 + 8 + 2 = 101 breit und 20 hoch; in der Mitte steht er
bei x 270–371, y 170–190. Der Hinweis mit zwei Zeilen reicht links bis x 106.

**Grund:** Der Spielbildschirm ist ein Platzhalter (FR-019). Der Hinweis nennt das laufende Spiel,
so sieht Klaus bei der Abnahme, welches Spiel geladen ist, ohne dass der Bildschirm mehr zeigt, als
die Spec erlaubt. Den Knopf braucht später jedes Fenster; deshalb gleich als Baustein.

Auf `nacht` ist die Fokuslinie in `tusche` aus dem Style-Guide nicht zu sehen (Kontrast 1,1 : 1;
`papier` auf `nacht` hat 13,7 : 1). Vorschlag für den Style-Guide: Auf dunklem Grund ist die
Fokuslinie `papier`. Das kommt vor dem Bauen in den Style-Guide (Grundsatz IV, R17).

**Verworfen:**
- Der Knopf unten rechts wie später in der Bedienleiste: Neben ihm reicht der Platz nach unten
  nicht für einen Hinweis mit zwei Zeilen.
- Ein Blatt mit einem Eintrag „Zum Hauptmenü“: braucht nichts Neues, aber Klaus hat einen Knopf
  entschieden, und den Baustein braucht das Spiel ohnehin.
- Grund `papier` oder `gehaeuse`: Ein heller, leerer Bildschirm sieht nach Fehler aus.

## R16 Messen

**Entscheidung:** Die Tests messen, statt zu schätzen (`ki_dev.md`, „Tests“):
- SC-003 im Kern: für die Seeds 1, 4711 und 99999 in allen drei Graden ein Lauf ohne Pause gegen
  einen, der am 14.03.1986 als Datei gespeichert, gelesen und bis zum 31.12.1999 weitergespielt
  wird. Verglichen werden alle Zeilen ab dem 15.03.1986. Dazu dasselbe mit Eingriffen vor und nach
  dem 14.03.1986, damit das Nachspielen geprüft ist.
- SC-003 über die Autoloads einmal mit Uhr und Signalen: Seed 4711, Schwer, fortgesetzt am
  14.03.1986, Tag für Tag bis zum 31.12.1986 (US3, Szenario 4).
- SC-005 über `GameSession` mit eigener Uhr: Spieldatum nach dem Verlassen am 01.01.1985, am
  15.02.1985, am 14.03.1986 und am 31.12.1999.
- SC-002: Liste mit 20 Spielständen, je mit einer Kopie von `catalog_500.json` (500 Ereignisse,
  rund 25-mal so viele wie heute), in höchstens einer Sekunde gelesen; das Anzeigen des Blatts
  misst der Test der Oberfläche. Dazu ein Spielstand mit `catalog_500.json` vom 31.12.1999, in
  höchstens einer Sekunde fortgesetzt (Checkliste, CHK024).
- SC-004: je Fehlerfall ein Test mit einer kaputten Datei als Fixture oder im Testordner erzeugt;
  ein Speichern, das scheitert, entsteht ohne Hilfe im Code: Liegt dort, wo die `.neu` hin soll, ein
  Ordner mit Inhalt, lässt sie sich weder löschen noch schreiben. Ebenso scheitert Löschen, wenn an
  der Stelle von `spiel_N.json` ein Ordner mit Inhalt liegt (Analyse, E2).
- FR-022 über `GameSession`: ein Spiel anlegen, den Katalog der Zeitleiste gegen einen anderen
  tauschen, fortsetzen; der Fahrplan ist der des gespeicherten Katalogs (Analyse, E1).
- Zwei Fenster: Eine Datei mit der nächsten Nummer liegt schon da, bevor `start_new()` schreibt;
  das neue Spiel weicht auf die übernächste aus (Analyse, C4).

Als Katalog dienen die eingefrorenen Test-Kataloge unter `src/test/fixtures/`, nie der echte. Jeder
Test schreibt in einen eigenen Ordner unter `user://`, etwa `user://test_spielstaende/`, und räumt
ihn ab.

**Grund:** Der Bytevergleich ganzer Ausgaben hat in Feature 002 und 003 Fehler gefunden, die
Stichproben übersehen hätten.

## R17 Vorarbeit im Style-Guide

**Entscheidung:** Bevor gebaut wird, kommen in den Style-Guide (Grundsatz IV, FR-021):
1. **Blätter im Titel** (Baustein Menü): Gradwahl, Spielstände und Rückfrage ersetzen das
   Hauptmenü an seiner Stelle, oben bündig, rechts bündig; Breite nach Inhalt; Esc und „Zurück“
   führen eine Ebene zurück; die Kopfzeile darf den Modus nennen.
2. **Liste** (neuer Baustein auf Basis von Menü): Spalten mit festen Anfängen, höchstens sechs
   sichtbare Zeilen, Rollen mit Dreiecken als Rollmarken, nicht fortsetzbare Zeilen gedämpft,
   Löschmodus.
3. **Rückfrage im Titel:** ein Blatt mit „Abbrechen“ vorgewählt; die Hinweise nennen, worum es
   geht.
4. **Meldung** (neu): wie der Hinweis, aber mit Kontur in `kassenrot`; sie ersetzt den Hinweis,
   bis der Spieler die Auswahl ändert oder etwas auslöst. Für „Speichern ging nicht“.
5. **Knopf auf dunklem Grund:** Fokuslinie in `papier`; dazu der Spielbildschirm als Platzhalter:
   Vollbild in `nacht`, Knopf in der Mitte. Ein Knopf, der allein auf einem Bildschirm steht und
   den Fokus hat, zeigt seinen Hinweis wie ein Menüeintrag, ohne Verzögerung; Knöpfe in Fenstern
   behalten den Tooltip (Checkliste, CHK017).

Claude schreibt die Abschnitte, Klaus gibt sie frei; erst dann baut der Agent die Oberfläche.

**Grund:** Grundsatz IV und `ki_dev.md`, „Was man sieht, steht zuerst im Style-Guide“. Der
Stil-Prüfer prüft gegen den Style-Guide; was dort fehlt, meldete er als Lücke.

## R18 Vorschläge für die Sätze zu den Graden

Maßstab ist der Abschnitt „Sprache“ im Style-Guide: trocken, knapp, der Witz im Nachsatz, duzen.
Jeder Satz verspricht nur, was der Grad heute tut: Er verschiebt die Chancen von Ereignissen
(FR-004). Alle passen in zwei Zeilen des Hinweises (gemessen in Ark Pixel 10, je Zeile 150).

| | Leicht | Mittel | Schwer |
|---|---|---|---|
| **A, Glück** (Empfehlung) | Das Glück ist eher auf deiner Seite. | Das Glück hält sich raus. | Das Glück ist eher auf der Seite der anderen. |
| B, Ereignisse | Gute Ereignisse kommen öfter, schlechte seltener. | Es kommt, wie es kommt. | Schlechte Ereignisse kommen öfter, gute seltener. |
| C, Zufall mit Nachsatz | Der Zufall meint es gut mit dir. Meistens. | Der Zufall bleibt neutral. Wie ein Finanzbeamter. | Der Zufall hat etwas gegen dich. Nichts Persönliches. |

**Empfehlung A:** Sie baut auf Klaus' Beispiel aus der Klärung auf, ist ehrlich und verspricht
keine Richtung je Ereignis. B ist am genauesten, aber nur wahr, wenn die Profile wirklich gute
Ereignisse fördern und schlechte bremsen; heute stehen dort vorläufige Werte (Feature 003, R18). C
hat den meisten „Das Amt“, behauptet aber mit „gegen dich“ mehr, als der Grad tut.

**Entschieden:** Vorschlag A (Klaus, 2026-10-26, nach Empfehlung). Der Text-Prüfer prüft die Sätze
in der Phasenprüfung von Phase 4.
