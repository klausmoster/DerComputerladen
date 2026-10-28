extends GutTest

## Prüft den Kern des Spiels auf der Anzeige (Feature 006, T012; contracts/invaders.md, „Tests“;
## data-model.md, „Partie“). Jede Partie läuft mit festem Seed Schritt für Schritt, ohne Szene und
## ohne zu warten. Was der Test sieht, liest er wie die Seite aus drawables() und den Ereignissen;
## in den Zustand hinter dem Unterstrich greift er nicht.
##
## Wo eine Partie länger läuft, spielt ein einfacher Testspieler (_spieler_schritt): Er weicht
## Bomben aus und fährt, wenn er zielen soll, unter den waagrecht nächsten lebenden Außerirdischen
## und schießt, sobald einer über ihm ist. Ohne Ausweichen träfen die Bomben die Kanone so oft, dass
## die meisten Partien verloren gingen, bevor sich Sieg oder Landung messen ließen.

const SEED := 4711
## Mit diesem Seed wirft der Block ohne Gegenwehr dreimal zugleich.
const SEED_DREI_BOMBEN := 42
## Seeds 1 bis hierher für die Obergrenze der Bomben.
const SEEDS_BOMBEN_BIS := 50
## Seeds für die Messungen zu SC-002.
const SEEDS_SC002: Array[int] = [1, 2, 3, 4, 5]
## SC-002: höchstens 3 Minuten bis zum Sieg, frühestens 1 Minute bis zur Landung.
const SIEG_HOECHSTENS := 10800
const LANDUNG_FRUEHESTENS := 3600
## Sicherheitsgrenze für Schleifen: 10 Minuten Spielzeit.
const GRENZE := 36000
## Bis hierhin kann noch keine Bombe die Kanone erreichen: erster Takt nach 30 Schritten, die Bombe
## fällt von y 45 bis 71 in 52 Schritten.
const OHNE_BOMBENGEFAHR := 81


# --- Start --------------------------------------------------------------------------------------

func test_start() -> void:
	var spiel := InvadersGame.new(SEED)

	assert_eq(spiel.state, InvadersGame.State.PLAYING)
	assert_eq(spiel.lost_reason, InvadersGame.LostReason.NONE)
	assert_eq(spiel.aliens_left(), 32, "8 Spalten × 4 Reihen.")
	assert_eq(spiel.lives, 3)
	assert_eq(spiel.score, 0)
	assert_eq(spiel.cannon_x, 75, "Die Kanone steht mittig, x 75 bis 83.")
	assert_eq(spiel.march_frame, 0)
	var ausserirdische := _ausserirdische(spiel)
	assert_eq(ausserirdische.size(), 32)
	assert_eq(ausserirdische[0], Vector2i(34, 12), "Der Block beginnt bei x 34, y 12.")
	assert_eq(ausserirdische[31], Vector2i(118, 39), "Unten rechts endet er bei x 125, y 44.")
	var arten := []
	for teil in spiel.drawables():
		if String(teil["sprite"]).begins_with("alien"):
			arten.append(teil["sprite"])
	assert_eq(arten.slice(0, 8).count(&"alien_a"), 8, "Oben alien_a.")
	assert_eq(arten.slice(8, 24).count(&"alien_b"), 16, "Zwei Reihen alien_b.")
	assert_eq(arten.slice(24, 32).count(&"alien_c"), 8, "Unten alien_c.")
	assert_eq(_teile(spiel, &"cannon"), [Vector2i(75, 73)], "Kanone in den Zeilen 73 bis 77.")


# --- Kanone und Schuss ----------------------------------------------------------------------------

