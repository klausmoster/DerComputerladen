# Recherche: Ladeneröffnung

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md). Die Recherche zu Mieten und Startkapital
steht in [recherche-geld.md](recherche-geld.md).

Wer entschieden hat, steht an jeder Entscheidung. „Claude, 2026-10-29“ heißt: eigene Festlegung,
eingetragen in `docs/offene-punkte.md`, Abschnitt „Feature 010, Plan“; Klaus kann sie bei der
Checkliste oder jeder Abnahme ändern. Eine Entscheidung ohne Vermerk ist eine solche Festlegung
von Claude.

Nachgeschlagen in der lokalen Godot-Referenz (`godot_referenz/`, Godot 4.7.2): `LineEdit`
(`max_length`, `text_change_rejected`), `Control` (`mouse_default_cursor_shape`, Fokus),
`GameClock` im Projekt (`month_passed` kommt am Ersten mit dem neuen Datum).

## R1 Drei Szenen hintereinander: Titel, Büro des Maklers, Spielbildschirm

**Entscheidung:** Die Gradwahl legt kein Spiel mehr an. Sie beginnt eine **Ladeneröffnung**
(`GameSession.begin_opening(grad)`), der Communicator fährt hinaus wie bisher, und statt des
Spielbildschirms kommt die neue Szene `res://scenes/opening/broker_office.tscn`, das Büro des
Maklers. Dort laufen Stadtplan, Exposé, Mietvertrag und Gewerbeanmeldung. Erst die abgegebene
Anmeldung ruft `GameSession.start_new()`, das wie bisher erst schreibt und dann startet; danach
wechselt das Büro zum Spielbildschirm. „Zurück“ vom Stadtplan wechselt zum Titel; der Titel sieht
die offene Eröffnung, zeigt die Gradwahl mit dem gewählten Grad vorgewählt und beendet die
Eröffnung (`GameSession.end_opening()`).

**Grund:** FR-003 verlangt, dass vor der Anmeldung nichts geschrieben wird; das alte „Erst
schreiben, dann starten“ bleibt, nur später. Die offene Eröffnung ist kleiner Ablaufzustand über
einen Szenenwechsel hinweg, genau das, was ein Autoload halten darf (AR-01, AR-03); ein neues
Autoload braucht es nicht. Das Büro bleibt eine eigene Szene, die ein späterer Umzug wieder
öffnen kann (Klaus, 2026-10-29).

**Verworfen:**
- Das Spiel bei der Gradwahl anlegen und den Laden später nachtragen: Bricht der Spieler im Büro ab,
  läge ein Spielstand ohne Laden im Ordner (widerspricht FR-003 und SC-007).
- Die Ladenwahl als Seiten im Titel: Klaus hat das Büro als Adventure-Szene gewählt.
- Den Grad über eine statische Variable oder einen Szenenparameter weitergeben: Godot kennt keine
  Parameter für `change_scene_to_file()`, und eine statische Variable wäre ein verstecktes
  Autoload.

## R2 Ein Kern für die Eröffnung: `ShopOpening`

**Entscheidung:** `ShopOpening` (`src/core/shop/shop_opening.gd`, `RefCounted`) hält Grad,
Startkapital, die Angebote der Stadt, den gewählten Laden und den Schritt als `enum Step { MAP,
EXPOSE, LEASE, REGISTRATION }` (AR-11). Er beantwortet, ob ein Laden bezahlbar ist, nennt Kaution
und Kapitalnachweis, blättert, geht einen Schritt zurück, nimmt die Unterschrift an und prüft den
Ladennamen. Das Büro ist nur die Hülle: Es zeigt das Blatt zum Schritt und meldet, was der Spieler
will.

**Grund:** So lässt sich der ganze Ablauf ohne Szene testen, auch „auf Schwer ist die
Fußgängerzone grau“ und „Zurück aus jedem Schritt“ (AR-01, AR-15). Die Regeln stehen einmal.

