# Recherche: Zeitleisten-Werkstatt

Grundlage: [spec.md](spec.md), [Verfassung 2.1.0](../../.specify/memory/constitution.md), der
vorhandene Code unter `src/core/` und `src/data/`, die Feature-Docs 01-01 und 01-02. Godot-Stand:
4.7.2. API-Angaben stammen aus der Klassenreferenz 4.7 (docs.godotengine.org/en/4.7); was mit
„Probe“ markiert ist, wurde am 2026-10-20 headless in Godot 4.7.2 ausprobiert.

## R1 Kern ohne Node, Autoload als Hülle

- **Entscheidung:** Die ganze Logik steckt in `TimelineRun`, einer Klasse auf `RefCounted` ohne
  Szene und ohne Uhr. Sie nimmt Katalog und Seed entgegen, legt den Fahrplan an und spielt auf
  Aufruf Tage ab. Jeder Aufruf gibt die Meldungen dieses Abschnitts als Liste zurück. Das
  Autoload `Timeline` verbindet den Kern mit `GameClock.day_passed` und macht aus den Meldungen
  Signale. Werkstatt, Textausgabe, Statistik und Tests benutzen `TimelineRun` direkt.
- **Begründung:** So läuft derselbe Code im Spiel, in den Tests und in der Werkstatt (US5), ohne
  dass die echte Uhr laufen muss. Eine Liste von Meldungen lässt sich in Tests einfach
  vergleichen, Signale müsste man erst abhören. Das Muster heißt „funktionaler Kern, imperative
  Hülle“.
- **Alternativen:** Logik im Autoload wie bisher (nur mit laufender Uhr testbar, die Werkstatt
  bräuchte eine zweite Uhr); Kern als `Node` (braucht einen Szenenbaum, für Statistik über
  1.000 Spiele unnötiger Ballast).

## R2 Datenklassen: RefCounted, Namen bleiben

- **Entscheidung:** `TimelineEvent` und `EventEffect` bleiben als Klassennamen erhalten, werden
  aber von `Resource` auf `RefCounted` umgestellt und bekommen das neue Modell (data-model.md).
  Neu sind `EventCategory`, `FollowUp`, `EventCondition`, `ScheduleEntry`, `ChanceModifier` und
  `TimelineMessage`. Jede Datenklasse hat `static func from_dict()` und `func to_dict()`.
- **Begründung:** Die Signale `event_fired(event: TimelineEvent, …)` und
  `effect_applied(effect: EventEffect, …)` behalten so ihre Signaturen (FR-017). `Resource` lohnt
  sich, wenn Daten als `.tres` gespeichert oder im Inspector bearbeitet werden; beides fällt weg,
  der Katalog ist JSON. `RefCounted` ist leichter und wird nicht versehentlich zur `.tres`
  (dieselbe Begründung wie bei `GameDate` in 01-01).
- **Alternativen:** neue Namen wie `EventDefinition` (klarer, bricht aber den Signalvertrag);
  `Resource` behalten (kein Nutzen, und die `@export`-Anmerkungen versprächen einen Inspector,
  den es nicht gibt).

## R3 Format des Ereigniskatalogs

- **Entscheidung:** Eine Datei `src/data/event_catalog.json`, Format in
  [contracts/ereigniskatalog.md](contracts/ereigniskatalog.md):
  - geschrieben mit `JSON.stringify(daten, "\t", true)`: Tabs, Schlüssel alphabetisch sortiert;
  - Ereignisse nach Kennung sortiert, Kategorien in der Reihenfolge der Zeilen im Zeitstrahl;
  - Schlüssel englisch wie die Felder im Code, Texte deutsch;
  - Datumsangaben als `"JJJJ-MM-TT"`, Tage im Jahr als `"MM-TT"` oder `"MM-ende"`;
  - Wahrscheinlichkeiten und Stärken als Anteil von 0 bis 1 (`0.03` = 3 %), wie bisher in
    `EventDatabase`, auf vier Nachkommastellen gerundet geschrieben.
  - Einzige Ausnahme: Die Gewichte je Anzahl stehen in Prozent mit Summe 100, weil „30 / 70“
    lesbarer ist als „0.3 / 0.7“. Geschrieben werden sie auf zwei Nachkommastellen gerundet, als
    `Array[float]` mit 64 Bit. Erst zum Würfeln werden sie in das `PackedFloat32Array` für
    `rand_weighted()` umgewandelt.
- **Probe:** `JSON.stringify` schreibt `int` ohne Nachkomma (`14`), `float` mit (`1.0`, `0.03`);
  `0.03 + 0.05` erscheint als `0.08`. `JSON.parse` liefert jede Zahl als `float` (14 → 14.0). Der
  Katalog wandelt deshalb ganzzahlige Felder beim Lesen mit `int()` um und schreibt sie als `int`.
  Sonst würde aus `14` beim nächsten Speichern `14.0`, und jede Datei hätte einen falschen Diff.
  Ein `PackedFloat32Array` schrieb in einer zweiten Probe `33.3333320617676`; deshalb gibt es
  keine 32-Bit-Zahlen in der Datei. Listen bricht `JSON.stringify` mit Einrückung zeilenweise um,
  je Eintrag eine Zeile.
- **Begründung:** Eine Datei ist für die Werkstatt einfach zu lesen und zu schreiben. Sortierte
  Schlüssel und Ereignisse ergeben eine kanonische Form: Gleicher Inhalt ergibt gleiche Datei, eine
  Feldänderung ändert genau eine Zeile (FR-035). Die Datumsform ist im Diff ohne Umrechnung lesbar.
  02-01 hat für die Produkte aus denselben Gründen JSON gewählt.
