# Werkzeuge

Werkzeuge sind Programme für die Entwicklung; zum ausgelieferten Spiel gehören sie nicht. Das erste ist die Zeitleisten-Werkstatt: Darin pflegt Klaus die Ereignisse der Zeitleiste, taktet sie auf einem Zeitstrahl ein und spielt sie ohne das Spiel durch. Werkzeuge zeigen viel Text und brauchen viel Fläche. Deshalb gelten für sie eigene Regeln zu Auflösung und Schrift. Die Farben bleiben die des Computerladens.

Der Abschnitt gilt für Werkzeuge mit Oberfläche, die in Godot laufen. Die Python-Werkzeuge unter `tools/` haben keine Oberfläche.

## Auflösung

- Werkzeuge nutzen die volle Auflösung ihres Fensters, nicht das Oberflächenraster von 640 × 360 und keine ganzzahlige Skalierung. Das Fenster öffnet maximiert.
- Ausnahme: Der Selbsttest zeigt seine Zusammenfassung im Fenster, in dem er gelaufen ist, ohne Größe und Lage zu ändern. So bleibt die Fenstergröße des Laufs reproduzierbar.
- Maße in diesem Abschnitt sind logische Pixel. Auf Bildschirmen mit doppelter Pixeldichte, etwa Retina, wird alles mit dem Bildschirmfaktor vergrößert. So bleibt Text scharf und überall gleich groß.
- Godot: `content_scale_mode` auf `disabled` und `content_scale_factor` auf `DisplayServer.screen_get_scale()`. Die Fensterlogik des Spiels (`GameWindow`) ist im Werkzeug abgeschaltet.

## Schrift

- Die Schrift ist Open Sans SemiBold, die eingebaute Schrift von Godot (`ThemeDB.fallback_font`), mit Kantenglättung und ohne Pixelraster. Sie gehört zur Engine und braucht keine eigene Datei.
- Größen: 14 für Text, Eingabefelder, Listen und Tooltips (`werkzeug-text`), 12 für die Zeitachse und kleine Angaben (`werkzeug-klein`), 16 für die Titel von Bereichen (`werkzeug-titel`).
- Das Theme des Werkzeugs setzt die Schrift selbst. Sonst erbt es Ark Pixel vom Theme des Spiels.
- Ark Pixel, Saira und Doto gehören zum Spiel und kommen in Werkzeugen nicht vor.
- Zahlen und Daten wie im Spiel: 22.03.1993, 12.450,00 DM, 3,5 %. Modifikatoren stehen in Prozentpunkten mit Vorzeichen, etwa +5.
- Texte sind kurz und sachlich und duzen wie im Spiel: „Der Katalog hat 1 Fehler. Trotzdem speichern?“ Mehr in „Texte“ unten.

## Farbrollen

Werkzeuge benutzen nur die 15 Farben dieses Guides, auf hellem Grund wie Endlospapier und Zeitung im Spiel.

