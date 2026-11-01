extends CheckBase
## Feature 13: desgaste e manutenção (G1 a G5).
## godot --headless --path . -s tests/check_wear.gd


func _initialize() -> void:
	label = "Verificações de desgaste"
	var s := GameState.new_game(1, false)
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)

	# US-13.1: usar gasta durabilidade, sem quebrar, e a ação demora mais
	_check(Wear.durability(hoe) == 100 and Wear.time_factor(s, hoe) == 1.0, "ferramenta nova: 100, tempo normal")
	var t := s.minutes
	_check(s.apply_recipe(hoe["uid"], soil["uid"]), "arar")
	_check(s.minutes - t == 30, "30 min com ferramenta nova")
	_check(Wear.durability(hoe) == 98, "perdeu 2 de durabilidade")
	for i in 60:
		s.farm_area_limit = 100000
		s.apply_recipe(hoe["uid"], soil["uid"])
	_check(Wear.durability(hoe) == 0 and s.hand.has(hoe), "durabilidade chega a 0 e a ferramenta continua existindo (não quebra)")
	t = s.minutes
	var expected := ceili(30 * 4 * s.buff_multiplier("time_mult")) # cansado muda o tempo (T9)
	s.apply_recipe(hoe["uid"], soil["uid"])
	_check(s.minutes - t == expected and Wear.durability(hoe) == 0, "com durabilidade 0 leva 4x (120 min) e não passa de 0")
	var half := s.spawn(&"enxada", GameState.HAND)
	half["state"] = {"durability": 50}
	_check(absf(Wear.time_factor(s, half) - 2.5) < 0.001, "durabilidade 50 -> 2,5x")

	# US-13.2: fio e afiar
	var axe := s.spawn(&"machado", GameState.HAND)
	var tree := s.spawn(&"arvore", GameState.LOCATION)
	_check(Wear.edge(axe) == 100, "fio cheio")
	s.apply_recipe(axe["uid"], tree["uid"])
	_check(Wear.edge(axe) == 96 and Wear.durability(axe) == 98, "cortar gasta fio (4) e durabilidade (2)")
	t = s.minutes
	axe["state"]["edge"] = 0
	s.apply_recipe(axe["uid"], tree["uid"])
	_check(s.minutes - t > 30 and Wear.edge(axe) == 0, "sem fio demora mais")
	var stone := s.spawn(&"pedra_afiar", GameState.HAND)
	_check(s.apply_recipe(stone["uid"], axe["uid"]) and Wear.edge(axe) == 100, "afiar restaura o fio")
	_check(s.hand.has(stone), "pedra não é consumida")
	_check(not s.apply_recipe(stone["uid"], hoe["uid"]), "enxada não tem fio para afiar")

	# US-13.3: durabilidade baixa perde o fio mais rápido
	var a1 := s.spawn(&"serrote", GameState.HAND)
	var a2 := s.spawn(&"serrote", GameState.HAND)
	a2["state"] = {"durability": 0}
	s.apply_recipe(a1["uid"], tree["uid"])
	s.apply_recipe(a2["uid"], tree["uid"])
	_check(100 - Wear.edge(a2) > 100 - Wear.edge(a1), "serrote gasto perde mais fio (%d vs %d)" % [100 - Wear.edge(a2), 100 - Wear.edge(a1)])
	_check(100 - Wear.edge(a1) == 4 and 100 - Wear.edge(a2) == 8, "4 contra 8")

	# US-13.4: limpar e proteger
	var tool := s.spawn(&"martelo", GameState.HAND)
	s.add_status(tool, "sujo")
	var tap := s.spawn(&"torneira", GameState.LOCATION)
	_check(s.apply_recipe(tap["uid"], tool["uid"]), "lavar na torneira")
	_check(not s.has_status(tool, "sujo") and s.has_status(tool, "molhado"), "ficou limpo e molhado")
	var rusty: Dictionary = s.spawn(&"enxada", GameState.HAND)
	s.add_status(rusty, "enferrujada")
	var wool := s.spawn(&"palha_aco", GameState.HAND, 2)
	_check(s.apply_recipe(wool["uid"], rusty["uid"]) and not s.has_status(rusty, "enferrujada") and wool["n"] == 1, "palha de aço tira a ferrugem e gasta 1")
	var oil := s.spawn(&"oleo", GameState.HAND)
	var fresh := s.spawn(&"enxada", GameState.HAND)
	var fresh2 := s.spawn(&"enxada", GameState.HAND)
	_check(s.apply_recipe(oil["uid"], fresh["uid"]) and s.has_status(fresh, "oleada"), "óleo protege")
	_check(not s.hand.has(oil), "óleo acabou")
	s.apply_recipe(fresh["uid"], soil["uid"])
	s.apply_recipe(fresh2["uid"], soil["uid"])
	_check(100 - Wear.durability(fresh) < 100 - Wear.durability(fresh2), "oleada se degrada menos (%d vs %d)" % [100 - Wear.durability(fresh), 100 - Wear.durability(fresh2)])
	var dirty := s.spawn(&"enxada", GameState.HAND)
	dirty["state"] = {"status": ["enferrujada"]}
	var clean := s.spawn(&"enxada", GameState.HAND)
	s.apply_recipe(dirty["uid"], soil["uid"])
	s.apply_recipe(clean["uid"], soil["uid"])
	_check(Wear.durability(dirty) < Wear.durability(clean), "enferrujada se degrada mais")

	# US-13.5: guardar sujo ou molhado desgasta
	s.select_card(s.hand[0]["uid"])
	var stored := s.spawn(&"martelo", GameState.HAND)
	s.add_status(stored, "molhado")
	var d0 := Wear.durability(stored)
	_check(s.move_card(stored["uid"], GameState.BACKPACK), "guardar martelo molhado")
	_check(Wear.durability(stored) == d0 - 5, "perdeu 5 de durabilidade")
	var dry := s.spawn(&"martelo", GameState.HAND)
	dry["state"] = {"durability": 90}
	s.move_card(dry["uid"], GameState.BACKPACK)
	_check(Wear.durability(dry) == 90, "guardar seca não desgasta")

	# Compra dos itens de manutenção na ferragem
	s.travel_to(&"cidade")
	s.travel_to(&"ferragem")
	var ids: Array = Economy.shop_items(s).map(func(i: Dictionary) -> String: return i["id"])
	_check(ids.has("pedra_afiar") and ids.has("oleo") and ids.has("palha_aco"), "ferragem vende manutenção")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	var rs: Dictionary = r.backpack.filter(func(c: Dictionary) -> bool: return Wear.durability(c) == d0 - 5)[0]
	_check(Wear.durability(rs) == d0 - 5, "durabilidade sobrevive ao save")
	_finish()