func test_kanone_faehrt_und_bleibt_im_feld() -> void:
	var rechts := InvadersGame.new(SEED)
	rechts.step(false, true, false)
	assert_eq(rechts.cannon_x, 76, "Ein Bildpixel je Schritt.")
	for i in OHNE_BOMBENGEFAHR - 1:
		rechts.step(false, true, false)
	assert_eq(rechts.cannon_x, 149, "Rechts endet die Kanone bei x 157.")

	var links := InvadersGame.new(SEED)
	for i in OHNE_BOMBENGEFAHR:
		links.step(true, false, false)
	assert_eq(links.cannon_x, 2, "Links beginnt sie bei x 2.")

	var beide := InvadersGame.new(SEED)
	for i in OHNE_BOMBENGEFAHR:
		beide.step(true, true, false)
	assert_eq(beide.cannon_x, 75, "Links und rechts zugleich heben sich auf.")
	assert_eq(beide.state, InvadersGame.State.PLAYING)


func test_schuss_kommt_aus_der_spitze_und_fliegt_nach_oben() -> void:
	var spiel := InvadersGame.new(SEED)

	var ereignisse := spiel.step(false, false, true)

	assert_eq(_arten(ereignisse), [InvadersGame.Event.SHOT])
	assert_eq(_teile(spiel, &"shot"), [Vector2i(79, 69)],
			"Direkt über der Spitze, der mittleren Spalte der Kanone.")
	spiel.step(false, false, false)
	assert_eq(_teile(spiel, &"shot"), [Vector2i(79, 67)], "2 Bildpixel je Schritt.")


func test_ein_schuss_nur_wenn_keiner_im_feld_ist() -> void:
	var spiel := InvadersGame.new(SEED)
	var schuesse := 0

	for i in 600:
		var vorher := _teile(spiel, &"shot")
		var ereignisse := spiel.step(false, false, true)
		assert_lte(_teile(spiel, &"shot").size(), 1,
				"Höchstens ein Schuss im Feld (Schritt %d)." % i)
		if InvadersGame.Event.SHOT in _arten(ereignisse):
			schuesse += 1
			assert_true(vorher.is_empty() or vorher[0].y - 2 < 8,
					"Neu geschossen nur, wenn keiner mehr im Feld ist (Schritt %d)." % i)

	assert_gt(schuesse, 1, "Nach dem ersten Schuss kamen weitere.")
	assert_lt(schuesse, 100, "Aber nicht bei jedem Druck.")


func test_treffer_trifft_einen_und_zaehlt_punkte_je_reihe() -> void:
	var spiel := InvadersGame.new(SEED)
	# Unter Spalte 3 fahren: unten links x 70, der Schuss bei x 74.
	for i in 5:
		spiel.step(true, false, false)
	assert_eq(spiel.cannon_x, 70)

	var treffer: Array[Dictionary] = []
	for i in GRENZE:
		var ereignisse := _spieler_schritt(spiel, true)
		var hier := ereignisse.filter(func(e: Dictionary) -> bool:
				return e["event"] == InvadersGame.Event.ALIEN_HIT)
		assert_lte(hier.size(), 1, "Ein Schuss trifft höchstens einen.")
		treffer.append_array(hier)
		if treffer.size() == 4:
			break

	assert_eq(treffer.map(func(e: Dictionary) -> int: return e["row"]), [3, 2, 1, 0],
			"Die Spalte von unten nach oben.")
	assert_eq(treffer.map(func(e: Dictionary) -> int: return e["points"]), [10, 20, 20, 30],
			"Unten 10, Mitte 20, oben 30.")
	assert_eq(spiel.score, 80)
	assert_eq(spiel.aliens_left(), 28)


func test_explosion_steht_15_schritte_und_haelt_nichts_auf() -> void:
	var spiel := InvadersGame.new(SEED)
	for i in 5:
		spiel.step(true, false, false)
	spiel.step(false, false, true)
	var ort := Vector2i(-1, -1)
	for i in 100:
		var ereignisse := spiel.step(false, false, false)
		if InvadersGame.Event.ALIEN_HIT in _arten(ereignisse):
			ort = _teile(spiel, &"explosion")[0]
			break
	assert_eq(ort, Vector2i(70, 39), "An der Stelle des Getroffenen, unten in Spalte 3.")

	var gesehen := 1
	var schuss_danach := false
	for i in 20:
		var ereignisse := spiel.step(false, false, true)
		schuss_danach = schuss_danach or InvadersGame.Event.SHOT in _arten(ereignisse)
		if ort in _teile(spiel, &"explosion"):
			gesehen += 1
	assert_eq(gesehen, 15, "0,25 s, also 15 Schritte.")
	assert_true(schuss_danach, "Während der Explosion geht der nächste Schuss.")