| Rolle | Farbe | Kontrast | Wofür |
|---|---|---|---|
| Grund | `papier` | – | Fenster, Zeitstrahl, Formular, Listen |
| Zweite Zeile | `endlos-gruen` | – | jede zweite Zeile in Listen, Tabellen und im Zeitstrahl; in Listen mit mehrzeiligen Einträgen jeder zweite Eintrag, nicht jede zweite Textzeile |
| Fläche | `gehaeuse` mit `relief-erhaben` | – | Werkzeugleiste, Knöpfe, Köpfe von Bereichen und Tabellen, Achse des Zeitstrahls |
| Text | `tusche` | 15,3:1 auf `papier`, 12,7:1 auf `endlos-gruen`, 8,4:1 auf `gehaeuse` | aller Text |
| Gedämpfter Text | `gehaeuse-dunkel` | 5,0:1 auf `papier` | Nebenangaben, Einheiten, leere Felder; nur auf `papier` |
| Überfahren | `signalgelb` | `tusche` darauf 10,2:1 | Zeile oder Knopf unter der Maus |
| Auswahl | `petrol`, Text in `papier` | 5,1:1 | gewählte Zeile in Listen und Tabellen, aktiver Reiter |
| Fehler | `kassenrot` | 4,8:1 auf `papier`, `papier` darauf 4,8:1 | Fehlermeldungen; in Listen ein Feld in `kassenrot` mit „!“ in `papier`; eine Meldung an Stelle eines Bereichs als Feld in `kassenrot` mit Text in `papier` |
| Nicht gelaufen | Feld mit `tusche`-Kontur auf `papier`, „–“ in `tusche` | 15,3:1 | in Listen ein Schritt, der nicht lief; Text daneben in `tusche` |
| Gesperrt | `papier`, Kontur `tusche`, Text `gehaeuse-dunkel` | 5,0:1 | Knopf, der gerade nichts tut; so, wie das Theme der Werkstatt ihn hat |
| Warnung | `holz` | 5,1:1 auf `papier` | Warnungen als Text mit „?“ davor; nur in Werkzeugen steht `holz` als Text |
| Ziehen | `signalgelb` mit `tusche`-Kontur | `tusche` darauf 10,2:1 | die gezogene Marke und ihr Datum am Mauszeiger |
| Fokus | `tusche` | 15,3:1 auf `papier` | Linie von 2 Pixeln mit 2 Pixeln Abstand um das Element mit Tastaturfokus |
| Raster | `gehaeuse` für Jahre, `gehaeuse-hell` für Monate | unter 3:1, gewollt | senkrechte Linien von 1 Pixel durch die Zeilen des Zeitstrahls; sie ordnen nur und tragen keinen Inhalt |
| Fortschritt | Füllung `petrol` auf `papier`, Kontur `tusche` | 5,1:1 | Fortschrittsbalken, etwa bei der Statistik über viele Spiele; der Text dazu steht daneben, nie auf der Füllung |

- Fehler und Warnung unterscheiden sich in Form und Zeichen, nicht nur in der Farbe: Ein Fehler ist ein gefülltes Feld, eine Warnung farbiger Text. Ebenso ein nicht gelaufener Schritt: leeres Feld mit Kontur und „–“.
- „In Ordnung“ hat keine Farbe. Es steht nur als Wortlaut da, etwa „Alles in Ordnung: 37 von 37 Schritten.“
- Im Zeitstrahl zeigt eine `tusche`-Linie von 2 Pixeln mit 2 Pixeln Abstand die gewählte Marke. Beim Überfahren wechselt der Mauszeiger, und ein Tooltip erscheint.
- Die Achse des Zeitstrahls ist ein Kasten wie der Kopf einer Tabelle: Jahre, ab dem Monatszoom Monate, ganz hineingezoomt die Tageszahlen, Text in `tusche` in `werkzeug-klein`. Durch die Zeilen darunter laufen die Linien der Rolle Raster.
- Keine Verläufe, keine weichen Schatten, keine Transparenz, wie im Spiel.

## Kategorienfarben

Im Zeitstrahl hat jede Kategorie eine Zeile, und ihre Marken tragen die Farbe der Kategorie. Erlaubt sind nur diese sieben Farben, in dieser Reihenfolge. Jede hat mindestens 3:1 Kontrast zu `papier` und zu `endlos-gruen`, auf denen die Zeilen liegen. Im Code stehen sie in `UiPalette.CATEGORY_TOKENS`.

| Nr. | Farbe | auf `papier` | auf `endlos-gruen` |
|---|---|---|---|
| 1 | `nacht-hell` | 9,4:1 | 7,8:1 |
| 2 | `petrol` | 5,1:1 | 4,3:1 |
| 3 | `nacht` | 13,7:1 | 11,4:1 |
| 4 | `kassenrot` | 4,8:1 | 4,0:1 |
| 5 | `holz-dunkel` | 9,5:1 | 7,9:1 |
| 6 | `gehaeuse-dunkel` | 5,0:1 | 4,1:1 |
| 7 | `holz` | 5,1:1 | 4,2:1 |

