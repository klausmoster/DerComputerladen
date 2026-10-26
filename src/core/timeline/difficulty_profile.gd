class_name DifficultyProfile
extends RefCounted

## Das Profil eines Schwierigkeitsgrads (Feature 003, data-model.md, „DifficultyProfile“): die
## Start-Modifikatoren von Leicht oder Schwer. Mittel hat kein Profil, Mittel ist der Katalog
## allein (FR-004). Ein leeres Profil spielt sich deshalb wie Mittel.
##
## Ein Start-Modifikator ist ein ChanceModifier, der schon beim Spielstart gilt. Er verschiebt die
## Chance eines Ereignisses über Wahrscheinlichkeit für seinen Zeitraum, genau wie ein Eingriff aus
## Feature 002. Mehrere auf dasselbe Ereignis addieren sich.
##
## Im Katalog steht das Profil als Liste im Abschnitt „profiles“, etwa unter „schwer“. Eine Stelle
## i in dieser Liste heißt in Prüfmeldungen wie in der Datei, profiles.schwer[2].reason, und im
## Text „Profil „Schwer“, Start-Modifikator „reklamationswelle““. So sagt jede Meldung, wo sie
## hingehört, ohne ein Ereignis zu nennen: Ein Fehler im Profil darf kein Ereignis aus dem Spiel
## nehmen (research.md, R8).

## Der erste Tag nach dem Spiel, der 01.01.2000; die Grenze hinter dem letzten Abschnitt.
const _AFTER_GAME := TimelineRun.LAST_DAY + 1

var level: Difficulty.Level = Difficulty.Level.LEICHT
## Die Start-Modifikatoren in der Reihenfolge der Datei. Neue kommen ans Ende, ein Duplikat direkt
## hinter sein Original; sortiert wird nie, sonst wanderte ein ganzer Block, wenn Klaus eine
## Kennung ändert (research.md, R2).
var modifiers: Array[ChanceModifier] = []


func _init(p_level: Difficulty.Level = Difficulty.Level.LEICHT) -> void:
	level = p_level


## Liest die Liste eines Profils (ereigniskatalog.md, „Lesen“). Strukturfehler V22 kommen mit Feld
## und Ort nach [param issues]: ChanceModifier.from_dict() meldet sie mit dem bloßen Schlüssel,
## etwa „value“; danach setzt CatalogIssue.prefix_fields() field_prefix() davor und
## CatalogIssue.locate() den Ort aus place().
##
## Ist [param data] keine Liste, ist das Profil leer. Ein Eintrag, der kein Objekt ist, wird ein
## Start-Modifikator mit den Vorgaben und hat das Feld „profiles.schwer[2]“. So passen die Stellen
## im Profil zu den Feldern der Meldungen, und Klaus kann den Eintrag in der Werkstatt löschen.
static func from_list(p_level: Difficulty.Level, data: Variant,
		issues: Array[CatalogIssue]) -> DifficultyProfile:
	var profile := DifficultyProfile.new(p_level)
	var first := issues.size()
	if typeof(data) != TYPE_ARRAY:
		issues.append(CatalogIssue.wrong_type("profiles.%s" % Difficulty.key(p_level), "eine Liste",
			data))
		CatalogIssue.locate(issues, first, "Profil „%s“" % Difficulty.label(p_level))
		return profile
	var items: Array = data
	for i in items.size():
		first = issues.size()
		var modifier: ChanceModifier
		if typeof(items[i]) == TYPE_DICTIONARY:
			modifier = ChanceModifier.from_dict(items[i], issues)
			CatalogIssue.prefix_fields(issues, first, field_prefix(p_level, i))
		else:
			# Die Vorgaben stehen an einer Stelle, in from_dict(). Seine Meldungen über die
			# fehlenden Schlüssel braucht es hier nicht; eine Meldung über den Eintrag reicht.
			var unused: Array[CatalogIssue] = []
			modifier = ChanceModifier.from_dict({}, unused)
			issues.append(CatalogIssue.wrong_type(field_prefix(p_level, i).trim_suffix("."),
				"ein Objekt", items[i]))
		CatalogIssue.locate(issues, first, place(p_level, i, modifier))
		profile.modifiers.append(modifier)
	return profile


## Je Start-Modifikator ChanceModifier.to_dict(), in der Reihenfolge des Profils.
func to_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for modifier in modifiers:
		list.append(modifier.to_dict())
	return list


## { "schwer": to_list() }: der Teil des Abschnitts profiles für diesen Grad. EventCatalog.to_dict()
## setzt den Abschnitt daraus zusammen, und CatalogEditor.content_key() bekommt darüber den Text
## des Profils (Analyse, U1).
func to_dict() -> Dictionary:
	return {Difficulty.key(level): to_list()}


## Tiefe Kopie über to_list() und from_list(). Wie bei Ereignissen hat die Kopie, was in der Datei
## stünde: Werte auf vier Nachkommastellen gerundet.
func duplicate_profile() -> DifficultyProfile:
	# Aus einem gültigen to_list() entstehen keine Meldungen.
	var ignored: Array[CatalogIssue] = []
	return from_list(level, to_list(), ignored)


## „profiles.schwer[2].“: der Anfang der Felder aller Meldungen zu dieser Stelle.
static func field_prefix(p_level: int, index: int) -> String:
	return "profiles.%s[%d]." % [Difficulty.key(p_level), index]


## „Profil „Schwer“, Start-Modifikator „reklamationswelle““, ohne Kennung „Profil „Schwer“,
## Start-Modifikator Nr. 3 ohne Kennung“. Die Nummer zählt ab 1, die Stelle ab 0.
static func place(p_level: int, index: int, modifier: ChanceModifier) -> String:
	var where := "Profil „%s“, Start-Modifikator" % Difficulty.label(p_level)
	if modifier != null and not modifier.id.is_empty():
		return "%s „%s“" % [where, modifier.id]
	return "%s Nr. %d ohne Kennung" % [where, index + 1]


