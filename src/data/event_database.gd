class_name EventDatabase
extends RefCounted

## Seed-Daten für die Zeitleiste. Die fixen Ereignisse bilden die reale
## PC-Geschichte des deutschen Marktes 1985–1999 ab, die variablen Ereignisse
## sind Vorlagen, die zufällig im Spielverlauf auftreten können.
##
## Die `target`-Strings der Effekte sind bewusst frei gewählt (z.B. "cpu_486",
## "ram", "modem", "*"). Die noch zu bauenden Systeme (Preise, Nachfrage,
## Reputation, Kundenstrom) interpretieren diese Strings, wenn sie sich an
## `Timeline.effect_applied` hängen.


static func build_fixed_events() -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []

	events.append(_fixed("intel_386", "Intel 80386 erscheint", 1985, 10, 17,
		TimelineEvent.Category.HARDWARE,
		"Die erste 32-Bit-CPU für den PC. High-End und teuer – ein Statussymbol.",
		[
			_fx(EventEffect.Kind.PRESSE, "cpu", 0.0, "Fachpresse feiert die 32-Bit-Ära."),
			_fx(EventEffect.Kind.NACHFRAGE, "cpu_high_end", 0.10, "Enthusiasten wollen das Neueste."),
		]))

	events.append(_fixed("ibm_ps2", "IBM PS/2 mit VGA und PS/2-Maus", 1987, 4, 2,
		TimelineEvent.Category.HARDWARE,
		"VGA-Grafik und der PS/2-Mausanschluss setzen neue Standards.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "maus", 0.15, "PS/2-Maus etabliert sich."),
			_fx(EventEffect.Kind.PRESSE, "grafik", 0.0, "VGA wird zum Maßstab."),
		]))

	events.append(_fixed("intel_486", "Intel 80486 erscheint", 1989, 4, 10,
		TimelineEvent.Category.HARDWARE,
		"Integrierte FPU und Cache – der 386 rutscht in die Mittelklasse.",
		[
			_fx(EventEffect.Kind.PREIS, "cpu_386", -0.30, "386 verliert die Spitzenposition."),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.10, "Neue Systeme brauchen mehr Speicher."),
			_fx(EventEffect.Kind.PRESSE, "cpu", 0.0, ""),
		]))

	events.append(_fixed("win_30", "Windows 3.0", 1990, 5, 22,
		TimelineEvent.Category.SOFTWARE,
		"Die erste wirklich erfolgreiche Windows-Version. Grafische Oberfläche im Massenmarkt.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "maus", 0.20, "Ohne Maus kein Windows."),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.15, ""),
		]))

	events.append(_fixed("wiedervereinigung", "Deutsche Wiedervereinigung", 1990, 10, 3,
		TimelineEvent.Category.WIRTSCHAFT,
		"Ein riesiger neuer Markt mit Nachholbedarf an Technik.",
		[
			_fx(EventEffect.Kind.KUNDENSTROM, "*", 0.25, "Neue Kundschaft, Nachholbedarf.", 60),
		]))

	events.append(_fixed("amd_386dx40", "AMD Am386DX-40", 1991, 3, 1,
		TimelineEvent.Category.HARDWARE,
		"AMD bringt einen schnelleren, günstigeren 386 – Preiskampf beginnt.",
		[
			_fx(EventEffect.Kind.PREIS, "cpu_386", -0.20, "AMD unterbietet Intel."),
			_fx(EventEffect.Kind.NACHFRAGE, "cpu_budget", 0.15, "Preisbewusste greifen zu."),
		]))

	events.append(_fixed("win_31", "Windows 3.1", 1992, 4, 6,
		TimelineEvent.Category.SOFTWARE,
		"TrueType-Schriften, stabiler, Multimedia. Windows wird zum Standard.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "maus", 0.20, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.20, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "software_windows", 0.30, ""),
		]))

	events.append(_fixed("rezession_93", "Konjunkturflaute", 1993, 1, 1,
		TimelineEvent.Category.WIRTSCHAFT,
		"Wirtschaftskrise 1993 – die Leute halten ihr Geld zusammen.",
		[
			_fx(EventEffect.Kind.KUNDENSTROM, "*", -0.20, "Kaufzurückhaltung."),
			_fx(EventEffect.Kind.NACHFRAGE, "komplett_pc", -0.15, ""),
		]))

	events.append(_fixed("msdos_6", "MS-DOS 6.0", 1993, 3, 30,
		TimelineEvent.Category.SOFTWARE,
		"DoubleSpace-Kompression und Defrag – DOS bleibt relevant.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "software", 0.10, ""),
		]))

	# Design-Beispiel: Pentium erscheint → 486-Preise fallen, RAM-Nachfrage steigt, Presse berichtet.
	events.append(_fixed("intel_pentium", "Intel Pentium erscheint", 1993, 3, 22,
		TimelineEvent.Category.HARDWARE,
		"Superskalare P5-Architektur, 64-Bit-Bus. Das neue High-End – teuer und heiß.",
		[
			_fx(EventEffect.Kind.PREIS, "cpu_486", -0.30, "486 wird zur Mittelklasse."),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.20, "Pentium-Systeme wollen Speicher.", 14),
			_fx(EventEffect.Kind.PRESSE, "cpu", 0.0, "Fachpresse berichtet groß."),
		]))

	events.append(_fixed("cdrom_standard", "CD-ROM wird Standard", 1994, 1, 1,
		TimelineEvent.Category.TECH,
		"Multimedia-PCs setzen sich durch – ohne CD-ROM-Laufwerk geht nichts mehr.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "cdrom", 0.40, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "software_cd", 0.30, ""),
			_fx(EventEffect.Kind.PRESSE, "multimedia", 0.0, ""),
		]))

	events.append(_fixed("msdos_622", "MS-DOS 6.22", 1994, 6, 1,
		TimelineEvent.Category.SOFTWARE,
		"Letzte eigenständige DOS-Version.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "software", 0.05, ""),
		]))

	# Design-Beispiel: Windows 95 → Maus-Nachfrage steigt, CD-ROM wird Pflicht, mehr RAM nötig.
	events.append(_fixed("win_95", "Windows 95", 1995, 8, 24,
		TimelineEvent.Category.SOFTWARE,
		"Riesiges Medienereignis. Startmenü, 32-Bit, Plug & Play. Treibt einen ganzen Aufrüstungs-Boom.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "maus", 0.40, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "cdrom", 0.30, "Auslieferung auf CD.", 7),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.30, "Mindestens 8 MB empfohlen."),
			_fx(EventEffect.Kind.NACHFRAGE, "komplett_pc", 0.25, "Aufrüst- und Neukauf-Welle."),
			_fx(EventEffect.Kind.PRESSE, "windows", 0.0, "Wochenlang in allen Medien."),
		]))

	events.append(_fixed("pentium_pro", "Intel Pentium Pro", 1995, 11, 1,
		TimelineEvent.Category.HARDWARE,
		"Auf Server und Workstations gemünzt – im DOS-Alltag kaum schneller.",
		[
			_fx(EventEffect.Kind.PREIS, "cpu_pentium", -0.15, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "cpu_server", 0.10, ""),
		]))

	# Design-Beispiel: Internet wird verfügbar → Modems gefragt, neue Kundenschicht.
	events.append(_fixed("internet_privat", "Internet für Privatkunden", 1995, 11, 28,
		TimelineEvent.Category.TECH,
		"Online-Dienste starten in Deutschland durch. Das Modem wird zum Verkaufsschlager.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "modem", 0.50, ""),
			_fx(EventEffect.Kind.KUNDENSTROM, "enthusiasten", 0.20, "Neue, technikbegeisterte Kundschaft."),
			_fx(EventEffect.Kind.PRESSE, "internet", 0.0, ""),
		]))

	events.append(_fixed("usb_10", "USB 1.0 vorgestellt", 1996, 1, 15,
		TimelineEvent.Category.TECH,
		"Der neue Anschlussstandard – noch ohne nennenswerte Geräte.",
		[
			_fx(EventEffect.Kind.PRESSE, "usb", 0.0, "Zukunftsmusik – noch kaum Hardware verfügbar."),
		]))

	events.append(_fixed("intel_pentium2", "Intel Pentium II", 1997, 5, 7,
		TimelineEvent.Category.HARDWARE,
		"Slot-1-Kassette, schnell und teuer. Der erste Pentium wird Einsteiger-Ware.",
		[
			_fx(EventEffect.Kind.PREIS, "cpu_pentium", -0.30, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "ram", 0.15, ""),
			_fx(EventEffect.Kind.PRESSE, "cpu", 0.0, ""),
		]))

	events.append(_fixed("win_98", "Windows 98", 1998, 6, 25,
		TimelineEvent.Category.SOFTWARE,
		"USB-Unterstützung ab Werk, Internet Explorer integriert.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "komplett_pc", 0.20, ""),
			_fx(EventEffect.Kind.NACHFRAGE, "usb_geraete", 0.20, "USB wird endlich nutzbar."),
			_fx(EventEffect.Kind.PRESSE, "windows", 0.0, ""),
		]))

	events.append(_fixed("euro_buchgeld", "Euro als Buchgeld", 1999, 1, 1,
		TimelineEvent.Category.WIRTSCHAFT,
		"Der Euro kommt als Verrechnungswährung – Preise müssen umgedacht werden.",
		[
			_fx(EventEffect.Kind.PRESSE, "wirtschaft", 0.0, "Preisauszeichnung im Wandel."),
		]))

	return events