- Die Reihenfolge wechselt zwischen dunklen und mittleren Tönen, damit benachbarte Zeilen verschieden aussehen.
- Nicht dabei sind `papier` (Grund), `tusche` (Text und Konturen), `signalgelb` (Überfahren und Ziehen), `anzeige-grund` (neben `nacht` nicht zu unterscheiden) und die hellen Farben, die auf `papier` unter 3:1 bleiben: `gehaeuse`, `gehaeuse-hell`, `endlos-gruen`, `anzeige`.
- Eine neue Kategorie bekommt die erste noch freie Farbe der Liste. Sind alle vergeben, bekommt sie die am seltensten benutzte, bei Gleichstand die frühere.
- Für zehn Kategorien reichen sieben Farben nicht; drei kommen doppelt vor. Zu ihrer Kategorie gehört eine Marke durch ihre beschriftete Zeile, die Farbe hilft nur.
- Marken: ein fixes Ereignis als Punkt, mit Dauer als Balken; ein Zeitfenster als Rahmen von 2 Pixeln; ein Ereignis über Wahrscheinlichkeit als Band von 4 Pixeln Höhe über sein Zeitfenster.
- Titel und Prozentzahlen stehen in `tusche` auf dem Grund neben der Marke, nie auf der Kategorienfarbe.

Startfarben der zehn Kategorien, nach der Regel oben in der Reihenfolge der Zeilen vergeben:

| Kategorie | Kennung | Farbe |
|---|---|---|
| Hardware | `hardware` | `nacht-hell` |
| Software | `software` | `petrol` |
| Tech | `tech` | `nacht` |
| Wirtschaft | `wirtschaft` | `kassenrot` |
| Lokal | `lokal` | `holz-dunkel` |
| Konkurrenz | `konkurrenz` | `gehaeuse-dunkel` |
| Kunde | `kunde` | `holz` |
| Reklamation | `reklamation` | `nacht-hell` |
| Lieferung | `lieferung` | `petrol` |
| Kalender | `kalender` | `nacht` |

Die Namen sind die bisherigen aus dem Spiel; umbenennen lässt sich jede Kategorie in der Werkstatt.

## Bedienelemente

- Wie im Spiel ist alles Bedienbare eckig (`ecke-0`) und hat eine Kontur von 1 Pixel in `tusche`. Knöpfe haben `gehaeuse` mit `relief-erhaben`, beim Drücken `relief-gedrueckt`.
- Eingabefelder haben `papier` als Grund. Ein Feld mit Fehler, ob Eingabe- oder Auswahlfeld, bekommt eine Kontur von 2 Pixeln in `kassenrot`, darunter steht der Hinweis in `kassenrot`.
- Tooltips und Menüs stehen auf `papier` mit `tusche`-Kontur und `pixelschatten`.
- Abstände kommen aus `raster-4`, `raster-8` und `raster-16`, gemessen in logischen Pixeln.
- Zwischen Knöpfen stehen `raster-8`, damit die Fokuslinie (2 Pixel mit 2 Pixeln Abstand) frei steht und den Nachbarn nicht berührt.
- Der Titel eines Bereichs steht `raster-8` über seinem Inhalt und `raster-16` unter dem Bereich davor. Ein Titel ist nur Text in `werkzeug-titel`; ein Kopf ist eine Fläche `gehaeuse` mit `relief-erhaben`, etwa über einer Tabelle.
- Alles Anklickbare hat einen Tooltip, der sagt, was es tut, und zeigt beim Überfahren den Handzeiger. Das gilt für alle Werkzeuge, wie in der Werkstatt.
- Ein gesperrter Knopf zeigt den Pfeil statt des Handzeigers, und sein Tooltip sagt, warum er gesperrt ist, etwa „Kein Zip: Im Ordner lässt sich nicht schreiben.“
- Zeilen, die man nicht anklicken kann, haben kein Überfahren und keinen Handzeiger.
- Knöpfe sind Standard-Knöpfe des Themes ohne eigene Styles; Überfahren, Drücken, Fokus und gesperrt kommen aus dem Theme.
- Bestätigung einer Handlung, etwa „Kopiert.“: `raster-16` rechts neben der Knopfreihe in `werkzeug-text` und `tusche`, bis zum nächsten Klick. Kein eigenes Fenster, kein Ausblenden nach Zeit.
- Lange Werte werden umbrochen, Pfade nach einem Trenner wie `/`. Gekürzt wird nie, damit jeder Pfad und jeder Wert vollständig zu lesen ist.