- **Alternativen:** eine Datei je Ereignis (viele kleine Dateien, Umbenennen heißt Datei
  umbenennen); deutsche Schlüssel (näher an der game_bible, aber zweierlei Namen für dasselbe
  Feld); Tagesindizes statt Datum (im Diff unlesbar); Prozentzahlen (`3` statt `0.03`, wäre
  lesbarer, aber anders als `magnitude` und als jeder bisherige Wert).

## R4 Katalog lesen: Spiel und Werkstatt

- **Entscheidung:** Beide lesen mit `FileAccess.get_file_as_string()` und parsen mit einer
  `JSON`-Instanz. Bei einem Fehler nennen `get_error_line()` und `get_error_message()` die Stelle
  (Probe: kaputte Datei → `ERR_PARSE_ERROR` mit „Expected value“; `get_error_line()` zählt ab 0,
  die Meldung nennt die Zeile deshalb mit `+ 1` wie ein Texteditor). Strukturfehler wie ein
  fehlendes Feld werden zu Prüfmeldungen. Schwere Fehler schließen im Spiel nur das betroffene
  Ereignis aus, nicht den ganzen Katalog (FR-049).
- **Export:** Die Doku rät, Projektdateien nach dem Export über `ResourceLoader` zu lesen, weil
  importierte Dateien im Paket umgewandelt liegen. JSON wird nicht importiert: `load()` liefert
  die Datei als `JSON`-Ressource (Probe), sie liegt also unverändert im Paket. Ob
  `FileAccess` sie in der exportierten App findet, prüft ein Probe-Export als eigene Aufgabe in
  Phase 3, gleich nachdem die Zeitleiste den Katalog liest. Falls nicht, kommt `*.json` in den
  Include-Filter des Presets.
- **Alternativen:** `load()` als `JSON`-Ressource (liefert bei Fehlern nur `null` ohne Zeile und
  legt den Katalog in den Ressourcen-Cache, was die Werkstatt beim Neuladen stört).

## R5 Zufall: ein Seed je Spiel, ein Würfel je Ereignis

- **Entscheidung:**
  - Jedes Spiel hat einen Seed (`int`).
  - Jedes Ereignis bekommt für jeden Zweck einen eigenen `RandomNumberGenerator`. Dessen
    Startwert sind die ersten 8 Byte von SHA-256 über `"<seed>|<zweck>|<kennung>"`
    (`String.sha256_buffer().decode_u64(0)`).
  - Zwecke: `chance` für die Würfelrunden, `preset` für die beim Start gesetzten Termine,
    `follow|<quelle>|<nr>|<tag>` für jede Entscheidung über ein Folgeereignis.
  - Der `chance`-Würfel eines Ereignisses würfelt in jedem der 180 Monate genau zweimal: Wurf und
    Tag. Das geschieht auch dann, wenn das Ereignis in diesem Monat gar nicht in Frage kommt.
- **Begründung:** Damit hängt jede Entscheidung nur von Seed, Ereignis und Zeitpunkt ab (FR-015):
  - Eine Spieleraktion verschiebt nur die Schwelle; der Wurf bleibt gleich.
  - Ein neues Ereignis verschiebt die Würfe der anderen nicht.
  - Dass der Monat immer zwei Würfe kostet, hält die Folge in Takt, egal was vorher geschah.

  Die Doku sagt, ähnliche Startwerte ergäben ähnliche Folgen, und empfiehlt einen Hash davor. Dazu
  dient SHA-256. Spiele mit teilbaren Seeds machen es genauso: Slay the Spire etwa hat getrennte
  Zufallsquellen je Bereich.
- **Probe:** Gleicher Startwert ergibt dieselbe Folge. `rand_weighted([30, 70])` trifft bei
  10.000 Würfen 3.024 zu 6.976.
- **Grenze:** Die Doku nennt PCG32 „ein Implementierungsdetail“. Gleiche Ergebnisse sind deshalb
  nur bei gleicher Godot-Version zugesagt; über Betriebssysteme hinweg gelten sie, denn PCG32 und
  SHA-256 rechnen nur mit ganzen Zahlen. Nach einem Godot-Update werden gespeicherte Textausgaben
  neu erzeugt, falls sich etwas ändert. Für 11-01 heißt das: Spielstände speichern Seed, Fahrplan
  und Eingriffe, nicht den Zustand der Würfel. Klaus hat im Review entschieden, dass die gleiche
  Godot-Version reicht; ein eigener Zufallsgenerator ist damit nicht nötig.
- **Alternativen:**
  - Ein gemeinsamer Generator wie bisher (`randomize()`): Jede Kleinigkeit würfelt das
    restliche Spiel neu, und kein Lauf lässt sich wiederholen.
  - SHA-256 für jeden einzelnen Wurf: rein rechnerisch die sauberste Lösung, aber 1.000 Spiele
    würfeln mit dem übernommenen Katalog rund 2,2 Millionen Mal (6 Ereignisse × 180 Monate × 2
    Würfe × 1.000 Spiele), mit 500 Ereignissen das Vielfache; das sprengt SC-004 und SC-011.
  - Godots `hash()`: ist schneller, aber nicht als stabil dokumentiert und nur 32 Bit breit.

## R6 Fahrplan und Tagesablauf

- **Entscheidung:** Beim Anlegen stehen alle fixen, jährlichen und beim Start gesetzten Termine
  im Fahrplan. Jeder Termin hat eine laufende Nummer (`serial`) in der Reihenfolge seines
  Entstehens. Ein Tag läuft in dieser festen Folge ab (FR-016):
  1. Enden: laufende Termine, deren Ende auf diesen Tag fällt, und ihre Wirkungen „während“.
  2. Verzögerte Wirkungen, die heute fällig werden.
  3. Würfelrunde, nur am Monatsersten, Ereignisse in Kennungsreihenfolge.
  4. Beginne: geplante Termine des Tages in der Reihenfolge Herkunft (fix, jährlich, gesetzt,
     gewürfelt, Folge, Eingriff), dann Kennung, dann laufende Nummer. Folgeereignisse ohne
     Verzögerung kommen hinten an und laufen am selben Tag.
