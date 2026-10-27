extends GutTest

## Prüft die Töne unter res://assets/sounds/ und die Tonkanäle (Feature 006, contracts/ton.md).
##
## Maßstab ist der Style-Guide, Abschnitt „Ton“: WAV, 22 050 Hz, 16 Bit, mono; jeder Ton beginnt
## ohne Stille und endet mit 5 ms Ausblenden; Längen laut Tabelle; Kanal `Effekte` auf −10 dB mit
## Ziel `Master`, `Master` auf 0 dB, kein Effekt auf den Kanälen.
##
## Proben, Länge und Prüfsumme kommen aus der Rohdatei (FileAccess), nicht aus der importierten
## Ressource: Der Import könnte die Proben verändern (Kompression, Trimmen, Normalisieren), und dann
## prüfte der Test die falsche Sache. Was der Import daraus macht, prüft ein eigener Test an der
## geladenen `AudioStreamWAV` und an der `.import`-Datei.
##
## Die Prüfsummen schreibt `tools/ton/make_sounds.py --pruefsummen` nach
## `res://test/fixtures/ton_pruefsummen.txt`. Der Test schreibt nichts.

const TONORDNER := "res://assets/sounds/"
const PRUEFSUMMEN := "res://test/fixtures/ton_pruefsummen.txt"
const ABTASTRATE := 22050
const BITS := 16
## Vollausschlag einer 16-Bit-Probe.
const VOLLAUSSCHLAG := 32768
## Die letzte Probe gilt als „nahe null“ unter 1 % des Vollausschlags.
const LETZTE_PROBE_HOECHSTENS := VOLLAUSSCHLAG / 100
## Erlaubte Abweichung der Länge in Millisekunden.
const LAENGE_TOLERANZ_MS := 1.0
## Pegel der Kanäle in dB (Style-Guide, „Tonkanäle“).
const PEGEL_MASTER_DB := 0.0
const PEGEL_EFFEKTE_DB := -10.0
## Werte in der `.import` einer WAV: `compress/mode` 0 ist „PCM (Uncompressed)“, `edit/loop_mode`
## 1 ist „Disabled“ (0 hieße „Detect from WAV“).
const IMPORT_PCM := 0
const IMPORT_SCHLEIFE_AUS := 1

## Länge je Datei in Millisekunden (Style-Guide, „Töne“).
const LAENGEN_MS := {
	"knopf.wav": 4.0,
	"schuss.wav": 80.0,
	"treffer.wav": 120.0,
	"kanone.wav": 600.0,
	"marsch_1.wav": 60.0,
	"marsch_2.wav": 60.0,
	"marsch_3.wav": 60.0,
	"marsch_4.wav": 60.0,
	"sieg.wav": 360.0,
	"niederlage.wav": 480.0,
}


func test_im_ordner_liegen_genau_die_zehn_toene() -> void:
	# Arrange
	var erwartet: Array = LAENGEN_MS.keys()
	erwartet.sort()

	# Act
	var gefunden := _toene_im_ordner(TONORDNER)

	# Assert: Ein neuer oder fehlender Ton fällt auf, bevor er ungeprüft ins Spiel kommt.
	assert_eq(gefunden, erwartet, "Die Töne in %s laut Style-Guide." % TONORDNER)


func test_jeder_ton_laedt_als_audiostreamwav_in_pcm_ohne_schleife() -> void:
	for datei: String in LAENGEN_MS:
		# Arrange
		var pfad := TONORDNER + datei

		# Act
		var ton := load(pfad) as AudioStreamWAV

		# Assert
		assert_not_null(ton, "%s lädt als AudioStreamWAV." % datei)
		if ton == null:
			continue
		assert_false(ton.stereo, "%s ist mono." % datei)
		assert_eq(ton.mix_rate, ABTASTRATE, "%s hat 22 050 Hz." % datei)
		assert_eq(ton.format, AudioStreamWAV.FORMAT_16_BITS,
			"%s ist 16 Bit PCM, nicht komprimiert." % datei)
		assert_eq(ton.loop_mode, AudioStreamWAV.LOOP_DISABLED, "%s spielt ohne Schleife." % datei)