## Texte

- Werkzeuge folgen Anrede und Ton aus „Sprache“. Die Wortliste der Zeit gilt für Texte im Spiel, nicht für Werkzeuge; in sichtbaren Texten der Werkzeuge steht trotzdem kein „App“.
- Auf dem Bildschirm stehen Daten, Zeiten und Maße deutsch: „28.10.2026, 14:03 Uhr“, „640 × 360“, „Faktor 2,5“, „0,5 s“.
- In Protokollen für Maschinen, etwa `protokoll.txt` des Selbsttests, stehen Messwerte in fester Maschinenform: `2026-10-28 14:03:12`, `3024x1964`, `2.0`. Sie sind ausgenommen von den Regeln für Texte, wie Testausgaben. Maschinenform gilt nur für Messwerte; Texte darin, etwa die Beschreibung eines Schritts, sind deutsch mit „ד.
- Auf dem Bildschirm gilt dasselbe wie im Protokoll: Werte ohne Schlusspunkt, ganze Sätze mit; endet ein Satz mit einem Pfad, entfällt der Punkt, damit er nicht zum Pfad gehört.
- Werte in Protokollen stehen ohne Schlusspunkt. Nur ein ganzer Satz wie `ergebnis: Alles in Ordnung: 37 von 37 Schritten.` endet mit Punkt. Ein Text aus dem Spiel, der mit Punkt endet, steht in Anführungszeichen und behält ihn.
- Tasten heißen: Enter, Esc, Tab, Umschalt+Tab, Leertaste, Pfeil runter, Pfeil hoch, Pfeil rechts, Mausrad runter. Eine Eingabe nennt ihr Ziel: „Enter auf Mittel“, „Linksklick auf „Spiel laden““.
- Anzahlen und Maße in Ziffern: „7 Spielstände“, „auf 1 Pixel genau“. „Ein“ und „eine“ ohne Maß bleiben Wörter: „ein Schuss unterwegs“.
- Eine Lage neben einem Ziel steht mit Richtungen statt Vorzeichen: „2 Pixel rechts, 3 Pixel unter der Mitte“.
- Fehlernamen der Engine, etwa „File: Can't open“, dürfen in Meldungen stehen, wie sie sind; übersetzt wären sie geraten.
- Fachwörter der Entwicklung, die es im Deutschen so nicht gibt, bleiben: Seed, Zip, Tooltip.
- „Texte“ gilt auch für Python-Werkzeuge ohne Oberfläche: Konsolenausgaben, Hilfe und Berichte wie `vergleich.md` zählen als Bildschirm. Kennungen, Ordnernamen und Pfade bleiben, wie sie sind.
- Englische Meldungen von Python und seinen Bibliotheken zählen wie Fehlernamen der Engine und dürfen stehen, etwa „File is not a zip file“ oder „usage:“ in der Hilfe von argparse.
- Gekürzt wird nie, auch nicht in Texten: Ein Pfad steht ganz da, nicht als „specs/007-…/belege/“.
