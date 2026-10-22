class_name Difficulty
extends RefCounted

## Die Schwierigkeitsgrade des Spiels (Feature 003, FR-001; research.md, R1): Leicht, Mittel und
## Schwer, dazu ihre Namen an einer Stelle. Die Klasse hat keine Instanzen, nur die Aufzählung und
## statische Hilfen.
##
## Leicht und Schwer haben je ein Profil aus Start-Modifikatoren (DifficultyProfile). Mittel hat
## keins: Mittel ist der Katalog ohne Start-Modifikatoren (FR-004).
##
## Eine Aufzählung ist zur Laufzeit eine ganze Zahl. Ein Parameter vom Typ Difficulty.Level nimmt
## deshalb auch eine 7 an, ohne Fehler. Wer einen Grad von außen bekommt, aus einer Datei, einem
## Argument oder einer Auswahl, prüft ihn mit is_valid() und wandelt ihn mit
## `as Difficulty.Level` um (contracts/zeitleiste.md, „Difficulty“).

enum Level { LEICHT, MITTEL, SCHWER }

const DEFAULT := Level.MITTEL
## Die Grade mit Profil, in der Reihenfolge der Profile im Katalog (FR-002, FR-004).
const WITH_PROFILE: Array[int] = [Level.LEICHT, Level.SCHWER]

## Die Namen in Katalog, Probe und Textausgabe, in der Reihenfolge von Level.
const _KEYS: Array[String] = ["leicht", "mittel", "schwer"]
## Die Namen in Texten, in der Reihenfolge von Level.
const _LABELS: Array[String] = ["Leicht", "Mittel", "Schwer"]


## "leicht", "mittel", "schwer": der Name in Katalog, Probe und Textausgabe; leer bei einem
## unbekannten Grad.
static func key(level: int) -> String:
	return _KEYS[level] if is_valid(level) else ""


## „Leicht“, „Mittel“, „Schwer“: der Name in Texten; bei einem unbekannten Grad „Grad 7“.
static func label(level: int) -> String:
	return _LABELS[level] if is_valid(level) else "Grad %d" % level


## Name → Grad; −1, wenn es den Grad nicht gibt. Groß- und Kleinschreibung zählt: „Schwer“ mit
## großem S ist kein Name, denn in Dateien und Argumenten stehen die Namen klein (FR-011).
static func from_key(text: String) -> int:
	return _KEYS.find(text)


## Ob [param level] einer der drei Grade ist. Eine Aufzählung ist zur Laufzeit eine ganze Zahl,
## deshalb prüft jeder Spielstart hier (FR-011).
static func is_valid(level: int) -> bool:
	return level >= Level.LEICHT and level <= Level.SCHWER
