# Feature-Ideen

Vormerkungen. Alles hier ist **unverbindlich** — noch nicht spezifiziert, noch
nicht entschieden, Reihenfolge offen. Sobald an einem Punkt wirklich gearbeitet
wird, entsteht daraus mit `/speckit-specify` ein Feature unter `specs/`, und der
Eintrag wandert in die Tabelle in [[Features]].

Die IDs sind **reserviert, nicht vergeben** — sie können sich noch verschieben.
Abgeleitet aus `docs/game_design.md`, ergänzt um das, was beim Bauen der
Zeitleiste aufgefallen ist.

---

## 01 Zeitleiste

Weitgehend gebaut ([[archiv/01-01-spieluhr]], [[archiv/01-02-ereignis-engine]]).

| ID | Idee | Braucht |
|---|---|---|
| 01-03 | Ereignis-Historie nutzbar machen — `Timeline.history` wird gefüllt, aber nie gelesen. Rückblick „was ist passiert" | 01-02 |
| 01-04 | Ereignisse datengetrieben statt in GDScript — sobald die Datenbank über ~50 Einträge wächst. **Teilweise aufgegangen in [Feature 002](../../specs/002-zeitleisten-werkstatt/spec.md):** Der Katalog wird eine Datei im Spielprojekt, gepflegt in der Werkstatt; offen bleibt nur ein möglicher Umzug in die game_bible | 02-01 |
| 01-05 | **Neues Spiel: Startdatum, Seed und Grad** (Klaus, 2026-10-22, Review von [Feature 003](../../specs/003-schwierigkeitsgrade/spec.md), CHK021). Der Bildschirm, auf dem der Spieler beim Start den Schwierigkeitsgrad wählt, gehört hierher. Seed und Grad übergibt er mit `Timeline.start_game(seed, difficulty)`; für das Startdatum braucht es eine eigene Erweiterung, `start_game()` kennt keins. Bis dahin startet das Spiel mit Mittel. Ursprünglich: Spielstart zu einem späteren Datum — `fast_forward_to()` ist dafür da, die Uhr kann es aber nicht. **Mit [Feature 002](../../specs/002-zeitleisten-werkstatt/spec.md) entfällt `fast_forward_to()`; ein späterer Start baut dann auf `TimelineRun.advance_to()` auf. Achtung: Das Autoload `Timeline` ruft `start_game()` aus `_ready()` per `call_deferred()` auf; ein eigener Spielstart muss diesen Aufruf ersetzen, sonst überschreibt er ihn mit einem gewürfelten Seed** **Seed und Grad sind mit [Feature 004](../../specs/004-neues-spiel/spec.md) umgesetzt:** Die Gradwahl kommt nach „Neues Spiel“, der Seed wird gewürfelt, und die Zeitleiste startet nicht mehr von selbst, das tut `GameSession`. Offen bleibt das Startdatum: Jedes Spiel beginnt am 01.01.1985 | 01-01 |
| 01-06 | **Aufgegangen in [Feature 002](../../specs/002-zeitleisten-werkstatt/spec.md).** **Kalender-Ereignisse** — Jahreszeitenwechsel und Weihnachtsgeschäft beim Spielstart als Ereignisse erzeugen und in die Timeline legen, statt sie aus dem Datum zu berechnen. Neue Kategorie `KALENDER`; `GameClock.season_changed` entfällt dadurch. Entschieden am 13.08.2026: **alles, was ein Ereignis auslösen kann, steht in der Timeline** — eine Quelle statt zwei, damit sich der gesamte Spielverlauf an einer Stelle prüfen lässt | 01-02 |
| 01-07 | **Aufgegangen in [Feature 002](../../specs/002-zeitleisten-werkstatt/spec.md); das Speichern der Modifikatoren bleibt bei 11-01.** **Beeinflussbare Wahrscheinlichkeiten** — `monthly_chance` wird nicht mehr überschrieben, sondern berechnet: ein **unveränderlicher Grundwert** plus eine **Liste benannter Modifikatoren**. Jeder Modifikator hat eine eigene Id, einen Wert und einen lesbaren Grund; mehrere gelten gleichzeitig, und jeder lässt sich einzeln entfernen, ohne die übrigen anzutasten. Beispiel (hypothetisch): „wenig Bäume: +4 %" erhöht die Brandgefahr, „Feuerwehr gegenüber: −6 %" senkt sie — zieht die Feuerwehr weg, bleibt der Baum-Modifikator unverändert bestehen. Grundwert **und** alle im Spielverlauf erworbenen Modifikatoren müssen im Spielstand persistiert werden, sonst fallen sie beim Laden auf den Ausgangswert zurück. Braucht außerdem ein öffentliches `Timeline.get_event(id)` — heute ist die Suche privat. **Jeder Modifikator hat verpflichtend ein Enddatum**, kein optionales Feld: „gilt unbegrenzt" wird als Spielende ausgedrückt (31.12.1999 bzw. `GameClock.END_YEAR`). Das spart die Sonderbehandlung für „kein Ende" und macht das Datenmodell einheitlich. Sinnvollerweise als Tagesindex ablegen, wie die Timeline es schon bei `_fixed_by_day` und den verzögerten Effekten tut. Abgelaufene Modifikatoren beim Auslesen herausfiltern, statt sie aufzuräumen — dann braucht es keinen Aufräumlauf und ein Spielstand aus der Vergangenheit rechnet sich von selbst richtig. Entschieden am 13.08.2026 | 01-02, 11-01 |

