extends Control
## Tela de configurações, só com vídeo por enquanto (MN3, MN4, VD1 a VD6).
## As escolhas ficam num rascunho e só valem ao clicar em "Aplicar" (VD6).

const MENU_SCENE := "res://ui/main_menu.tscn"

var _draft: VideoSettings
var _screen_option: OptionButton
var _mode_option: OptionButton
var _resolution_option: OptionButton
var _fps_option: OptionButton
var _refresh_label: Label
var _vsync_check: CheckBox
var _status_label: Label
var _resolutions: Array[Vector2i] = []
var _building := true


func _ready() -> void:
	_draft = VideoSettings.load_from()
	_draft.sanitize(DisplayServer.get_screen_count(),
		DisplayServer.screen_get_size(_clamped_screen(_draft.screen)))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "Configurações - Vídeo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)

	_screen_option = _add_option(grid, "Monitor")
	_mode_option = _add_option(grid, "Modo de janela")
	_resolution_option = _add_option(grid, "Resolução")
	_fps_option = _add_option(grid, "Limite de FPS")

	_add_caption(grid, "Frequência do monitor")
	_refresh_label = Label.new()
	grid.add_child(_refresh_label)

	_add_caption(grid, "V-Sync")
	_vsync_check = CheckBox.new()
	_vsync_check.text = "Ligado"
	grid.add_child(_vsync_check)

	_fill_screens()
	_mode_option.add_item("Janela", VideoSettings.MODE_WINDOWED)
	_mode_option.add_item("Tela cheia", VideoSettings.MODE_FULLSCREEN)
	for limit in VideoSettings.FPS_LIMITS:
		_fps_option.add_item("Sem limite" if limit == 0 else "%d FPS" % limit, limit)

	_screen_option.item_selected.connect(_on_screen_selected)
	_mode_option.item_selected.connect(_on_mode_selected)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_fps_option.item_selected.connect(_on_fps_selected)
	_vsync_check.toggled.connect(_on_vsync_toggled)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	var back := _add_button(buttons, "Voltar")
	back.pressed.connect(_on_back_pressed)
	var apply := _add_button(buttons, "Aplicar")
	apply.pressed.connect(_on_apply_pressed)

	_refresh_from_draft()
	_building = false
	apply.grab_focus()


func _add_caption(grid: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)


func _add_option(grid: GridContainer, caption: String) -> OptionButton:
	_add_caption(grid, caption)
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(260, 40)
	grid.add_child(o)
	return o


func _add_button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


func _clamped_screen(index: int) -> int:
	return clampi(index, 0, DisplayServer.get_screen_count() - 1)


func _fill_screens() -> void:
	_screen_option.clear()
	for i in DisplayServer.get_screen_count():
		var size := DisplayServer.screen_get_size(i)
		_screen_option.add_item("Monitor %d (%dx%d)" % [i + 1, size.x, size.y], i)


func _fill_resolutions() -> void:
	_resolution_option.clear()
	_resolutions = VideoSettings.resolutions_for(
		DisplayServer.screen_get_size(_clamped_screen(_draft.screen)))
	for r in _resolutions:
		_resolution_option.add_item("%dx%d" % [r.x, r.y])


## Põe o rascunho nos controles sem disparar os sinais deles.
func _refresh_from_draft() -> void:
	_draft.sanitize(DisplayServer.get_screen_count(),
		DisplayServer.screen_get_size(_clamped_screen(_draft.screen)))
	_screen_option.select(_screen_option.get_item_index(_draft.screen))
	_mode_option.select(_mode_option.get_item_index(_draft.window_mode))
	_fill_resolutions()
	_resolution_option.select(maxi(_resolutions.find(_draft.resolution), 0))
	# VD3: a resolução só vale no modo janela.
	_resolution_option.disabled = _draft.window_mode == VideoSettings.MODE_FULLSCREEN
	_fps_option.select(_fps_option.get_item_index(_draft.max_fps))
	_vsync_check.set_pressed_no_signal(_draft.vsync)
	var hz := DisplayServer.screen_get_refresh_rate(_clamped_screen(_draft.screen))
	_refresh_label.text = "%.0f Hz" % hz if hz > 0.0 else "Desconhecida"
	_status_label.text = ""


func _on_screen_selected(index: int) -> void:
	_draft.screen = _screen_option.get_item_id(index)
	_refresh_from_draft()


func _on_mode_selected(index: int) -> void:
	_draft.window_mode = _mode_option.get_item_id(index)
	_refresh_from_draft()


func _on_resolution_selected(index: int) -> void:
	_draft.resolution = _resolutions[index]


func _on_fps_selected(index: int) -> void:
	_draft.max_fps = _fps_option.get_item_id(index)


func _on_vsync_toggled(pressed: bool) -> void:
	_draft.vsync = pressed


func _on_apply_pressed() -> void:
	_draft.apply()
	var err := _draft.save_to()
	_refresh_from_draft()
	_status_label.text = "Configurações aplicadas." if err == OK \
		else "Aplicadas, mas não foi possível salvar."


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