# --- Block ----------------------------------------------------------------------------------------

func test_block_rueckt_im_takt_am_rand_tiefer_und_zurueck() -> void:
	var spiel := InvadersGame.new(SEED)
	var takte: Array[int] = []
	var lagen: Array[Vector2i] = []
	var bilder: Array[int] = []
	var noten: Array[int] = []

	for schritt in range(1, 1600):
		var ereignisse := _spieler_schritt(spiel, false)
		assert_false(InvadersGame.Event.CANNON_HIT in _arten(ereignisse),
				"Der Testspieler weicht aus; mit diesem Seed trifft nichts.")
		for e in ereignisse:
			if e["event"] == InvadersGame.Event.MARCH:
				takte.append(schritt)
				lagen.append(_ausserirdische(spiel)[0])
				bilder.append(spiel.march_frame)
				noten.append(e["note"])

	assert_eq(takte[0], 30, "Der erste Takt nach 30 Schritten (0,5 s).")
	for i in range(1, takte.size()):
		assert_eq(takte[i] - takte[i - 1], 30, "Bei 32 Übrigen 30 Schritte zwischen den Takten.")
	assert_eq(lagen[0], Vector2i(36, 12), "Erst 2 nach rechts.")
	assert_eq(lagen[15], Vector2i(66, 12), "Nach 16 Takten endet der Block bei x 157.")
	assert_eq(lagen[16], Vector2i(66, 15), "Im nächsten Takt 3 tiefer, nicht zur Seite.")
	assert_eq(lagen[17], Vector2i(64, 15), "Dann zurück nach links.")
	assert_eq(lagen[48], Vector2i(2, 15), "32 Takte später steht er links bei x 2.")
	assert_eq(lagen[49], Vector2i(2, 18), "Wieder 3 tiefer.")
	assert_eq(lagen[50], Vector2i(4, 18), "Und nach rechts.")
	assert_eq(bilder.slice(0, 4), [1, 0, 1, 0] as Array[int], "Das Bild wechselt mit jedem Takt.")
	assert_eq(noten.slice(0, 6), [0, 1, 2, 3, 0, 1] as Array[int], "Vier Marschtöne im Kreis.")


func test_abstand_der_takte_sinkt_mit_den_uebrigen() -> void:
	var spiel := InvadersGame.new(SEED)
	# Der Start zählt wie ein Takt: Der erste kommt 30 Schritte danach.
	var letzter_takt := -1
	var gestoert := false
	var abstaende := {}

	for schritt in GRENZE:
		var uebrig := spiel.aliens_left()
		var ereignisse := _spieler_schritt(spiel, true)
		var arten := _arten(ereignisse)
		if InvadersGame.Event.ALIEN_HIT in arten or InvadersGame.Event.CANNON_HIT in arten:
			gestoert = true
		if InvadersGame.Event.MARCH in arten:
			if not gestoert:
				var erwartet := 3 + roundi(27.0 * (uebrig - 1) / 31.0)
				assert_eq(schritt - letzter_takt, erwartet, "Abstand bei %d Übrigen." % uebrig)
				abstaende[uebrig] = schritt - letzter_takt
			letzter_takt = schritt
			gestoert = false
		if spiel.state == InvadersGame.State.WON:
			break

	# 30 Schritte bei 32 prüft test_block_rueckt_im_takt_am_rand_tiefer_und_zurueck; hier trifft der
	# Testspieler schon vor dem ersten Takt.
	assert_eq(abstaende.get(1), 3, "3 Schritte (0,05 s) bei einem.")
	assert_gt(abstaende.size(), 10, "Gemessen bei vielen verschiedenen Zahlen von Übrigen.")


