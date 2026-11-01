extends CheckBase
## Feature 24: construções (B1 a B12, S4, V5).
## godot --headless --path . -s tests/check_buildings.gd


func _initialize() -> void:
	label = "Verificações de construções"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 40
	s.spawn(&"dinheiro", GameState.HAND, 2000)
	s.spawn(&"madeira", GameState.HAND, 20)

	# US-24.1 / B2: o profissional entrega qualidade mediana, por dinheiro
	var m0 := s.money()
	var pro := s.build(&"galinheiro", "Galinheiro do Zé", true)
	_check(pro != &"" and s.money() == m0 - 300, "contratou: 300")
	_check(Buildings.info(s, pro)["quality"] == 1.0 and Buildings.info(s, pro)["built_by"] == "profissional", "qualidade mediana (1,0)")
	_check(s.minutes == 360, "o profissional não gasta tempo do jogador")
	_check(s.location_name(pro) == "Galinheiro do Zé" and s.parent_of(pro) == &"fazenda", "local com nome, na fazenda (L6)")

	# US-24.3 / B4: m² dentro = fora; limite da fazenda vale
	_check(s.farm_area_used() == 6, "galinheiro de 6 m² ocupa 6 m²")
	_check(Multipliers.location_multiplier(s, pro) == 1.0, "multiplicador = base x qualidade")
	var poor := GameState.new_game(9, false)
	poor.farm_area_limit = 5
	poor.spawn(&"dinheiro", GameState.HAND, 2000)
	_check(poor.build(&"galinheiro", "Grande demais", true) == &"" and poor.money() == 2000, "não cabe na fazenda: recusa sem cobrar")
	_check(s.build(&"galinheiro", "", true) == &"" and s.build(&"castelo", "x", true) == &"", "sem nome ou tipo desconhecido")

	# US-24.2 / B3: o jogador começa com qualidade ruim e melhora
	var q0 := Buildings.player_quality(s)
	_check(absf(q0 - 0.6) < 0.0001, "começa em 0,6")
	var t := s.minutes
	var mine := s.build(&"shed", "Shed do jogador", false)
	_check(mine != &"" and s.minutes - t == 240, "construir levou 240 min")
	_check(Buildings.info(s, mine)["quality"] == q0 and Multipliers.location_multiplier(s, mine) < Multipliers.location_multiplier(s, pro), "obra do jogador rende menos que a do profissional")
	var wood_left := 0
	for c in s.hand:
		if c["id"] == "madeira":
			wood_left += c["n"]
	_check(wood_left == 14, "gastou 6 madeiras")
	_check(s.skills["construcao"] == 10 and Buildings.player_quality(s) > q0, "a skill de construção subiu")
	s.add_skill(&"construcao", 400)
	_check(Buildings.player_quality(s) > 1.3, "com muita prática passa do profissional (%.2f)" % Buildings.player_quality(s))
	var broke := GameState.new_game(8, false)
	_check(broke.build(&"shed", "Sem madeira", false) == &"" and broke.build(&"shed", "Sem dinheiro", true) == &"", "sem madeira ou dinheiro não constrói")

	# US-24.4 / 24.5: durabilidade, dano e reparo
	_check(Buildings.info(s, pro)["durability"] == 100 and not s.is_damaged(pro), "nova: 100, sem dano")
	for i in 20:
		s.sleep()
	_check(Buildings.info(s, pro)["durability"] == 60 and not s.is_damaged(pro), "20 dias: 60")
	var normal := Multipliers.location_multiplier(s, pro)
	for i in 6:
		s.sleep()
	_check(Buildings.info(s, pro)["durability"] == 48 and s.is_damaged(pro), "abaixo de 50 fica danificada")
	_check(Multipliers.location_multiplier(s, pro) == normal * 0.5, "a danificada rende metade (B6, S4)")
	_check(not s.repair_location(pro), "sem martelo não conserta")
	s.spawn(&"martelo", GameState.HAND)
	t = s.minutes
	_check(s.repair_location(pro) and Buildings.info(s, pro)["durability"] == 100 and not s.is_damaged(pro), "conserto restaura")
	_check(s.minutes - t >= 60, "conserto leva tempo")
	_check(not s.repair_location(pro), "inteira não precisa de conserto")

	# I2: a roça inicial danificada pode ser consertada
	var g := GameState.new_game(5)
	_check(g.is_damaged(&"roca") and Buildings.info(g, &"roca")["durability"] == 40, "roça inicial: durabilidade 40, danificada")
	g.spawn(&"madeira", GameState.HAND, 2)
	g.spawn(&"martelo", GameState.HAND)
	_check(g.repair_location(&"roca") and not g.is_damaged(&"roca"), "consertar a roça inicial")
	_check(Multipliers.location_multiplier(g, &"roca") == 1.0, "e ela volta a render 1,0")

	# US-24.6 / B7: poucos níveis, com capacidade
	_check(Buildings.capacity(s, pro) == 6, "galinheiro nível 1: 6 galinhas")
	_check(s.upgrade_location(pro) and Buildings.capacity(s, pro) == 12, "nível 2: 12")
	_check(s.upgrade_location(pro) and Buildings.capacity(s, pro) == 20, "nível 3: 20")
	_check(not s.upgrade_location(pro), "só há 3 níveis")
	_check(Multipliers.location_multiplier(s, pro) > 1.0, "nível alto rende mais")

	# US-24.7 / B10: armários e barris
	var w := GameState.new_game(3, false)
	var closet := w.spawn(&"armario", GameState.LOCATION)
	_check(w.farm_area_used() == 1, "armário: 1 m²")
	w.select_card(closet["uid"])
	_check(w.area_limit(GameState.STORAGE) == 100000, "armário: 100 kg")
	w.select_card(closet["uid"])
	var better := w.spawn(&"armario_reforcado", GameState.LOCATION)
	w.select_card(better["uid"])
	_check(w.area_limit(GameState.STORAGE) == 200000, "armário melhor aguenta mais")
	w.select_card(better["uid"])

	# US-24.8 / B11: conserva vale mais que os itens crus
	var barrel := w.spawn(&"barril", GameState.LOCATION)
	var crops := w.spawn(&"colheita", GameState.HAND, 3)
	_check(w.apply_recipe(crops["uid"], barrel["uid"]), "conservar")
	var jar: Dictionary = w.stages["fazenda"].filter(func(c: Dictionary) -> bool: return c["id"] == "conserva")[0]
	var cat := w.catalog
	_check(cat.get_def(&"conserva").extra["sell_value"] > 3 * cat.get_def(&"colheita").extra["sell_value"], "conserva vale mais que 3 colheitas")
	_check(jar["n"] == 1 and not w.hand.has(crops), "3 colheitas viraram 1 conserva")

	# US-24.9 / B8: máquina dentro de uma construção é só uma carta no local dela
	var tool_card := s.spawn(&"machado", GameState.HAND)
	s.travel_to(mine)
	_check(s.move_card(tool_card["uid"], GameState.LOCATION), "uma carta pode ficar dentro da construção")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(Buildings.info(r, pro)["level"] == 3 and r.location_name(pro) == "Galinheiro do Zé", "construções sobrevivem ao save")
	_finish()
