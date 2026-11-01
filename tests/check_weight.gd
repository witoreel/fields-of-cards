extends CheckBase
## Feature 5: peso e capacidade (P1, P2, P3, P5).
## godot --headless --path . -s tests/check_weight.gd


func _initialize() -> void:
	label = "Verificações de peso"
	var s := GameState.new_game(1, false)

	# US-5.1: peso unitário × quantidade; dinheiro e locais sem peso
	var seeds := s.spawn(&"semente", GameState.LOCATION, 10)
	_check(s.card_weight(seeds) == 50, "10 sementes de 5 g = 50 g")
	var hoe := s.spawn(&"enxada", GameState.LOCATION)
	_check(s.card_weight(hoe) == 1200, "enxada 1200 g")
	_check(s.card_weight(s.spawn(&"terra_bruta", GameState.LOCATION)) == 0, "terra bruta sem peso")

	# US-5.2: limite da mochila
	_check(s.area_limit(GameState.BACKPACK) == 20000, "limite da mochila vem da definição")
	s.select_card(s.hand[0]["uid"])
	_check(s.move_card(hoe["uid"], GameState.BACKPACK), "cabe")
	_check(s.area_weight(GameState.BACKPACK) == 1200, "peso carregado")
	var log_c := s.spawn(&"madeira", GameState.LOCATION, 10) # 20000
	_check(not s.move_card(log_c["uid"], GameState.BACKPACK), "passaria de 20000 g: recusa")
	_check(s.cards_at(&"fazenda").has(log_c) and s.area_weight(GameState.BACKPACK) == 1200, "nada mudou")
	log_c["n"] = 8 # 16000 + 1200 = 17200
	_check(s.move_card(log_c["uid"], GameState.BACKPACK), "agora cabe")
	_check(s.area_weight(GameState.BACKPACK) == 17200, "17200 g")

	# US-5.3: storage com limite e peso aninhado
	var box := s.spawn(&"bau", GameState.LOCATION)
	_check(s.area_limit(GameState.STORAGE) == 0, "sem storage aberto, sem limite")
	s.select_card(box["uid"])
	_check(s.area_limit(GameState.STORAGE) == 50000, "limite do baú")
	s.travel_to(&"floresta")
	s.travel_to(&"fazenda")
	s.select_card(box["uid"])
	var heavy := s.spawn(&"madeira", GameState.STAGE, 25) # 50000
	_check(s.move_card(heavy["uid"], GameState.STORAGE), "cabe exatamente no limite")
	var one := s.spawn(&"semente", GameState.STAGE)
	_check(not s.move_card(one["uid"], GameState.STORAGE), "um grama a mais não cabe")
	s.select_card(box["uid"]) # fecha
	_check(s.card_weight(box) == 5000 + 50000, "o baú pesa ele mais o conteúdo")
	_check(not s.move_card(box["uid"], GameState.BACKPACK), "baú cheio não cabe na mochila")

	# US-5.4 / P5: regador com volume
	var pot := s.spawn(&"regador", GameState.HAND)
	_check(s.volume_of(pot) == 2000, "regador novo está cheio")
	var plant := s.spawn(&"terra_semeada", GameState.LOCATION, 4) # 4 m² × 50 g = 200 g
	_check(s.apply_recipe(pot["uid"], plant["uid"]), "regar")
	_check(s.volume_of(pot) == 1800, "gastou 200 g")
	for i in 9:
		s.remove_status(plant, "regada"); s.remove_status(plant, "encharcada")
		s.apply_recipe(pot["uid"], plant["uid"])
	_check(s.volume_of(pot) == 0, "esvaziou depois de 10 regas")
	s.remove_status(plant, "regada"); s.remove_status(plant, "encharcada")
	_check(not s.apply_recipe(pot["uid"], plant["uid"]), "sem volume não rega")
	_check(not s.has_status(plant, "regada"), "a planta não foi regada")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	var rp: Dictionary = r.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "regador")[0]
	_check(r.volume_of(rp) == 0, "volume sobrevive ao save")
	_finish()