- **Stichtage:** `advance_to(tag)` prüft nicht jeden Tag einzeln, sondern springt zum nächsten
  Tag, an dem etwas ansteht: Termin, Ende, fällige Wirkung oder Monatserster. Ein Spiel hat damit
  rund 300 statt 5.478 Schritte. Ob die Uhr Tag für Tag oder in Sprüngen ruft, ändert nichts an
  den Meldungen (SC-002).
- **Begründung:** Eine feste Folge macht das Protokoll wiederholbar und im Fahrplan sichtbar.
  Enden vor Beginnen verlangt die Spec, und so wechselt der Winter am 01.03. sauber zum Frühling.
- **Alternativen:** jeden Tag alle Ereignisse prüfen wie bisher (bei 1.000 Spielen zu langsam);
  eine Prioritätswarteschlange (bei einigen Hundert Terminen kein Gewinn gegenüber Wörterbüchern
  nach Tag).

## R7 Beim Start gesetzte Ereignisse

- **Entscheidung:** Der `preset`-Würfel zieht erst mit `rand_weighted()` über die Gewichte je
  Anzahl einen Index j; die Anzahl ist k = `count_min` + j. Dann zieht er die Termine:
  - L = `window_to` − `window_from` ist die Länge des Zeitfensters in Tagen, g der Mindestabstand.
  - k Zahlen kommen aus `randi_range(0, L − (k − 1) · g)` und werden aufsteigend sortiert.
  - Die i-te Zahl zᵢ (i = 0 … k − 1) ergibt den Termin `window_from` + zᵢ + i · g.

  Dass auch die höchste Anzahl hineinpasst, also L ≥ (k − 1) · g, stellt V10 sicher.
- **Begründung:** Das Verfahren verteilt die Termine gleichmäßig über das Fenster und hält den
  Mindestabstand immer ein, ohne neu zu würfeln. Die Zahl der Würfe hängt nur von k ab, ist also
  wiederholbar.
- **Alternativen:** würfeln und verwerfen, bis der Abstand passt (Zahl der Würfe schwankt, bei
  engen Fenstern endlos); feste Abstände (keine echte Streuung).

## R8 Würfelrunde für Ereignisse über Wahrscheinlichkeit

- **Entscheidung:** Am Ersten jedes Monats, auch am 01.01.1985, würfelt jedes Ereignis über
  Wahrscheinlichkeit zweimal (R5): Wurf w und Tag t. Ein Termin entsteht, wenn alles zutrifft:
  - Der Monat überschneidet das Zeitfenster.
  - Die Bedingungen sind erfüllt.
  - Die Höchstzahl ist nicht erreicht; dabei zählen alle Termine außer entfallenen und
    abgesagten.
  - Der gewürfelte Tag liegt mindestens den Mindestabstand hinter dem Beginn des letzten Termins,
    der weder entfallen noch abgesagt ist (FR-005).
  - w liegt unter der wirksamen Chance.

  Der Tag ist der t-te Teil der Tage dieses Monats, die im Zeitfenster liegen. Als Begründung
  bekommt der Termin Würfelwert, Schwelle und Grundchance, dazu die Modifikatoren mit Grund und
  Wert, wie sie beim Wurf galten (`modifier_notes`). So bleibt sie lesbar, auch wenn ein
  Modifikator später entfernt wird (FR-012). Termine von Folgeereignissen halten Wurf und
  Wahrscheinlichkeit genauso fest.
- **Begründung:** Das Würfeln im Januar 1985 fehlte bisher (offene Frage in 01-02). Ein
  gewürfelter Tag verteilt die Ereignisse über den Monat, statt alle auf den Ersten zu legen.
- **Alternativen:** Ereignis am Monatsersten (alles ballt sich); täglich würfeln (180-mal so
  viele Würfe, Chancen müssten auf Tage umgerechnet werden).

## R9 Dauer und jährliche Ereignisse

- **Entscheidung:**
  - `end_day` eines Termins ist der Tag, an dem sein Ende gemeldet wird: Beginn + Dauer. Ohne
    Dauer ist er gleich dem Beginn, und nichts endet.
  - Jährliche Ereignisse haben Beginn und Ende als Tag im Jahr; „ende“ heißt Monatsende, so
    stimmt der Februar in Schaltjahren.
  - Kandidaten sind die Vorkommen, die in den Jahren `yearly_from − 1` bis `yearly_to` beginnen.
    In den Fahrplan kommt ein Vorkommen nur, wenn es sich mit dem 01.01. von `yearly_from` bis
    31.12. von `yearly_to` und mit dem Spielzeitraum überschneidet. Beispiel: Die CeBIT ab 1986
    hat im März 1985 kein Vorkommen; der Winter ab 1985 hat eines, das am 01.12.1984 beginnt.
  - Ein Vorkommen, das vor dem 01.01.1985 begonnen hat, beginnt im Fahrplan am 01.01.1985 und
    trägt die Herkunft „jährlich, lief schon vor Spielbeginn“.
  - Dafür rechnet `GameDate` auch Tage vor 1985, als negative Indizes (31.12.1984 = −1). Bisher
    zählte `to_day_index()` die Jahre vor 1985 nicht ab und ergab für den 31.12.1984 den Wert 365.
  - Jede Wirkung hat `scope` `ONCE` oder `DURING`. `DURING` meldet Beginn und Ende. Eine
    verzögerte `DURING`-Wirkung beginnt später und endet mit dem Ereignis.
  - Ein Ereignis, das noch läuft, beginnt nicht erneut (FR-022); der neue Termin entfällt mit
    Begründung.
