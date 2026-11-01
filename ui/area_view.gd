class_name AreaView
extends PanelContainer
## Uma área de cartas na tela: título e fileira de cartas. Soltar uma carta
## no espaço vazio a põe no fim da área.

var area: StringName = &""
var _row: HFlowContainer
var _title: Label


func _init() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	_title = Label.new()
	box.add_child(_title)
	_row = HFlowContainer.new()
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_row)
	custom_minimum_size = Vector2(0, 110)


func show_area(p_area: StringName, title: String, state: GameState) -> void:
	area = p_area
	_title.text = title
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var list := state.area_cards(p_area)
	for i in list.size():
		var v := CardView.new()
		v.setup(list[i], p_area, i, state)
		_row.add_child(v)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("uid")


func _drop_data(_at: Vector2, data: Variant) -> void:
	GameSession.state.move_card(int(data["uid"]), area)
