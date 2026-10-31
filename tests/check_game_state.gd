extends SceneTree
## godot --headless --path . -s tests/check_game_state.gd

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FALHOU: ", msg)


func _initialize() -> void:
	var path := "user://test_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(not SaveGame.exists(path), "sem arquivo, sem save")

	# Estado e ordem das cartas (SV1, Z3)
	var s := GameState.new_game(42)
	_check(s.current_location == &"fazenda", "começa na fazenda")
	s.cards_at(&"fazenda").append({"id": "enxada", "n": 1})
	s.cards_at(&"fazenda").append({"id": "regador", "n": 1})
	s.cards_at(&"floresta").append({"id": "tronco", "n": 3})

	# Ida e volta por dados, sem mudar nada (US-22.1)
	var copy := GameState.from_dict(s.to_dict())
	_check(copy != null, "from_dict aceita to_dict")
	_check(copy.cards_at(&"fazenda")[0]["id"] == "enxada" and copy.cards_at(&"fazenda")[1]["id"] == "regador", "ordem preservada")
	_check(copy.cards_at(&"floresta")[0]["n"] == 3, "carta da floresta")

	# RNG continua de onde parou (Z4)
	var a := s.rng.randi()
	var restored := GameState.from_dict(s.to_dict())
	_check(restored.rng.randi() == s.rng.randi(), "RNG restaurado gera a mesma sequência")
	_check(a != null, "rng usado")

	# Autosave a cada local andado (SV2)
	var saves := [0]
	s.arrived.connect(func(_id: StringName) -> void:
		_check(SaveGame.save_state(s, path) == OK, "gravar")
		saves[0] += 1)
	_check(s.travel_to(&"floresta"), "andar para a floresta")
	_check(s.travel_to(&"cidade"), "andar para a cidade")
	_check(not s.travel_to(&"lua"), "local inexistente é recusado")
	_check(saves[0] == 2, "um autosave por local andado (recusado não salva)")
	_check(s.current_location == &"cidade", "continua na cidade após recusa")

	# Continuar (SV5, US-22.3)
	_check(SaveGame.exists(path), "save existe")
	var l := SaveGame.load_state(path)
	_check(l.current_location == &"cidade", "carregado na cidade")
	_check(l.cards_at(&"floresta")[0]["id"] == "tronco", "cartas carregadas")

	# Save quebrado ou de outra versão é ignorado (SV4, US-22.4)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ isso não é json")
	f.close()
	_check(not SaveGame.exists(path), "json quebrado é ignorado")
	var bad := s.to_dict()
	bad["version"] = 999
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(bad))
	f.close()
	_check(not SaveGame.exists(path), "versão desconhecida é ignorada")
	var bad2 := s.to_dict()
	bad2["current_location"] = "lua"
	_check(GameState.from_dict(bad2) == null, "local desconhecido é recusado")
	_check(GameState.from_dict("texto") == null, "dado que não é Dictionary")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# Sessão: iniciar e continuar
	GameSession.start_new()
	GameSession.state.travel_to(&"floresta")
	_check(SaveGame.exists(), "sessão salvou no caminho padrão")
	GameSession.state = null
	_check(GameSession.continue_saved() and GameSession.state.current_location == &"floresta", "continuar pela sessão")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.DEFAULT_PATH))

	# Cenas montam com e sem save
	for scene_path in ["res://ui/main_menu.tscn", "res://ui/game_placeholder.tscn"]:
		var node: Node = load(scene_path).instantiate()
		root.add_child(node)
		await process_frame
		_check(node.get_child_count() > 0, "cena monta: " + scene_path)
		node.queue_free()

	print("Verificações de estado concluídas, falhas: ", failures)
	quit(1 if failures > 0 else 0)