**Verworfen:** Den Ablauf im Skript des Büros: nicht ohne Szene testbar, und ein Umzug müsste die
Regeln kopieren.

## R3 Geld in Pfennig, Beträge als Stellschrauben

**Entscheidung:** Alle Beträge sind ganze Zahlen in Pfennig (AR-16, gilt ab diesem Feature).
`Money` (`src/core/shop/money.gd`) formatiert sie nach Style-Guide: „25.680,00 DM“, negativ
mit Minus und „SOLL“ wie im Baustein Anzeige. Die Stellschrauben stehen als Konstanten in `ShopRules`
(`src/core/shop/shop_rules.gd`): Startkapital je Grad (Leicht 10.000.000, Mittel 6.000.000,
Schwer 3.000.000 Pfennig), Kaution `DEPOSIT_MONTHS = 3`, Kapitalnachweis `PROOF_MONTHS = 6`
zusätzlich zur Kaution, Mietbeginn 01.01.1985, erster Monat mietfrei.

**Grund:** AR-04 trennt Spielinhalt (Mieten, aus der game_bible) von Stellschrauben einer Mechanik
(Startkapital je Grad, Anzahl Monatsmieten); Stellschrauben stehen als benannte Konstanten an einer
Stelle, wie `UiPalette`. Pfennig, weil später Preise wie 2.499,00 DM dazukommen.

**Verworfen:**
- Startkapital in den Profilen der Grade im Ereigniskatalog: Der Katalog ist die Zeitleiste; Geld
  gehört nicht hinein, und die Werkstatt müsste es pflegen.
- Startkapital in der game_bible: Es ist kein Marktwert, sondern Balance.

## R4 Das Konto: `ShopAccount`, gehalten von `GameSession`

**Entscheidung:** `ShopAccount` (`src/core/shop/shop_account.gd`, Kern) hält Kontostand und Miete
in Pfennig und den Monat, bis zu dem die Miete gebucht ist (`rent_paid_through`, ein Monatsindex).
`month_begins(date)` bucht die Miete, wenn `date` ein Erster nach `rent_paid_through` ist, und gibt
den Betrag zurück (0, wenn nichts zu buchen war). `GameSession` besitzt das Konto des laufenden
Spiels, hängt es an `GameClock.month_passed` und sendet `account_changed(balance)`. Beim Speichern
schreibt es Kontostand und Monat in den Spielstand, beim Fortsetzen baut es das Konto daraus.

**Grund:** Miete ist Mechanik eines Kerns, kein Ereignis der Zeitleiste; den Monatswechsel reicht
die Hülle hinein (AR-07, Wortlaut der Aussage). Mit `rent_paid_through` wird jede Miete genau
einmal gebucht, auch wenn die Uhr beim Fortsetzen still springt (FR-023, SC-004). Ein Lager oder
Konto ist laut AR-03 ein Kern, den `GameSession` besitzt.

**Verworfen:**
- Den Kontostand aus dem Spieldatum ausrechnen statt speichern: Stimmt heute, aber nicht mehr,
  sobald Verkäufe dazukommen.
- Die Miete als festes jährliches Ereignis im Katalog: Der Katalog kennt keine Beträge je Laden,
  und AR-07 nimmt Regelmäßiges wie Miete ausdrücklich aus.

## R5 Spielstand: zwei neue Pflichtteile, Formatversion bleibt 1

**Entscheidung:** Der Spielstand bekommt die Pflichtschlüssel `shop` (Kopie der Werte des Ladens
bei der Anmeldung) und `account` (Kontostand in Pfennig, Miete gebucht bis `"JJJJ-MM"`). `name` ist
der Ladenname. Die Formatversion bleibt 1, es gibt keine Umwandlung: Eine Datei ohne `shop` oder
`account` ist beschädigt mit dem bisherigen Grund „Lässt sich nicht lesen: Ein Teil der Datei
stimmt nicht.“ (FR-031, Klaus, 2026-10-29).

