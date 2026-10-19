# Datenmodell: Start bis zum Hauptmenü

Abgeleitet aus [spec.md](spec.md). Das Feature hat keine Spieldaten und keine Spielstände;
modelliert werden nur der Menüeintrag, die Versionszeile und zwei Zustände.

## Menüeintrag (`MenuEntry`)

Ein Eintrag im Hauptmenü. In Godot eine eigene Resource, damit die Einträge im Inspector
gepflegt und in Tests erzeugt werden können (Vertrag: [contracts/titelbildschirm.md](contracts/titelbildschirm.md)).

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | StringName | Feste Kennung: `&"new_game"`, `&"load_game"`, `&"settings"`, `&"quit"` |
| `label` | String | Text im Menü, deutsch |
| `available` | bool | Ob der Eintrag ausgelöst werden kann |
| `hint` | String | Text des Hinweises: Funktion oder Grund, warum nicht verfügbar |

**Regeln (aus FR-006 bis FR-008, FR-015):**

- Genau vier Einträge in dieser Reihenfolge:

  | id | label | available | hint |
  |---|---|---|---|
  | `new_game` | Neues Spiel | nein | Der Laden hat noch zu. Bald kannst du ihn eröffnen. |
  | `load_game` | Spiel laden | nein | Noch keine Spielstände. Speichern kommt bald. |
  | `settings` | Einstellungen | nein | Noch nichts einzustellen. Kommt später. |
  | `quit` | Beenden | ja | Laden abschließen und zurück zum Desktop. |

- `id` ist eindeutig. `hint` ist nie leer.
- Die Texte duzen den Spieler (Review, Entscheidung von Klaus) und stehen so in FR-016.
- Der Mauszeiger folgt aus `available`: Hand bei verfügbaren Einträgen, Pfeil bei den übrigen
  (FR-018).

## Versionszeile

| Teil | Quelle | Beispiel |
|---|---|---|
| Versionsnummer | `application/config/version` in `project.godot` | `0.1` |
| Kennzeichen | Konstante im Titelbildschirm | `PROTOTYP` |
| Anzeige | `"V%s · %s" % [version, kennzeichen]` | `V0.1 · PROTOTYP` |

Regel: Ist die Version leer, wird kein „V“ ohne Zahl gezeigt, sondern nur das Kennzeichen.

## Zustand: Auswahl im Menü

- Es gibt genau eine gewählte Zeile, einen Index von 0 bis 3 (FR-011).
- Startwert beim Erscheinen: 0, also „Neues Spiel“ (FR-010).
- Pfeil runter oder Tab: Index + 1, nach 3 folgt 0. Pfeil hoch oder Shift+Tab: Index − 1, vor 0
  kommt 3.
- Maus über Zeile *n* oder Rechtsklick auf Zeile *n*: Index = *n*. Über Kopfzeile und Lochrändern
  ändert sich nichts. Verlässt die Maus das Menü, bleiben Index und Hinweis.
- Enter, Leertaste oder Linksklick: Ist der gewählte Eintrag verfügbar, wird seine Aktion
  ausgelöst, sonst geschieht nichts (FR-007). Ein Rechtsklick löst nie etwas aus (FR-009).
- Jede Änderung des Index zeigt sofort den Hinweis des neuen Eintrags (FR-017).

## Zustand: Fenster

```text
           Start
             │
             ▼
        ┌─────────┐   Ctrl+Cmd+F oder grüner Knopf   ┌─────────┐
        │Vollbild │ ───────────────────────────────▶ │ Fenster │
        │         │ ◀─────────────────────────────── │         │
        └─────────┘   Ctrl+Cmd+F oder grüner Knopf   └─────────┘
```

- **Vollbild:** ganzzahlig skaliert, Rest schwarz (FR-012).
- **Beim Wechsel ins Fenster:** Die Fenstergröße wird auf den größten ganzzahligen Faktor `f` der
  Basisgröße gesetzt, für den `f · 640` und `f · 360` samt Titelleiste in den nutzbaren Bereich
  des Bildschirms passen, auf dem das Fenster gerade liegt, mindestens `f = 1`. Danach wird das
  Fenster zentriert (FR-004).
- **Im Fenster:** Der Spieler darf die Größe frei ändern, aber nicht unter 640 × 360
  Bildschirmpixel (FR-013). Die Darstellung bleibt ganzzahlig mit Rändern (FR-012).
