extends CheckBase
## Feature 3: cartas, áreas e ordem (C4, C5, L2, Z3).
## godot --headless --path . -s tests/check_cards.gd


func _initialize() -> void:
	label = "Verificações de cartas"
	var s := GameState.new_game(1)
	var stacked_events := [0]
	s.stacked.connect(func(_u: int) -> void: stacked_events[0] += 1)

	# US-3.5: acumuláveis iguais se somam
	var a := s.spawn(&"semente", GameState.STAGE, 3)
	var b := s.spawn(&"semente", GameState.STAGE, 2)
	_check(s.stages["fazenda"].size() == 1, "sementes iguais viram uma carta")
	_check(a["n"] == 5 and b["uid"] == a["uid"], "quantidade somada na carta existente")
	_check(stacked_events[0] == 1 and s.last_stacked_uid == a["uid"], "soma sinalizada para o destaque")
	# Não acumuláveis não somam
	s.spawn(&"enxada", GameState.STAGE)
	s.spawn(&"enxada", GameState.STAGE)
	_check(s.stages["fazenda"].size() == 3, "ferramentas não somam")
	# Soma ao mover entre áreas
	var seeds2 := s.spawn(&"semente", GameState.HAND, 4)
	_check(s.move_card(seeds2["uid"], GameState.STAGE), "move sementes para o chão")
	_check(s.stages["fazenda"][0]["n"] == 9 and s.hand.size() == 1, "somou ao mover e a original sumiu")
	# Reordenar na mesma área não soma
	var x := s.spawn(&"semente", GameState.LOCATION, 1)
	var y := s.spawn(&"enxada", GameState.LOCATION)
	_check(s.move_card(y["uid"], GameState.LOCATION, 0), "reordena")
	_check(s.cards_at(&"fazenda")[0]["uid"] == y["uid"] and s.cards_at(&"fazenda").size() == 2, "ordem do local mudou sem somar")
	# Cartas com buffs diferentes não são iguais
	s.select_card(s.hand[0]["uid"])
	var p := s.spawn(&"semente", GameState.BACKPACK)
	s.add_buff(p["uid"], {"id": "molhado"})
	var r := s.spawn(&"semente", GameState.BACKPACK)
	_check(s.backpack.size() == 2, "semente com buff é outra carta")
	_check(r["uid"] != p["uid"], "não soma com a carta que tem buff")

	# US-3.2: cada local tem a sua área
	s.travel_to(&"floresta")
	_check(s.cards_at(&"floresta").is_empty() and s.area_cards(GameState.STAGE).is_empty(), "floresta vazia")
	s.travel_to(&"fazenda")
	_check(s.area_cards(GameState.STAGE).size() == 3, "chão da fazenda voltou como estava")

	# US-3.3/3.4: ordem preservada ao salvar e carregar
	var order: Array = []
	for c in s.stages["fazenda"]:
		order.append(c["uid"])
	var loaded := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	var order2: Array = []
	for c in loaded.stages["fazenda"]:
		order2.append(c["uid"])
	_check(order == order2, "ordem do chão igual após salvar e carregar")
	_check(loaded.stages["fazenda"][0]["n"] == 9, "quantidade preservada")
	_finish()
