# Sprache

Der Computerladen spricht wie „Das Amt“: trocken, knapp, der Witz steckt im Nachsatz. Die Sprache gehört in die Jahre 1985 bis 1999, ohne verkleidet zu klingen. Dieser Abschnitt ist der Maßstab für alle Texte im Spiel und für den Text-Prüfer.

## Leitsätze

- **Trocken statt laut.** Gesagt wird sachlich, die Pointe kommt leise hinterher: „Die Lieferung ist da. Drei Wochen zu spät, aber vollzählig. Fast.“ Keine Ausrufezeichen-Witze, keine Wortspiele um jeden Preis.
- **Bedienung bleibt klar.** Knöpfe, Menüs, Warnungen und Fehlermeldungen sagen ohne Witz, was ist: „Speichern“, „Nicht genug Geld“. Witz gehört in Meldungen, Zeitung, Figuren und Hinweise: „Die Bank lächelt nicht mehr.“
- **Kurz und gesprochen.** Ein Satz pro Meldung, Schlagzeilen höchstens sechs Wörter, ein Hinweis höchstens zwei Zeilen.
- **Maßvoll aus der Zeit.** Klares heutiges Deutsch, dazu Begriffe der Zeit, wo sie passen: Kiste, Rechenknecht, Festplatte statt „Laufwerk C:“. Keine Jugendsprache als Verkleidung.

## Anrede

- Das Spiel duzt den Spieler: Bedienung, Hinweise, Meldungen und Tooltips. „Bald kannst du ihn eröffnen.“ Die Werkzeuge und Probeszenen duzen ebenso; für ihre Texte gelten dieselben Regeln wie im Spiel. Ausgenommen sind Testausgaben im Code, die der Spieler nie sieht.
- Figuren sprechen, wie man damals sprach. Kunden, Bank, Ämter und Lieferanten siezen den Ladenbesitzer: „Haben Sie die neue Soundblaster da?“ Freunde und Familie duzen ihn.
- Briefe und Bescheide in der Spielwelt siezen ebenfalls: „Sehr geehrter Herr …“

## Zahlen, Geld und Daten

- Beträge in DM mit zwei Nachkommastellen: 1.299,00 DM. Negative Beträge mit Minus und SOLL (Abschnitt Farben): -4.320,00 DM SOLL. Das Minus ist der Bindestrich „-“, nicht das Minuszeichen „−“, denn Ark Pixel hat es nicht; so steht es in jeder Schrift gleich (Klaus, 2026-10-29, Feature 010).
- Daten als 14.10.1991, Uhrzeiten als 09:30 Uhr.
- Namen von Einträgen und Graden gelten im Satz als Namen: groß und ohne Anführungszeichen, „Weiter mit Spiel 2, Schwer, am 14.03.1986.“ Zustände wie „beschädigt“ sind keine Namen und stehen klein.
- In Spalten einer Liste steht die Uhrzeit ohne „Uhr“, damit sie in die Spalte passt: „26.10.2026 21:40“. Ausgeschrieben steht sie im Hinweis der Zeile: „Steht am 13.07.1985. Gespielt am 26.10.2026, 21:40 Uhr.“ (Baustein Liste).
- Preise stehen nie in Euro. Den Euro gibt es nur als Thema, etwa in der Zeitung, und erst ab dem 16.12.1995, als sein Name feststand.

## Wortschatz

Begriffe und ab wann sie in Texten stehen dürfen. Gilt ein Begriff erst ab einem Jahr, sagt man vorher das Wort daneben.

| Begriff | ab | vorher |
|---|---|---|
| DM, Diskette, Festplatte, Maus, Drucker | 1985 | |
| Mailbox, Modem, Akustikkoppler | 1985 | |
| Btx (Bildschirmtext) | 1985 | |
| Laptop | 1985 | |
| Notebook | 1990 | Laptop |
| CD-ROM | 1990 | |
| Handy | 1994 | Autotelefon, Funktelefon |
| Windows 95 | 24.08.1995 | Windows 3.1 |
| T-Online | 1995 | Btx |
| Internet, E-Mail | 1995 | Mailbox, Btx |
| Homepage | 1996 | |