**Grund:** Klaus: „Ich möchte keinen Code drin haben, der Sonderlocken für alten Käse hat.“ Bis es
eine herausgegebene Version gibt, ist jede Formatversion 1. AR-13 bleibt erfüllt: Der Spielstand
sagt klar, dass er sich nicht lesen lässt, und nennt alles über feste Namen; der Laden steht mit
seiner ID und allen Werten darin, nicht als Position in einer Liste.

**Verworfen:** Formatversion 2 mit `_upgrade()` von 1: Sonderweg für alte Spielstände, den Klaus
nicht will. Nur die ID des Ladens speichern: FR-030 verlangt die Werte von damals.

## R6 game_bible als Quelle, ein Importer schreibt Resources

**Entscheidung:** Neu in der game_bible:
- `Templates/TEMPLATE_Laden.md` und je Laden eine Notiz unter `Läden/`, etwa
  `Läden/Fußgängerzone.md`; Miete als Zeitreihe `preise_miete` mit `datum`, `von`, `bis` in DM wie
  bei den Komponenten.
- `Templates/TEMPLATE_Stadt.md` und `Stadt/<Name>.md` mit Name, Einwohnern und Vierteln.
- `Templates/TEMPLATE_Figur.md` und `Figuren/Makler.md` mit Steckbrief und den Sätzen (R9).

Der Importer `tools/bible/importiere.py` (Python, `[C]`) liest die Notizen und schreibt
`src/data/stadt.tres` (`CityData`), `src/data/laeden/<id>.tres` (`ShopOffer`) und
`src/data/figuren/<id>.tres` (`FigureData`). Für die Miete nimmt er den Eintrag mit `datum`
„1985-01“ und verlangt `von` gleich `bis`; ein Laden hat eine Miete, keine Spanne. Jede erzeugte
Datei trägt im Kopf „Erzeugt von tools/bible/importiere.py aus docs/game_bible/…; nicht von Hand
ändern.“ Ein Lauf ohne Änderung in der game_bible ändert keine Datei (bytegleich).

**Grund:** AR-04: Mieten sind Spielinhalt, Quelle ist die game_bible, Resources entstehen über
einen Importer, nie von Hand (Klaus, 2026-10-29). Der Importer ist der erste Schritt zu 02-01
(Bible-Importer) und taugt später für Produkte.

**Verworfen:** `.tres` von Hand, eine JSON-Datei wie der Katalog (beides Ausnahmen von AR-04, von
Klaus verworfen). Den Importer in GDScript als Editor-Plugin: Die game_bible liegt außerhalb von
`src/`, und `regenerate_tables.py` liest das Frontmatter schon mit Python.

## R7 Ladenname: Regeln in einem Kern, Feld aus `LineEdit`

**Entscheidung:** `ShopName` (`src/core/shop/shop_name.gd`) prüft und säubert: Leerzeichen am
Anfang und Ende fallen weg, mehrere Leerzeichen werden eines, dann 1 bis 24 Zeichen
(`MAX_LENGTH`), nur Zeichen aus `ALLOWED`: Buchstaben A–Z und a–z, ÄÖÜäöüß, Ziffern, Leerzeichen und
`. , - & ' / + ( )`; „!“ und „?“ nicht, damit ein Name im Satz kein Satzende vortäuscht (Checkliste,
CHK026). Das Feld auf der Gewerbeanmeldung ist ein `LineEdit` mit `max_length` 24,
das unerlaubte Zeichen beim Tippen nicht annimmt. Ein Test prüft, dass Ark Pixel 10 und 12 jedes
erlaubte Zeichen haben.

**Grund:** Die Regel steht einmal, im Kern, und gilt auch, wenn später ein Umzug oder eine
Umbenennung den Namen setzt. 24 Zeichen sind vorläufig (FR-016): Der Plan misst sie in Liste,
Hinweis, Rückfrage und Bedienleiste mit „Wöhrmann & Söhne Computer“-artigen Namen aus breiten
Zeichen; passt es nicht, wird die Grenze kleiner, nicht die Schrift.

