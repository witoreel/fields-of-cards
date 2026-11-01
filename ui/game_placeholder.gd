extends Control
## Tela do jogo, no layout do mockup (mockup/tela-jogo.html): Local em cima,
## Mochila embaixo, Mão à esquerda, contexto (storage aberto ou mapa) à
## direita e o Chão no centro, com um dock de ícones suspenso. Só chama
## comandos do GameState; ao mudar o estado, refaz a tela (sem animação,
## W5/W6). Andar entre locais dispara o autosave (SV2).

const MENU_SCENE := "res://ui/main_menu.tscn"
const ICON_PATHS := {
	"map": "res://ui/icons/map.svg",
	"hand": "res://ui/icons/hand.svg",
	"bag": "res://ui/icons/bag.svg",
	"ground": "res://ui/icons/ground.svg",
}

var _views: Dictionary = {} # área -> AreaView
var _farm_label: Label
var _clock_label: Label
var _skill_label: Label
var _mail_label: Label
var _shop_box: HFlowContainer
var _center: Control
var _dock: PanelContainer
var _dock_buttons: Dictionary = {}
var _show_map := false
var _show_hand := true
var _show_ground := true
var _last_storage := 0
var _dirty := false


func _ready() -> void:
	if GameSession.state == null:
		GameSession.start_new()
	theme = UiStyle.make_theme()

	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.offset_left = UiStyle.GAP
		root.offset_top = UiStyle.GAP
		root.offset_right = -UiStyle.GAP
		root.offset_bottom = -UiStyle.GAP
	root.add_theme_constant_override("separation", UiStyle.GAP)
	add_child(root)

	root.add_child(_build_top_bar())

	_views[GameState.LOCATION] = AreaView.new(AreaView.Layout.ROW)
	root.add_child(_views[GameState.LOCATION])

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", UiStyle.GAP)
	root.add_child(middle)
	_views[GameState.HAND] = AreaView.new(AreaView.Layout.GRID2)
	middle.add_child(_views[GameState.HAND])
	_center = Control.new()
	_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.clip_contents = true
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	middle.add_child(_center)
	_views[GameState.STORAGE] = AreaView.new(AreaView.Layout.GRID2)
	middle.add_child(_views[GameState.STORAGE])

	_views[GameState.BACKPACK] = AreaView.new(AreaView.Layout.ROW)
	root.add_child(_views[GameState.BACKPACK])

	_build_center()
	GameSession.state.areas_changed.connect(_mark_dirty)
	_center.resized.connect(_place_ground)
	_dock.resized.connect(_place_ground)
	_rebuild()
	_place_ground.call_deferred()


func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.custom_minimum_size.y = 32
	_skill_label = Label.new()
	bar.add_child(_skill_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var sleep_btn := Button.new()
	sleep_btn.text = "Dormir"
	sleep_btn.pressed.connect(func() -> void: GameSession.state.sleep())
	bar.add_child(sleep_btn)
	_farm_label = Label.new()
	_farm_label.add_theme_color_override("font_color", UiStyle.MUTED)
	bar.add_child(_farm_label)
	_clock_label = Label.new()
	bar.add_child(_clock_label)
	var gear := Button.new()
	gear.text = "⚙"
	gear.tooltip_text = "Voltar ao menu"
	gear.custom_minimum_size = Vector2(32, 30)
	gear.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	bar.add_child(gear)
	return bar


func _build_center() -> void:
	var info := VBoxContainer.new()
	info.set_anchors_preset(Control.PRESET_TOP_WIDE)
	info.offset_left = 12
	info.offset_right = -12
	info.offset_top = 8
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(info)
	_mail_label = Label.new()
	_mail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_mail_label)
	_shop_box = HFlowContainer.new()
	info.add_child(_shop_box)

	_views[GameState.STAGE] = AreaView.new(AreaView.Layout.FLOW)
	_center.add_child(_views[GameState.STAGE])

	# Dock suspenso, no meio de baixo (mapa, mão, mochila e chão).
	_dock = PanelContainer.new()
	_dock.add_theme_stylebox_override("panel", UiStyle.box(Color(0.15, 0.19, 0.16, 0.92), UiStyle.PANEL_LINE, 16))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_dock.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var tips := {"map": "Mapa", "hand": "Mão", "bag": "Mochila", "ground": "Chão"}
	for key in ["map", "hand", "bag", "ground"]:
		var b := Button.new()
		b.toggle_mode = true
		b.icon = load(ICON_PATHS[key])
		b.expand_icon = true
		b.custom_minimum_size = UiStyle.DOCK_BUTTON
		b.tooltip_text = tips[key]
		b.add_theme_stylebox_override("normal", UiStyle.box(Color("#33423a"), Color(0, 0, 0, 0), 14, 2))
		b.add_theme_stylebox_override("hover", UiStyle.box(Color("#33423a"), UiStyle.MUTED, 14, 2))
		b.add_theme_stylebox_override("pressed", UiStyle.box(Color("#3d4d43"), UiStyle.ACCENT, 14, 2))
		b.add_theme_stylebox_override("hover_pressed", UiStyle.box(Color("#3d4d43"), UiStyle.ACCENT, 14, 2))
		b.pressed.connect(_on_dock_pressed.bind(key))
		row.add_child(b)
		_dock_buttons[key] = b
	_center.add_child(_dock)
	_dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 10)