func test_rand_zaehlt_nach_den_lebenden() -> void:
	var spiel := InvadersGame.new(SEED)
	# Erst die rechte Spalte abschießen, dann nur noch ausweichen.
	for i in GRENZE:
		_spieler_schritt(spiel, true, true)
		if spiel.aliens_left() == 28:
			break
	assert_eq(spiel.aliens_left(), 28)
	assert_eq(_rechte_kante(_ausserirdische(spiel)) - _linke_kante(_ausserirdische(spiel)), 79,
			"Die rechte Spalte ist weg: Die Lebenden sind 80 breit statt 92.")

	var gesehen := false
	var vorher := _ausserirdische(spiel)
	for i in GRENZE:
		var ereignisse := _spieler_schritt(spiel, false)
		if spiel.state != InvadersGame.State.PLAYING and spiel.state != InvadersGame.State.RESPAWN:
			break
		if not InvadersGame.Event.MARCH in _arten(ereignisse):
			continue
		var jetzt := _ausserirdische(spiel)
		if jetzt[0].y > vorher[0].y:
			var rechts := _rechte_kante(vorher)
			var links := _linke_kante(vorher)
			assert_true(rechts == 157 or links == 2,
					"Gewendet wird nur, wenn die Lebenden den Innenrand erreichen.")
			if rechts == 157:
				assert_eq(links, 78, "Ohne rechte Spalte fährt der Block 12 weiter nach rechts.")
				gesehen = true
				break
		vorher = jetzt

	assert_true(gesehen, "Der Block hat ohne seine rechte Spalte rechts gewendet.")


# --- Bomben und Treffer an der Kanone -------------------------------------------------------------

func test_hoechstens_drei_bomben_aus_der_untersten_reihe() -> void:
	var spiel := InvadersGame.new(SEED_DREI_BOMBEN)
	var hoechstens := 0
	var abwuerfe := 0

	while spiel.state == InvadersGame.State.PLAYING or spiel.state == InvadersGame.State.RESPAWN:
		var vorher := _teile(spiel, &"bomb")
		var unterste := _unterste_je_spalte(spiel)
		var ereignisse := spiel.step(false, false, false)
		var jetzt := _teile(spiel, &"bomb")
		assert_lte(jetzt.size(), 3, "Höchstens 3 Bomben im Feld.")
		hoechstens = maxi(hoechstens, jetzt.size())
		if jetzt.size() > vorher.size():
			abwuerfe += 1
			assert_true(InvadersGame.Event.MARCH in _arten(ereignisse), "Abgeworfen wird im Takt.")
			var neu: Vector2i = jetzt[jetzt.size() - 1]
			var nach_dem_takt := _unterste_je_spalte(spiel)
			assert_true(nach_dem_takt.any(func(a: Vector2i) -> bool:
					return neu == a + Vector2i(3, 6)),
					"Aus der Mitte der Unterkante eines untersten Außerirdischen.")
			assert_eq(unterste.size(), nach_dem_takt.size())

	assert_eq(hoechstens, 3, "Mit diesem Seed liegen einmal drei zugleich im Feld.")
	assert_gt(abwuerfe, 3)


