extends CheckBase
## Feature 6: área da fazenda (L7, N1, N2, N3).
## godot --headless --path . -s tests/check_farm_area.gd


func _initialize() -> void:
	label = "Verificações da área da fazenda"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 10

	# US-6.2: terra bruta não ocupa m² e não se esgota
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)
	_check(s.farm_area_used() == 0, "terra bruta não conta")
	_check(s.card_area(soil) == 0 and s.card_area(hoe) == 0, "cartas sem m²")

	# US-6.3: terra arada ocupa m²; o contador é a quantidade
	_check(s.apply_recipe(hoe["uid"], soil["uid"]), "arar 4 m²")
	_check(s.farm_area_used() == 4 and s.farm_area_free() == 6, "4 usados, 6 livres")
	s.apply_recipe(hoe["uid"], soil["uid"])
	_check(s.farm_area_used() == 8, "8 m²")

	# US-6.1: o limite vale; recusa sem gastar tempo
	var t := s.minutes
	_check(not s.apply_recipe(hoe["uid"], soil["uid"]), "mais 4 m² passaria de 10: recusa")
	_check(s.farm_area_used() == 8 and s.minutes == t, "nada mudou")
	_check(s.cards_at(&"fazenda").has(soil), "terra bruta continua lá (infinita)")

	# Semear e colher não mudam o total (m² trocam de estágio)
	var plowed: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	var seed_c := s.spawn(&"semente", GameState.HAND, 2)
	_check(s.apply_recipe(seed_c["uid"], plowed["uid"]), "semear com a fazenda quase cheia")
	_check(s.farm_area_used() == 8, "semear mantém 8 m²")

	# Soma entre todos os locais da fazenda (casa, roças)
	_check(s.add_location(&"roca_2", "Roça 2", &"fazenda"), "nova roça")
	s.travel_to(&"roca_2")
	s.spawn(&"terra_arada", GameState.LOCATION, 2)
	_check(s.farm_area_used() == 10, "soma os locais da fazenda (10)")
	var soil2 := s.spawn(&"terra_bruta", GameState.LOCATION)
	_check(not s.apply_recipe(hoe["uid"], soil2["uid"]), "limite é global, vale na outra roça")

	# Fora da fazenda o limite não vale
	s.travel_to(&"floresta")
	var soil3 := s.spawn(&"terra_bruta", GameState.LOCATION)
	_check(s.apply_recipe(hoe["uid"], soil3["uid"]), "na floresta não há limite de fazenda")
	_check(s.farm_area_used() == 10, "terra da floresta não conta na fazenda")

	# US-6.4: árvore não se esgota
	var tree := s.spawn(&"arvore", GameState.LOCATION)
	var axe := s.spawn(&"machado", GameState.HAND)
	for i in 5:
		s.apply_recipe(axe["uid"], tree["uid"])
	_check(s.cards_at(&"floresta").has(tree) and tree["n"] == 1, "árvore intacta após 5 cortes")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.farm_area_limit == 10 and r.farm_area_used() == 10, "limite e uso sobrevivem ao save")
	_finish()
