class_name CardView
extends Button
## Uma carta na tela. Clicar seleciona (abre/fecha mochila e storage);
## arrastar move; soltar outra carta sobre esta a põe antes dela (C5).
## Só chama comandos do GameState (Z2).

var uid := 0
var area: StringName = &""
var index := 0


func setup(card: Dictionary, p_area: StringName, p_index: int, state: GameState) -> void:
	uid = int(card["uid"])
	area = p_area
	index = p_index
	var d := state.def_of(card)
	var title: String = d.display_name if d != null and d.display_name != "" else String(card["id"])
	if int(card.get("n", 1)) > 1:
		title += " x%d" % int(card["n"])
	if card.has("open"):
		title += " (aberto)"
	for st in state.statuses_of(card):
		title += "\n[%s]" % st # status visível na carta (S1)
	var w := state.card_weight(card)
	if w > 0:
		title += "\n%d g" % w
	if d != null and d.extra.has("capacity"):
		title += "\n%d/%d g de água" % [state.volume_of(card), int(d.extra["capacity"])]
	text = title
	custom_minimum_size = Vector2(104, 72)
	focus_mode = Control.FOCUS_ALL
	tooltip_text = _describe(card, d)
	# Destaque estático da soma (C4, W6): só cor, sem movimento.
	if uid == state.last_stacked_uid:
		modulate = Color(1.0, 0.95, 0.55)
	pressed.connect(func() -> void: GameSession.state.select_card(uid))


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = text
	set_drag_preview(preview)
	return {"uid": uid}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("uid") and int(data["uid"]) != uid


func _drop_data(_at: Vector2, data: Variant) -> void:
	# Arrastar sobre outra carta tenta a receita (C2); sem receita, reordena (C5).
	var preview := GameSession.state.recipe_preview(int(data["uid"]), uid)
	if not preview.is_empty():
		if preview["variable"] and preview["max_units"] > 1:
			_ask_time(int(data["uid"]), preview) # diálogo com slider (V2)
		else:
			GameSession.state.apply_recipe(int(data["uid"]), uid)
		return
	var dest := index
	# Dentro da mesma área, tirar a carta de antes desloca o destino.
	var from := GameSession.state.find_card(int(data["uid"]))
	if not from.is_empty() and from["area"] == area and from["index"] < index:
		dest -= 1
	GameSession.state.move_card(int(data["uid"]), area, dest)


const PROP_NAMES := {
	"location": "local", "tool": "ferramenta", "stackable": "acumulável",
	"movable": "móvel", "fixed": "inerente ao local", "vehicle": "veículo",
	"storage": "storage", "backpack": "mochila",
}


## Propriedades da carta em texto (US-3.1).
static func _describe(card: Dictionary, d: CardDef) -> String:
	var names: Array[String] = []
	var all: Array = []
	if d != null:
		all.append_array(Array(d.props))
	all.append_array(card.get("props", []))
	for p in all:
		names.append(PROP_NAMES.get(p, p))
	var out := ", ".join(names) if not names.is_empty() else "sem propriedades"
	for b in card.get("buffs", []):
		out += "\n" + str(b.get("id", "efeito"))
	return out


## Diálogo com slider de tempo (V2). O slider anda de uma unidade em uma.
func _ask_time(a_uid: int, preview: Dictionary) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Quanto tempo?"
	var box := VBoxContainer.new()
	var label := Label.new()
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = preview["max_units"]
	slider.step = 1
	slider.value = 1
	slider.custom_minimum_size = Vector2(320, 24)
	box.add_child(slider)
	var per: int = preview["minutes"]
	var update := func(v: float) -> void:
		label.text = "%d min (%d unidade(s))" % [int(v) * per, int(v)]
	slider.value_changed.connect(update)
	update.call(1.0)
	dialog.add_child(box)
	var target_uid := uid
	dialog.confirmed.connect(func() -> void:
		GameSession.state.apply_recipe(a_uid, target_uid, int(slider.value))
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
