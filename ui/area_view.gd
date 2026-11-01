class_name AreaView
extends PanelContainer
## Uma área de cartas na tela. O nome da área fica no fundo, grande e quase
## transparente, para ganhar pixels. Soltar uma carta no espaço vazio a põe
## no fim da área.

enum Layout { ROW, GRID2, FLOW }

var area: StringName = &""
var layout: Layout = Layout.ROW
var _watermark: Label
var _content: Container


func _init(p_layout: Layout = Layout.ROW) -> void:
	layout = p_layout
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.PANEL_LINE, 6))
	mouse_filter = Control.MOUSE_FILTER_STOP

	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(holder)

	_watermark = Label.new()
	_watermark.add_theme_font_size_override("font_size", 40)
	_watermark.add_theme_color_override("font_color", Color(1, 1, 1, 0.06))
	_watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_watermark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	_watermark.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_watermark.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.add_child(_watermark)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiStyle.MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	match layout:
		Layout.ROW:
			scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", UiStyle.GAP)
			_content = row
		Layout.GRID2:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", UiStyle.GAP)
			grid.add_theme_constant_override("v_separation", UiStyle.GAP)
			_content = grid
		Layout.FLOW:
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", UiStyle.GAP)
			flow.add_theme_constant_override("v_separation", UiStyle.GAP)
			flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_content = flow
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(_content)
	if layout != Layout.ROW:
		_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	_apply_minimum_size()


func _apply_minimum_size() -> void:
	var inner := 2 * UiStyle.MARGIN + 2
	match layout:
		Layout.ROW:
			# Uma carta de altura mais a barra de rolagem horizontal.
			custom_minimum_size = Vector2(0, UiStyle.CARD_SIZE.y + inner + 14)
		Layout.GRID2:
			custom_minimum_size = Vector2(2 * UiStyle.CARD_SIZE.x + UiStyle.GAP + inner + 14, 0)
		Layout.FLOW:
			var pad := UiStyle.GROUND_PADDING - UiStyle.MARGIN
			custom_minimum_size = Vector2(0, 2 * UiStyle.CARD_SIZE.y + UiStyle.GAP + inner + 2 * pad)


func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


func show_area(p_area: StringName, title: String, state: GameState) -> void:
	area = p_area
	_watermark.text = title
	_clear()
	var list := state.area_cards(p_area)
	for i in list.size():
		var v := CardView.new()
		v.setup(list[i], p_area, i, state)
		_content.add_child(v)


## Mostra destinos do mapa como cartas (clicar viaja).
func show_places(title: String, state: GameState) -> void:
	area = &"map"
	_watermark.text = title
	_clear()
	for id in state.destinations():
		var v := CardView.new()
		var parent := state.parent_of(id)
		v.setup_place(id, state.location_name(id), state.location_name(parent) if parent != &"" else "",
			state.travel_minutes(state.current_location, id))
		_content.add_child(v)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return area != &"map" and data is Dictionary and data.has("uid")


func _drop_data(_at: Vector2, data: Variant) -> void:
	GameSession.state.move_card(int(data["uid"]), area)
