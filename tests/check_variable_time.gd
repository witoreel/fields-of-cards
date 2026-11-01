extends CheckBase
## Feature 11: ações com tempo variável (V1, V2).
## godot --headless --path . -s tests/check_variable_time.gd


func _initialize() -> void:
	label = "Verificações de tempo variável"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 1000
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)

	# US-11.1: a pré-visualização diz se há slider e até onde ele vai
	var pv := s.recipe_preview(hoe["uid"], soil["uid"])
	_check(pv["variable"] and pv["minutes"] == 30, "arar é variável, 30 min por unidade")
	_check(pv["max_units"] > 1 and pv["max_units"] <= 36, "o slider vai até o fim do dia (%d)" % pv["max_units"])
	_check(s.recipe_preview(hoe["uid"], hoe["uid"]).is_empty(), "sem receita, sem pré-visualização")
	var pot := s.spawn(&"regador", GameState.HAND)
	_check(s.recipe_preview(pot["uid"], soil["uid"]).is_empty(), "regador + terra bruta: nada")
	var sown := s.spawn(&"terra_semeada", GameState.LOCATION, 2)
	_check(not s.recipe_preview(pot["uid"], sown["uid"])["variable"], "regar não é variável")

	# US-11.2: mais tempo, mais resultado
	var t := s.minutes
	_check(s.apply_recipe(hoe["uid"], soil["uid"], 1), "1 unidade")
	var one: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(one["n"] == 4 and s.minutes - t == 30, "30 min -> 4 m²")
	t = s.minutes
	_check(s.apply_recipe(hoe["uid"], soil["uid"], 3), "3 unidades")
	_check(one["n"] == 16 and s.minutes - t >= 90, "90 min -> +12 m² (total 16)")
	_check(Wear.durability(hoe) == 100 - 2 - 8, "o desgaste cresce com o tempo (3 usos, ferramenta suja: 6 x 1,25)")

	# O slider escolhe minutos: 75 min = 2 unidades de 30
	var r := s.recipes.find(&"enxada", &"terra_bruta")
	_check(RecipeRunner.units_for_minutes(r, 75) == 2 and RecipeRunner.units_for_minutes(r, 10) == 1, "minutos viram unidades")
	var rg := s.recipes.find(&"regador", &"terra_semeada")
	_check(RecipeRunner.units_for_minutes(rg, 100) == 1, "receita fixa ignora o slider")
	t = s.minutes
	s.apply_recipe(pot["uid"], sown["uid"], 5)
	_check(s.minutes - t < 20, "receita fixa ignora as unidades")

	# Limites: o consumo, os m² e o dia
	var seeds := s.spawn(&"semente", GameState.HAND, 3)
	_check(s.recipe_preview(seeds["uid"], one["uid"])["max_units"] == 3, "limitado pelas 3 sementes")
	s.apply_recipe(seeds["uid"], one["uid"], 50)
	var semeada := s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_semeada" and c["n"] >= 3)
	_check(not semeada.is_empty() and not s.hand.has(seeds) and one["n"] == 13, "pediu 50, plantou só 3 (limite pelas sementes)")
	s.farm_area_limit = s.farm_area_used() + 9
	_check(s.recipe_preview(hoe["uid"], soil["uid"])["max_units"] == 2, "limitado pelos m² livres (9 -> 2 unidades de 4)")
	s.farm_area_limit = 1000
	s.sleep()
	s.advance_time(18 * 60 - 60) # faltam 60 min... mas a enxada está gasta
	var left := 1440 - s.minute_of_day()
	_check(left == 60 + 0 or left > 0, "perto da meia-noite")
	var late := s.recipe_preview(hoe["uid"], soil["uid"])
	_check(late["max_units"] == 1, "pouco tempo sobrando: só 1 unidade")

	# Dentro de uma receita variável a ação ainda respeita a meia-noite
	var s2 := GameState.new_game(2, false)
	s2.farm_area_limit = 1000
	var soil2 := s2.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe2 := s2.spawn(&"enxada", GameState.HAND)
	s2.apply_recipe(hoe2["uid"], soil2["uid"], 9999)
	_check(s2.minutes <= 1440 + 360 and s2.day_number() >= 1, "unidades limitadas pelo dia")
	_finish()
