extends CheckBase
## Feature 19: estado inicial (I1, I2, I3).
## godot --headless --path . -s tests/check_initial.gd


func _ids(list: Array) -> Array:
	return list.map(func(c: Dictionary) -> String: return c["id"])


func _initialize() -> void:
	label = "Verificações do estado inicial"
	var s := GameState.new_game(7)

	# US-19.1 / I1: enxada enferrujada, regador furado, algum dinheiro
	_check(_ids(s.hand).has("enxada") and _ids(s.hand).has("regador"), "enxada e regador na mão")
	var hoe: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "enxada")[0]
	var pot: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "regador")[0]
	_check(hoe["state"]["status"] == ["enferrujada"], "enxada enferrujada")
	_check(pot["state"]["status"] == ["furado"], "regador furado")
	_check(s.money() > 0, "começa com dinheiro (%d)" % s.money())
	_check(s.def_of(s.hand[0]).id == &"mochila", "a mochila é a primeira carta da mão")
	_check(s.current_location == &"fazenda" and s.minutes == 360, "fazenda, 06:00")

	# I2: a roça inicial existe, na fazenda, danificada
	_check(s.has_location(&"roca") and s.parent_of(&"roca") == &"fazenda", "roça na fazenda")
	_check(s.is_damaged(&"roca"), "roça danificada")
	_check(s.cards_at(&"roca").any(func(c: Dictionary) -> bool: return c["id"] == "terra_bruta"), "terra bruta para arar")
	_check(s.cards_at(&"fazenda").any(func(c: Dictionary) -> bool: return c["id"] == "caixa_venda"), "caixa de venda na fazenda")

	# I3: carta de boas-vindas com sementes anexas; ler não gasta tempo
	var letter: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "carta_boas_vindas")[0]
	_check(not _ids(s.hand).has("semente"), "sementes ainda não estão na mão")
	var t := s.minutes
	_check(s.select_card(letter["uid"]), "ler a carta")
	_check(_ids(s.hand).has("semente") and s.minutes == t, "sementes anexas, sem gastar tempo (M2)")
	_check(not s.select_card(letter["uid"]), "ler de novo não dá mais sementes")
	var seeds: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "semente")[0]
	_check(seeds["n"] == 5, "5 sementes")

	# O começo é jogável: arar na roça, semear, regar (volume cheio), dormir, colher
	s.travel_to(&"roca")
	var soil: Dictionary = s.cards_at(&"roca")[0]
	_check(s.apply_recipe(hoe["uid"], soil["uid"]), "arar na roça")
	var plowed: Dictionary = s.cards_at(&"roca").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(s.apply_recipe(seeds["uid"], plowed["uid"]), "semear")
	var sown: Dictionary = s.cards_at(&"roca").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_semeada")[0]
	_check(s.apply_recipe(pot["uid"], sown["uid"]), "regar")
	s.sleep()
	_check(sown["id"] == "terra_broto", "cresceu durante a noite")

	# Ida e volta pelo save mantém o estado inicial alterado
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.is_damaged(&"roca") and r.has_location(&"roca"), "roça danificada sobrevive ao save")

	# Jogo em branco continua disponível para testes
	_check(GameState.new_game(1, false).hand.size() == 1, "new_game sem estado inicial só tem a mochila")
	_finish()