**Verworfen:** Jedes Zeichen der Schrift zulassen: Die Schrift hat Zeichen, die im Spiel nichts zu
suchen haben, etwa Steuerzeichen und Pfeile. Ein eigenes Eingabefeld aus Labels: `LineEdit` kann
Cursor, Markieren, Einfügen und Rückgängig schon.

## R8 Bausteine des Adventures ohne Inhalt

**Entscheidung:** Neue Bausteine unter `src/ui/adventure/`, die keinen Inhalt kennen (AR-18):
- **Anklickbare Stelle** `Hotspot` (`Control`): Fläche, Beschriftung, Mauszeiger, Fokus per
  Tastatur, Signal `activated`. Was sie bedeutet, legt die Szene fest, die sie einsetzt.
- **Sprechblase** `SpeechBubble`: zeigt einen Satz neben einer Stelle, verschwindet nach Zeit oder
  Klick.
- **Papierblatt** `PaperSheet` unter `src/ui/paper/`: ein Blatt, das herangeholt über der Szene
  liegt, mit Platz für Inhalt und den Knöpfen „Zurück“ und einer Handlung.
Das Büro (`src/scenes/opening/`) setzt sie ein: Stadtplan, Schreibtisch und Makler sind Hotspots
in der Szene, Stadtplan, Exposé, Mietvertrag und Anmeldung je eine eigene Szene auf einem
Papierblatt.

**Grund:** AR-05 und AR-18: Ein späterer Ort, etwa der Großhändler, nutzt dieselben Bausteine,
ohne sie zu ändern. Die Lage der Hotspots gehört zum Raum, also zur Szene des Büros, nicht in die
Daten der Läden (Spec, Annahme „Grafiken“).

**Verworfen:** `Area2D` mit `CollisionShape2D` für Hotspots: Die Oberfläche ist aus `Control`s;
Fokus per Tastatur und Tooltip gibt es dort umsonst.

## R9 Sätze des Maklers als Daten

**Entscheidung:** Die Sätze stehen in der Figur-Notiz der game_bible als Liste `saetze` mit
`anlass` und `text`, etwa `anlass: expose_fussgaengerzone`. Der Importer schreibt sie in
`FigureData.lines` (Anlass → Sätze). Das Büro fragt die Figur nach dem Satz zu einem Anlass; gibt
es mehrere, nimmt es den nächsten der Reihe nach (kein Zufall, AR-08). Klick auf den Makler nimmt
den Anlass `klick`.

**Grund:** AR-20, Dialoge als Daten, gilt ab diesem Feature; feste Sätze sind der einfachste
Dialog. Der Text-Prüfer findet sie an einer Stelle. Ein späterer Dialog (09-02) baut auf denselben
Anlässen auf.

**Verworfen:** Sätze als Konstanten in einer Textklasse: wären Inhalt im Code und müssten für den
Umzug kopiert werden.

## R10 Spielbildschirm: Bildrahmen, Ladenbild, Bedienleiste mit Anzeige und Uhr

**Entscheidung:** Der Spielbildschirm verlässt den Platzhalter aus Feature 004 und folgt dem
Style-Guide, „Bildaufbau“: Bildrahmen mit dem Inneren des Ladens (312 × 144 Bildpixel), darunter
die Bedienleiste. Gebaut wird in 010 nur, was das Feature braucht: Ortsbild (Laden von außen), die
Leuchtanzeige mit Datum und Kontostand, die Bedienung der Uhr und „Zum Hauptmenü“. Die sechs
Symbolknöpfe und das Porträt kommen mit ihren Features. Wie die Uhr in der Leiste bedient wird,
regelt zuerst der Style-Guide (R14).

