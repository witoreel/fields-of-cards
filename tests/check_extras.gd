extends CheckBase
## Feature 29: ervas daninhas e açude (O1, O2).
## godot --headless --path . -s tests/check_extras.gd


func _count(list: Array, id: String) -> int:
	var n := 0
	for c in list:
		if c["id"] == id:
			n += int(c["n"])
	return n


func _initialize() -> void:
	label = "Verificações de ervas e açude"

	# US-29.1: ervas nascem em terra trabalhada, com RNG de seed
	var s := GameState.new_game(11, false)
	s.pests_enabled = true
	s.farm_area_limit = 1000
	_check(Pests.weeds_at(s, &"fazenda") == 0, "sem erva no começo")
	for i in 5:
		s.sleep()
	_check(Pests.weeds_at(s, &"fazenda") == 0, "terra bruta ou vazia não cria erva")
	s.spawn(&"terra_arada", GameState.LOCATION, 4)
	for i in 30:
		s.sleep()
	var weeds := Pests.weeds_at(s, &"fazenda")
	_check(weeds > 0, "em 30 noites com terra arada nasceram ervas (%d m²)" % weeds)
	_check(s.farm_area_used() == 4 + weeds, "as ervas ocupam m² da fazenda")
	var s2 := GameState.new_game(11, false)
	s2.pests_enabled = true
	s2.farm_area_limit = 1000
	for i in 5:
		s2.sleep()
	s2.spawn(&"terra_arada", GameState.LOCATION, 4)
	for i in 30:
		s2.sleep()
	_check(Pests.weeds_at(s2, &"fazenda") == weeds, "mesma seed, mesmas ervas")

	# Erva para o plantio
	var g := GameState.new_game(1, false)
	g.farm_area_limit = 1000
	var plot := g.spawn(&"terra_semeada", GameState.LOCATION, 3)
	var pot := g.spawn(&"regador", GameState.HAND)
	g.spawn(&"erva_daninha", GameState.LOCATION, 3)
	g.apply_recipe(pot["uid"], plot["uid"])
	g.sleep()
	_check(plot["id"] == "terra_semeada", "com erva no local o plantio não cresce")

	# Foice rende feno; ancinho não; limpar libera o plantio
	var weed: Dictionary = g.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "erva_daninha")[0]
	var sickle := g.spawn(&"foice", GameState.HAND)
	var rake := g.spawn(&"ancinho", GameState.HAND)
	_check(g.apply_recipe(sickle["uid"], weed["uid"]), "foice")
	_check(_count(g.stages["fazenda"], "feno") >= 1 and weed["n"] == 2, "foice tira 1 m² e dá feno")
	_check(g.apply_recipe(rake["uid"], weed["uid"], 2), "ancinho, 2 unidades")
	_check(not g.cards_at(&"fazenda").has(weed) and Pests.weeds_at(g, &"fazenda") == 0, "terreno limpo")
	_check(_count(g.stages["fazenda"], "feno") == 1, "ancinho não dá feno")
	g.apply_recipe(pot["uid"], plot["uid"])
	g.sleep()
	_check(plot["id"] == "terra_broto", "sem erva, o plantio volta a crescer")

	# US-29.2: açude e peixes
	var w := GameState.new_game(2, false)
	w.farm_area_limit = 1000
	w.spawn(&"dinheiro", GameState.HAND, 1000)
	var lake := w.build(&"acude", "Açude da Roça", true)
	_check(lake != &"" and w.farm_area_used() == 20, "açude de 20 m²")
	w.travel_to(lake)
	var fry := w.spawn(&"peixe_filhote", GameState.LOCATION)
	_check(w.cards_at(lake).has(fry), "alevino no açude")
	for i in 3:
		var feed := w.spawn(&"racao_crescimento", GameState.HAND)
		w.apply_recipe(feed["uid"], fry["uid"])
		w.sleep()
	_check(fry["id"] == "peixe", "o alevino cresceu e virou peixe")
	_check(_count(w.cards_at(lake), "esterco") == 0, "peixe não suja")
	var rod := w.spawn(&"vara_pesca", GameState.HAND)
	var t := w.minutes
	_check(w.apply_recipe(rod["uid"], fry["uid"]) and w.minutes - t >= 30, "pescar leva tempo")
	_check(_count(w.stages[String(lake)], "peixe_cru") == 2 and not w.cards_at(lake).has(fry), "pescou o peixe: 2 de peixe cru")
	_check(w.skills.get("pesca", 0) == 1, "pescar dá skill de pesca")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	_check(r.has_location(lake), "açude sobrevive ao save")
	_finish()