- **Begründung:** So deckt ein Modell Weihnachtsgeschäft, Jahreszeiten und Lieferengpass ab, und
  das Ende fällt nie auf einen falschen Tag. Der Winter am ersten Spieltag (US3, Szenario 2)
  ergibt sich ohne Sonderfall.
- **Alternativen:** Dauer nur in Tagen, auch bei jährlichen Ereignissen (Winter wäre in
  Schaltjahren einen Tag zu kurz); Jahreszeiten aus dem Datum berechnen wie bisher (widerspricht
  der Verfassung: alles, was etwas auslösen kann, steht in der Timeline).

## R10 Folgeereignisse und Ketten

- **Entscheidung:** Beginnt ein Ereignis, entscheidet je Folgeereignis ein eigener Würfel über
  ob (Wahrscheinlichkeit) und wann (Tag aus der Verzögerungsspanne). Die Prüfung im Katalog sucht
  Kreise über Kanten mit 100 % und Verzögerung 0 und meldet sie als Fehler.
- **Kettenbremse:** Gezählt wird je Kette (FR-018):
  - Ein Termin, den der Tag von sich aus beginnt, ist das erste Glied seiner Kette.
  - Ein Folgeereignis ohne Verzögerung ist ein Glied mehr als sein Auslöser.
  - Ein Folgetermin mit Verzögerung beginnt an seinem Tag eine neue Kette.
  - Das 17. Glied beginnt nicht (`MAX_CHAIN = 16`). Sein Termin entfällt mit der Meldung
    `CHAIN_STOPPED` im Protokoll, und das Autoload gibt im Spiel eine Warnung aus (R12).
- **Begründung:** Die Kettenbremse ersetzt den fehlenden Schutz vor Endlosschleifen aus 01-02.
  16 Glieder sind weit mehr, als ein sinnvoller Spieltag braucht. Der Würfel je Entscheidung hält
  FR-015 ein.
- **Alternativen:** Kreise nur im Katalog verbieten (Kreise mit Zufall oder Verzögerung sind
  erlaubt und können trotzdem lang werden); Folgeereignisse als Wirkungsart `SPAWN` wie bisher
  (vermischt Meldung und Ablauf).

## R11 Eingriffe

- **Entscheidung:**
  - **Modifikatoren:** Wert als Anteil, `+0.05` heißt +5 Prozentpunkte. Beginn und Ende sind
    Tagesindizes, das Ende ist Pflicht. Ob ein Modifikator gilt, wird beim Würfeln geprüft;
    abgelaufene werden nicht aufgeräumt, sondern übersprungen (wie 01-07 entschieden). Die
    wirksame Chance ist Grundchance plus Summe, begrenzt auf 0 bis 1.
  - **Termine:** Absagen, Verschieben und Einplanen gehen nur für Tage nach dem zuletzt
    abgespielten Tag und nur für Termine, die nicht fix oder jährlich sind. Vor `begin()` ist
    `today = -1`, Eingriffe sind dann ab dem 01.01.1985 möglich. Jeder Eingriff erzeugt eine
    Meldung `INTERVENTION` im Protokoll.
  - **Randfälle:** Ein Modifikator mit Ende vor Beginn, leerem Grund oder doppelter Kennung wird
    abgelehnt. Ein Beginn in der Vergangenheit und der Wert 0 sind erlaubt.
  - Abgelehnte Eingriffe geben einen `Error` zurück, den Grund auf Deutsch in `last_refusal`.
- **Statistik mit Eingriffen:** Modifikatoren und Einplanungen beziehen sich auf Ereignisse und
  Tage und lassen sich auf jeden Seed übertragen. Absagen und Verschiebungen beziehen sich auf
  einen Termin eines bestimmten Seeds und lassen sich nicht übertragen. Die Statistik nimmt
  deshalb nur Modifikatoren und Einplanungen mit; FR-045 ist entsprechend präzisiert. Sie wendet
  sie an dem Tag an, an dem sie im Simulator geschahen. Ein Modifikator, den Klaus dort später
  entfernt hat, wirkt also auch in der Statistik nur bis zu diesem Tag.
- **Eingriffsprotokoll:** Jeder angenommene Eingriff kommt mit dem Tag, an dem er geschah, in
  `TimelineRun.interventions`. Aus diesem Protokoll entstehen Proben (R22) und die Eingriffe der
  Statistik.
- **Alternativen:** Chance im Katalog überschreiben (verboten durch FR-025); Eingriffe in die
  Vergangenheit (würden das Protokoll umschreiben).

## R12 Meldungen und Signale

- **Entscheidung:**
  - `Timeline` behält `event_fired(event, date)` und `effect_applied(effect, source, date)`
    (FR-017). Neu sind `event_ended(event, date)`, `effect_ended(effect, source, date)` und
    `entry_skipped(entry, date)`.
  - `start_game(seed)` legt einen neuen Lauf an. Bis es „Neues Spiel“ gibt, ruft das Autoload es
    per `call_deferred()` am Ende des ersten Bilds auf, also nach dem `_ready()` der Hauptszene.
    So hören Abnehmer in der Szene den ersten Spieltag schon mit.
  - Für spätere Abnehmer gibt es außerdem `running_entries()`: Sie fragen damit beim Einstieg den
    Stand ab. Das Autoload reicht die Abfrage an den Lauf durch.
  - Aus `CHAIN_STOPPED` wird `entry_skipped`, wie bei jedem entfallenen Termin, und zusätzlich eine
    Warnung über `push_warning()` mit Ereignis und Tag (FR-018). Meldungen `INTERVENTION` stehen
    nur im Protokoll und werden kein Signal.
- **Begründung:** Ein Abnehmer, der erst später dazukommt (etwa nach dem Laden), braucht den
  Zustand und nicht nur die Änderungen. Das ist das übliche Paar aus Abfrage und Meldung.
