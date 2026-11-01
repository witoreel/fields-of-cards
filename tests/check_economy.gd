extends CheckBase
## Feature 7: economia (D1-D5, D9, E1).
## godot --headless --path . -s tests/check_economy.gd


func _initialize() -> void:
	label = "Verificações da economia"
	var s := GameState.new_game(1)

	# US-7.6: dinheiro é carta, sem peso
	var cash := s.spawn(&"dinheiro", GameState.HAND, 100)
	_check(s.money() == 100 and s.card_weight(cash) == 0, "100 de dinheiro, peso 0")
	s.spawn(&"dinheiro", GameState.HAND, 20)
	_check(s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "dinheiro").size() == 1, "notas somam numa carta")

	# US-7.2: comprar na ferragem
	_check(not s.buy(&"enxada"), "na fazenda não há ferragem")
	s.travel_to(&"cidade")
	s.travel_to(&"ferragem")
	_check(Economy.shop_items(s).size() >= 5, "ferragem tem itens")
	var before := s.money()
	_check(s.buy(&"enxada") and s.money() == before - 50, "comprou enxada por 50")
	_check(s.hand.any(func(c: Dictionary) -> bool: return c["id"] == "enxada"), "enxada na mão")
	_check(not s.buy(&"semente"), "semente não se vende na ferragem")
	Economy.spend(s, s.money())
	_check(not s.buy(&"martelo") and s.money() == 0, "sem dinheiro não compra")

	# US-7.1: venda em lote na caixa da fazenda
	s.travel_to(&"fazenda")
	var box := s.spawn(&"caixa_venda", GameState.LOCATION)
	var crop := s.spawn(&"colheita", GameState.LOCATION, 5)
	var hoe := s.spawn(&"enxada", GameState.LOCATION)
	_check(not s.apply_recipe(hoe["uid"], box["uid"]), "enxada não tem valor de venda")
	_check(s.apply_recipe(crop["uid"], box["uid"]), "vende a colheita arrastando para a caixa")
	_check(s.money() == 50 and not s.cards_at(&"fazenda").has(crop), "5 × 10 = 50 e a pilha sumiu")
	_check(not s.sell(hoe["uid"], hoe["uid"]), "só caixa de venda compra")

	# US-7.3: conta tem prazo e valor
	var bill := s.issue_bill(30, s.minutes + 2 * 1440)
	_check(bill["state"]["amount"] == 30 and bill["state"]["due"] == s.minutes + 2880, "conta com valor e prazo")
	_check(Economy.open_bills(s).size() == 1, "uma conta aberta")

	# US-7.4: pagar exige ir à cidade (gasta o tempo da viagem)
	_check(not s.pay_bill(bill["uid"]), "na fazenda não paga")
	var t := s.minutes
	s.travel_to(&"cidade")
	_check(s.minutes == t + 60, "ir à cidade custou 60 min")
	_check(s.pay_bill(bill["uid"]) and s.money() == 20, "pagou 30")
	_check(Economy.open_bills(s).is_empty(), "conta paga some")
	var bill2 := s.issue_bill(500, s.minutes + 100)
	_check(not s.pay_bill(bill2["uid"]), "sem dinheiro suficiente não paga")
	_check(Economy.open_bills(s).size() == 1 and s.money() == 20, "nada mudou")

	# US-7.5: atraso gera multa, não game over
	s.sleep()
	var st: Dictionary = bill2["state"]
	_check(Economy.is_overdue(s, bill2) and st["amount"] == 550 and st["fined"], "multa de 10% (550)")
	s.sleep()
	_check(st["amount"] == 550, "multa só uma vez")
	_check(s.day_number() == 3, "o jogo continua")

	# Dinheiro na mochila também conta
	s.select_card(s.hand[0]["uid"])
	var cash2: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "dinheiro")[0]
	s.move_card(cash2["uid"], GameState.BACKPACK)
	_check(s.money() == 20, "dinheiro na mochila conta")
	_check(Economy.spend(s, 15) and s.money() == 5, "gasta")
	_check(not Economy.spend(s, 6), "não gasta mais do que tem")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.money() == 5 and Economy.open_bills(r).size() == 1, "dinheiro e contas sobrevivem ao save")
	_finish()