Nie, in keinem Jahr: googeln, App, Smartphone, Cloud, streamen, USB-Stick, Preise in Euro.

## Zeilen in Versalien

Kopfzeilen, Anzeigen und die Ergebnisse auf der Anzeige des Communicators stehen in Versalien. Ein Satz endet mit Punkt („ALLE ERWISCHT.“), eine Frage mit Fragezeichen („LÖSCHEN?“), eine Angabe ohne Zeichen („640 PUNKTE“, „GAME OVER“, „HAUPTMENÜ“).

## Texte im Spiel auf der Anzeige

Das Ergebnis eines Spiels auf der Anzeige des Communicators zählt als Meldung: trocken, Witz im Nachsatz erlaubt („ALLE ERWISCHT.“). Eine Niederlage heißt „GAME OVER“ wie auf dem Automaten der Zeit; das ist die einzige englische Zeile und gilt als Computerwort der Zeit. Die Zeile zum Weitermachen ist Bedienung, ohne Witz („Weiter mit Taste oder Klick.“). Je Zeile ein Satz. Schrift, Versalien und Zahlen regelt der Baustein Spiel auf der Anzeige.

## Texte für Entwickler

Testausgaben im Code sieht der Spieler nie (Abschnitt Anrede). Für sie gilt (Klaus, 2026-10-28):

- Klares Deutsch und die Begriffe des Maßstabs, den der Test misst, etwa „Kern“, „Autoload“ und „Weg nach oben“ aus dem Architektur-Leitfaden. Ton und Wortschatz der Zeit gelten nicht.
- Namen aus Code und Engine bleiben stehen: Autoload, Node, RefCounted, `GameSession`.
- „Das Spiel“ darf das Programm heißen; die Regel unter „Nicht“ gilt nur für Texte, die der Spieler sieht.
- Der Ort steht vorn als `pfad:zeile:`, die Nummer der Regel einmal in Klammern hinter dem Satz: „res://tools/werkstatt/werkstatt.gd:917: Weg nach oben über /root/ (AR-02)“.

## Beispiele

| Wo | So | Nicht so |
|---|---|---|
| Knopf | „Bestellen“ | „Ab die Post!“ |
| Warnung | „Nicht genug Geld für diese Bestellung.“ | „Ups, da ist wohl Ebbe in der Kasse!“ |
| Meldung | „Die Lieferung ist da. Drei Wochen zu spät, aber vollzählig. Fast.“ | „Lieferung eingetroffen (Verzögerung: 21 Tage).“ |
| Hinweis im Menü | „Noch keine Spielstände. Speichern kommt bald.“ | „Bitte wählen Sie einen Spielstand.“ |
| Kunde | „Haben Sie was gegen Viren? Mein Rechner hustet.“ | „Hast du was gegen Viren?“ |
| Schlagzeile, 1995 | „Windows 95: Schlange vor dem Laden“ | „Windows 95 erscheint heute in Deutschland“ |

## Nicht

- Kein „Sie“ in Bedienung, Hinweisen und Meldungen.
- Keine Anglizismen, wo ein deutsches Wort der Zeit passt: „Bestellung“, nicht „Order“. Computerwörter der Zeit bleiben: Software, Hardware, Monitor.
- Kein Wort für zwei Dinge auf demselben Blatt; auf dem Communicator heißt Blatt eine Seite. Auf verschiedenen Seiten nacheinander darf ein Wort je nach Zusammenhang anderes meinen, etwa „Weiter mit Spiel 2 …“ im Hauptmenü und „Weiter mit Taste oder Klick.“ in der Ergebnisanzeige. Heißt der Spielstand „Spiel 7“, fragt nicht „das Spiel“ nach: „Spiel 7 wird gelöscht. Vorher kommt eine Rückfrage.“
- Das Programm heißt in Texten, die der Spieler sieht, nicht „das Spiel“, denn so heißen die Spielstände. Wo es nötig ist: „Der Computerladen“ oder nur „Version“, etwa „Mit einer neueren Version gespeichert.“
- Keinen Spott über echte Firmen. Echte Produkte dürfen vorkommen, etwa im Katalog; über sie wird nicht gelacht.
