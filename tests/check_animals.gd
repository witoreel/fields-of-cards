extends CheckBase
## Feature 23: animais (A1 a A6).
## godot --headless --path . -s tests/check_animals.gd


func _count(list: Array, id: String) -> int:
	var n := 0
	for c in list:
		if c["id"] == id:
			n += int(c["n"])
	return n


func _initialize() -> void:
	label = "Verificações de animais"
	var s := GameState.new_game(1, false)
	s.add_location(&"galinheiro", "Galinheiro", &"fazenda")
	s.travel_to(&"galinheiro")

	# US-23.1: medidores que caem com os dias
	var hen := s.spawn(&"galinha", GameState.LOCATION)
	_check(Animals.meter(hen, "food") == 100 and Animals.meter(hen, "clean") == 100 and Animals.meter(hen, "happy") == 100, "animal novo: tudo em 100")
	_check(s.spawn(&"galinha", GameState.LOCATION)["uid"] != hen["uid"] and s.cards_at(&"galinheiro").size() == 2, "animais não somam (cada um tem os seus medidores)")
	s.cards_at(&"galinheiro").pop_back()
	s.sleep()
	_check(Animals.meter(hen, "food") == 70 and Animals.meter(hen, "happy") == 90, "um dia: comida 70, felicidade 90")
	_check(Animals.meter(hen, "clean") == 85 - 0, "limpeza 85 (sem esterco ainda)")

	# T5 / A4: bem cuidada, um ovo por dia
	_check(_count(s.cards_at(&"galinheiro"), "ovo") == 1, "uma galinha bem tratada põe 1 ovo por dia")
	_check(_count(s.cards_at(&"galinheiro"), "esterco") == 1, "e deixa esterco")

	# US-23.2: ração, escova, brinquedo e vassoura
	var feed := s.spawn(&"racao_organico", GameState.HAND, 3)
	_check(s.apply_recipe(feed["uid"], hen["uid"]), "dar ração")
	_check(Animals.meter(hen, "food") == 100 and Animals.meter(hen, "happy") == 100 and feed["n"] == 2, "comida 70+40 (limite 100), felicidade 90+10, gastou 1")
	var brush := s.spawn(&"escova", GameState.HAND)
	_check(s.apply_recipe(brush["uid"], hen["uid"]) and Animals.meter(hen, "clean") == 100, "escovar sobe a limpeza")
	hen["state"]["happy"] = 20
	var toy := s.spawn(&"brinquedo", GameState.HAND)
	_check(s.apply_recipe(toy["uid"], hen["uid"]) and Animals.meter(hen, "happy") == 60, "brincar sobe a felicidade")
	var broom := s.spawn(&"vassoura", GameState.HAND)
	var dung: Dictionary = s.cards_at(&"galinheiro").filter(func(c: Dictionary) -> bool: return c["id"] == "esterco")[0]
	_check(s.apply_recipe(broom["uid"], dung["uid"]) and _count(s.cards_at(&"galinheiro"), "esterco") == 0, "limpar o celeiro tira o esterco")
	# Esterco acumulado piora a limpeza (A2)
	var clean_hen := s.spawn(&"galinha", GameState.LOCATION)
	s.spawn(&"esterco", GameState.LOCATION, 4)
	s.sleep()
	_check(100 - Animals.meter(clean_hen, "clean") > 15, "celeiro sujo faz a limpeza cair mais que 15 (caiu %d)" % (100 - Animals.meter(clean_hen, "clean")))

	# A4: produção depende do bem-estar
	var sad := s.spawn(&"galinha", GameState.LOCATION)
	sad["state"].merge({"food": 40, "clean": 10, "happy": 10}, true)
	var eggs_before := _count(s.cards_at(&"galinheiro"), "ovo")
	var dung_before := _count(s.cards_at(&"galinheiro"), "esterco")
	s.sleep()
	_check(Animals.wellness(sad) < 60, "bem-estar baixo (%d)" % Animals.wellness(sad))
	var eggs_after := _count(s.cards_at(&"galinheiro"), "ovo")
	_check(eggs_after - eggs_before <= 2, "a galinha mal tratada não põe (só as outras)")

	# A5: ração de postura dobra o ovo do dia
	var layer := s.spawn(&"galinha", GameState.LOCATION)
	var fresh_feed := s.spawn(&"racao_postura", GameState.HAND)
	s.apply_recipe(fresh_feed["uid"], layer["uid"])
	_check(layer["state"]["boost"] == 1, "ração de postura marca o bônus")
	s.cards_at(&"galinheiro").filter(func(c: Dictionary) -> bool: return c["id"] == "ovo").map(func(c: Dictionary) -> void: c["n"] = 0)
	s.cards_at(&"galinheiro").assign(s.cards_at(&"galinheiro").filter(func(c: Dictionary) -> bool: return c["id"] != "ovo"))
	for other in s.cards_at(&"galinheiro"):
		if other["id"] == "galinha" and other != layer:
			other["state"]["food"] = 0
			other["state"]["happy"] = 0
			other["state"]["clean"] = 0
			other["state"]["hungry_days"] = 0
	s.sleep()
	_check(not layer["state"].has("boost"), "bônus de postura gasto")
	_check(_count(s.cards_at(&"galinheiro"), "ovo") >= 2, "pôs 2 ovos")

	# A5: engorda rende mais carne; crescimento faz o filhote virar adulto
	var fat := s.spawn(&"galinha", GameState.LOCATION)
	for i in 3:
		var f := s.spawn(&"racao_engorda", GameState.HAND)
		s.apply_recipe(f["uid"], fat["uid"])
	_check(Animals.meter(fat, "fat") == 75, "engorda acumulou 75")
	var chick := s.spawn(&"pintinho", GameState.LOCATION)
	for i in 2:
		var g := s.spawn(&"racao_crescimento", GameState.HAND)
		s.apply_recipe(g["uid"], chick["uid"])
		s.sleep()
		chick["state"]["food"] = 100
	_check(chick["id"] == "galinha", "o pintinho virou galinha com ração de crescimento")

	# A6: vender, manter ou cortar
	_check(s.slaughter(fat["uid"]), "cortar")
	_check(_count(s.stages["galinheiro"], "carne") == 3, "2 de carne + 1 pela engorda (75/50)")
	_check(not s.cards_at(&"galinheiro").has(fat), "a galinha saiu")
	var box := s.spawn(&"caixa_venda", GameState.LOCATION)
	var keep := s.spawn(&"galinha", GameState.LOCATION)
	var sell := s.spawn(&"galinha", GameState.LOCATION)
	var cash := s.money()
	_check(s.sell(sell["uid"], box["uid"]) and s.money() == cash + 32, "vender a galinha: 40 x 0,8 = 32")
	_check(s.cards_at(&"galinheiro").has(keep), "manter não faz nada")
	_check(not s.slaughter(box["uid"]), "só animal vai para o corte")

	# A3: morre de fome ou de tristeza
	var doomed := s.spawn(&"galinha", GameState.LOCATION)
	doomed["state"].merge({"food": 0, "hungry_days": 0}, true)
	for i in 3:
		s.sleep()
	_check(not s.cards_at(&"galinheiro").has(doomed), "3 dias sem comida: morreu")
	var blue := s.spawn(&"galinha", GameState.LOCATION)
	blue["state"].merge({"happy": 0, "food": 100}, true)
	for i in 3:
		blue["state"]["food"] = 100
		s.sleep()
		_check(s.cards_at(&"galinheiro").has(blue), "ainda viva no dia %d de tristeza" % (i + 1))
	blue["state"]["food"] = 100
	s.sleep()
	_check(not s.cards_at(&"galinheiro").has(blue), "4 dias deprimida: morreu")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.cards_at(&"galinheiro").size() == s.cards_at(&"galinheiro").size(), "animais sobrevivem ao save")
	_finish()