static func build_variable_events() -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []

	events.append(_variable("neubaugebiet", "Neubaugebiet in der Nähe",
		TimelineEvent.Category.LOKAL, 0.04, 1985, 1999, 4, 365,
		"Ein neues Wohngebiet entsteht – mehr potenzielle Laufkundschaft.",
		[
			_fx(EventEffect.Kind.KUNDENSTROM, "*", 0.20, "Neue Anwohner ziehen zu.", 30),
		]))

	events.append(_variable("konkurrent_eroeffnet", "Konkurrent eröffnet",
		TimelineEvent.Category.KONKURRENZ, 0.03, 1986, 1999, 0, 540,
		"Ein neuer Computerladen macht in der Nähe auf.",
		[
			_fx(EventEffect.Kind.KUNDENSTROM, "*", -0.25, "Kundschaft wird abgezogen."),
			_fx(EventEffect.Kind.NACHFRAGE, "*", -0.10, ""),
		]))

	events.append(_variable("konkurrent_schliesst", "Konkurrent gibt auf",
		TimelineEvent.Category.KONKURRENZ, 0.025, 1988, 1999, 0, 540,
		"Ein Mitbewerber schließt – dessen Kundschaft sucht eine neue Anlaufstelle.",
		[
			_fx(EventEffect.Kind.KUNDENSTROM, "*", 0.20, "Verwaiste Kundschaft."),
		]))

	events.append(_variable("grosskunde", "Großkunde meldet sich",
		TimelineEvent.Category.KUNDE, 0.06, 1985, 1999, 0, 120,
		"Eine Schule oder ein Büro fragt nach einer Sammelbestellung.",
		[
			_fx(EventEffect.Kind.NACHFRAGE, "komplett_pc", 0.30, "Sammelbestellung in Aussicht.", 7),
			_fx(EventEffect.Kind.PRESSE, "geschaeft", 0.0, ""),
		]))

	events.append(_variable("reklamationswelle", "Reklamationswelle",
		TimelineEvent.Category.REKLAMATION, 0.03, 1985, 1999, 0, 90,
		"Mehrere Kunden kommen gleichzeitig mit defekter Ware zurück.",
		[
			_fx(EventEffect.Kind.REPUTATION, "*", -0.15, "Häufung von Ausfällen."),
			_fx(EventEffect.Kind.PRESSE, "negativ", 0.0, "Negativer Zeitungsartikel droht.", 14),
		]))

	events.append(_variable("lieferengpass", "Lieferengpass",
		TimelineEvent.Category.LIEFERUNG, 0.04, 1985, 1999, 0, 120,
		"Der Großhändler kann eine gefragte Komponente nicht liefern.",
		[
			_fx(EventEffect.Kind.PREIS, "*", 0.15, "Knappheit treibt die Einkaufspreise."),
			_fx(EventEffect.Kind.NACHFRAGE, "*", -0.05, "Was es nicht gibt, wird nicht gekauft."),
		]))

	return events


