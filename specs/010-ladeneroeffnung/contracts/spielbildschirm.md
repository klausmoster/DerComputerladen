# Vertrag: Spielbildschirm mit Laden, Anzeige und Uhr

Der Spielbildschirm verlässt den Platzhalter aus Feature 004 und zeigt den eigenen Laden.
Entscheidungen in [research.md](../research.md) (R4, R10, R14), Konto in
[data-model.md](../data-model.md). Der Vertrag aus Feature 004,
[titelbildschirm.md](../../004-neues-spiel/contracts/titelbildschirm.md), Abschnitt
„Spielbildschirm“, gilt weiter, wo hier nichts anderes steht.

**Vorbedingung:** Die Fragen 1 und 2 aus R14 sind im Style-Guide entschieden (Uhr statt
Weiter-Pfeil, Ladenname im Bild), und Klaus hat sie freigegeben.

## Dateien

```text
src/scenes/game/
├── game_screen.tscn / .gd         # geändert: Bildrahmen, Ladenbild, Bedienleiste
└── game_screen_texts.gd           # neu: class_name GameScreenTexts
src/ui/
├── frame/picture_frame.tscn / .gd # neu: Baustein Bildrahmen
└── bar/control_bar.tscn / .gd     # neu: Baustein Bedienleiste, in 010 mit Ortsbild, Anzeige, Uhr
src/test/
├── test_game_screen.gd            # geändert
├── test_picture_frame.gd, test_control_bar.gd
```

## Aufbau

```text
GameScreen (Control, 640 × 360)
├── PictureFrame          Bildrahmen, darin das Innere des Ladens (312 × 144 Bildpixel, ×2)
│   └── ShopSign          Ladenname über dem Bild (Lage nach Style-Guide, R14 Frage 2)
├── ControlBar            Bedienleiste
│   ├── Ortsbild          Laden von außen, Tooltip mit Anschrift
│   ├── Anzeige           Datum und Kontostand
│   └── Uhr               Pause/Weiter und Tempo (nach Style-Guide, R14 Frage 1)
└── LeaveButton, MenuHint wie in Feature 004, Lage nach Style-Guide
```

## Verhalten

- Ladenbild, Ortsbild und Name kommen aus `GameSession.current` und den Daten des Ladens; Datum aus
  `GameClock.date`, Kontostand aus `GameSession.account`.
- Der Bildschirm erscheint mit angehaltener Uhr, auch nach dem Fortsetzen (FR-027).
- Leertaste und der Knopf der Uhr wechseln zwischen Pause und Lauf. Tempi `SPEEDS = [1.0, 2.0,
  7.0]` Tage je Sekunde, Vorgabe der erste; die Tasten fürs Tempo legt der Style-Guide fest, nicht
  1 bis 6 (dort liegen die Symbolknöpfe).
- Datum und Kontostand ändern sich im selben Bild wie `day_passed` bzw. `account_changed`.
- Negativer Kontostand: Minus, „SOLL“, `kassenrot`, wie der Style-Guide es für negative Beträge
  festlegt (FR-025).
- Am 31.12.1999 hält die Uhr an (`GameClock.reached_end`); der Knopf der Uhr ist dann nicht
  verfügbar, sein Tooltip sagt warum.
- „Zum Hauptmenü“ wie bisher; `leave()` hält die Uhr an. Hinweis: „Speichert {Ladenname} und führt
  ins Hauptmenü.“
- Esc tut weiterhin nichts.

## Wortlaute (vorläufig)

| Stelle | Text |
|---|---|
| Tooltip Uhr, läuft | „Hält die Zeit an. Leertaste geht auch.“ |
| Tooltip Uhr, steht | „Lässt die Zeit laufen. Leertaste geht auch.“ |
| Tooltip Uhr, Ende | „Ende 1999. Weiter geht es nicht.“ |
| Tooltip Tempo | „{n} Tage je Sekunde.“ bzw. „Ein Tag je Sekunde.“ |
| Tooltip Ortsbild | „{Anschrift}“ |

## Feste Größen

- Ein Spiel bis 31.12.1999 hat 179 Mieten gebucht; Kontostand wie in data-model.md, „Rechnung für
  SC-003“, auf den Pfennig.
- Fortsetzen an einem Monatsersten, am Tag davor und an einem beliebigen Tag ergibt am 31.12.1999
  denselben Kontostand wie ohne Pause (SC-004).
- Auf dem Titel vergeht keine Spielzeit: Nach `leave()` steht die Uhr.