func test_hoechstens_drei_bomben_auch_wenn_der_wurf_gelingt() -> void:
	# Die Obergrenze greift nur, wenn schon drei fallen und der Wurf gelingt. Ob das vorkam, zählt
	# der Beobachter; ohne diesen Fall bliebe auch ein Kern mit vier Bomben grün. Der Testspieler
	# zielt, damit der Block schnell wird und sich die Bomben stauen, und weicht aus, damit sie
	# nicht an der Kanone verschwinden.
	var faelle := 0
	for seed_nummer in range(1, SEEDS_BOMBEN_BIS + 1):
		var spiel := Beobachter.new(seed_nummer)
		for i in GRENZE:
			_spieler_schritt(spiel, true)
			assert_lte(_teile(spiel, &"bomb").size(), 3,
					"Seed %d, Schritt %d: höchstens 3 Bomben." % [seed_nummer, i])
			if spiel.state == InvadersGame.State.WON or spiel.state == InvadersGame.State.LOST:
				break
		faelle += spiel.voll_und_gewuerfelt
	assert_gt(faelle, 0, "Mindestens einmal fielen drei, und der Wurf gelang.")
	gut.p("Drei im Feld und Wurf gelungen, über %d Seeds: %d-mal" % [SEEDS_BOMBEN_BIS, faelle])


func test_bombe_auf_der_kanone() -> void:
	var spiel := InvadersGame.new(SEED)
	var ereignisse: Array[Dictionary] = []
	for i in GRENZE:
		ereignisse = spiel.step(false, false, false)
		if InvadersGame.Event.CANNON_HIT in _arten(ereignisse):
			break

	assert_eq(_arten(ereignisse), [InvadersGame.Event.CANNON_HIT])
	assert_eq(spiel.lives, 2, "Ein Leben weniger.")
	assert_eq(spiel.state, InvadersGame.State.RESPAWN)
	assert_eq(_teile(spiel, &"bomb"), [], "Alle Bomben weg.")
	assert_eq(_teile(spiel, &"cannon"), [], "Keine Kanone in der Pause.")
	assert_true(Vector2i(75, 72) in _teile(spiel, &"explosion"),
			"Die Explosion mittig über der Kanone, mit der Unterkante auf Zeile 77.")

	var block := _ausserirdische(spiel)
	for i in 59:
		var waehrenddessen := spiel.step(true, false, true)
		assert_eq(waehrenddessen, [] as Array[Dictionary],
				"Kein Takt, kein Schuss, keine Bombe in der Pause.")
		assert_eq(spiel.state, InvadersGame.State.RESPAWN,
				"Noch Pause nach %d Schritten." % (i + 1))
		assert_eq(_ausserirdische(spiel), block, "Der Block steht.")
		assert_eq(_teile(spiel, &"shot"), [])
		assert_eq(_teile(spiel, &"bomb"), [])

	spiel.step(false, false, false)
	assert_eq(spiel.state, InvadersGame.State.PLAYING, "Nach 60 Schritten (1 s) geht es weiter.")
	assert_eq(spiel.cannon_x, 75, "Die Kanone steht wieder in der Mitte.")
	assert_eq(_teile(spiel, &"cannon"), [Vector2i(75, 73)])


# --- Ende -----------------------------------------------------------------------------------------

func test_ende_gewonnen() -> void:
	var spiel := InvadersGame.new(SEED)
	var ereignisse: Array[Dictionary] = []
	for i in GRENZE:
		ereignisse = _spieler_schritt(spiel, true)
		if spiel.state == InvadersGame.State.WON or spiel.state == InvadersGame.State.LOST:
			break

	assert_eq(spiel.state, InvadersGame.State.WON)
	assert_eq(spiel.aliens_left(), 0)
	assert_eq(spiel.score, 640, "Alle Punkte: 8 · (30 + 20 + 20 + 10).")
	assert_eq(_arten(ereignisse).slice(-2),
			[InvadersGame.Event.ALIEN_HIT, InvadersGame.Event.WON])
	_pruefe_nach_dem_ende(spiel)


func test_ende_verloren_getroffen() -> void:
	var spiel := InvadersGame.new(SEED)
	var ereignisse: Array[Dictionary] = []
	for i in GRENZE:
		ereignisse = spiel.step(false, false, false)
		if spiel.state == InvadersGame.State.LOST:
			break

	assert_eq(spiel.state, InvadersGame.State.LOST)
	assert_eq(spiel.lost_reason, InvadersGame.LostReason.HIT,
			"Ohne Ausweichen trifft mit diesem Seed die dritte Bombe vor der Landung.")
	assert_eq(spiel.lives, 0)
	assert_eq(_arten(ereignisse), [InvadersGame.Event.CANNON_HIT, InvadersGame.Event.LOST])
	assert_eq(_teile(spiel, &"cannon"), [], "An der Stelle der Kanone die Explosion.")
	_pruefe_nach_dem_ende(spiel)


