extends CheckBase
## Feature 4: locais navegáveis (L1-L6, L8, L3).
## godot --headless --path . -s tests/check_locations.gd


func _initialize() -> void:
	label = "Verificações de locais"
	var s := GameState.new_game(1)

	# US-4.3: locais iniciais
	for id in [&"fazenda", &"floresta", &"cidade", &"casa", &"ferragem", &"feira"]:
		_check(s.has_location(id), "existe: %s" % id)
	_check(s.current_location == &"fazenda", "começa na fazenda")
	_check(s.parent_of(&"casa") == &"fazenda", "a casa fica dentro da fazenda")
	_check(s.parent_of(&"ferragem") == &"cidade" and s.parent_of(&"feira") == &"cidade", "lojas e feira na cidade")
	_check(s.parent_of(&"cidade") == &"", "cidade é de primeiro nível")
	_check(s.children_of(&"cidade").size() == 2, "cidade tem duas filhas")

	# US-3.2/4.1: cada local tem a sua lista, e viajar muda onde estou
	_check(s.cards.has("casa") and s.stages.has("feira"), "cada local tem cartas e chão")
	var dests := s.destinations()
	_check(dests.has(&"floresta") and dests.has(&"cidade") and dests.has(&"casa"), "da fazenda: floresta, cidade e casa")
	_check(not dests.has(&"ferragem") and not dests.has(&"fazenda"), "da fazenda não aparece a ferragem nem ela mesma")
	_check(s.travel_to(&"cidade"), "vai à cidade")
	dests = s.destinations()
	_check(dests.has(&"ferragem") and dests.has(&"feira"), "na cidade: ferragem e feira (US-4.4)")
	_check(s.travel_to(&"ferragem"), "entra na ferragem")
	dests = s.destinations()
	_check(dests.has(&"feira") and dests.has(&"cidade") and dests.has(&"fazenda"), "da ferragem: a feira, a cidade e o resto")
	_check(not dests.has(&"casa"), "da ferragem não se vai direto à casa")

	# US-4.2: itens levados na mochila e na mão acompanham; o resto fica
	s.travel_to(&"fazenda")
	s.select_card(s.hand[0]["uid"]) # abre a mochila
	var hoe := s.spawn(&"enxada", GameState.LOCATION)
	var seed_card := s.spawn(&"semente", GameState.LOCATION)
	var water := s.spawn(&"regador", GameState.LOCATION)
	s.move_card(hoe["uid"], GameState.BACKPACK)
	s.move_card(water["uid"], GameState.HAND)
	s.travel_to(&"floresta")
	_check(s.backpack.size() == 1 and s.backpack[0]["uid"] == hoe["uid"], "mochila vem junto")
	_check(s.hand.any(func(c: Dictionary) -> bool: return c["uid"] == water["uid"]), "mão vem junto")
	_check(s.cards_at(&"floresta").is_empty(), "a floresta não tem a semente")
	s.travel_to(&"fazenda")
	_check(s.cards_at(&"fazenda").size() == 1 and s.cards_at(&"fazenda")[0]["uid"] == seed_card["uid"], "o que não foi levado ficou")
	# Largar na floresta e voltar
	s.travel_to(&"floresta")
	s.move_card(hoe["uid"], GameState.STAGE)
	s.travel_to(&"fazenda")
	_check(s.backpack.is_empty(), "o que foi largado não vem junto")
	s.travel_to(&"floresta")
	_check(s.stages["floresta"].size() == 1, "largado fica no chão da floresta")

	# US-4.6: construído com nome, dentro da fazenda
	_check(s.add_location(&"galinheiro_1", "Galinheiro do Zé", &"fazenda"), "cria galinheiro com nome")
	s.travel_to(&"fazenda")
	_check(s.destinations().has(&"galinheiro_1") and s.location_name(&"galinheiro_1") == "Galinheiro do Zé", "aparece com o nome")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.location_name(&"galinheiro_1") == "Galinheiro do Zé" and r.parent_of(&"galinheiro_1") == &"fazenda", "construído sobrevive ao save")
	_check(r.cards.has("casa"), "locais fixos sobrevivem ao save")
	_finish()
