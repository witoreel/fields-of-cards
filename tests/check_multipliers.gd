extends CheckBase
## Feature 12: multiplicadores (V3, V4, V5, R8, E2, E3, K1-K3).
## godot --headless --path . -s tests/check_multipliers.gd


func _initialize() -> void:
	label = "Verificações de multiplicadores"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 100000
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)

	# Base: 4 m² por unidade, multiplicador 1
	_check(Multipliers.total(s, hoe, &"lavoura") == 1.0, "multiplicador base 1,0")
	s.apply_recipe(hoe["uid"], soil["uid"])
	var plowed: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(plowed["n"] == 4, "4 m² sem multiplicador")

	# US-12.1: ferramenta de qualidade maior rende mais no mesmo tempo
	var good := CardDef.new()
	good.id = &"enxada_boa"
	good.display_name = "Enxada boa"
	good.props = PackedStringArray(["tool", "movable"])
	good.extra = {"quality": 1.5}
	s.catalog.add(good)
	var hoe2 := s.spawn(&"enxada_boa", GameState.HAND)
	s.recipes.recipes.append(s.recipes.find(&"enxada", &"terra_bruta").duplicate())
	s.recipes.recipes[-1].a = &"enxada_boa"
	var t := s.minutes
	s.apply_recipe(hoe2["uid"], soil["uid"])
	_check(plowed["n"] == 4 + 6 and s.minutes - t == 30, "qualidade 1,5: 6 m² em 30 min (total 10)")
	s.recipes.recipes.pop_back()

	# US-12.2: skill, com retorno decrescente (K3)
	_check(s.skills.get("lavoura", 0) == 2, "arar deu pontos de skill")
	var lvl_low := Multipliers.skill_level(s, &"lavoura")
	s.add_skill(&"lavoura", 100)
	var lvl_mid := Multipliers.skill_level(s, &"lavoura")
	s.add_skill(&"lavoura", 100)
	var lvl_high := Multipliers.skill_level(s, &"lavoura")
	_check(lvl_low < lvl_mid and lvl_mid < lvl_high and lvl_high < 1.0, "mais skill, mais nível, nunca chega a 1")
	_check(lvl_mid - lvl_low > lvl_high - lvl_mid, "ganho decrescente: o segundo bloco de 100 vale menos")
	_check(absf(Multipliers.skill_level(s, &"inexistente")) < 0.0001, "sem pontos, nível 0")
	_check(Multipliers.skill_multiplier(s, &"lavoura") > 1.5, "skill alta passa de 1,5x")
	var before: int = plowed["n"]
	s.apply_recipe(hoe["uid"], soil["uid"])
	_check(plowed["n"] - before >= 7, "com skill alta arar rende mais que 4 (+%d)" % (plowed["n"] - before))

	# US-12.3 / 12.4: construção dá multiplicador para tudo que se faz dentro dela
	var w := GameState.new_game(2, false)
	w.farm_area_limit = 1000
	var site := w.spawn(&"construcao", GameState.LOCATION)
	_check(w.farm_area_used() == 10, "a construção ocupa 10 m²")
	var new_id := w.build_location(site["uid"], "Roça do Fundo")
	_check(new_id != &"" and w.has_location(new_id) and w.location_name(new_id) == "Roça do Fundo", "construiu a roça com nome")
	_check(w.parent_of(new_id) == &"fazenda" and not w.cards_at(&"fazenda").has(site), "dentro da fazenda; carta consumida")
	_check(w.farm_area_used() == 10, "os m² passam da carta para o local")
	_check(Multipliers.location_multiplier(w, new_id) == 1.25, "roça nova: 1,25")
	_check(w.build_location(site["uid"], "x") == &"", "a carta já foi usada")
	w.travel_to(new_id)
	var s2 := w.spawn(&"terra_bruta", GameState.LOCATION)
	var h := w.spawn(&"enxada", GameState.HAND)
	w.apply_recipe(h["uid"], s2["uid"])
	var got: Dictionary = w.cards_at(new_id).filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(got["n"] == 5, "4 m² x 1,25 = 5 dentro da roça nova")
	w.travel_to(&"fazenda")
	var s3 := w.spawn(&"terra_bruta", GameState.LOCATION)
	w.apply_recipe(h["uid"], s3["uid"])
	_check(w.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]["n"] == 4, "fora da roça nova, 4")
	_check(w.build_location(w.spawn(&"enxada", GameState.LOCATION)["uid"], "Nada") == &"", "só construções constroem")

	# Roça inicial (R8): existe, multiplicador 1
	var g := GameState.new_game(3)
	_check(g.has_location(&"roca") and Multipliers.location_multiplier(g, &"roca") == 0.5, "a roça inicial está danificada: 1,0 x 0,5 (S4)")

	# US-12.5 / 12.6: canais de venda
	var m := GameState.new_game(4, false)
	var crop := m.spawn(&"colheita", GameState.LOCATION, 10)
	var box := m.spawn(&"caixa_venda", GameState.LOCATION)
	m.sell(crop["uid"], box["uid"])
	_check(m.money() == 80, "caixa na fazenda: 10 x 10 x 0,8 = 80")
	m.travel_to(&"cidade")
	m.travel_to(&"feira")
	var crop2 := m.spawn(&"colheita", GameState.LOCATION, 10)
	var stall := m.spawn(&"banca_feira", GameState.LOCATION)
	m.sell(crop2["uid"], stall["uid"])
	_check(m.money() == 80 + 130, "feira: 10 x 10 x 1,3 = 130 (maior que a caixa)")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.skills["lavoura"] == s.skills["lavoura"], "skill sobrevive ao save")
	var rw := GameState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	_check(Multipliers.location_multiplier(rw, new_id) == 1.25, "multiplicador sobrevive ao save")
	_finish()