- **Alternativen:** Spielbeginn direkt in `_ready()` des Autoloads (die Meldungen des ersten Tags
  gingen ins Leere).

## R13 Die Werkstatt als Szene im Projekt

- **Entscheidung:**
  - **Ort und Start:** `src/tools/werkstatt/werkstatt.tscn`. Gestartet wird im Editor mit F6
    („Aktuelle Szene starten“) oder mit
    `Godot --path src res://tools/werkstatt/werkstatt.tscn`.
  - **Fenster:** In `_ready()` setzt die Werkstatt `content_scale_mode` des Fensters auf
    `CONTENT_SCALE_MODE_DISABLED` und schaltet das Fenster auf `MODE_MAXIMIZED`, außer es läuft
    eingebettet im Editor (`Engine.is_embedded_in_editor()`). Sie schaltet die Verarbeitung von
    `GameWindow` ab, damit dessen Ganzzahl-Größe das Fenster nicht zurücksetzt.
  - **Bildschirmfaktor:** Dazu setzt sie `content_scale_factor` auf
    `DisplayServer.screen_get_scale()`, auf einem Retina-Bildschirm also 2. Ohne das stünde Text
    in physischen Pixeln da, eine Schrift der Größe 14 wäre dort nur halb so groß (Style-Guide,
    Abschnitt „Werkzeuge“). **Probe:** Der Faktor wirkt auch mit `CONTENT_SCALE_MODE_DISABLED`;
    die Transformation des Fensters hat dann den Maßstab 2.
  - **Headless:** Läuft Godot ohne Fenster, lässt die Werkstatt das Fenster in Ruhe; das braucht
    der Rauchtest.
  - **Export:** Der Export schließt `tools/*` aus wie heute `test/*`.
- **Begründung:** Die Werkstatt soll viel Text auf einen großen Bildschirm bringen (FR-029),
  das Spielraster 640 × 360 ist dafür zu klein. Die Eigenschaften lassen sich zur Laufzeit setzen
  (öffentliche Setter in der Klassenreferenz). Ob das Umschalten aus dem Vollbild unter macOS
  sauber aussieht, prüft der Quickstart.
- **Alternativen:** Editor-Plugin (von Klaus verworfen, siehe Spec); eigene Projekteinstellungen
  für die Werkstatt (Godot kennt nur ein Set je Projekt).

## R14 Look der Werkstatt

- **Entscheidung:** Eigenes Theme `werkstatt_theme.tres` auf dem Wurzelknoten der Werkstatt. Es
  verdeckt für alles darunter das Projekt-Theme. Die Farben kommen aus `UiPalette`, ihre Rollen
  (Grund, Fläche, Text, Auswahl, Fehler, Warnung und weitere) legt der Abschnitt „Werkzeuge“ im
  Style-Guide fest, von Klaus am 2026-10-20 freigegeben. Die Schrift ist laut diesem Abschnitt
  Godots eingebaute Open Sans SemiBold (`ThemeDB.fallback_font`, Probe in 4.7.2), gesetzt per Code
  als `default_font`, in den Größen 14 für Text, 12 für die Zeitachse und 16 für Titel. Dafür
  braucht es keine neue Datei und keine Lizenz.
- **Wichtig:** Das Theme muss `default_font` selbst setzen. Ohne eigene Schrift fällt Godot auf
  das Projekt-Theme zurück, und dort steht Ark Pixel.
- **Kategorienfarben:** Im Katalog stehen Token-Namen der Palette (`"petrol"`). `UiPalette`
  bekommt dafür `static func by_token(token: StringName) -> Color`.
  - Erlaubt sind nur die Tokens, die der Style-Guide für Kategorien freigibt, als Liste
    `UiPalette.CATEGORY_TOKENS`. Jedes hat zum Grund des Zeitstrahls mindestens 3 : 1 Kontrast,
    wie für farbige Flächen ohne Text üblich.
  - Titel stehen in Textfarbe auf dem Grund neben der Marke, nie auf der farbigen Fläche; so gilt
    für sie der Kontrast aus FR-029.
  - Eine neue Kategorie bekommt das erste noch freie Token dieser Liste; sind alle vergeben, das am
    seltensten benutzte, bei Gleichstand das frühere. Die Grundfarbe steht nicht darin und kann
    deshalb nie zur Kategorienfarbe werden.
  - Auf `papier` erreichen nur sieben der 15 Farben 3 : 1. Für die zehn Kategorien kommen drei
    deshalb doppelt vor; eine Marke gehört über ihre beschriftete Zeile zur Kategorie, die Farbe
    hilft nur.
- **Alternativen:** Godots Standard-Theme (von Klaus verworfen, Option „nüchternes Werkzeug“);
  Pixelschriften der Spieloberfläche (bei voller Auflösung winzig).

## R15 Bearbeiten und Rückgängig

- **Entscheidung:** Alle Änderungen am Katalog laufen über `CatalogEditor`, eine Klasse ohne
  Oberfläche, mit einem `UndoRedo`:
  - Jede Änderung ist eine Aktion mit `add_do_method`/`add_undo_method`.
  - Ein Ziehen auf dem Zeitstrahl wird erst beim Loslassen zu einer Aktion, ein Cmd+Z nimmt also
    das ganze Ziehen zurück.
  - Ob es ungespeicherte Änderungen gibt, sagt der Vergleich von `get_version()` mit dem Stand
    beim Speichern; laut Doku ist sie genau dafür da.
- **Kürzel:** `InputEventKey` mit `command_or_control_autoremap = true`: Cmd auf dem Mac, Ctrl
  unter Windows und Linux. Belegt sind S, Z und Shift+Z.
- **Eingabefelder:** Ein Feld übernimmt seinen Wert beim Verlassen oder mit Enter. Enter gibt dabei
  den Fokus ab; sonst gehörte das nächste Cmd+Z noch dem Textfeld und erreichte den Verlauf des
  Katalogs nicht.