func test_jede_import_datei_hat_pcm_ohne_trimmen_normalisieren_und_schleife() -> void:
	for datei: String in LAENGEN_MS:
		# Arrange
		var einstellungen := ConfigFile.new()

		# Act
		var fehler := einstellungen.load(TONORDNER + datei + ".import")

		# Assert
		assert_eq(fehler, OK, "%s.import ist lesbar." % datei)
		assert_eq(einstellungen.get_value("params", "compress/mode", -1), IMPORT_PCM,
			"%s: Kompression aus (PCM)." % datei)
		assert_eq(einstellungen.get_value("params", "edit/trim", true), false,
			"%s: kein Trimmen." % datei)
		assert_eq(einstellungen.get_value("params", "edit/normalize", true), false,
			"%s: kein Normalisieren." % datei)
		assert_eq(einstellungen.get_value("params", "edit/loop_mode", -1), IMPORT_SCHLEIFE_AUS,
			"%s: keine Schleife." % datei)
		assert_eq(einstellungen.get_value("params", "force/mono", true), false,
			"%s: nichts erzwungen, die Datei ist schon mono." % datei)
		assert_eq(einstellungen.get_value("params", "force/8_bit", true), false,
			"%s: bleibt 16 Bit." % datei)
		assert_eq(einstellungen.get_value("params", "force/max_rate", true), false,
			"%s: die Abtastrate bleibt." % datei)


func test_rohdatei_mono_22050_hz_16_bit() -> void:
	for datei: String in LAENGEN_MS:
		# Act
		var wav := _lies_wav(TONORDNER + datei)

		# Assert
		assert_eq(wav.get("fehler", ""), "", datei)
		assert_eq(wav.get("kanaele", 0), 1, "%s ist mono." % datei)
		assert_eq(wav.get("rate", 0), ABTASTRATE, "%s hat 22 050 Hz." % datei)
		assert_eq(wav.get("bits", 0), BITS, "%s hat 16 Bit." % datei)


func test_erste_probe_klingt_und_letzte_ist_ausgeblendet() -> void:
	for datei: String in LAENGEN_MS:
		# Act
		var wav := _lies_wav(TONORDNER + datei)
		var proben: PackedByteArray = wav.get("proben", PackedByteArray())

		# Assert: Kein stiller Anfang (SC-007), Ausblenden am Ende gegen Knacken.
		assert_gt(proben.size(), 1, "%s hat Proben." % datei)
		if proben.size() < 2:
			continue
		var erste := proben.decode_s16(0)
		var letzte := proben.decode_s16(proben.size() - 2)
		assert_ne(erste, 0, "%s beginnt ohne Stille." % datei)
		assert_lt(absi(letzte), LETZTE_PROBE_HOECHSTENS,
			"%s endet nahe null (letzte Probe %d)." % [datei, letzte])


func test_laenge_je_ton_wie_im_style_guide() -> void:
	for datei: String in LAENGEN_MS:
		# Act
		var wav := _lies_wav(TONORDNER + datei)
		var proben: PackedByteArray = wav.get("proben", PackedByteArray())
		var laenge_ms := proben.size() / 2.0 / ABTASTRATE * 1000.0

		# Assert
		assert_almost_eq(laenge_ms, LAENGEN_MS[datei], LAENGE_TOLERANZ_MS,
			"%s ist %.3f ms lang." % [datei, laenge_ms])


