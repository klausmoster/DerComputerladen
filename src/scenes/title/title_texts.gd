class_name TitleTexts
extends RefCounted

## Alle Texte der Blätter im Titel und des Spielbildschirms an einer Stelle (Feature 004,
## contracts/titelbildschirm.md, „Texte“): Kopfzeilen, Einträge, Hinweise und die Meldung zum
## Löschen. Die Klasse hat keine Instanzen, nur Konstanten und statische Funktionen.
##
## Texte mit Platzhaltern stehen als Vorlage da, etwa „Weiter mit {name}, {grad}, am {datum}.“;
## die Funktionen unten füllen sie mit String.format(). Die Platzhalter heißen {name} („Spiel 2“),
## {grad} („Schwer“), {datum} („14.03.1986“), {uhrzeit} („21:40“) und {zustand} („beschädigt“ oder
## „neuere Version“). Datum und Uhrzeit kommen schon fertig geschrieben herein.
##
## Nicht hier, damit nichts doppelt steht: die Namen der Grade (Difficulty.label()), die Meldungen
## zum Speichern (GameSession.MESSAGE_*) und die Gründe, warum ein Spielstand nicht fortsetzbar ist
## (SaveGame.REASON_*, SaveSlot.REASON_*). test_title_texts.gd misst alle zusammen: Jeder Hinweis und
## jede Meldung passt in höchstens zwei Zeilen des Hinweises.

# --- Kopfzeilen --------------------------------------------------------------------------------

const HEADER_MAIN := "HAUPTMENÜ"
const HEADER_DIFFICULTY := "SCHWIERIGKEIT"
const HEADER_SAVES := "SPIELSTÄNDE"
## Kopfzeile der Liste im Löschmodus.
const HEADER_DELETE_MODE := "WELCHES LÖSCHEN?"
## Kopfzeile der Rückfrage.
const HEADER_CONFIRM := "LÖSCHEN?"

# --- Einträge ----------------------------------------------------------------------------------

const LABEL_CONTINUE := "Weiterspielen"
const LABEL_NEW_GAME := "Neues Spiel"
const LABEL_LOAD_GAME := "Spiel laden"
const LABEL_SETTINGS := "Einstellungen"
const LABEL_QUIT := "Beenden"
## In Gradwahl und Liste.
const LABEL_BACK := "Zurück"
## Schaltet in der Liste den Löschmodus ein.
const LABEL_DELETE_MODE := "Löschen …"
## Rückfrage; vorgewählt.
const LABEL_CANCEL := "Abbrechen"
## Rückfrage: die Aktion mit ihrem Gegenstand.
const LABEL_DELETE := "{name} löschen"
## Der Knopf auf dem Spielbildschirm.
const LABEL_LEAVE := "Zum Hauptmenü"

# --- Hinweise im Hauptmenü ---------------------------------------------------------------------

const HINT_CONTINUE := "Weiter mit {name}, {grad}, am {datum}."
## „Weiterspielen“ ist nicht verfügbar, weil es keine Spielstände gibt.
const HINT_CONTINUE_NO_SAVES := "Noch kein Spiel angefangen."
## „Weiterspielen“ ist nicht verfügbar, weil sich keiner fortsetzen lässt.
const HINT_CONTINUE_NONE_RESUMABLE := "Kein Spielstand lässt sich fortsetzen."
const HINT_NEW_GAME := "Einen neuen Laden aufmachen. Los geht es am 01.01.1985."
const HINT_LOAD_GAME := "Alle Spielstände: fortsetzen oder löschen."
## „Spiel laden“ ist nicht verfügbar.
const HINT_LOAD_GAME_NO_SAVES := "Noch keine Spielstände."
## Wie Feature 001.
const HINT_SETTINGS := "Noch nichts einzustellen. Kommt später."
## Wie Feature 001.
const HINT_QUIT := "Laden abschließen und zurück zum Desktop."

# --- Gradwahl: die Sätze zu den Graden (Klaus, 2026-10-26, research.md, R18) -------------------

const HINT_EASY := "Das Glück ist eher auf deiner Seite."
const HINT_MEDIUM := "Das Glück hält sich raus."
const HINT_HARD := "Das Glück ist eher auf der Seite der anderen."
## „Zurück“ in Gradwahl und Liste.
const HINT_BACK := "Zurück zum Hauptmenü. Esc geht auch."

# --- Liste der Spielstände ---------------------------------------------------------------------