- **Verwerfen:** `revert()` liest die Datei neu, leert den Verlauf und löscht die Sicherungskopie
  (FR-034).
- **Speichern mit Fehlern:** Hat der Katalog Fehler, fragt die Werkstatt vor dem Speichern nach
  (FR-034). Die Meldungen beim Lesen (V22) behält der `CatalogEditor` bis zum nächsten Speichern,
  auch wenn die laufende Prüfung sie nicht kennt. Ein unbekannter Schlüssel geht so nicht still
  verloren: Er ist ein Fehler, und verworfen wird er erst, wenn Klaus die Rückfrage bestätigt.
- **Schließen:** `get_tree().auto_accept_quit = false`; `_notification()` fängt
  `NOTIFICATION_WM_CLOSE_REQUEST` ab und fragt bei ungespeicherten Änderungen nach. Ob Cmd+Q unter
  macOS dieselbe Meldung schickt, prüft der Quickstart.
- **Fremde Änderung:** Beim Öffnen merkt sich die Werkstatt `FileAccess.get_modified_time()`. Hat
  sich der Wert vor dem Speichern geändert, fragt sie nach.
- **Probe:** `UndoRedo.new()` funktioniert außerhalb des Editors: Aktion ausgeführt, `undo()` nimmt
  sie zurück, `get_version()` zählt hoch.
- **Hinweis:** `UndoRedo` erbt von `Object`, nicht von `RefCounted`. `CatalogEditor` muss es
  beim Abräumen selbst freigeben (`NOTIFICATION_PREDELETE`).
- **Alternativen:** eigener Verlauf mit Kopien des ganzen Katalogs (einfach, aber bei jedem
  Tastendruck eine Kopie); `EditorUndoRedoManager` (nur in Editor-Plugins).

## R16 Zeitstrahl

- **Entscheidung:** Ein eigenes `Control` (`TimelineView`):
  - **Zeichnen:** `_draw()` zeichnet Jahresachse, eine Zeile je Kategorie, fixe Ereignisse als
    Punkt oder Balken, Zeitfenster als Rahmen und Wahrscheinlichkeiten als Band mit Prozentzahl.
  - **Maus:** `_gui_input()` übernimmt Ziehen, Doppelklick und Rechtsklick (dann ein
    `PopupMenu`). Hinweise liefert `_get_tooltip(at_position)`; sie erscheinen, solange
    `mouse_filter` nicht `IGNORE` ist.
  - **Zoom:** mit dem Mausrad bei gedrückter Cmd- bzw. Ctrl-Taste, um die Mausposition herum.
  - **Verschieben:** Mausrad, Shift+Mausrad oder Ziehen auf leerer Fläche.
  - **Genauigkeit:** Ab der Monatsansicht sind Tage als Striche zu sehen. Beim Ziehen steht das
    Datum tagesgenau neben dem Mauszeiger.
  - **Vorschau beim Ziehen:** Bis zum Loslassen ändert sich der Katalog nicht (R15). Der Zeitstrahl
    prüft eine Kopie des Ereignisses mit dem neuen Wert über `CatalogValidator.validate_event()`
    und zeigt einen Fehler sofort am Mauszeiger, etwa wenn Anzahl und Mindestabstand nicht mehr ins
    Fenster passen (US4, Szenario 2).
- **Begründung:** Eigenes Zeichnen ist für eine Achse mit Hunderten Marken das Übliche und
  schnell. Zugleich lernt Klaus dabei, was er für Spielansichten braucht: `_draw`, Eingaben,
  Tooltips.
- **Alternativen:** je Ereignis ein eigenes Control in einem Container (viele Nodes, Zoom wird
  zäh); `GraphEdit` (für Knotengraphen gedacht, nicht für Zeitachsen).

## R17 Statistik ohne Ruckeln

- **Entscheidung:** `TimelineStatistics` rechnet in Häppchen nach Zeit. Die Werkstatt ruft je Bild
  `run_for(15)` auf und wartet dazwischen mit `await get_tree().process_frame`:
  - `run_for()` spielt das laufende Spiel monatsweise weiter und beginnt danach das nächste, bis
    15 ms verbraucht sind (gemessen mit `Time.get_ticks_usec()`).
  - Abbrechen setzt ein Flag; das Ergebnis der fertigen Spiele bleibt stehen, das angefangene zählt
    nicht.
  - Mit Stichtagen (R6) dauert ein Spiel mit dem übernommenen Katalog wenige Millisekunden,
    1.000 Spiele also Sekunden (SC-004).
- **Begründung:** Häppchen im Hauptthread sind einfach zu verstehen und brauchen keinen Schutz
  vor gleichzeitigem Zugriff. Ein Zeitbudget statt einer festen Zahl von Spielen hält die
  Werkstatt auch mit 500 Ereignissen bedienbar: Dort dauert ein Spiel 0,1 bis 0,2 s (R21), und
  25 Spiele je Bild ließen sie sekundenlang einfrieren. Ein einzelner Monat dauert auch dann nur
  etwa eine Millisekunde.
- **Alternativen:** `Thread` oder `WorkerThreadPool` (schneller auf vielen Kernen, aber Katalog
  und Ergebnis müssten gegen gleichzeitigen Zugriff geschützt werden, für einen Lernenden ein
  Minenfeld); alles in einem Zug (die Werkstatt friert ein, Abbrechen ginge nicht).

## R18 Textausgabe auf der Konsole

