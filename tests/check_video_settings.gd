extends SceneTree
## Verificação sem dependências: godot --headless --path . -s tests/check_video_settings.gd
## (Quando o GUT ou o gdUnit4 for escolhido, estes casos migram para lá.)

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FALHOU: ", msg)


func _initialize() -> void:
	# Padrões
	var d := VideoSettings.new()
	_check(d.vsync, "V-Sync deve vir ligado (VD5)")
	_check(d.max_fps == 0, "sem limite de FPS por padrão (VD4)")

	# Resoluções que cabem (VD3)
	var r := VideoSettings.resolutions_for(Vector2i(1920, 1080))
	_check(r == [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)], "filtro 1080p")
	_check(VideoSettings.resolutions_for(Vector2i(800, 600)).size() == 1, "lista nunca vazia")

	# Sanitize
	var s := VideoSettings.new()
	s.screen = 5
	s.resolution = Vector2i(3840, 2160)
	s.max_fps = 77
	s.sanitize(2, Vector2i(1920, 1080))
	_check(s.screen == 1, "monitor desconectado vira o último")
	_check(s.resolution == Vector2i(1920, 1080), "resolução grande demais vira a maior que cabe")
	_check(s.max_fps == 0, "limite desconhecido vira sem limite")

	# Salvar e carregar (VD6)
	var path := "user://test_settings.cfg"
	var w := VideoSettings.new()
	w.screen = 1
	w.window_mode = VideoSettings.MODE_FULLSCREEN
	w.resolution = Vector2i(1600, 900)
	w.max_fps = 180
	w.vsync = false
	_check(w.save_to(path) == OK, "salvar")
	var l := VideoSettings.load_from(path)
	_check(l.screen == 1 and l.window_mode == 1 and l.resolution == Vector2i(1600, 900)
		and l.max_fps == 180 and l.vsync == false, "round-trip do arquivo")
	_check(VideoSettings.load_from("user://nao_existe.cfg").vsync, "arquivo ausente usa padrões")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# Aplicar (headless não tem janela real, só não pode quebrar)
	VideoSettings.new().apply()

	# Cenas carregam e montam
	for scene_path in ["res://ui/main_menu.tscn", "res://ui/settings_screen.tscn", "res://ui/game_placeholder.tscn"]:
		var node: Node = load(scene_path).instantiate()
		root.add_child(node)
		await process_frame
		_check(node.get_child_count() > 0, "cena monta: " + scene_path)
		node.queue_free()

	print("Verificações concluídas, falhas: ", failures)
	quit(1 if failures > 0 else 0)
