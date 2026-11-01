extends CheckBase
## Feature 26: mapa e veículos (Q1 a Q10, L8, H5).
## godot --headless --path . -s tests/check_vehicles.gd


func _initialize() -> void:
	label = "Verificações de mapa e veículos"
	var s := GameState.new_game(1, false)
	s.spawn(&"dinheiro", GameState.HAND, 100000)

	# US-26.1: a vila é pequena, próxima, com loja limitada
	_check(s.has_location(&"vila") and s.parent_of(&"vila") == &"", "vila é de primeiro nível")
	_check(s.travel_minutes(&"fazenda", &"vila") < s.travel_minutes(&"fazenda", &"cidade"), "a vila é mais perto que a cidade")
	s.travel_to(&"vila")
	var vila_items: Array = Economy.shop_items(s).map(func(i: Dictionary) -> String: return i["id"])
	s.travel_to(&"cidade")
	s.travel_to(&"ferragem")
	var ferr_items: Array = Economy.shop_items(s).map(func(i: Dictionary) -> String: return i["id"])
	_check(vila_items.size() > 0 and vila_items.size() < ferr_items.size(), "a vila tem menos opções que a ferragem (%d vs %d)" % [vila_items.size(), ferr_items.size()])
	_check(LostFound.PLACE == &"vila", "o achados e perdidos fica na vila (H5)")

	# US-26.2 / Q4: dormir na vila, pagando
	s.travel_to(&"cidade")
	_check(not s.sleep_at_inn(), "fora da vila não há hospedagem")
	s.travel_to(&"vila")
	var cash := s.money()
	_check(s.sleep_at_inn() and s.money() == cash - 30 and s.minute_of_day() == 360, "pagou 30 e acordou às 06:00")
	var poor := GameState.new_game(2, false)
	poor.travel_to(&"vila")
	_check(not poor.sleep_at_inn(), "sem dinheiro não dorme na pousada")

	# US-26.3 / Q2, Q3: a cidade grande exige veículo
	s.travel_to(&"fazenda")
	var t := s.minutes
	_check(not s.travel_to(&"cidade_grande") and s.current_location == &"fazenda" and s.minutes == t, "a pé é inviável")

	# US-26.4: bicicleta reduz o tempo de viagem
	s.travel_to(&"cidade")
	_check(s.buy(&"bicicleta"), "comprou a bicicleta na cidade")
	var bike: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "bicicleta")[0]
	s.travel_to(&"fazenda")
	t = s.minutes
	s.travel_to(&"cidade")
	_check(s.minutes - t == 36, "60 min a pé -> 36 min de bicicleta (0,6)")
	_check(Vehicles.fuel_of(bike) == 0, "bicicleta não usa combustível (Q8)")
	# a carta no chão não ajuda
	s.move_card(bike["uid"], GameState.STAGE)
	s.travel_to(&"fazenda")
	s.travel_to(&"cidade")
	s.travel_to(&"fazenda")
	t = s.minutes
	s.travel_to(&"cidade")
	_check(s.minutes - t == 60, "bicicleta deixada para trás: a pé")
	s.travel_to(&"fazenda")
	# cidade grande com a bicicleta (carta na mão)
	s.travel_to(&"cidade")
	_check(not s.claim_lost(0), "fora da vila não se busca nada")
	var left: Array = s.stages["cidade"].filter(func(c: Dictionary) -> bool: return c["id"] == "bicicleta")
	_check(left.size() == 1, "a bicicleta ficou no chão da cidade")
	s.move_card(left[0]["uid"], GameState.HAND)
	_check(s.travel_to(&"cidade_grande"), "com bicicleta, a cidade grande é alcançável")
	_check(s.current_location == &"cidade_grande", "chegou")

	# US-26.5: combustível para os motorizados
	s.travel_to(&"cidade")
	_check(s.buy(&"motocicleta"), "comprou a moto")
	var moto: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "motocicleta")[0]
	s.hand.erase(bike)
	s.travel_to(&"fazenda")
	t = s.minutes
	s.travel_to(&"cidade")
	_check(s.minutes - t == 60, "moto sem combustível não anda (60 min a pé)")
	s.travel_to(&"fazenda")
	s.travel_to(&"cidade")
	_check(s.buy(&"combustivel"), "comprou combustível")
	var fuel: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "combustivel")[0]
	_check(s.apply_recipe(fuel["uid"], moto["uid"]) and Vehicles.fuel_of(moto) == 10, "abastecer: +10")
	t = s.minutes
	s.travel_to(&"fazenda")
	_check(s.minutes - t == 24 and Vehicles.fuel_of(moto) == 7, "moto: 60 x 0,4 = 24 min e gastou 3 de combustível")
	s.travel_to(&"cidade")
	_check(Vehicles.fuel_of(moto) == 4, "a volta gastou mais 3")
	moto["state"]["fuel"] = 2
	t = s.minutes
	s.travel_to(&"fazenda")
	_check(s.minutes - t == 60, "combustível insuficiente: vai a pé")

	# US-26.6 / Q6, Q7 / L8: depósito próprio, é preciso carregar e descarregar
	var truck := s.spawn(&"caminhao", GameState.HAND)
	s.move_card(truck["uid"], GameState.LOCATION)
	_check(s.select_card(truck["uid"]) and s.area_limit(GameState.STORAGE) == 1000000, "abre o depósito do caminhão")
	var logs := s.spawn(&"madeira", GameState.STAGE, 50)
	_check(s.move_card(logs["uid"], GameState.STORAGE), "carrega a madeira no depósito")
	s.select_card(truck["uid"]) # fecha
	_check(s.find_card(logs["uid"]).is_empty(), "o que está no depósito fechado não está à mão")
	s.select_card(truck["uid"])
	_check(s.move_card(logs["uid"], GameState.HAND), "descarrega para usar")
	s.select_card(truck["uid"])

	# US-26.7 / Q10: mochila maior
	var base_limit := s.area_limit(GameState.BACKPACK)
	s.hand.append(s.new_card(&"mochila"))
	_check(s.area_limit(GameState.BACKPACK) == 20000, "mochila comum: 20 kg")
	s.hand.append(s.new_card(&"mochila_grande"))
	_check(s.area_limit(GameState.BACKPACK) == 40000 and base_limit != 40000, "mochila grande: 40 kg")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.has_location(&"cidade_grande") and r.hand.any(func(c: Dictionary) -> bool: return c["id"] == "motocicleta" and Vehicles.fuel_of(c) == 2), "combustível sobrevive ao save")
	_finish()
