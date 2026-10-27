# Titelbildschirm und Hauptmenü

- **Worum es geht:** was vom Start der App bis zum Hauptmenü passiert und wie das Menü sich
  bedienen lässt.
- **Laden, wenn:** Titelbildschirm, Hauptmenü oder Hinweis geändert werden, ein Menüeintrag
  dazukommt oder verfügbar wird.
- **Code:** `src/scenes/title/` (`title_screen`, `main_menu`, `menu_entry`, `menu_hint`); Tests
  `src/test/test_title_screen.gd`, `test_main_menu.gd`
- **Herkunft:** `specs/001-hauptmenue/` (Vertrag `contracts/titelbildschirm.md`)
- **Stand:** Feature 003, 2026-10-27; Feature 004 erweitert das Menü
- **Nachbarn:** Fenster, Theme, Farben und Schriften in [darstellung.md](darstellung.md)

## Start

Die App startet per Doppelklick im Fenster (bis 2026-10-20 im Vollbild). Bis zum ersten Bild ist
der Grund `anzeige-grund`, ohne Splash-Bild. Hauptszene ist
`res://scenes/title/title_screen.tscn`. Ziel: höchstens 3 s bis zum bedienbaren Titelbildschirm.

Gleichzeitig starten die Autoloads `GameClock`, `Timeline` und `GameWindow`. `Timeline` legt
schon jetzt ein Spiel an (siehe [zeitleiste.md](zeitleiste.md)); auf dem Titelbildschirm merkt
man davon nichts, weil die Uhr pausiert.

## Aufbau

```text
TitleScreen (Control, 640 × 360)
├── Background    Titelbild T-01, 640 × 360, genau doppelt aus dem Bildraster
├── LogoBlock     Ladenschild-Logo, darunter „WIRTSCHAFTSSIMULATION · 1985–1999“
├── MainMenu      rechts, Endlospapier mit Lochrändern, Kopfzeile „HAUPTMENÜ“
├── MenuHint      links neben der gewählten Zeile
└── VersionLine   unten links, „V0.1 · PROTOTYP“
```

`TitleScreen` setzt nur zusammen und verbindet. Menü und Hinweis kennen einander nicht: Das Menü
meldet per Signal, der Titelbildschirm reicht weiter und entscheidet, was ein Eintrag bewirkt.

## Menüeinträge

Jeder Eintrag ist eine `MenuEntry`-Resource mit `id`, `label`, `available` und `hint`, gepflegt
in `title_screen.tscn`. Das Menü baut daraus in `_ready()` je Eintrag einen Button.

| id | Text | verfügbar | Hinweis |
|---|---|---|---|
| `new_game` | Neues Spiel | nein | Der Laden hat noch zu. Bald kannst du ihn eröffnen. |
| `load_game` | Spiel laden | nein | Noch keine Spielstände. Speichern kommt bald. |
| `settings` | Einstellungen | nein | Noch nichts einzustellen. Kommt später. |
| `quit` | Beenden | ja | Laden abschließen und zurück zum Desktop. |

„Beenden“ schließt ohne Rückfrage. Alle Texte duzen den Spieler.

## Bedienung

Die Auswahl ist Godots Fokus: Gewählt ist die Zeile, deren Button den Fokus hat. So gibt es genau
eine Auswahl, egal ob Maus oder Tastatur sie ändert.

| Eingabe | Wirkung |
|---|---|
| Maus über einer Zeile, Rechtsklick | wählt die Zeile, zeigt ihren Hinweis; Rechtsklick löst nie aus |
| Pfeil runter, Tab / Pfeil hoch, Shift+Tab | nächste / vorige Zeile, am Ende geht es oben weiter |
| Enter, Leertaste, Linksklick | löst die gewählte Zeile aus, wenn sie verfügbar ist, sonst nichts |
| Maus verlässt das Menü | Auswahl und Hinweis bleiben |

Beim Erscheinen ist die erste Zeile gewählt. Nicht verfügbare Einträge stehen in
`gehaeuse-dunkel`, lassen sich aber wählen und zeigen ihren Hinweis. Der Mauszeiger ist eine Hand
nur über verfügbaren Einträgen.

**Signale von `MainMenu`:** `entry_activated(id)` nur für verfügbare Einträge,
`selection_changed(entry, row_rect)` bei jedem Wechsel.

**Hinweis (`MenuHint`):** erscheint sofort, für Maus und Tastatur gleich, links neben der Zeile
mit 4 Pixeln Abstand, höchstens 160 breit, mit Umbruch. Godots Tooltip passt dafür nicht, er
erscheint nur für die Maus und mit Verzögerung.

## Versionszeile

`"V%s · %s" % [version, "PROTOTYP"]`. Die Nummer kommt aus `application/config/version` in
`project.godot` (heute `0.1`) und wird nur dort gepflegt. Ist sie leer, steht nur „PROTOTYP“ da.