func test_ende_gelandet_genau_auf_der_zeile_der_kanone() -> void:
	var spiel := InvadersGame.new(SEED)
	var ereignisse: Array[Dictionary] = []
	var unten_vorher := 0
	for i in GRENZE:
		unten_vorher = _unterste_zeile(spiel)
		ereignisse = _spieler_schritt(spiel, false)
		if spiel.state == InvadersGame.State.LOST:
			break
		assert_lt(_unterste_zeile(spiel), 73, "Über der Kanone landet nichts.")

	assert_eq(spiel.state, InvadersGame.State.LOST)
	assert_eq(spiel.lost_reason, InvadersGame.LostReason.LANDED)
	assert_eq(_arten(ereignisse), [InvadersGame.Event.MARCH, InvadersGame.Event.LOST])
	assert_lt(unten_vorher, 73, "Vor dem letzten Takt lag die Unterkante über Zeile 73.")
	assert_gte(_unterste_zeile(spiel), 73, "Danach erreicht sie die oberste Zeile der Kanone.")
	_pruefe_nach_dem_ende(spiel)


# --- Gleichheit -----------------------------------------------------------------------------------

func test_gleicher_seed_und_gleiche_eingaben_ergeben_dieselbe_partie() -> void:
	var a := _ereignisfolge(SEED, 4000)
	var b := _ereignisfolge(SEED, 4000)
	var c := _ereignisfolge(SEED + 1, 4000)

	assert_gt(a.length(), 1000, "Die Folge ist nicht leer.")
	assert_eq(a, b, "Gleicher Seed, gleiche Eingaben: Zeichen für Zeichen dieselbe Folge.")
	assert_ne(a, c, "Ein anderer Seed wirft andere Bomben.")


func test_der_block_haengt_nicht_an_der_kanone() -> void:
	# Grundlage der Landungsmessung: Ob die Kanone steht oder ausweicht, ändert den Weg des Blocks
	# nicht, solange nichts trifft. Ein Treffer hält ihn nur an (RESPAWN).
	var steht := InvadersGame.new(SEED)
	var weicht_aus := InvadersGame.new(SEED)
	var verglichen := 0
	for i in GRENZE:
		var e1 := steht.step(false, false, false)
		var e2 := _spieler_schritt(weicht_aus, false)
		if InvadersGame.Event.CANNON_HIT in _arten(e1) + _arten(e2):
			break
		assert_eq(_ausserirdische(steht), _ausserirdische(weicht_aus))
		verglichen += 1
	assert_gt(verglichen, 500, "Verglichen bis zum ersten Treffer, mit diesem Seed 735 Schritte.")


# --- SC-002 ---------------------------------------------------------------------------------------

func test_sc002_gezielt_gewonnen_in_hoechstens_3_minuten() -> void:
	var gemessen: Array[int] = []
	for seed_nummer in SEEDS_SC002:
		var spiel := InvadersGame.new(seed_nummer)
		var schritte := 0
		while spiel.state != InvadersGame.State.WON and spiel.state != InvadersGame.State.LOST \
				and schritte < GRENZE:
			_spieler_schritt(spiel, true)
			schritte += 1
		assert_eq(spiel.state, InvadersGame.State.WON, "Seed %d gewinnt." % seed_nummer)
		assert_lte(schritte, SIEG_HOECHSTENS, "Seed %d: %d Schritte." % [seed_nummer, schritte])
		gemessen.append(schritte)
	gut.p("SC-002, Sieg in Schritten je Seed %s: %s" % [SEEDS_SC002, gemessen])


