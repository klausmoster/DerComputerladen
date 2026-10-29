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
src/core/
└── game_clock.gd                  # geändert: set_speed() (CHK039)
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
│   ├── Ortsbild          Ausschnitt <id>_ort.png, 60 × 28 Bildpixel, ohne Klick, Tooltip (CHK012, CHK028)
│   ├── Anzeige           Datum und Kontostand nach Baustein Anzeige, etwa DI 01.01.1985
│   └── Uhr               Pause/Weiter und Tempo (nach Style-Guide, R14 Frage 1)
└── LeaveButton           „Zum Hauptmenü“ mit Tooltip statt Hinweis (CHK032), Lage nach Style-Guide
```

## Verhalten

- Ladenbild, Ortsbild und Name kommen aus `GameSession.current` und `ShopOffer.load_by_id()`;
  Datum aus der Uhr über die Naht `GameScreen.clock` (Rückfall `GameClock`, AR-12, CHK039),
  Kontostand aus `GameSession.account`.
- Die Leiste bekommt Bild, Texte und den Zustand der Uhr hineingereicht und meldet Pause und Tempo
  per Signal; sie kennt weder `GameClock` noch `ShopLease` (AR-02, AR-05, CHK045).
- Der Bildschirm erscheint mit angehaltener Uhr, auch nach dem Fortsetzen (FR-027).
- Leertaste und der Knopf der Uhr wechseln zwischen Pause und Lauf. Die Knöpfe des
  Spielbildschirms lösen nicht mit der Leertaste aus; sie gehört dort immer der Uhr (CHK035, im
  Style-Guide festzuhalten). Tempi `SPEEDS = [1.0, 2.0, 7.0]` Tage je Sekunde, Vorgabe der erste,
  gesetzt über `GameClock.set_speed()`, nicht über das Feld (CHK039); die Tasten fürs Tempo legt
  der Style-Guide fest, nicht 1 bis 6 (dort liegen die Symbolknöpfe).
- Datum und Kontostand ändern sich im selben Bild wie `day_passed` bzw. `account_changed`. Bei
  laufender Uhr blinkt das Datum nicht, der Kontostand blinkt bei jeder Buchung (CHK034, im
  Baustein Anzeige zu ergänzen).
- Negativer Kontostand: Minus und „SOLL“, die Farbe bleibt die der Anzeige (Style-Guide, Baustein
  Anzeige; FR-025).
- Am 31.12.1999 hält die Uhr an (`GameClock.reached_end`); der Knopf der Uhr ist dann aus, ohne
  Tooltip; das Ende sieht man am Datum (CHK031).
- „Zum Hauptmenü“ speichert wie bisher; `leave()` hält die Uhr an. Tooltip statt Hinweis:
  „Speichert {Ladenname} und führt ins Hauptmenü.“ Scheitert das Speichern, steht die Meldung
  links neben dem Knopf (Baustein Meldung).
- Esc tut weiterhin nichts.

## Wortlaute (vorläufig)

| Stelle | Text |
|---|---|
| Tooltip Uhr, läuft | „Hält die Zeit an. Leertaste geht auch.“ |
| Tooltip Uhr, steht | „Lässt die Zeit laufen. Leertaste geht auch.“ |
| Tooltip Tempo | „{n} Tage je Sekunde. Taste {Taste}.“ bzw. „Ein Tag je Sekunde. Taste {Taste}.“ |
| Tooltip Ortsbild | „Dein Laden: {Anschrift}.“ |

## Feste Größen

- Ein Spiel bis 31.12.1999 hat 179 Mieten gebucht; Kontostand wie in data-model.md, „Rechnung für
  SC-003“, auf den Pfennig.
- Fortsetzen an einem Monatsersten, am Tag davor und an einem beliebigen Tag ergibt am 31.12.1999
  denselben Kontostand wie ohne Pause (SC-004).
- Auf dem Titel vergeht keine Spielzeit: Nach `leave()` steht die Uhr.
