extends CheckBase
## Feature 18: progressão e desbloqueio (U1, U2).
## godot --headless --path . -s tests/check_progression.gd


func _initialize() -> void:
	label = "Verificações de progressão"
	var s := GameState.new_game(1)

	# U2: começa só com a fazenda; o resto vem aos poucos
	_check(s.is_unlocked(&"fazenda") and s.is_unlocked(&"roca") and s.is_unlocked(&"casa"), "fazenda, roça e casa abertas")
	_check(not s.is_unlocked(&"floresta") and not s.is_unlocked(&"cidade"), "floresta e cidade fechadas")
	_check(not s.travel_to(&"floresta") and s.current_location == &"fazenda", "não dá para andar até lá")
	_check(not s.destinations().has(&"floresta") and s.destinations().has(&"roca"), "o destino fechado não aparece")
	var t := s.minutes
	s.travel_to(&"cidade")
	_check(s.minutes == t, "viagem recusada não gasta tempo")

	# U1: uma carta do correio libera
	s.sleep()
	var box: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "caixa_correio")[0]
	s.select_card(box["uid"])
	var letter: Dictionary = s.area_cards(GameState.STORAGE).filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Conheça a floresta")[0]
	_check(not s.is_unlocked(&"floresta"), "carta não lida não libera")
	s.select_card(letter["uid"])
	_check(s.is_unlocked(&"floresta") and s.destinations().has(&"floresta"), "ler a carta libera a floresta")
	_check(s.travel_to(&"floresta"), "agora dá para ir")
	_check(not s.is_unlocked(&"cidade"), "a cidade continua fechada (uma mecânica de cada vez)")
	s.travel_to(&"fazenda")

	# Itens à venda também são liberados aos poucos
	s.sleep()
	s.select_card(box["uid"])
	for c in s.area_cards(GameState.STORAGE).duplicate():
		if c["state"]["title"] == "A cidade":
			s.select_card(c["uid"])
	s.select_card(box["uid"])
	_check(s.travel_to(&"cidade") and s.travel_to(&"ferragem"), "dia 3: cidade e ferragem liberadas")
	s.spawn(&"dinheiro", GameState.HAND, 1000)
	var names: Array = Economy.shop_items(s).map(func(i: Dictionary) -> String: return i["id"])
	_check(names.has("enxada") and names.has("oleo") and not names.has("machado") and not names.has("martelo"), "ferragem sem machado nem martelo ainda")
	_check(not s.buy(&"machado"), "item fechado não se compra")

	# Evento agendado também libera (U1)
	s.schedule(s.minutes + 60, "unlock", {"id": "machado"})
	_check(not s.is_unlocked(&"machado"), "ainda não")
	s.advance_time(61)
	_check(s.is_unlocked(&"machado") and s.buy(&"machado"), "o evento liberou o machado")

	# Progressão sobrevive ao save e jogo em branco não bloqueia nada
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.is_unlocked(&"machado") and not r.is_unlocked(&"martelo") and r.is_unlocked(&"cidade"), "liberações sobrevivem ao save")
	var blank := GameState.new_game(2, false)
	_check(blank.is_unlocked(&"cidade") and blank.travel_to(&"cidade"), "jogo em branco não tem bloqueios")

	# O mapa de liberações está nos dados, na ordem gradual (US-18.2)
	var order := {}
	for e in Mail.load_schedule():
		for id in e.get("unlock", []):
			order[id] = e["day"]
	_check(order["floresta"] < order["cidade"] and order["cidade"] < order["martelo"], "floresta, depois cidade, depois ferramentas")
	_finish()