func test_sc002_ohne_schuss_gelandet_fruehestens_nach_1_minute() -> void:
	var gemessen: Array[int] = []
	var ohne_treffer: Array[int] = []
	for seed_nummer in SEEDS_SC002:
		var spiel := InvadersGame.new(seed_nummer)
		var schritte := 0
		var getroffen := false
		while spiel.state != InvadersGame.State.WON and spiel.state != InvadersGame.State.LOST \
				and schritte < GRENZE:
			var ereignisse := _spieler_schritt(spiel, false)
			getroffen = getroffen or InvadersGame.Event.CANNON_HIT in _arten(ereignisse)
			schritte += 1
		if spiel.lost_reason != InvadersGame.LostReason.LANDED:
			continue
		assert_gte(schritte, LANDUNG_FRUEHESTENS, "Seed %d: %d Schritte." % [seed_nummer, schritte])
		gemessen.append(schritte)
		if not getroffen:
			ohne_treffer.append(schritte)

	assert_false(ohne_treffer.is_empty(), "Mindestens ein Seed landet ohne Treffer.")
	for schritte in ohne_treffer:
		assert_eq(schritte, ohne_treffer[0], "Ohne Treffer landet der Block immer gleich spät.")
	gut.p("SC-002, Landung in Schritten: %s, davon ohne Treffer: %s" % [gemessen, ohne_treffer])


# --- Hilfen ---------------------------------------------------------------------------------------

## Testhilfe: Eine Partie, die vor jedem Wurf zählt, ob schon drei Bomben fallen und der Wurf
## gelingen würde. Sie greift dafür in den inneren Zustand (_bombs, _rng); der Kern bekommt dafür
## keine öffentliche API. Den Wurf sieht sie an einer Kopie des Zufallsgenerators mit gleichem Seed
## und Zustand voraus, so dass die Partie selbst unverändert weiterwürfelt.
class Beobachter extends InvadersGame:
	var voll_und_gewuerfelt := 0

	func _maybe_drop_bomb() -> void:
		var probe := RandomNumberGenerator.new()
		probe.seed = _rng.seed
		probe.state = _rng.state
		if _bombs.size() >= MAX_BOMBS and probe.randf() < BOMB_CHANCE:
			voll_und_gewuerfelt += 1
		super()


# --- Weitere Hilfen -------------------------------------------------------------------------------

## Ein Schritt des Testspielers. Er weicht jeder Bombe aus, die über der Kanone fällt. Mit
## [param zielen] fährt er sonst unter den waagrecht nächsten lebenden Außerirdischen, mit
## [param rechte_spalte] unter den am weitesten rechts, und schießt, sobald einer über ihm ist.
func _spieler_schritt(spiel: InvadersGame, zielen: bool,
		rechte_spalte: bool = false) -> Array[Dictionary]:
	var bomben := _teile(spiel, &"bomb")
	var richtung := _ausweichen(spiel.cannon_x, bomben)
	var schiessen := false
	if zielen and spiel.state == InvadersGame.State.PLAYING:
		var ausserirdische := _ausserirdische(spiel)
		var schuss_x := spiel.cannon_x + 4
		var ziel: Vector2i = ausserirdische[0]
		for a in ausserirdische:
			if rechte_spalte:
				if a.x > ziel.x:
					ziel = a
			elif absi(a.x + 3 - schuss_x) < absi(ziel.x + 3 - schuss_x):
				ziel = a
		for a in ausserirdische:
			if schuss_x >= a.x and schuss_x <= a.x + 7 and (not rechte_spalte or a.x == ziel.x):
				schiessen = true
		schiessen = schiessen and _teile(spiel, &"shot").is_empty()
		if richtung == 0:
			var wunsch := signi(ziel.x + 3 - schuss_x)
			if _sicher(spiel.cannon_x + wunsch, bomben):
				richtung = wunsch
	return spiel.step(richtung < 0, richtung > 0, schiessen)