Die Uhr: Der Bildschirm erscheint angehalten (FR-027). Tempi 1, 2 und 7 Tage je Sekunde als
Konstanten (`GameScreen.SPEEDS`), Vorgabe 1. `GameSession.leave()` hält die Uhr an, damit auf dem
Titel keine Zeit vergeht.

**Grund:** Der Style-Guide hat Bildrahmen und Bedienleiste schon; der Spielbildschirm ist der Ort,
an dem sie zum ersten Mal gebraucht werden. Die Bedienleiste sagt „keine weiteren Knöpfe, ohne sie
hier einzutragen“, deshalb zuerst der Style-Guide.

**Verworfen:** Ein eigener Spielbildschirm ohne Rahmen und Leiste für 010: Er müsste mit dem
nächsten Feature umgebaut werden.

## R11 Bilder: Platzhalter als echte Dateien

**Entscheidung:** Bis zur Phase „Bilder“ liegen Platzhalter als PNG an den endgültigen Pfaden:
`src/assets/images/buero/buero.png` (320 × 180), `stadtplan.png` (Größe im Style-Guide),
`src/assets/images/laeden/<id>_aussen.png` und `<id>_innen.png` (312 × 144), dazu die Figur. Ein
kleines Skript `tools/raster/platzhalter.py` (`[C]`) erzeugt sie: Fläche in `nacht-hell`, Rand in
`tusche`, Beschriftung wie „FOTO FUSSGÄNGERZONE“. Die Phase „Bilder“ ersetzt die Dateien, der Code
bleibt.

Dazu je Laden `<id>_ort.png` mit 60 × 28 Bildpixeln fürs Ortsbild (Checkliste, CHK028).

**Grund:** Kein Code für „Bild fehlt“, den später niemand mehr braucht (Klaus' Satz zu
Sonderlocken gilt sinngemäß). Pfade und Größen stehen von Anfang an fest. Dass die Platzhalter
Text im Bild tragen, verstößt bewusst und nur bis Phase 8 gegen „kein Text im Szenenbild“; ein
Test vor der Gesamtabnahme prüft, dass keiner mehr da ist (CHK036).

**Verworfen:** Fehlende Bilder im Code durch farbige Flächen ersetzen.

## R12 Selbsttest und Fabrik für Spielstände

**Entscheidung:** Der Ablauf `neues_spiel` endet nicht mehr im Spielbildschirm, sondern im Büro;
ein neuer Ablauf `ladenwahl` führt durch Stadtplan, Exposé, Mietvertrag und Anmeldung bis in den
Laden, mit einem festen Namen. Der Fahrer baut Spielstände für andere Abläufe nicht mehr selbst,
sondern über eine Fabrik in `src/core/save/` (`SaveGameFactory.new_game()`), die auch
`GameSession.start_new()` nutzt.

**Grund:** Jede neue Seite, jeder Weg und jede Eingabe braucht einen Schritt im Selbsttest
(Fahrplan, D1). Die Fabrik behebt zugleich den Befund B4 aus Feature 007 (11-09): Mit `shop` und
`account` müsste der Fahrer sonst noch mehr nachbauen.

**Verworfen:** Den Fahrer nur um die neuen Felder erweitern: zwei Stellen, die wissen, wie ein
neuer Spielstand aussieht.

## R13 Rückfrage beim Löschen: schon mit Grad und Spieldatum

**Entscheidung:** Nichts Neues zu bauen. Die Hinweise der Rückfrage nennen schon heute Name, Grad
und Spieldatum, etwa „Computer Klaus ist danach weg: Schwer, 14.03.1986. Für immer.“
(`TitleTexts.HINT_CONFIRM_DELETE`, `CONFIRM_DETAILS`). Damit ist FR-018 erfüllt. Zu messen ist nur,
dass ein Name mit 24 breiten Zeichen in Liste, Rückfrage und Hinweisen passt (R7).

**Grund:** Zwei Spiele dürfen gleich heißen (Klaus, 2026-10-29); Feature 004 hat die Angaben in
der Rückfrage schon so gebaut, damals für „Spiel 9999“.