## Die Stellen im Profil von [param p_level], zu denen eine Meldung der Stufe ERROR gehört, als
## { index: true }. Dazu gehört eine Meldung mit dem Feld „profiles.<key>[<i>]“ oder mit
## „profiles.<key>[<i>].“ am Anfang. Verglichen wird nach ganzen Pfadteilen: Zu „profiles.schwerr“
## gehört keine Stelle von Schwer, zu „profiles.schwer“ allein auch nicht. without_faulty() und
## das Formular nutzen es.
static func faulty_indices(issues: Array[CatalogIssue], p_level: int) -> Dictionary:
	var result := {}
	if not Difficulty.WITH_PROFILE.has(p_level):
		return result
	# Mit der Klammer: „profiles.schwer[“ ist kein Anfang von „profiles.schwerr[0]“.
	var start := "profiles.%s[" % Difficulty.key(p_level)
	for issue in issues:
		if issue.severity != CatalogIssue.Severity.ERROR or not issue.field.begins_with(start):
			continue
		var rest := issue.field.substr(start.length())
		var close := rest.find("]")
		if close < 0:
			continue
		var digits := rest.left(close)
		var after := rest.substr(close + 1)
		# Nur Ziffern in der Form, die field_prefix() schreibt: „2“, nicht „02“, „+2“ oder „-1“.
		if digits.is_empty() or not digits.lstrip("0123456789").is_empty() \
				or str(digits.to_int()) != digits:
			continue
		if after.is_empty() or after.begins_with("."):
			result[digits.to_int()] = true
	return result


## Die wirksame Chance von [param event] über das ganze Spiel in Abschnitten, je
## { "from_day": int, "to_day": int, "chance": float } (data-model.md, „Chance je
## Zeitabschnitt“). [param profile] null heißt Mittel. Stellen in [param skip] zählen nicht; das
## Formular gibt dort faulty_indices() mit, denn Start-Modifikatoren mit einem Fehler gelten auch im
## Spiel nicht (FR-015).
##
## Die Chance ist zwischen zwei Grenzen gleich. Grenzen liegen beim 01.01.1985, am Beginn jedes
## Start-Modifikators auf das Ereignis, am Tag nach seinem Ende und beim 01.01.2000, alle begrenzt
## auf den Spielzeitraum. Je Abschnitt gilt die Grundchance plus die Summe der dort geltenden Werte,
## begrenzt auf 0 bis 1 wie im Lauf. Gleiche Nachbarn werden zusammengelegt, so erscheinen nur
## echte Wechsel.
static func chance_periods(event: TimelineEvent, profile: DifficultyProfile,
		skip: Dictionary = {}) -> Array[Dictionary]:
	var periods: Array[Dictionary] = []
	if event == null:
		return periods
	var relevant: Array[ChanceModifier] = []
	if profile != null:
		for i in profile.modifiers.size():
			if not skip.has(i) and profile.modifiers[i].event_id == event.id:
				relevant.append(profile.modifiers[i])
	var bounds := {TimelineRun.FIRST_DAY: true, _AFTER_GAME: true}
	for modifier in relevant:
		bounds[clampi(modifier.from_day, TimelineRun.FIRST_DAY, _AFTER_GAME)] = true
		bounds[clampi(modifier.to_day + 1, TimelineRun.FIRST_DAY, _AFTER_GAME)] = true
	var days: Array = bounds.keys()
	days.sort()
	for i in days.size() - 1:
		var from: int = days[i]
		var chance := event.monthly_chance
		for modifier in relevant:
			if modifier.is_active(from):
				chance += modifier.value
		chance = clampf(chance, 0.0, 1.0)
		var last: Dictionary = periods.back() if not periods.is_empty() else {}
		if not last.is_empty() and is_equal_approx(last["chance"], chance):
			last["to_day"] = int(days[i + 1]) - 1
		else:
			periods.append({"from_day": from, "to_day": int(days[i + 1]) - 1, "chance": chance})
	return periods


## „8 %“ bei einem Abschnitt, sonst „3 % bis 31.12.1994, 6 % ab 01.01.1995“, in der Mitte „5 % vom
## 01.01.1990 bis 31.12.1994“. Formatiert im Kern wie ScheduleEntry._percent(), nie über
## EventForm, denn die Werkstatt ist vom Export ausgeschlossen (Analyse, U11).
static func describe_periods(periods: Array[Dictionary]) -> String:
	if periods.size() == 1:
		return _percent(periods[0]["chance"])
	var parts := PackedStringArray()
	for i in periods.size():
		var period := periods[i]
		var chance := _percent(period["chance"])
		var from := _date(period["from_day"])
		var until := _date(period["to_day"])
		if i == 0:
			parts.append("%s bis %s" % [chance, until])
		elif i == periods.size() - 1:
			parts.append("%s ab %s" % [chance, from])
		else:
			parts.append("%s vom %s bis %s" % [chance, from, until])
	return ", ".join(parts)


## Anteil als Prozent mit deutschem Komma und höchstens zwei Nachkommastellen, etwa 0.03 als „3 %“
## und 0.025 als „2,5 %“; wie ScheduleEntry._percent().
static func _percent(share: float) -> String:
	var text := ("%.2f" % (share * 100.0)).rstrip("0").rstrip(".")
	return "%s %%" % text.replace(".", ",")


## Tag als „TT.MM.JJJJ“.
static func _date(day: int) -> String:
	return str(GameDate.from_day_index(day))
