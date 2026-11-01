extends CheckBase
## Feature 20: áreas e movimentação (AR1-AR10, C1, C7-C9, L8, Z8).
## godot --headless --path . -s tests/check_areas.gd


func _initialize() -> void:
	label = "Verificações de áreas"
	var s := GameState.new_game(1)

	# US-20.1 / 20.10: cinco áreas; a mão começa com a carta da mochila
	_check(GameState.AREAS.size() == 5, "cinco áreas")
	_check(s.hand.size() == 1 and s.def_of(s.hand[0]).id == &"mochila", "mochila na mão")
	# US-20.2 / 20.5: mochila e storage fechados, chão e mão sempre abertos
	_check(s.is_open(GameState.HAND) and s.is_open(GameState.STAGE) and s.is_open(GameState.LOCATION), "mão, chão e local abertos")
	_check(not s.is_open(GameState.BACKPACK) and not s.is_open(GameState.STORAGE), "mochila e storage fechados")
	_check(s.spawn(&"enxada", GameState.BACKPACK).is_empty(), "área fechada não recebe cartas")

	# US-20.3 / 20.9: selecionar a mochila abre; clicar de novo fecha
	var bag_uid := int(s.hand[0]["uid"])
	_check(s.select_card(bag_uid) and s.is_open(GameState.BACKPACK), "abre a mochila")
	_check(s.select_card(bag_uid) and not s.is_open(GameState.BACKPACK), "fecha a mochila")
	s.select_card(bag_uid)

	# US-20.6: mover entre áreas abertas
	var hoe := s.spawn(&"enxada", GameState.LOCATION)
	var tree := s.spawn(&"arvore", GameState.LOCATION)
	_check(s.move_card(hoe["uid"], GameState.BACKPACK), "enxada vai para a mochila")
	_check(s.backpack.size() == 1 and s.cards_at(&"fazenda").size() == 1, "listas atualizadas")
	_check(not s.move_card(tree["uid"], GameState.STAGE), "carta inerente ao local não se move (C8)")
	_check(s.move_card(hoe["uid"], GameState.STAGE), "mochila -> chão")
	_check(s.move_card(hoe["uid"], GameState.HAND), "chão -> mão")
	_check(not s.move_card(bag_uid, GameState.STAGE), "carta sem 'movable' não se move (C7)")
	_check(not s.move_card(bag_uid, GameState.BACKPACK), "mochila não entra em si mesma")
	s.select_card(bag_uid) # fecha
	_check(not s.move_card(hoe["uid"], GameState.BACKPACK), "mochila fechada não recebe")
	_check(not s.move_card(99999, GameState.STAGE), "uid inexistente")

	# Reordenar na mesma área (C5)
	var a := s.spawn(&"semente", GameState.STAGE)
	var b := s.spawn(&"enxada", GameState.STAGE)
	var c := s.spawn(&"regador", GameState.STAGE)
	_check(s.move_card(c["uid"], GameState.STAGE, 0), "reordena para o início")
	_check(s.stages["fazenda"][0]["uid"] == c["uid"] and s.stages["fazenda"][2]["uid"] == b["uid"], "nova ordem")

	# US-20.4 / 20.12: storage abre em cima, ícone vai para a mão
	var box := s.spawn(&"bau", GameState.LOCATION)
	var other := s.spawn(&"regador", GameState.LOCATION)
	var box_index: int = s.cards_at(&"fazenda").find(box)
	_check(s.select_card(box["uid"]), "abre o baú")
	_check(s.is_open(GameState.STORAGE) and not s.is_open(GameState.LOCATION), "storage toma o lugar do local")
	_check(s.hand.back()["uid"] == box["uid"] and s.hand.back().has("open"), "ícone aberto na mão")
	_check(not s.cards_at(&"fazenda").has(box), "baú saiu da lista do local")
	_check(s.move_card(a["uid"], GameState.STORAGE), "chão -> storage")
	_check(not s.move_card(box["uid"], GameState.STAGE), "ícone aberto não se move")
	_check(s.spawn(&"enxada", GameState.LOCATION).is_empty(), "local fechado enquanto o storage está aberto")
	_check(s.select_card(box["uid"]) and not s.is_open(GameState.STORAGE), "clicar no ícone fecha")
	_check(s.cards_at(&"fazenda")[box_index]["uid"] == box["uid"], "carta volta à mesma posição do local")
	_check(s.storages[str(box["uid"])].size() == 1, "conteúdo do storage é guardado")
	_check(s.select_card(box["uid"]) and s.storages[str(box["uid"])][0]["uid"] == a["uid"], "reabre com o mesmo conteúdo")
	# Andar com storage aberto o fecha
	s.travel_to(&"floresta")
	_check(not s.is_open(GameState.STORAGE) and s.cards_at(&"fazenda").has(box), "viajar fecha o storage")
	_check(s.area_cards(GameState.LOCATION) == s.cards_at(&"floresta"), "local mudou")

	# US-20.8: veículo é um local dentro de outro (L8)
	_check(s.add_location(&"carroca", "Carroça", &"fazenda"), "cria veículo")
	_check(s.parent_of(&"carroca") == &"fazenda", "veículo está na fazenda")
	_check(not s.add_location(&"carroca", "x", &"fazenda"), "id repetido")
	_check(not s.add_location(&"v2", "x", &"lua"), "pai inexistente")
	var cart := s.spawn(&"carroca", GameState.LOCATION)
	_check(s.move_card(cart["uid"], GameState.HAND), "carta do veículo vai para a mão (AR9)")

	# US-20.7: propriedade e buff são dados (C9, Z8)
	var seed_card := s.spawn(&"semente", GameState.STAGE)
	_check(not s.has_prop(seed_card, &"vehicle"), "sem a propriedade")
	seed_card["props"] = ["vehicle"]
	_check(s.has_prop(seed_card, &"vehicle"), "propriedade acrescentada por dado")
	_check(s.add_buff(seed_card["uid"], {"id": "molhado", "valor": 2}), "buff aplicado")
	_check(seed_card["buffs"][0]["id"] == "molhado", "buff guardado na carta")

	# Estado e ordem sobrevivem ao save (Z3), com um storage aberto
	s.travel_to(&"fazenda")
	s.select_card(box["uid"])
	var json := JSON.stringify(s.to_dict())
	var parsed = JSON.parse_string(json)
	var r := GameState.from_dict(parsed)
	_check(r != null, "recarrega do JSON")
	_check(r.open_storage_uid == box["uid"] and r.is_open(GameState.STORAGE), "storage continua aberto")
	_check(r.hand.size() == s.hand.size() and r.hand[0]["uid"] == s.hand[0]["uid"], "mão preservada")
	_check(r.storages[str(box["uid"])][0]["uid"] == a["uid"], "conteúdo preservado")
	_check(r.stages["fazenda"][0]["uid"] == c["uid"], "ordem do chão preservada")
	_check(r.parent_of(&"carroca") == &"fazenda" and r.has_location(&"carroca"), "veículo preservado")
	_check(r.next_uid == s.next_uid, "uids não se repetem após carregar")
	r.select_card(box["uid"])
	_check(r.cards_at(&"fazenda").size() == s.cards_at(&"fazenda").size() + 1, "fecha após carregar")

	# Save inválido
	var bad := s.to_dict()
	bad["open_storage_uid"] = 777
	_check(GameState.from_dict(bad) == null, "storage aberto inexistente é recusado")
	var v1 := {"version": 1, "current_location": "fazenda", "cards": {"fazenda": [{"id": "enxada", "n": 1}]}, "rng_seed": "1", "rng_state": "1"}
	_check(GameState.from_dict(v1) != null, "save v1 ainda carrega")
	_finish()