func test_pruefsummen_gleich_der_liste() -> void:
	# Arrange
	var liste := _lies_pruefsummen(PRUEFSUMMEN)

	# Assert: Die Liste nennt genau die zehn Töne, und jede Datei ist bytegleich mit dem, was das
	# Skript erzeugt.
	var namen: Array = liste.keys()
	namen.sort()
	var erwartet: Array = LAENGEN_MS.keys()
	erwartet.sort()
	assert_eq(namen, erwartet, "%s nennt die zehn Töne." % PRUEFSUMMEN)
	for datei: String in LAENGEN_MS:
		assert_eq(FileAccess.get_md5(TONORDNER + datei), liste.get(datei, ""),
			"%s ist bytegleich mit make_sounds.py." % datei)


func test_kanaele_master_und_effekte() -> void:
	# Arrange: Godot lädt res://default_bus_layout.tres von selbst beim Start.
	var effekte := AudioServer.get_bus_index(&"Effekte")

	# Assert
	assert_eq(AudioServer.bus_count, 2, "Genau zwei Kanäle: Master und Effekte.")
	assert_eq(AudioServer.get_bus_name(0), "Master", "Kanal 0 ist Master.")
	assert_almost_eq(AudioServer.get_bus_volume_db(0), PEGEL_MASTER_DB, 0.001,
		"Master steht auf 0 dB.")
	assert_gt(effekte, 0, "Den Kanal Effekte gibt es.")
	if effekte <= 0:
		return
	assert_eq(AudioServer.get_bus_send(effekte), &"Master", "Effekte mündet in Master.")
	assert_almost_eq(AudioServer.get_bus_volume_db(effekte), PEGEL_EFFEKTE_DB, 0.001,
		"Effekte steht auf -10 dB.")
	for kanal in AudioServer.bus_count:
		assert_eq(AudioServer.get_bus_effect_count(kanal), 0,
			"Kein Effekt auf %s." % AudioServer.get_bus_name(kanal))
		assert_false(AudioServer.is_bus_mute(kanal),
			"%s ist nicht stumm." % AudioServer.get_bus_name(kanal))


## Die Namen der WAV-Dateien im Ordner, sortiert.
func _toene_im_ordner(ordner: String) -> Array:
	var namen := []
	for datei in DirAccess.get_files_at(ordner):
		if datei.get_extension() == "wav":
			namen.append(datei)
	namen.sort()
	return namen


## Liest eine WAV-Datei roh: Kanäle, Rate und Bits aus dem Block `fmt `, die Proben aus `data`.
## Bei einem Fehler steht dessen Beschreibung unter "fehler".
func _lies_wav(pfad: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(pfad)
	if bytes.size() < 12 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF" \
			or bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return {"fehler": "%s ist keine RIFF/WAVE-Datei." % pfad.get_file()}
	var ergebnis := {}
	var stelle := 12
	while stelle + 8 <= bytes.size():
		var kennung := bytes.slice(stelle, stelle + 4).get_string_from_ascii()
		var groesse := bytes.decode_u32(stelle + 4)
		var inhalt := stelle + 8
		if kennung == "fmt ":
			ergebnis["kanaele"] = bytes.decode_u16(inhalt + 2)
			ergebnis["rate"] = bytes.decode_u32(inhalt + 4)
			ergebnis["bits"] = bytes.decode_u16(inhalt + 14)
		elif kennung == "data":
			ergebnis["proben"] = bytes.slice(inhalt, inhalt + groesse)
		# Blöcke ungerader Länge haben ein Füllbyte.
		stelle = inhalt + groesse + (groesse % 2)
	if not ergebnis.has("kanaele") or not ergebnis.has("proben"):
		ergebnis["fehler"] = "%s hat keinen Block fmt oder data." % pfad.get_file()
	return ergebnis


## Liest die Liste `name md5` je Zeile.
func _lies_pruefsummen(pfad: String) -> Dictionary:
	var liste := {}
	for zeile in FileAccess.get_file_as_string(pfad).split("\n", false):
		var teile := zeile.strip_edges().split(" ", false)
		if teile.size() == 2:
			liste[teile[0]] = teile[1]
	return liste