- **Entscheidung:** Ein SceneTree-Skript `src/tools/werkstatt/fahrplan_ausgabe.gd`:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --bis 1999-12-31
  ```

  - Optionen nach `--`, gelesen mit `OS.get_cmdline_user_args()`: `--katalog` mit einem Pfad zu
    einem anderen Katalog, `--protokoll` für alle Meldungen statt nur der Termine.
  - Die Textausgabe spielt den Lauf bis `--bis` ab, ohne Angabe bis zum 31.12.1999, und gibt dann
    den Fahrplan bis zu diesem Tag aus. So stehen auch gewürfelte Termine und Folgetermine darin.
  - Die Zeilen baut `ScheduleText`. Dieselbe Klasse nutzen die Tests, die die Ausgabe vergleichen.
  - Bei Katalogfehlern stehen die Meldungen auf stderr. Die Ausgabe läuft trotzdem, ohne die
    fehlerhaften Ereignisse wie im Spiel, und der Exit-Code ist 1. Ist der Katalog nicht lesbar,
    gibt es nur die Meldung, ebenfalls mit Exit-Code 1.
- **Begründung:** Die Doku nennt `-s` mit `extends SceneTree` als Weg für Skripte ohne Szene. Eine
  Textausgabe lässt sich mit `diff` vergleichen (SC-002).
- **Alternativen:** eine Szene mit `--quit-after` (startet unnötig die Oberfläche); ein
  EditorScript (nur im Editor, nicht im Terminal).

## R19 Übernahme der vorhandenen Ereignisse

- **Entscheidung:** In drei Schritten; die ersten beiden laufen, solange der alte Code noch da ist:
  1. **Schnappschuss:** Ein Einmal-Skript außerhalb des Repos erzeugt mit dem alten
     `EventDatabase` die Datei `src/test/fixtures/historische_ereignisse.txt`. Darin steht je
     fixes Ereignis eine Zeile mit Datum, Kennung und Wirkungen.
  2. **Katalog:** Ein zweites Einmal-Skript schreibt aus denselben Daten
     `src/data/event_catalog.json`, dazu die zehn Kategorien samt „Kalender“ mit ihren
     Startfarben:
     - Kategorie-Enum → Kategorie-Kennung (`hardware` …).
     - `earliest_year`/`latest_year` → Zeitfenster 01.01. bis 31.12.
     - `cooldown_days` → `min_gap_days`.
  3. **Normalisieren und einfrieren:** Sobald es `EventCatalog` gibt, wird der Katalog einmal mit
     `read_file()` gelesen und mit `write_file()` geschrieben. Erst danach hat er sicher die
     kanonische Form, die das Einmal-Skript ohne die neuen Klassen nur nachahmen kann. Eine Kopie
     wird zur eingefrorenen Übernahme `src/test/fixtures/event_catalog_uebernahme.json`; an ihr
     wird SC-005 geprüft, und sie ändert sich nie mehr.

  Gelöscht werden `event_database.gd`, die alten Tests und `timeline_demo` im selben Schritt, in
  dem `TimelineEvent` und `EventEffect` umgebaut werden; dazwischen kompilierte der alte Code
  nicht. Die Kalender-Ereignisse legt Klaus mit User Story 3 in der Werkstatt an.
- **Startwerte der Kalender-Ereignisse** (Klaus stellt in der Werkstatt nach):

  | Ereignis | Termin | Wirkung |
  |---|---|---|
  | Weihnachtsgeschäft | 01.11. bis Ende Dezember | „Kundenstrom alles +30 %“, gilt während |
  | Frühling, Sommer, Herbst, Winter | je 1. März, Juni, September, Dezember bis zum Monatsende vor der nächsten | keine |
  | CeBIT | 15. bis 21. März, ab 1986 | Pressemeldung mit Ziel `messe`, einmaliger Anstoß |
- **Begründung:** Der Schnappschuss belegt SC-005 („wie vor dem Umbau“) auch dann noch, wenn der
  alte Code weg ist. Die eingefrorene Kopie hält den Nachweis fest, auch wenn Klaus den echten
  Katalog in der Werkstatt ändert. Ein Skript überträgt 25 Ereignisse fehlerfrei; von Hand
  abzuschreiben wäre fehleranfällig.
- **Alternativen:** von Hand abschreiben; den alten Code als Prüfreferenz behalten (toter Code,
  den 01-01 ausdrücklich nicht will).

## R20 Tests

- **Entscheidung:** GUT-Tests je Klasse unter `src/test/`. Sie arbeiten mit Test-Katalogen unter
  `src/test/fixtures/`, nie mit dem echten Katalog. Ausnahmen:
  - `test_shipped_catalog.gd` prüft am echten Katalog nur, was dauerhaft gelten muss: keine
    Fehler (FR-048), die Kalender-Ereignisse aus FR-023 und das Weihnachtsgeschäft in allen
    15 Jahren (SC-009).
  - `test_uebernahme.gd` prüft die eingefrorene Übernahme (R19): 25 Ereignisse, zehn Kategorien
    und die 19 historischen Termine für 100 Seeds wie im Schnappschuss (SC-005).

  Dazu:
  - Jede Prüfregel bekommt eine kaputte Fixture (SC-006).
  - `test_large_catalog.gd` misst für SC-011 die Prüfung, eine Änderung über den `CatalogEditor`
    samt neuer Prüfung und ein ganzes Spiel.
  - Der Rauchtest lädt die Werkstatt headless und prüft, dass sie ohne Fehler aufbaut.
  - Zeitstrahl, Formulare, Fenster und Look prüft Klaus von Hand nach dem Quickstart.
- **Begründung:** Abnahme unabhängig vom Spielinhalt (Annahme in der Spec); der echte Katalog
  ändert sich laufend in der Werkstatt. Ein Test, der ihn Zeile für Zeile prüft, bräche bei der
  ersten Änderung, die Klaus macht.

## R21 Größe des Katalogs

- **Entscheidung:** Ausgelegt wird für bis zu 500 Ereignisse. SC-004 gilt für den übernommenen
  Katalog, SC-011 für einen erzeugten Test-Katalog mit 500 Ereignissen, je zur Hälfte fix und über
  Wahrscheinlichkeit: ein Spiel unter 2 s, Statistik über 1.000 Spiele unter 5 Minuten, Prüfung
  und Ziehen unter 100 ms.
- **Abschätzung:** 250 Ereignisse über Wahrscheinlichkeit würfeln in 180 Monaten je zweimal, das
  sind 90.000 Würfe je Spiel. Bei 1 bis 2 µs je Wurf samt Prüfung sind das 0,1 bis 0,2 s je
  Spiel und für 1.000 Spiele 2 bis 4 Minuten.
- **Begründung:** Die Ideensammlung („Zeitgeschehen in der Zeitung“) kann einige Hundert reine
  Meldungen bringen; mehr ist nicht absehbar.

## R22 Was-wäre-wenn-Proben speichern

- **Entscheidung:** Je Probe eine JSON-Datei unter `src/tools/werkstatt/proben/`, kanonisch
  geschrieben wie der Katalog (data-model.md, WhatIfProbe).
  - Gespeichert werden der Seed, der Tag, bis zu dem der Lauf abgespielt war, und das
    Eingriffsprotokoll (R11): jeder Eingriff mit dem Tag, an dem er geschah.
  - Absagen und Verschiebungen merken sich Ereignis und Tag statt der laufenden Nummer.
  - Beim Laden legt `WhatIfProbe.build_run()` einen Lauf mit dem Seed der Probe an, spielt ihn bis
    zum Tag jedes Eingriffs ab und wendet ihn dort an. Die nicht anwendbaren Eingriffe gibt sie als
    Sätze zurück (FR-051). Genauso startet der Simulator „mit Eingriffen“ neu.
  - Der Ordner hat eine Vorgabe und lässt sich angeben; die Tests schreiben in einen eigenen.
- **Begründung:** Im Projektordner landen die Proben in der Versionsverwaltung. So lässt sich eine
  Balance-Probe auch nach Wochen wiederholen. Mit dem Ordner `tools/` sind sie vom Export
  ausgeschlossen. Die laufende Nummer eines Termins hängt davon ab, wie der Katalog gerade
  aussieht; Ereignis und Tag dagegen sind das, was Klaus abgesagt hat. Alle Eingriffe vor dem
  ersten Tag anzuwenden reicht nicht: Ein gewürfelter Termin entsteht erst im Lauf, seine Absage
  ginge vorher ins Leere.
- **Alternativen:** Proben unter `user://` (nicht versioniert, auf einem anderen Rechner weg);
  alle Proben in einer Datei (jede Änderung einer Probe berührt alle).