## O chão tem a altura de duas fileiras de cartas e folga em volta; fica no
## meio, sem tomar o centro todo.
func _place_ground() -> void:
	var g: AreaView = _views[GameState.STAGE]
	var w := minf(UiStyle.GROUND_MAX_WIDTH, _center.size.x - 24)
	var h := g.custom_minimum_size.y
	g.size = Vector2(maxf(w, 0), h)
	# Centrado no espaço que sobra acima do dock, para não ficar atrás dele.
	var free_h := _center.size.y - _dock.size.y - 20.0
	g.position = Vector2((_center.size.x - g.size.x) / 2.0, maxf(0.0, (free_h - h) / 2.0)).round()


func _on_dock_pressed(key: String) -> void:
	var state := GameSession.state
	match key:
		"map":
			_show_map = not _show_map
		"hand":
			_show_hand = not _show_hand
		"ground":
			_show_ground = not _show_ground
		"bag":
			for c in state.hand:
				if state.has_prop(c, &"backpack"):
					state.select_card(c["uid"]) # abre ou fecha a mochila (AR3, AR8)
					break
	_mark_dirty()


func _mark_dirty() -> void:
	# Várias mudanças no mesmo frame viram uma só reconstrução.
	if not _dirty:
		_dirty = true
		_rebuild.call_deferred()


static func _kg(grams: int) -> String:
	return "%.1f" % (grams / 1000.0)


func _rebuild() -> void:
	_dirty = false
	var state := GameSession.state
	# Abrir um storage mostra o storage no lugar do mapa.
	if state.open_storage_uid != _last_storage:
		if state.open_storage_uid != 0:
			_show_map = false
		_last_storage = state.open_storage_uid

	_farm_label.text = "Fazenda %d / %d m²" % [state.farm_area_used(), state.farm_area_limit]
	_clock_label.text = state.clock_text() + ("  (cansado)" if state.is_tired() else "")
	if state.is_game_over:
		_clock_label.text = "FALÊNCIA: " + state.game_over_reason

	var parts: Array[String] = []
	for sk in Multipliers.skill_summary(state):
		parts.append("%s %d%%" % [sk["activity"], sk["percent"]])
	_skill_label.text = "Skills: " + ", ".join(parts) if not parts.is_empty() else ""
	var lr := state.last_read
	_mail_label.visible = not lr.is_empty()
	_mail_label.text = "%s: %s" % [lr.get("title", ""), lr.get("text", "")]
	_rebuild_shop(state)

	var storage_title := "Storage"
	var limit := state.area_limit(GameState.STORAGE)
	for c in state.hand:
		if int(c["uid"]) == state.open_storage_uid:
			storage_title = state.def_of(c).display_name
	if state.is_open(GameState.STORAGE):
		storage_title += " %s / %s kg" % [_kg(state.area_weight(GameState.STORAGE)), _kg(limit)] if limit > 0 else ""

	var right: AreaView = _views[GameState.STORAGE]
	var want := {
		GameState.LOCATION: true,
		GameState.HAND: _show_hand,
		GameState.BACKPACK: state.backpack_open,
		GameState.STAGE: _show_ground,
		GameState.STORAGE: _show_map or state.is_open(GameState.STORAGE),
	}
	for area in _views:
		var v: AreaView = _views[area]
		var was_visible := v.visible
		v.visible = want[area]
		if v.visible and not was_visible:
			Motion.reveal(v) # aparecer é curto; com movimento reduzido, instantâneo (W5)
	if _show_map:
		right.show_places("Mapa", state)
	elif state.is_open(GameState.STORAGE):
		right.show_area(GameState.STORAGE, storage_title, state)
	_views[GameState.LOCATION].show_area(GameState.LOCATION, state.location_name(state.current_location), state)
	if _show_hand:
		_views[GameState.HAND].show_area(GameState.HAND, "Mão", state)
	if state.backpack_open:
		var bag_title := "Mochila"
		var bag_limit := state.area_limit(GameState.BACKPACK)
		if bag_limit > 0:
			bag_title += " %s / %s kg" % [_kg(state.area_weight(GameState.BACKPACK)), _kg(bag_limit)]
		_views[GameState.BACKPACK].show_area(GameState.BACKPACK, bag_title, state)
	if _show_ground:
		_views[GameState.STAGE].show_area(GameState.STAGE, "Chão", state)

	(_dock_buttons["map"] as Button).set_pressed_no_signal(_show_map)
	(_dock_buttons["hand"] as Button).set_pressed_no_signal(_show_hand)
	(_dock_buttons["bag"] as Button).set_pressed_no_signal(state.backpack_open)
	(_dock_buttons["ground"] as Button).set_pressed_no_signal(_show_ground)


func _rebuild_shop(state: GameState) -> void:
	for child in _shop_box.get_children():
		_shop_box.remove_child(child)
		child.queue_free()
	var items := Economy.shop_items(state)
	var has_laf := state.root_of(state.current_location) == LostFound.PLACE and not state.lost_and_found.is_empty()
	_shop_box.visible = not items.is_empty() or has_laf
	if not items.is_empty():
		var money := Label.new()
		money.text = "Dinheiro: %d   Comprar:" % state.money()
		_shop_box.add_child(money)
	for item in items:
		var b := Button.new()
		b.text = "%s (%d)" % [state.catalog.get_def(item["id"]).display_name, item["price"]]
		b.pressed.connect(func() -> void: GameSession.state.buy(item["id"]))
		_shop_box.add_child(b)
	if has_laf:
		var lbl := Label.new()
		lbl.text = "Achados e perdidos:"
		_shop_box.add_child(lbl)
		for card in state.lost_and_found:
			var cb := Button.new()
			var cd := state.def_of(card)
			cb.text = "%s (%d dias)" % [cd.display_name if cd != null else card["id"], LostFound.days_left(state, card)]
			cb.pressed.connect(func() -> void: GameSession.state.claim_lost(card["uid"]))
			_shop_box.add_child(cb)
