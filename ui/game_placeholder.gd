extends Control
## Tela provisória do jogo. Mostra o local atual e deixa andar entre os locais,
## o que dispara o autosave (SV2). As áreas de cartas (feature 20) entram aqui.

var _location_label: Label
var _travel_buttons: Dictionary = {} # location_id -> Button


func _ready() -> void:
	if GameSession.state == null:
		GameSession.start_new()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	_location_label = Label.new()
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_location_label.add_theme_font_size_override("font_size", 32)
	box.add_child(_location_label)

	for id in GameState.LOCATION_NAMES:
		var b := Button.new()
		b.text = "Ir para %s" % GameState.LOCATION_NAMES[id]
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(_on_travel_pressed.bind(id))
		box.add_child(b)
		_travel_buttons[id] = b

	var back := Button.new()
	back.text = "Voltar ao menu"
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	box.add_child(back)

	_refresh()


func _refresh() -> void:
	var current := GameSession.state.current_location
	_location_label.text = GameState.LOCATION_NAMES[current]
	for id in _travel_buttons:
		(_travel_buttons[id] as Button).disabled = id == current
	# Foco no primeiro destino possível.
	for id in _travel_buttons:
		if not (_travel_buttons[id] as Button).disabled:
			(_travel_buttons[id] as Button).grab_focus()
			break


func _on_travel_pressed(id: StringName) -> void:
	GameSession.state.travel_to(id)
	_refresh()
