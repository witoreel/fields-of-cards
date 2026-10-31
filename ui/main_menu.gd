extends Control
## Menu inicial (MN1, MN2). A troca de tela é instantânea (MN5).

const GAME_SCENE := "res://ui/game_placeholder.tscn"
const SETTINGS_SCENE := "res://ui/settings_screen.tscn"
const META_APPLIED := "video_settings_applied"


func _ready() -> void:
	# O menu é a primeira tela, então é aqui que as configurações salvas
	# entram em vigor (VD6). Só uma vez por execução.
	if not Engine.has_meta(META_APPLIED):
		Engine.set_meta(META_APPLIED, true)
		VideoSettings.load_from().apply()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "Fields of Cards"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)

	var start := _make_button("Iniciar jogo", box)
	start.pressed.connect(_on_start_pressed)
	var settings := _make_button("Configurações", box)
	settings.pressed.connect(_on_settings_pressed)
	start.grab_focus()


func _make_button(text: String, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	parent.add_child(b)
	return b


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)
