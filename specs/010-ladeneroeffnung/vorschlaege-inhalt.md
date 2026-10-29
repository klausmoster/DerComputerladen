# Vorschläge: Stadt, Läden und Makler (T005)

Zur Wahl für Klaus (T006). Nach seiner Wahl kommen die Inhalte in die game_bible (T007 bis T009).
Beträge stehen fest (spec.md, FR-020). Texte im Exposé und Sätze des Maklers siezen
(Style-Guide, `docs/style-guide/sprache.md`, „Anrede“). Geprüft per Websuche am 2026-10-29: Keiner
der drei Stadtnamen ist eine echte Stadt; „Wesselbach“ gibt es nur als kleinen Wohnplatz in NRW.

## 1. Die Stadt

Rund 150.000 Einwohner, westdeutsch, Innenstadt mit Fußgängerzone, Bahnhof, Wohngebiet,
Gewerbegebiet.

| | Name | Land | Charakter |
|---|---|---|---|
| A | **Wesselbach** | Nordrhein-Westfalen | Alte Tuchmacherstadt am Rand des Ruhrgebiets; die Webereien sind zu, eine Fachhochschule ist neu. Bodenständig, ein bisschen grau, mit Hoffnung auf Neues |
| B | **Ellerbrück** | Niedersachsen | Kreisstadt mit Dom, Kaserne und Zuckerfabrik; viel Verwaltung, viel Beamtenschaft, sonntags alles zu |
| C | **Brakenfeld** | Hessen | Industriestadt mit einem großen Elektrokonzern als Arbeitgeber; Pendler, Ingenieure, ein Hang zur Technik |

**Empfehlung: A, Wesselbach.** Eine Stadt im Umbruch passt zum Computerladen: Die alte Industrie
geht, die neue kommt, und die Fachhochschule bringt die ersten Kunden mit Interesse an Rechnern.

## 2. Die vier Läden

Straßennamen passen zu jeder der drei Städte.

### Fußgängerzone (Reihenfolge 1)

- **Titel:** Ladenlokal in der Fußgängerzone
- **Anschrift:** Marktstraße 14
- **Fläche, Miete:** 60 m², 4.800,00 DM
- **Lage:** Laufkundschaft hoch, Sichtbarkeit hoch, Parkplätze niedrig
- **Beschreibung:** „Beste Lage zwischen Kaufhaus und Eiscafé. Wer hier vorbeigeht, hat Geld in
  der Tasche und Zeit zum Schauen.“
- **Kleingedrucktes:** „Parkplätze nur im Parkhaus am Markt, 1,50 DM die Stunde. Anlieferung bis
  10:00 Uhr. Schaufensterbeleuchtung nach Satzung der Werbegemeinschaft. Erster Monat mietfrei für
  den Ausbau.“

### Nähe Bahnhof (Reihenfolge 2)

- **Titel:** Ladenlokal am Bahnhofsvorplatz
- **Anschrift:** Bahnhofstraße 3
- **Fläche, Miete:** 80 m², 2.240,00 DM
- **Lage:** Laufkundschaft hoch, Sichtbarkeit mittel, Parkplätze mittel
- **Beschreibung:** „Hier kommt jeder vorbei, der in die Stadt will. Pendler, Schüler, Reisende.
  Manche bleiben sogar stehen.“
- **Kleingedrucktes:** „Vormieter: Spielhalle, ausgezogen. Rollgitter vorhanden. Abends belebte
  Umgebung. Erster Monat mietfrei für den Ausbau.“

### Stadtteilzentrum (Reihenfolge 3)

- **Titel:** Ladenlokal im Stadtteilzentrum
- **Anschrift:** Lindenplatz 7
- **Fläche, Miete:** 90 m², 1.440,00 DM
- **Lage:** Laufkundschaft mittel, Sichtbarkeit mittel, Parkplätze mittel
- **Beschreibung:** „Zwischen Bäcker, Apotheke und Sparkasse. Die Leute hier kennen sich. Sind Sie
  einmal bekannt, kommen sie wieder.“
- **Kleingedrucktes:** „Mittwochnachmittag ist der Platz leer, die anderen Geschäfte haben zu.
  Vormieter: Schreibwaren, Ruhestand. Erster Monat mietfrei für den Ausbau.“

### Gewerbegebiet (Reihenfolge 4)

- **Titel:** Gewerbefläche mit Lager im Gewerbegebiet Nord
- **Anschrift:** Industriestraße 22
- **Fläche, Miete:** 150 m², 1.350,00 DM
- **Lage:** Laufkundschaft niedrig, Sichtbarkeit niedrig, Parkplätze hoch
- **Beschreibung:** „Viel Platz für Lager und Werkstatt, Parkplätze direkt vor der Tür. Firmen
  fahren hier sowieso vorbei.“
- **Kleingedrucktes:** „Keine Bushaltestelle in der Nähe. Zufahrt über den Wirtschaftsweg, bei
  Regen schlammig. Lager unbeheizt. Erster Monat mietfrei für den Ausbau.“

## 3. Der Makler

