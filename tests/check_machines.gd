extends CheckBase
## Feature 28: maquinário (X1 a X8, Q9).
## godot --headless --path . -s tests/check_machines.gd


func _count(list: Array, id: String) -> int:
	var n := 0
	for c in list:
		if c["id"] == id:
			n += int(c["n"])
	return n


func _fuel(s: GameState, machine: Dictionary, amount: int) -> void:
	var f := s.spawn(&"combustivel", GameState.HAND, (amount + 9) / 10)
	for i in (amount + 9) / 10:
		s.apply_recipe(f["uid"], machine["uid"])


func _initialize() -> void:
	label = "Verificações de maquinário"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 100000
	s.travel_to(&"floresta")

	# US-28.2: as máquinas existem como cartas de dados
	for id in ["motosserra", "esmeril", "lavadora", "trator", "colheitadeira", "serra_circular", "bomba_dagua", "irrigacao", "alimentador", "bebedouro", "chocadeira", "moinho", "prensa", "gerador"]:
		_check(s.catalog.has_def(StringName(id)), "carta de máquina: " + id)

	# US-28.1 / X1: a máquina é uma ferramenta melhor que gasta combustível
	var tree := s.spawn(&"arvore", GameState.LOCATION)
	var saw := s.spawn(&"motosserra", GameState.HAND)
	_check(s.has_prop(saw, &"tool") and s.has_prop(saw, &"machine"), "motosserra é ferramenta e máquina")
	var t := s.minutes
	_check(not s.apply_recipe(saw["uid"], tree["uid"]), "sem combustível não funciona")
	_check(s.minutes == t and _count(s.stages["floresta"], "madeira") == 0, "e nada muda")
	_fuel(s, saw, 10)
	_check(Vehicles.fuel_of(saw) == 10, "abastecida com 10")
	t = s.minutes
	_check(s.apply_recipe(saw["uid"], tree["uid"]), "cortar com a motosserra")
	_check(Vehicles.fuel_of(saw) == 8, "gastou 2 de combustível")
	_check(s.minutes - t == 12, "30 min x 0,4 = 12 min (mais rápida que o machado)")
	_check(_count(s.stages["floresta"], "madeira") == 2, "qualidade 2,0: 2 madeiras em vez de 1")
	# tempo variável respeita o combustível (X1 + V1)
	_check(s.recipe_preview(saw["uid"], tree["uid"])["max_units"] == 4, "combustível 8 / 2 = 4 unidades no slider")
	s.apply_recipe(saw["uid"], tree["uid"], 100)
	_check(Vehicles.fuel_of(saw) == 0, "pediu 100 e gastou os 8 que tinha (4 unidades)")
	_check(not s.apply_recipe(saw["uid"], tree["uid"]), "tanque vazio de novo")

	# X8: esmeril afia, lavadora limpa
	var axe := s.spawn(&"machado", GameState.HAND)
	axe["state"] = {"edge": 10}
	var grinder := s.spawn(&"esmeril", GameState.HAND)
	_check(not s.apply_recipe(grinder["uid"], axe["uid"]), "esmeril sem combustível")
	_fuel(s, grinder, 10)
	t = s.minutes
	_check(s.apply_recipe(grinder["uid"], axe["uid"]) and Wear.edge(axe) == 100 and s.minutes - t <= 3, "esmeril afia em instantes")
	var washer := s.spawn(&"lavadora", GameState.HAND)
	_fuel(s, washer, 10)
	s.add_status(axe, "sujo")
	s.add_status(axe, "enferrujada")
	_check(s.apply_recipe(washer["uid"], axe["uid"]) and s.statuses_of(axe).is_empty(), "lavadora limpa sujeira e ferrugem")

	# X8: trator ara muito mais por tempo
	var farm := GameState.new_game(2, false)
	farm.farm_area_limit = 100000
	var soil := farm.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := farm.spawn(&"enxada", GameState.HAND)
	var tractor := farm.spawn(&"trator", GameState.LOCATION)
	t = farm.minutes
	farm.apply_recipe(hoe["uid"], soil["uid"])
	var by_hand := _count(farm.cards_at(&"fazenda"), "terra_arada")
	var hand_time := farm.minutes - t
	_fuel(farm, tractor, 30)
	t = farm.minutes
	farm.apply_recipe(tractor["uid"], soil["uid"])
	var by_tractor := _count(farm.cards_at(&"fazenda"), "terra_arada") - by_hand
	_check(by_tractor >= 3 * by_hand and farm.minutes - t < hand_time, "trator: %d m² em %d min contra %d m² em %d min à mão" % [by_tractor, farm.minutes - t, by_hand, hand_time])
	var combine := farm.spawn(&"colheitadeira", GameState.LOCATION)
	farm.spawn(&"terra_pronta", GameState.LOCATION, 4)
	_fuel(farm, combine, 10)
	var ready: Dictionary = farm.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_pronta")[0]
	_check(farm.apply_recipe(combine["uid"], ready["uid"], 4) and _count(farm.stages["fazenda"], "colheita") >= 4 * 2, "colheitadeira colhe os 4 m² com qualidade 2,5")

	# X8 / X7: bomba d'água liga o poço à irrigação
	var w := GameState.new_game(3, false)
	w.farm_area_limit = 100000
	w.spawn(&"dinheiro", GameState.HAND, 5000)
	w.spawn(&"terra_semeada", GameState.LOCATION, 8)
	w.spawn(&"irrigacao", GameState.LOCATION)
	var pump := w.spawn(&"bomba_dagua", GameState.LOCATION)
	_fuel(w, pump, 10)
	w.sleep()
	_check(_count(w.cards_at(&"fazenda"), "terra_semeada") == 8, "sem poço, a irrigação não funciona")
	w.spawn(&"madeira", GameState.HAND, 10)
	_check(w.build(&"poco", "Poço velho", false) != &"", "constrói o poço")
	w.sleep()
	_check(_count(w.cards_at(&"fazenda"), "terra_broto") == 8, "com poço, bomba e irrigação, o plantio é regado e cresce")
	_check(Vehicles.fuel_of(pump) == 8, "a bomba gastou 2 de combustível na noite em que irrigou (10 - 2)")
	w.spawn(&"terra_semeada", GameState.LOCATION, 30)
	w.sleep()
	var watered := _count(w.cards_at(&"fazenda"), "terra_pronta") + _count(w.cards_at(&"fazenda"), "terra_broto")
	_check(watered == 20 and _count(w.cards_at(&"fazenda"), "terra_semeada") == 18, "a irrigação alcança só 20 m² por noite (%d regados)" % watered)

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.hand.any(func(c: Dictionary) -> bool: return c["id"] == "motosserra"), "máquinas sobrevivem ao save")
	_finish()