# --- Bau-Helfer ----------------------------------------------------------

static func _fixed(id: String, title: String, year: int, month: int, day: int,
		category: TimelineEvent.Category, description: String,
		effects: Array) -> TimelineEvent:
	var e := TimelineEvent.new()
	e.id = id
	e.title = title
	e.year = year
	e.month = month
	e.day = day
	e.category = category
	e.description = description
	e.is_fixed = true
	e.effects = _as_effects(effects)
	return e


static func _variable(id: String, title: String, category: TimelineEvent.Category,
		monthly_chance: float, earliest: int, latest: int, max_occ: int, cooldown: int,
		description: String, effects: Array) -> TimelineEvent:
	var e := TimelineEvent.new()
	e.id = id
	e.title = title
	e.category = category
	e.is_fixed = false
	e.monthly_chance = monthly_chance
	e.earliest_year = earliest
	e.latest_year = latest
	e.max_occurrences = max_occ
	e.cooldown_days = cooldown
	e.description = description
	e.effects = _as_effects(effects)
	return e


static func _fx(kind: EventEffect.Kind, target: String, magnitude: float,
		note: String, delay: int = 0) -> EventEffect:
	var f := EventEffect.new()
	f.kind = kind
	f.target = target
	f.magnitude = magnitude
	f.note = note
	f.delay_days = delay
	return f


static func _as_effects(raw: Array) -> Array[EventEffect]:
	var typed: Array[EventEffect] = []
	for effect: EventEffect in raw:
		typed.append(effect)
	return typed