## R14 Offene Fragen an den Style-Guide

Vor dem Bau der Oberfläche ergänzt Claude den Style-Guide (`[C]`), Klaus gibt frei (Verfassung
IV). Offen sind:
1. **Weiter-Pfeil oder Uhr:** Die Bedienleiste hat einen „Weiter-Pfeil, beendet den Tag“. Mit der
   laufenden Uhr (FR-027) passt das nicht. Vorschlag: Der Pfeil wird zu Pause/Weiter, das Tempo
   wechselt mit Rechtsklick auf den Pfeil oder mit Tasten, die nicht 1 bis 6 belegen.
2. **Ladenname im Bild:** Die Leiste erlaubt Text nur in der Anzeige. Vorschlag: Der Name steht als
   Schild über dem Ladenbild im Bildrahmen, wie eine Leuchtreklame, gesetzt von der Oberfläche.
3. **Büro als Szene:** Vollbild ohne Rahmen oder im Bildrahmen mit Leiste (dann mit Datum und
   Kapital in der Anzeige)?
4. **Neue Bausteine:** anklickbare Stelle, Sprechblase, Papierblatt (Exposé, Mietvertrag,
   Formular, Stempel „zu teuer“, Kleingedrucktes), Eingabefeld, Markierung auf dem Stadtplan
   (bezahlbar, grau, gewählt).
5. **Größe des Stadtplans** und der Fotos auf dem Exposé; Bilder auf Blättern stehen auf geraden
   Koordinaten, damit sie auf dem Bildraster liegen.

Ergänzt nach der Checkliste (CHK012, CHK030 bis CHK037, Klaus, 2026-10-29):
6. **Ortsbild** in 010 ohne Klick, nur mit Tooltip; der Stadtplan ist im Büro.
7. **Markierung „nicht mietbar“**: ein eigener Zustand, der kein „gedämpft“ ist, weil er das Exposé
   öffnet; Farbe aus der Palette. Wählt die Markierung wie ein Menü oder wie ein Knopf mit Fokus?
8. **Hotspot**: Hover in `signalgelb` und Fokuslinie auf einem unruhigen Bild.
9. **Blatt**: einzelner Bogen mit oder ohne Lochrand; Fließtext `menue`, Kleingedrucktes `text`;
   Lage der Knöpfe; `pixelschatten`; Übergang beim Heranholen und Blättern; Preise in `kassenrot`?
10. **Stempel** ungedreht, Farbe; **Unterschrift** als gezeichneter Schriftzug.
11. **Eingabefeld**: Grund, Schreibmarke, Markierung, Fokus; der Grund unter dem Feld als Text des
    Formulars; Meldung links neben „Anmelden“.
12. **Sprechblase** (Feld, Zipfel, Schrift, Breite, Zeilen, Lage, Erscheinen) und ob das Porträt in
    der Leiste den Sprechenden zeigt.
13. **„Zum Hauptmenü“** neben Rahmen und Leiste, mit Tooltip statt Hinweis.
14. **Anzeige**: Größe von `anzeige-ziffern`, fehlendes Token `zeile-klein`; Datum blinkt bei
    laufender Uhr nicht, der Kontostand bei jeder Buchung.
15. **Leertaste** gehört auf dem Spielbildschirm der Uhr; Knöpfe lösen dort nicht mit ihr aus.
16. **Ton der Papiere der Spielwelt** (Exposé, Mietvertrag, Formular) im Abschnitt „Sprache“.
    Der Teil zum Minus ist vorgezogen und entschieden (T002a, T002b; Klaus, 2026-10-29): der
    Bindestrich „-“, in jeder Schrift gleich, etwa „-4.320,00 DM SOLL“. Geprüft in Godot 4.7.2: Ark
    Pixel 10 und 12 haben kein „−“ (U+2212), nur Doto; „-“ und „–“ haben alle drei. Verworfen: „−“
    nur in der Leuchtanzeige (zwei Regeln), „–“ (eigentlich der Gedankenstrich).