## Richtung zum nächsten Platz, an dem keine Bombe über der Kanone fällt; 0, wenn sie dort schon
## steht.
func _ausweichen(kanone_x: int, bomben: Array[Vector2i]) -> int:
	if _sicher(kanone_x, bomben):
		return 0
	for weite in range(1, 160):
		for x in [kanone_x - weite, kanone_x + weite]:
			if x >= 2 and x <= 149 and _sicher(x, bomben):
				return signi(x - kanone_x)
	return 0


## Ob an [param kanone_x] keine Bombe über der Kanone liegt, mit 1 Bildpixel Luft zu jeder Seite.
func _sicher(kanone_x: int, bomben: Array[Vector2i]) -> bool:
	for b in bomben:
		if b.x + 1 >= kanone_x - 1 and b.x <= kanone_x + 9:
			return false
	return true


## Die Ereignisfolge einer Partie mit festen Eingaben, als Text: Fahren in Abschnitten von 40
## Schritten links, rechts, stehen; jeder 7. Schritt ein Druck auf die Leertaste.
func _ereignisfolge(seed_nummer: int, schritte: int) -> String:
	var spiel := InvadersGame.new(seed_nummer)
	var folge: Array = []
	for i in schritte:
		var abschnitt := floori(i / 40.0) % 3
		folge.append([i, spiel.step(abschnitt == 0, abschnitt == 1, i % 7 == 0)])
	return var_to_str(folge)


func _pruefe_nach_dem_ende(spiel: InvadersGame) -> void:
	var vorher := _abbild(spiel)
	for i in 120:
		assert_eq(spiel.step(i % 2 == 0, i % 3 == 0, true), [] as Array[Dictionary],
				"Nach dem Ende keine Ereignisse mehr.")
	assert_eq(_abbild(spiel), vorher, "Nach dem Ende ändert step() nichts.")


func _abbild(spiel: InvadersGame) -> String:
	return var_to_str([spiel.state, spiel.lost_reason, spiel.score, spiel.lives, spiel.cannon_x,
			spiel.march_frame, spiel.aliens_left(), spiel.drawables()])


func _arten(ereignisse: Array[Dictionary]) -> Array:
	return ereignisse.map(func(e: Dictionary) -> InvadersGame.Event: return e["event"])


## Die Lagen aller Teile mit dem Muster [param sprite], in der Reihenfolge von drawables().
func _teile(spiel: InvadersGame, sprite: StringName) -> Array[Vector2i]:
	var lagen: Array[Vector2i] = []
	for teil in spiel.drawables():
		if teil["sprite"] == sprite:
			lagen.append(teil["pos"])
	return lagen


## Die Lagen der lebenden Außerirdischen, zeilenweise von oben links.
func _ausserirdische(spiel: InvadersGame) -> Array[Vector2i]:
	var lagen: Array[Vector2i] = []
	for teil in spiel.drawables():
		if String(teil["sprite"]).begins_with("alien"):
			lagen.append(teil["pos"])
	return lagen


## Je Spalte der unterste lebende Außerirdische.
func _unterste_je_spalte(spiel: InvadersGame) -> Array[Vector2i]:
	var je_spalte := {}
	for a in _ausserirdische(spiel):
		if not je_spalte.has(a.x) or je_spalte[a.x].y < a.y:
			je_spalte[a.x] = a
	var unterste: Array[Vector2i] = []
	unterste.assign(je_spalte.values())
	return unterste


## Unterste Zeile eines lebenden Außerirdischen, einschließlich.
func _unterste_zeile(spiel: InvadersGame) -> int:
	var unten := -1
	for a in _ausserirdische(spiel):
		unten = maxi(unten, a.y + 5)
	return unten


func _linke_kante(lagen: Array[Vector2i]) -> int:
	var links := 999
	for a in lagen:
		links = mini(links, a.x)
	return links


func _rechte_kante(lagen: Array[Vector2i]) -> int:
	var rechts := -1
	for a in lagen:
		rechts = maxi(rechts, a.x + 7)
	return rechts