## Eine fortsetzbare Zeile; Datum und Uhrzeit von „zuletzt gespielt“.
const HINT_SLOT := "Zuletzt gespielt am {datum} um {uhrzeit} Uhr."
const HINT_DELETE_MODE := "Einen Spielstand löschen. Vorher fragt das Spiel nach."
## „Löschen …“ im Löschmodus, wo es nicht verfügbar ist.
const HINT_DELETE_MODE_ACTIVE := "Wähl oben den Spielstand, der weg soll. Esc bricht ab."
## Eine Zeile im Löschmodus.
const HINT_SLOT_DELETE := "{name} wird gelöscht. Vorher fragt das Spiel nach."
## „Zurück“ im Löschmodus: Es beendet nur den Modus.
const HINT_BACK_DELETE_MODE := "Nicht löschen. Esc geht auch."
## Statt Grad und Spieldatum, in den Spalten und in der Rückfrage.
const STATE_DAMAGED := "beschädigt"
const STATE_TOO_NEW := "neuere Version"

# --- Rückfrage ---------------------------------------------------------------------------------

## Der Name steht vorn, damit der Hinweis auch mit „Spiel 9999“ in zwei Zeilen passt (Klaus,
## 2026-10-26).
const HINT_CONFIRM_CANCEL := "{name} bleibt: {grad}, {datum}. Esc geht auch."
const HINT_CONFIRM_DELETE := "{name} ist danach weg: {grad}, {datum}. Für immer."
## Bei einem Spielstand, der sich nicht fortsetzen lässt, steht sein Zustand statt Grad und Datum.
const HINT_CONFIRM_CANCEL_UNRESUMABLE := "{name}, {zustand}, bleibt. Esc geht auch."
const HINT_CONFIRM_DELETE_UNRESUMABLE := "{name}, {zustand}, ist danach weg. Für immer."

# --- Spielbildschirm ---------------------------------------------------------------------------

## Hinweis neben dem Knopf „Zum Hauptmenü“.
const HINT_LEAVE := "Speichert {name} und führt ins Hauptmenü."

# --- Meldungen ---------------------------------------------------------------------------------

## Löschen ist gescheitert. Die Meldungen zum Speichern stehen in GameSession.
const MESSAGE_DELETE_FAILED := "Löschen ging nicht. Der Spielstand ist noch da."


## „Weiter mit Spiel 2, Schwer, am 14.03.1986.“
static func continue_hint(game_name: String, difficulty: String, date: String) -> String:
	return HINT_CONTINUE.format({"name": game_name, "grad": difficulty, "datum": date})


## Der Satz zu [param level] (Difficulty.Level); leer bei einem unbekannten Grad.
static func difficulty_hint(level: int) -> String:
	match level:
		Difficulty.Level.LEICHT:
			return HINT_EASY
		Difficulty.Level.MITTEL:
			return HINT_MEDIUM
		Difficulty.Level.SCHWER:
			return HINT_HARD
	return ""


## „Zuletzt gespielt am 26.10.2026 um 21:40 Uhr.“
static func slot_hint(date: String, time: String) -> String:
	return HINT_SLOT.format({"datum": date, "uhrzeit": time})


## „Spiel 2 wird gelöscht. Vorher fragt das Spiel nach.“
static func slot_delete_hint(game_name: String) -> String:
	return HINT_SLOT_DELETE.format({"name": game_name})


## „Spiel 2 löschen“
static func delete_label(game_name: String) -> String:
	return LABEL_DELETE.format({"name": game_name})


## „Spiel 2 bleibt: Schwer, 14.03.1986. Esc geht auch.“
static func confirm_cancel_hint(game_name: String, difficulty: String, date: String) -> String:
	return HINT_CONFIRM_CANCEL.format({"name": game_name, "grad": difficulty, "datum": date})


## „Spiel 2 ist danach weg: Schwer, 14.03.1986. Für immer.“
static func confirm_delete_hint(game_name: String, difficulty: String, date: String) -> String:
	return HINT_CONFIRM_DELETE.format({"name": game_name, "grad": difficulty, "datum": date})


## „Spiel 3, beschädigt, bleibt. Esc geht auch.“; [param state] ist STATE_DAMAGED oder
## STATE_TOO_NEW.
static func confirm_cancel_hint_unresumable(game_name: String, state: String) -> String:
	return HINT_CONFIRM_CANCEL_UNRESUMABLE.format({"name": game_name, "zustand": state})


## „Spiel 3, beschädigt, ist danach weg. Für immer.“
static func confirm_delete_hint_unresumable(game_name: String, state: String) -> String:
	return HINT_CONFIRM_DELETE_UNRESUMABLE.format({"name": game_name, "zustand": state})


## „Speichert Spiel 2 und führt ins Hauptmenü.“
static func leave_hint(game_name: String) -> String:
	return HINT_LEAVE.format({"name": game_name})