Zwei Steckbriefe zur Wahl. Beide siezen, beide sind Figuren aus „Das Amt“-Holz: trocken, der Witz
im Nachsatz. Die Sätze stehen je Anlass (data-model.md, „Anlässe des Maklers“); zu `klick` gibt es
drei, die der Reihe nach kommen. Der Text-Prüfer hat die Texte am 2026-10-29 gelesen; seine zwei
Befunde (Getrenntschreibung „stehen bleibt“, „Lager“ statt „Halle“) und zwei Klarstellungen sind
eingearbeitet, die längsten Sätze gekürzt.

### A: Herr Brandt (Empfehlung)

- **Rolle, Alter:** Makler für Gewerbeflächen, 58
- **Optik in einem Satz:** Breites Gesicht, grauer Seitenscheitel, Brille mit Goldrand, braunes
  Sakko mit Einstecktuch, Siegelring.
- **Sprechweise:** Verkäuferisch und unerschütterlich; nennt jedes Loch eine „entwicklungsfähige
  Lage“; sagt „junger Mann“ unabhängig vom Alter.
- **Charakter:** Seit 30 Jahren im Geschäft, kennt jeden Vermieter der Stadt, hat schon alles
  vermietet, auch Dinge, die er besser nicht vermietet hätte.

| Anlass | Satz |
|---|---|
| `betreten` | „Setzen Sie sich, junger Mann. Meine Objekte sind praktisch schon weg.“ |
| `stadtplan` | „Schauen Sie ruhig. Die Stadt läuft nicht weg. Die Objekte schon.“ |
| `expose_fussgaengerzone` | „Eins-a-Lage. Wer da nicht verkauft, verkauft nirgends.“ |
| `expose_bahnhof` | „Viel Publikum. Nicht immer das, das man sich wünscht, aber viel.“ |
| `expose_stadtteilzentrum` | „Solide Nachbarschaft. Die Leute bezahlen bar und meckern laut.“ |
| `expose_gewerbegebiet` | „Platz ohne Ende. Kunden bringen Sie selbst mit.“ |
| `expose_zu_teuer` | „Da müsste ich die Bank fragen. Die Bank fragt dann Sie.“ |
| `mietvertrag` | „Standardvertrag. Das Kleingedruckte habe ich selbst nie gelesen.“ |
| `unterschrieben` | „Glückwunsch. Jetzt sind Sie Mieter. Der schwerste Teil kommt noch.“ |
| `anmeldung` | „Das Formular vom Gewerbeamt. Der Name kommt über die Tür.“ |
| `abschied` | „Viel Erfolg. Und wenn es nicht klappt: Ich vermiete auch kleinere Objekte.“ |
| `klick` | „Noch Fragen? Ich bin ganz Ohr.“ / „Die Miete ist fair. Fragen Sie nicht, wem gegenüber.“ / „Mein letzter Mieter hatte einen Videoverleih. Jetzt ist er sehr erfolgreich. Woanders.“ |

### B: Frau Kemper

- **Rolle, Alter:** Maklerin, 46, führt das Büro ihres Vaters weiter
- **Optik in einem Satz:** Kurze, toupierte Haare, große Brille, Kostüm mit Schulterpolstern, ein
  Klemmbrett, das sie nie weglegt.
- **Sprechweise:** Knapp, korrekt, ein wenig von oben herab; rechnet laut mit; mag keine
  Unentschlossenheit.
- **Charakter:** Hat das Geschäft modernisiert, Kartei statt Zettelwirtschaft, und hält Computer
  für eine Mode, die sie gern vermietet, aber nicht kauft.

| Anlass | Satz |
|---|---|
| `betreten` | „Guten Tag. Vier Objekte sind frei. Mehr brauchen Sie nicht.“ |
| `stadtplan` | „Die Stadt. Groß ist sie nicht, aber sie hat Kaufkraft.“ |
| `expose_fussgaengerzone` | „Beste Adresse. Der Preis auch.“ |
| `expose_bahnhof` | „Durchgangsverkehr. Wer stehen bleibt, kauft. Wer weitergeht, kauft woanders.“ |
| `expose_stadtteilzentrum` | „Ruhige Lage. Stammkunden sind die halbe Miete. Die andere Hälfte zahlen Sie.“ |
| `expose_gewerbegebiet` | „Günstig und groß. Ihre Kunden müssen nur noch herfinden.“ |
| `expose_zu_teuer` | „Ich rechne Ihnen das gern vor. Danach wollen Sie es nicht mehr.“ |
| `mietvertrag` | „Drei Monatsmieten Kaution. Das ist üblich. Das Übliche ist selten günstig.“ |
| `unterschrieben` | „Gut. Dann das Formular. Ohne Gewerbe kein Geschäft.“ |
| `anmeldung` | „Schreiben Sie den Namen deutlich. Das Amt liest nicht gern.“ |
| `abschied` | „Die Schlüssel. Pünktlich zahlen, dann sehen wir uns nicht wieder.“ |
| `klick` | „Ja?“ / „Ich habe noch andere Termine.“ / „Computer. Na, wenn Sie meinen.“ |

**Empfehlung: A, Herr Brandt.** Ein Makler, der jede Lage schönredet, macht das Kleingedruckte
spannend: Der Spieler lernt, ihm nicht ganz zu trauen. Beim späteren Umzug ist er ein alter
Bekannter, der sich an nichts Schlechtes erinnert.