## R15 Fahrplan der Zeitleiste bleibt unberührt

**Entscheidung:** `Timeline` und `TimelineRun` ändern sich nicht. Ein Test vergleicht den Fahrplan
für die Seeds 1, 4711 und 99999 in allen drei Graden bytegleich mit einer eingefrorenen Ausgabe
von vor diesem Feature, je mit jedem der vier Läden (SC-005).

**Grund:** Der Laden darf den Fahrplan nicht verschieben, sonst passen alte Messungen nicht mehr;
Ortsbezug ist 05-03.

## R16 Übersicht der Figuren in der game_bible

**Entscheidung:** Jede Figur des Spiels bekommt eine Notiz unter `docs/game_bible/Figuren/` nach
`TEMPLATE_Figur.md`: Name, Rolle, Alter, Optik in einem Satz, Art zu reden, Charakter, wo sie
vorkommt, ihre Sätze und der Verweis auf ihren Eintrag im Bildkatalog. Die Notiz
`docs/game_bible/Figuren.md` ist die Übersicht aller Figuren als Tabelle, wie `CPUs.md` für die
Prozessoren. Das ganze Aussehen, der feste Prompt-Baustein und das Figurenblatt als Referenzbild
stehen im Bildkatalog `docs/art/bildkatalog.md`, Abschnitt „Figuren“, den `dcl-grafik` pflegt; der
Ladenbesitzer steht dort schon mit F-01 (`docs/art/leonardo/f-01-figurenblatt.jpg`). Den Anfang in
der game_bible machen der Ladenbesitzer und der Makler; der Makler bekommt in Phase 8 seinen
Eintrag im Bildkatalog wie der Ladenbesitzer.

Geändert am 2026-10-29, als der Style-Guide und der Bildkatalog ins Repo kamen (Sitzung
„Style-Guide, Bildkatalog, Obsidian-Vault“): Bis dahin sollte die game_bible auch Optik im Einzelnen
und das Referenzbild führen; das stünde jetzt doppelt (Festlegung von Claude).

**Grund:** Klaus, 2026-10-29: eine Übersicht der Charaktere „inkl. der ganzen Beschreibung. Name,
Alter, Optik (die dann auch wieder als Referenzbild genommen wird) … Stuff für die KI und für die
Doku.“ Die game_bible ist der Spielinhalt und darf von Claude selbstständig befüllt werden; die
Sätze einer Figur liest der Importer aus derselben Notiz (R9), so gibt es eine Quelle.

**Verworfen:** Figuren im Style-Guide: Der regelt das Aussehen aller Figuren, nicht wer sie sind.
Aussehen und Referenzbild auch in der game_bible: zweite Stelle neben dem Bildkatalog.

## R17 Stadt, Straßen und Makler: Vorschläge, Klaus wählt

**Entscheidung:** Claude schlägt je drei Namen für die Stadt vor (fiktiv, westdeutsch, kein
Treffer bei echten Orten über 10.000 Einwohnern), Straßennamen der vier Läden, die Texte der
Exposés mit Kleingedrucktem und den Steckbrief des Maklers mit seinen Sätzen. Klaus wählt und gibt
frei (`[K]`), dann trägt Claude sie in die game_bible ein. Der Text-Prüfer liest sie vorher gegen
den Abschnitt „Sprache“ im Style-Guide.

Das Referenzbild des Ladenbesitzers ist geklärt (Checkliste, CHK020): F-01 liegt unter
`docs/art/leonardo/f-01-figurenblatt.jpg` und steht im Bildkatalog; seine offene Nacharbeit steht
dort und gehört nicht zu diesem Feature.

**Grund:** Name und Ton prägen das Spiel; das ist Klaus' Entscheidung. Die game_bible darf Claude
selbstständig befüllen (CLAUDE.md), aber nicht ohne seine Wahl der Namen.
