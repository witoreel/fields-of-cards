extends CheckBase
## Feature 14: status de cartas (S1, S2, C9).
## godot --headless --path . -s tests/check_status.gd


func _initialize() -> void:
	label = "Verificações de status"
	var s := GameState.new_game(1)

	# US-14.1: a carta mostra os seus status
	var hoe: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "enxada")[0]
	_check(s.statuses_of(hoe) == ["enferrujada"] and s.has_status(hoe, "enferrujada"), "enxada começa enferrujada")
	_check(s.add_status(hoe, "sujo") and s.statuses_of(hoe) == ["enferrujada", "sujo"], "acrescenta sujo")
	_check(not s.add_status(hoe, "sujo"), "não repete")
	_check(s.remove_status(hoe, "enferrujada") and not s.has_status(hoe, "enferrujada"), "remove enferrujada")
	_check(s.remove_status(hoe, "sujo") and not hoe.has("state"), "sem status nem estado sobrando")
	_check(not s.remove_status(hoe, "sujo"), "remover o que não tem")

	# US-14.2: buffs e debuffs são outra coisa e convivem com os status
	s.add_status(hoe, "molhado")
	_check(s.add_buff(hoe["uid"], {"id": "afiada", "yield_mult": 1.1}), "buff na carta")
	_check(hoe["buffs"].size() == 1 and s.statuses_of(hoe) == ["molhado"], "status e buffs separados")
	s.remove_status(hoe, "molhado")
	_check(hoe["buffs"].size() == 1, "tirar status não tira o buff")

	# Status distingue cartas para somar (um estágio diferente é outra carta)
	var a := s.spawn(&"semente", GameState.STAGE, 2)
	s.add_status(a, "molhado")
	var b := s.spawn(&"semente", GameState.STAGE, 3)
	_check(b["uid"] != a["uid"] and s.stages["fazenda"].size() == 2, "semente molhada não soma com seca")

	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	var ra: Dictionary = r.stages["fazenda"][0]
	_check(r.has_status(ra, "molhado"), "status sobrevive ao save")
	_finish()