## R23 Sicherungskopie der Werkstatt

- **Entscheidung:** Ein `Timer` ruft alle 120 Sekunden `CatalogEditor.write_backup()` auf. Gibt es
  ungespeicherte Änderungen, schreibt die Methode nach `user://werkstatt_sicherung.json`, kanonisch
  wie den Katalog: `{"catalog": {…}, "format": 1, "path": "<Pfad des Katalogs>", "saved":
  <Unix-Zeit>}`.
  - Beim Start fragt die Werkstatt, ob sie die Kopie übernehmen oder verwerfen soll. Dabei nennt
    sie die Zeiten von Kopie (`saved`) und Katalogdatei (`FileAccess.get_modified_time()`).
  - Angeboten wird nur eine Kopie, deren `path` zum geöffneten Katalog passt. Die Kopie eines
    anderen Katalogs bleibt liegen, und ein Hinweis nennt ihren Pfad.
  - Nach dem Speichern, nach dem Verwerfen und beim regulären Schließen löscht sie die Kopie
    (FR-050).
  - Der Pfad der Kopie hat diese Vorgabe und lässt sich ändern; die Tests nutzen eine eigene Datei.
- **Begründung:** `user://` liegt außerhalb des Projekts, die Kopie gerät also nie aus Versehen in
  einen Commit. Zwei Minuten begrenzen den Verlust bei einem Absturz und kosten bei einem kleinen
  Katalog nichts.
- **Alternativen:** Kopie neben dem Katalog (könnte mitcommittet werden); Kopie nach jeder Änderung
  (bei 500 Ereignissen unnötige Schreiblast).

## R24 Vergleich zweier Durchläufe

- **Entscheidung:** Läuft ein Durchlauf mit Eingriffen, rechnet der Simulator denselben Seed ohne
  Eingriffe bis zum selben Tag mit. `ScheduleDiff.compare()` paart dann je Ereignis die Termine:
  1. erst Termine am selben Tag; ein Paar mit anderem Zustand gilt als „anderer Zustand“;
  2. dann Termine, die ein Eingriff verschoben hat: Ein Termin mit `moved_from_day` paart sich mit
     dem Termin desselben Ereignisses an diesem ursprünglichen Tag und gilt als „verschoben“;
  3. was übrig bleibt, ist „neu“ oder „weggefallen“.
- **Begründung:** Dank der unabhängigen Würfel (R5) unterscheiden sich beide Läufe nur dort, wo die
  Eingriffe wirken. Die Paarung je Ereignis zeigt das ohne Rauschen. Die Kosten sind ein zweiter
  Lauf, also Millisekunden. „Verschoben“ heißt nur, was wirklich verschoben wurde: Ein Modifikator
  bringt Termine dazu oder nimmt welche weg. Würde der Vergleich die übrigen einfach der Reihe nach
  paaren, hieße ein weggefallener Termin 1995 zusammen mit einem neuen 1992 „verschoben“.
- **Alternativen:** Vergleich über die laufende Nummer (stimmt nicht mehr, sobald ein Termin
  dazukommt); nur die Protokolle als Text vergleichen (zeigt Zeilen, nicht Termine).
