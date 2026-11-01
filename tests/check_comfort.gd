extends CheckBase
## Feature 10: fluidez e conforto (W1-W6). A fluidez a 180 Hz (W1, W7) só o
## desenvolvedor valida na própria máquina; aqui ficam as garantias estáticas.
## godot --headless --path . -s tests/check_comfort.gd


func _initialize() -> void:
	label = "Verificações de conforto"
	var path := "user://test_comfort.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# US-10.5: movimento reduzido é opção, salva e lida do arquivo
	_check(not ComfortSettings.load_from(path).reduced_motion, "padrão: animações ligadas")
	var c := ComfortSettings.new()
	c.reduced_motion = true
	_check(c.save_to(path) == OK and ComfortSettings.load_from(path).reduced_motion, "ida e volta")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("lixo [[[")
	f.close()
	_check(not ComfortSettings.load_from(path).reduced_motion, "arquivo quebrado volta ao padrão")
	# Convive com a seção de vídeo
	var v := VideoSettings.new()
	v.max_fps = 144
	v.save_to(path)
	c.save_to(path)
	_check(VideoSettings.load_from(path).max_fps == 144 and ComfortSettings.load_from(path).reduced_motion, "vídeo e conforto no mesmo arquivo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# US-10.2 / 10.4 / 10.5: a animação usa Tween e some com movimento reduzido
	var box := Control.new()
	root.add_child(box)
	await process_frame
	ComfortSettings.set_current(ComfortSettings.new())
	var tw := Motion.reveal(box)
	_check(tw != null and box.modulate.a == 0.0, "animado: começa transparente, com Tween")
	_check(Motion.DURATION <= 0.2, "animação curta")
	tw.kill()
	var reduced := ComfortSettings.new()
	reduced.reduced_motion = true
	ComfortSettings.set_current(reduced)
	_check(Motion.reveal(box) == null and box.modulate.a == 1.0, "movimento reduzido: instantâneo, sem Tween")
	ComfortSettings.set_current(null)
	box.queue_free()

	# US-10.2: V-Sync ligado e sem limite de FPS por padrão
	var vs := VideoSettings.new()
	_check(vs.vsync and vs.max_fps == 0, "padrão: V-Sync ligado, sem limite de FPS")
	_check(ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 1, "projeto com V-Sync ligado")
	_check(int(ProjectSettings.get_setting("application/run/max_fps", 0)) == 0, "projeto sem limite de FPS")

	# US-10.3 / 10.4 / 10.6: o código de tela não faz trabalho por frame, não
	# mexe na câmera e não tem tremor
	var banned := ["_process(", "_physics_process(", "Camera2D", "Camera3D", "shake", "AnimationPlayer", "await get_tree().process_frame"]
	var scripts := 0
	for dir in ["res://ui", "res://src"]:
		for file in _gd_files(dir):
			scripts += 1
			var text := FileAccess.get_file_as_string(file)
			for b in banned:
				_check(not text.contains(b), "%s não pode conter '%s'" % [file, b])
	_check(scripts >= 15, "verificou os scripts (%d)" % scripts)
	for file in _files(("res://ui"), ".tscn"):
		var t := FileAccess.get_file_as_string(file)
		_check(not t.contains("Camera2D") and not t.contains("AnimationPlayer"), file + " sem câmera nem AnimationPlayer")

	# Destaque de soma é só cor (W6)
	var cv := FileAccess.get_file_as_string("res://ui/card_view.gd")
	_check(cv.contains("modulate = Color") and not cv.contains("create_tween"), "destaque de soma estático")
	_finish()


func _gd_files(dir: String) -> Array:
	return _files(dir, ".gd")


func _files(dir: String, ext: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(d), ext))
	return out
