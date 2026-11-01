extends CheckBase
## Feature 17: correio (M1-M5, T6).
## godot --headless --path . -s tests/check_mail.gd


func _initialize() -> void:
	label = "Verificações do correio"
	var s := GameState.new_game(1)
	s.gated.clear() # este teste não trata da progressão
	var box: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "caixa_correio")[0]

	# US-17.1 / M1: a caixa é um storage de cartas de correspondência
	_check(s.has_prop(box, &"storage") and s.has_prop(box, &"mailbox"), "caixa de correio é um storage")
	_check(Mail.mailbox_uid(s) == box["uid"] and Mail.unread(s) == 1, "uma carta nova (boas-vindas)")
	_check(s.mail_queue.size() == 7, "7 cartas agendadas em dados")

	# T6: as cartas chegam quando o jogador acorda, não antes
	s.sleep() # vira para o dia 2
	_check(s.day_number() == 2 and Mail.unread(s) == 4, "no dia 2 chegaram 3 cartas (dica de regar, floresta e vila) (%d novas)" % Mail.unread(s))
	s.advance_time(60)
	_check(Mail.unread(s) == 4, "nada chega no meio do dia")
	s.sleep()
	s.sleep()
	_check(s.day_number() == 4 and s.mail_queue.size() == 1 and Mail.unread(s) == 7, "dias 3 e 4 entregues (o dia 5 espera) (%d novas)" % Mail.unread(s))

	# US-17.2 / M2: ler ao clicar, sem gastar tempo
	s.select_card(box["uid"])
	var letters := s.area_cards(GameState.STORAGE)
	var tip: Dictionary = letters.filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Dica: regar")[0]
	var t := s.minutes
	_check(s.select_card(tip["uid"]) and s.minutes == t, "ler custa 0 minutos")
	_check(tip["state"]["read"] and s.last_read["title"] == "Dica: regar", "lida e mostrada")
	_check("rega" in s.last_read["text"] or "regadas" in s.last_read["text"], "texto da dica (M3)")
	_check(not s.select_card(tip["uid"]) and Mail.unread(s) == 6, "reler não conta como nova")

	# US-17.4 / M4: item anexo
	var welcome: Dictionary = letters.filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Bem-vindo à fazenda")[0]
	s.select_card(welcome["uid"])
	var seeds: Array = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "semente")
	_check(seeds.size() == 1 and seeds[0]["n"] == 5, "5 sementes anexas na mão")
	Mail.send_bill(s, 40, 3)
	s.select_card(box["uid"]) # fecha
	s.sleep()
	s.select_card(box["uid"])
	var bill_letter: Dictionary = s.area_cards(GameState.STORAGE).filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Conta a pagar")[0]
	_check(Economy.open_bills(s).is_empty(), "a conta ainda não apareceu")
	s.select_card(bill_letter["uid"])
	var bills := Economy.open_bills(s)
	_check(bills.size() == 1 and bills[0]["state"]["amount"] == 40, "ler a carta da conta traz a conta")
	_check(bills[0]["state"]["due"] == s.minutes + 3 * 1440, "prazo de 3 dias a partir da leitura")

	# US-17.5 / M5: promoção por intervalo de dias
	var promo: Dictionary = s.area_cards(GameState.STORAGE).filter(func(c: Dictionary) -> bool: return c["state"]["title"] == "Promoção de enxadas")[0]
	s.select_card(promo["uid"])
	s.select_card(box["uid"])
	_check(Economy.price_of(s, &"enxada") == 40, "enxada 50 -> 40 (20% off)")
	_check(Economy.price_of(s, &"martelo") == 35, "outros itens sem desconto")
	s.travel_to(&"cidade")
	s.travel_to(&"ferragem")
	var cash_before := s.money()
	_check(s.buy(&"enxada") and s.money() == cash_before - 40, "compra com desconto")
	var day0 := s.day_number()
	while s.day_number() <= day0 + 3:
		s.sleep()
	_check(Economy.price_of(s, &"enxada") == 50, "a promoção acabou depois do intervalo")

	# Sem caixa de correio a fila espera
	var blank := GameState.new_game(2, false)
	Mail.send(blank, {"title": "x", "text": "y"}, 1)
	blank.sleep()
	_check(blank.mail_queue.size() == 1 and Mail.unread(blank) == 0, "sem caixa, a carta espera")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.promotions.size() == 1 and r.last_read.size() > 0, "promoções e última leitura sobrevivem ao save")
	_finish()
