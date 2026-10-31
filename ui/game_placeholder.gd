extends Control
## Tela provisória do jogo. As áreas de cartas (feature 20) entram aqui depois.


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var label := Label.new()
	label.text = "O jogo começa aqui."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

	var back := Button.new()
	back.text = "Voltar ao menu"
	back.custom_minimum_size = Vector2(240, 48)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	box.add_child(back)
	back.grab_focus()
