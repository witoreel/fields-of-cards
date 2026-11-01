extends CheckBase
## Feature 16: chão e achados e perdidos (H1-H5).
## godot --headless --path . -s tests/check_ground.gd


func _initialize() -> void:
	label = "Verificações do chão"
	var s := GameState.new_game(1)
	s.farm_area_limit = 1000
	s.travel_to(&"roca")

	# US-16.1 / H1: cartas móveis novas chegam ao chão; a terra fica no local
	var soil: Dictionary = s.cards_at(&"roca").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_bruta")[0]
	var hoe: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "enxada")[0]
	s.apply_recipe(hoe["uid"], soil["uid"])
	_check(s.cards_at(&"roca").any(func(c: Dictionary) -> bool: return c["id"] == "terra_arada"), "terra arada fica no local")
	var crop := s.spawn(&"colheita", GameState.STAGE, 3)
	_check(s.stages["roca"].size() == 1, "colheita no chão")
	_check(s.move_card(crop["uid"], GameState.HAND), "o jogador leva a colheita para onde quiser")
	s.move_card(crop["uid"], GameState.STAGE)

	# US-16.2 / H2 / H3: sem limite, e continua lá no mesmo dia
	_check(s.area_limit(GameState.STAGE) == 0, "chão sem limite de peso")
	var logs := s.spawn(&"madeira", GameState.STAGE, 500) # 1.000 kg
	_check(not logs.is_empty(), "chão aceita qualquer quantidade")
	s.travel_to(&"fazenda")
	s.travel_to(&"roca")
	_check(s.stages["roca"].size() == 2, "voltando no mesmo dia, tudo no chão")
	s.advance_time(120)
	_check(s.stages["roca"].size() == 2, "horas depois, ainda no chão")

	# US-16.3 / H4: na virada do dia o chão vai para o achados e perdidos, com aviso
	s.sleep()
	_check(s.stages["roca"].is_empty() and s.lost_and_found.size() == 2, "chão esvaziou, 2 cartas guardadas")
	var box: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "caixa_correio")[0]
	_check(Mail.unread(s) >= 2, "chegou carta de aviso")
	s.travel_to(&"fazenda")
	s.select_card(box["uid"])
	var notice: Array = s.area_cards(GameState.STORAGE).filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Achados e perdidos")
	_check(notice.size() == 1 and "2 carta" in notice[0]["state"]["text"], "o aviso conta quantas cartas (%s)" % str(notice.size()))
	s.select_card(box["uid"])

	# US-16.4 / H5: buscar na cidade
	_check(not s.claim_lost(s.lost_and_found[0]["uid"]), "na fazenda não dá para buscar")
	s.travel_to(&"cidade")
	var found: Dictionary = s.lost_and_found.filter(func(c: Dictionary) -> bool: return c["id"] == "colheita")[0]
	_check(LostFound.days_left(s, found) == 7, "7 dias restantes")
	_check(s.claim_lost(found["uid"]), "pegou a colheita")
	_check(s.hand.any(func(c: Dictionary) -> bool: return c["id"] == "colheita" and c["n"] == 3) and not found.has("since_day"), "colheita na mão, sem marca de guarda")
	_check(s.lost_and_found.size() == 1, "sobrou a madeira")

	# Depois de 7 dias, perde-se
	for i in 6:
		s.sleep()
	_check(s.lost_and_found.size() == 1 and LostFound.days_left(s, s.lost_and_found[0]) == 1, "no sexto dia ainda está lá (1 dia restante)")
	s.sleep()
	_check(s.lost_and_found.is_empty(), "depois de 7 dias, perdeu")

	# Sem nada no chão não há aviso
	var n := Mail.unread(s)
	s.sleep()
	_check(Mail.unread(s) == n, "sem carta no chão, sem aviso")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	s.spawn(&"enxada", GameState.STAGE)
	s.sleep()
	var r2 := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r2.lost_and_found.size() == 1 and r2.lost_and_found[0]["since_day"] == s.day_number(), "achados e perdidos sobrevive ao save")
	_check(r != null, "estado anterior também carrega")
	_finish()
