extends Control
## Tela do jogo. Mostra as áreas abertas (AR2): mão, local (ou storage), chão
## e mochila. Só chama comandos do GameState; ao mudar o estado, refaz a tela
## (sem animação, W5/W6). Andar entre locais dispara o autosave (SV2).

const AREA_TITLES := {
	GameState.HAND: "Mão",
	GameState.BACKPACK: "Mochila",
	GameState.STORAGE: "Storage",
	GameState.LOCATION: "Local",
	GameState.STAGE: "Chão",
}

var _location_label: Label
var _clock_label: Label
var _travel_box: HBoxContainer
var _shop_box: HBoxContainer
var _views: Dictionary = {} # area -> AreaView
var _dirty := false


func _ready() -> void:
	if GameSession.state == null:
		GameSession.start_new()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = -16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	_location_label = Label.new()
	_location_label.add_theme_font_size_override("font_size", 28)
	header.add_child(_location_label)
	_clock_label = Label.new()
	header.add_child(_clock_label)
	var sleep_btn := Button.new()
	sleep_btn.text = "Dormir"
	sleep_btn.pressed.connect(func() -> void: GameSession.state.sleep())
	header.add_child(sleep_btn)
	_travel_box = HBoxContainer.new()
	_travel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_travel_box)
	var back := Button.new()
	back.text = "Voltar ao menu"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	header.add_child(back)

	_shop_box = HBoxContainer.new()
	root.add_child(_shop_box)

	# Cima: local/storage e chão. Baixo: mochila. Mão sempre embaixo.
	for area in [GameState.LOCATION, GameState.STORAGE, GameState.STAGE, GameState.BACKPACK, GameState.HAND]:
		var v := AreaView.new()
		v.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(v)
		_views[area] = v

	GameSession.state.areas_changed.connect(_mark_dirty)
	_rebuild()


func _mark_dirty() -> void:
	# Várias mudanças no mesmo frame viram uma só reconstrução.
	if not _dirty:
		_dirty = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_dirty = false
	var state := GameSession.state
	_location_label.text = state.location_name(state.current_location)
	_clock_label.text = "Fazenda %d/%d m²   " % [state.farm_area_used(), state.farm_area_limit] + state.clock_text() + ("  (cansado)" if state.is_tired() else "")
	for child in _travel_box.get_children():
		_travel_box.remove_child(child)
		child.queue_free()
	for id in state.destinations():
		var b := Button.new()
		b.text = state.location_name(id)
		b.pressed.connect(func() -> void: GameSession.state.travel_to(id))
		_travel_box.add_child(b)
	for child in _shop_box.get_children():
		_shop_box.remove_child(child)
		child.queue_free()
	var items := Economy.shop_items(state)
	_shop_box.visible = not items.is_empty()
	if not items.is_empty():
		var money := Label.new()
		money.text = "Dinheiro: %d   Comprar:" % state.money()
		_shop_box.add_child(money)
	for item in items:
		var b := Button.new()
		var d := state.catalog.get_def(item["id"])
		b.text = "%s (%d)" % [d.display_name, item["price"]]
		b.pressed.connect(func() -> void: GameSession.state.buy(item["id"]))
		_shop_box.add_child(b)
	for area in _views:
		var v: AreaView = _views[area]
		v.visible = state.is_open(area)
		if v.visible:
			v.show_area(area, AREA_TITLES[area], state)