## 02 Produktdatenbank

| ID | Idee | Braucht |
|---|---|---|
| 02-01 | game_bible-Importer — **Entwurf vor Spec Kit**, siehe [[archiv/02-01-bible-importer]] | — |
| 02-02 | Warengruppen — die `target`-Strings der Timeline (`"cpu_486"`, `"ram"`) auf echte Produkte abbilden | 02-01 |
| 02-03 | Produktlebenszyklus — Verfügbarkeit aus `grunddaten_einführung_de` / `marktende_de` | 02-01 |
| 02-04 | Kompatibilitätsregeln — der `kompatibilität`-Block der game_bible als prüfbare Bedingungen („braucht ISA-Slot") | 02-01 |
| 02-05 | Qualitätsfaktor pro Produkt — Grundlage für Ausfallraten | 02-01 |

## 03 Wirtschaftsmodell

Das größte unbearbeitete System. Hier hängen die meisten Timeline-Effekte in der Luft.

| ID | Idee | Braucht |
|---|---|---|
| 03-01 | Preiskurven — zwischen den Stützmonaten der game_bible interpolieren; erster echter Abnehmer für `PREIS`-Effekte | 02-01 |
| 03-02 | Nachfrage-Simulation — Abnehmer für `NACHFRAGE`-Effekte | 03-01 |
| 03-03 | Kundentypen — Privatkundschaft, Gamer, Geschäftskunden, Bastler mit je eigenem Verhalten | 03-02 |
| 03-04 | Kaufkraft-Faktoren — Standort, Jahreszeit, Wirtschaftslage, Reputation; Abnehmer für `KUNDENSTROM` | 03-02 |
| 03-05 | Reputation — Abnehmer für `REPUTATION`-Effekte | 03-02 |
| 03-06 | Finanzen — Konto, Kredit, laufende Kosten, Gewinn/Verlust *(siehe Frage unten)* | — |

## 04 Informationssystem

| ID | Idee | Braucht |
|---|---|---|
| 04-01 | Magazin-Abos — Hardware-, Software-, Branchenmagazin; Abnehmer für `PRESSE`-Effekte | 01-02 |
| 04-02 | Wissensvorsprung — wer früh informiert ist, deckt sich günstiger ein | 04-01, 07-01 |

## 05 Standortsystem

| ID | Idee | Braucht |
|---|---|---|
| 05-01 | Standortwahl zu Spielbeginn — Miete, Fläche, Laufkundschaft, Sichtbarkeit | 03-04 |
| 05-02 | Ladenausbau — Fläche, Werkstatt, Schaufenster, Lager erweitern | 05-01 |

## 06 Marketingsystem

| ID | Idee | Braucht |
|---|---|---|
| 06-01 | Werbekanäle — Zeitungsanzeigen, Flyer, Schaufenster | 03-02 |
| 06-02 | Mundpropaganda — ergibt sich aus Reputation, nicht kaufbar | 03-05 |
| 06-03 | Eigene Webseite — erst ab ca. 1995–1997 freigeschaltet | 06-01 |

## 07 Handelsnetzwerk

| ID | Idee | Braucht |
|---|---|---|
| 07-01 | Lager & Bestellung — Bestand, Wertverlust (der `lager`-Block der game_bible ist dafür schon da) | 02-01 |
| 07-02 | Bezugsquellen — seriöser Großhändler, Messe, Restposten, windiger Händler | 07-01, 02-05 |
| 07-03 | Einkaufskonditionen — Mindestbestellmengen, Lieferzeiten, Abnehmer für `LIEFERUNG`-Effekte | 07-02 |

## 08 Qualität & Risiko

| ID | Idee | Braucht |
|---|---|---|
| 08-01 | Ausfallraten & Gewährleistung — würfeln beim Verkauf | 02-05 |
| 08-02 | Reklamationen — Abnehmer für `REKLAMATION`-Ereignisse, Rückwirkung auf Reputation | 08-01, 03-05 |
| 08-03 | Gegenmaßnahmen — Qualitätsprüfung, Versicherung, Garantieverlängerung | 08-01 |

## 09 Adventure-Layer

Im GDD als Genre gesetzt, aber nirgends ausgearbeitet — hier ist am meisten offen.

| ID | Idee | Braucht |
|---|---|---|
| 09-01 | Orte & Navigation — Laden, Großhändler, Messe, Bank, Kiosk, Konkurrenz, Post | 10-02 |
| 09-02 | Dialogsystem — im GDD ausdrücklich als offene Frage markiert | 09-01 |
| 09-03 | Kundenberatung — der eigentliche Verkaufsvorgang als Dialog | 09-02, 03-03 |

## 10 Präsentation & UI

| ID | Idee | Braucht |
|---|---|---|
| 10-01 | **Aufgegangen in [Feature 002](../../specs/002-zeitleisten-werkstatt/spec.md):** Die Werkstatt ersetzt die Demo. Demo-UI ablösen — `timeline_demo.tscn` ist ein Testgerüst mit per Code gebauter UI | — |
| 10-02 | Laden-Bildschirm — der Hauptschauplatz | 10-03 |
| 10-03 | Pixel-Art-Pipeline — Zielauflösung, Skalierung, Import-Einstellungen festlegen | — |
| 10-04 | Ereignis-Anzeige im Spiel — Timeline-Ereignisse als Zeitungsmeldung statt als Log | 01-02, 04-01 |

## 11 Infrastruktur

| ID | Idee | Braucht |
|---|---|---|
| 11-01 | Speichersystem — betrifft `GameClock._day_index`, `Timeline.history/_occurrences/_pending_effects`. Seit [Feature 003](../../specs/003-schwierigkeitsgrade/spec.md) gehört der Schwierigkeitsgrad dazu: Ein Spielstand speichert ihn mit, Seed und Grad ergeben wieder denselben Fahrplan (`Timeline.get_difficulty()`). **Grundstock mit [Feature 004](../../specs/004-neues-spiel/spec.md):** Spielstände unter `user://spielstaende/` mit Seed, Grad, Spieltag, Eingriffen und einer Kopie des Katalogs, sicher geschrieben, mit Formatversion, fortsetzen und löschen aus dem Titel (`src/core/save/`, `GameSession`). Der Fahrplan wird beim Fortsetzen nachgespielt, nicht gespeichert. Offen bleibt alles, was spätere Systeme an Zustand mitbringen (Wirtschaft, Lager, Modifikatoren aus 01-07), Speichern während des Spiels und Spielstände zwischen Rechnern | — |
| 11-02 | Sound & Musik — MIDI-/AdLib-Ästhetik, im GDD noch offen | — |
| 11-03 | **Build & Export mit Selbsttest — vorgemerkt als nächstes Feature nach 006** (Klaus, 2026-10-27). Ein Feature, zwei Teile: erst der Selbsttest auf macOS, dann die Presets für Windows (x86_64) und Linux. **Selbsttest:** ein eigenes Export-Preset „Selbsttest“ baut eine App aus Spiel und Testabläufen; der normale Export schließt den Testcode aus wie heute die Werkstatt. Per Doppelklick gestartet, spielt die App Abläufe über die echte Oberfläche durch (Klicks und Tasten durch Godots Eingabe), etwa Communicator fährt herein → Neues Spiel → Grad → Spielstart → zurück, gespeichert → Spiel laden → löschen → Easter Egg. Je Schritt prüft sie den Zustand und macht ein Foto; am Ende stehen ein Protokoll mit Systemdaten (OS, Grafikkarte, Bildschirm, Skalierung, Renderer) und Ergebnis je Schritt, die Fotos und eine Zusammenfassung auf dem Bildschirm. Eigener Ordner für Spielstände, echte bleiben unberührt. Klaus startet sie auf Windows und Linux und gibt Protokoll und Fotos zurück; Claude vergleicht die Fotos pixelgenau mit Referenzbildern von macOS. Nicht abgedeckt: was vor Godot liegt (Fensterverwaltung des OS, Tastaturbelegung, Warnung beim ersten Start); dafür ein kurzer Blick von Klaus. Früh zu sehen: Forward+ braucht Vulkan oder Direct3D 12, in Linux-VMs oft nicht da. **Arbeitsweise:** jedes Feature bekommt eine Aufgabe „[A] Selbsttest-Abläufe anpassen“, die Phasenprüfung prüft die Abdeckung, Claude lässt den Test auf macOS nach jeder Phase laufen und pflegt die Referenzbilder; Regel in `ki_dev.md` und ggf. Verfassung erst auf Klaus' Entscheidung. **Export:** App-Symbol als `.ico` aus `tools/raster/` und `rcedit` (Download mit Erlaubnis), Fenster und Skalierung unter Windows prüfen, Signieren später. `export_presets.cfg` vor dem Committen prüfen. Aufwand geschätzt 2 bis 3 Tage | — |
| 11-04 | Tutorial & Einstieg — im GDD als offene Frage markiert | viele |
| 11-05 | Spielziel — Gewinn-/Verlustbedingungen, Schwierigkeitsgrade. Zuerst eine Design-, dann eine Bau-Frage. **Die Grade der Zeitleiste sind mit [Feature 003](../../specs/003-schwierigkeitsgrade/spec.md) gebaut** (Leicht, Mittel, Schwer als Profile aus Start-Modifikatoren); offen bleibt, was ein Grad an Wirtschaft, Startkapital, Preisen oder Kundenstrom ändert | 03-06 |
| 11-06 | **Godot- und Spielarchitektur mit Prüf-Agent — vorgemerkt als Feature nach 007** (Klaus, 2026-10-28). Festlegen, nach welchen Godot-Prinzipien und Mustern bestimmter Spiele „Der Computerladen“ gebaut wird, und ein Agent, der Code dagegen prüft, wie Stil- und Text-Prüfer gegen den Style-Guide. Welche Spiele und Prinzipien, wird beim Ausdefinieren geklärt | — |

---

## Zu klären, bevor IDs vergeben werden

- **Finanzen haben kein eigenes System.** Konto, Kredit, laufende Kosten und
  Gewinn/Verlust stecken im GDD nur implizit (die Bank taucht als Spielort auf).
  Für eine Wirtschaftssimulation ist das aber ein Kernsystem. Provisorisch als
  03-06 unter Wirtschaftsmodell einsortiert — oder soll es ein eigenes System
  werden? Dann verschieben sich Nummern.
- **09 Adventure-Layer ist unterspezifiziert.** Das GDD nennt das Genre
  „Point-and-Click Adventure", aber Dialogsystem und Verkaufsvorgang stehen unter
  „Offene Fragen". Die Kernfrage: **Wie läuft ein einzelner Verkauf ab?**
  - *Als Dialog* (wie Das Amt, Monkey Island): Kunde kommt, sagt was er braucht,
    man berät ihn über Antwortmöglichkeiten, er kauft oder geht. Charaktervoll,
    aber es sind höchstens ein paar Kunden pro Spieltag zu schaffen.
  - *Als Bildschirmmaske* (wie Pizza Connection, Der Patrizier): Preise und
    Sortiment festlegen, der Laden läuft; abends steht da „14 Kunden, 4 Verkäufe,
    6.800 DM". Skaliert über 15 Spieljahre, hat aber keine Persönlichkeit.

  Das entscheidet mit, wie schnell die Spieluhr überhaupt laufen darf
  (`GameClock.days_per_second` geht bis 60 — mit Dialogverkäufen unmöglich),
  wie viel Text geschrieben werden muss und wie 03-03 (Kundentypen) aussieht.
  Wahrscheinlichster Weg ist die Mischung: Tagesgeschäft simuliert, einzelne
  Kunden als handgeschriebene Szene — dafür gibt es in `timeline_event.gd`
  bereits die Kategorien `KUNDE` und `REKLAMATION`. Solange das offen ist,
  lassen sich 09-02 und 09-03 nicht sinnvoll spezifizieren.
- **Reihenfolge:** Fast alles hängt an 02-01 und 03-01. Die beiden zuerst zu
  bauen macht die meisten anderen Features überhaupt erst spezifizierbar.
