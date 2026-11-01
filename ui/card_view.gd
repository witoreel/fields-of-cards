class_name CardView
extends PanelContainer
## Uma carta na tela. Clicar seleciona (abre/fecha mochila e storage, lê
## carta, colhe...); arrastar mostra a carta seguindo o mouse e soltá-la sobre
## outra executa a receita (C2) ou reordena (C5). Só chama comandos do
## GameState (Z2). O movimento do arrasto vem do mouse, sem animação própria.

const PROP_NAMES := {
	"location": "local", "tool": "ferramenta", "stackable": "acumulável",
	"movable": "móvel", "fixed": "fixa", "vehicle": "veículo",
	"storage": "storage", "backpack": "mochila", "animal": "animal",
	"machine": "máquina", "mail": "carta",
}
## Propriedades que valem aparecer como etiqueta na carta.
const TAG_PROPS := ["fixed", "storage", "tool", "vehicle", "animal", "machine", "mail"]

var uid := 0
var area: StringName = &""
var index := 0
var place_id: StringName = &"" # carta de destino do mapa
var _draggable := false
var _dragging := false
var _style_normal: StyleBoxFlat
var _style_hint: StyleBoxFlat
var _style_recipe: StyleBoxFlat
var _hint_cache := {} # uid arrastado -> "recipe" | "move"


func setup(card: Dictionary, p_area: StringName, p_index: int, state: GameState) -> void:
	uid = int(card["uid"])
	area = p_area
	index = p_index
	var d := state.def_of(card)
	var kind := "normal"
	if state.has_prop(card, &"fixed"):
		kind = "fixed"
	elif card["id"] == "dinheiro":
		kind = "money"
	_apply_style(kind, uid == state.last_stacked_uid)
	_draggable = state.has_prop(card, &"movable") and not card.has("open")

	var title: String = d.display_name if d != null and d.display_name != "" else String(card["id"])
	if card.get("state", {}).has("title"):
		title = card["state"]["title"]
	if int(card.get("n", 1)) > 1:
		title += " x%d" % int(card["n"])
	var tags: Array[String] = []
	if card.has("open"):
		tags.append("aberto")
	if card.get("state", {}).get("read", null) != null:
		tags.append("lida" if card["state"]["read"] else "nova")
	for st in state.statuses_of(card):
		tags.append(String(st))
	for p in TAG_PROPS:
		if state.has_prop(card, StringName(p)) and tags.size() < 2:
			tags.append(PROP_NAMES[p])
	var meta := ""
	var w := state.card_weight(card)
	if w > 0:
		meta = "%d g" % w
	if d != null and d.extra.has("capacity"):
		meta = "%d/%d g água" % [state.volume_of(card), int(d.extra["capacity"])]
	elif d != null and d.extra.has("m2"):
		meta = "%d m²" % state.card_area(card)
	_build(title, ", ".join(tags), meta)
	tooltip_text = _describe(card, d)


## Carta de destino do mapa (clicar viaja).
func setup_place(id: StringName, title: String, tag: String, minutes: int) -> void:
	place_id = id
	_apply_style("place", false)
	_build(title, tag, "%d min" % minutes if minutes > 0 else "0 min")


func _apply_style(kind: String, stacked: bool) -> void:
	var bg := UiStyle.CARD
	var line := UiStyle.CARD_LINE
	match kind:
		"fixed":
			bg = UiStyle.CARD_FIXED
			line = Color("#9fae92")
		"money":
			bg = UiStyle.CARD_MONEY
		"place":
			bg = UiStyle.CARD_PLACE
			line = Color("#92a6b2")
	# Destaque estático da soma (C4, W6): só cor e contorno.
	_style_normal = UiStyle.box(bg, UiStyle.ACCENT if stacked else line, 5, 3 if stacked else 1)
	_style_hint = UiStyle.box(bg, Color("#ffffff"), 5, 2)
	_style_recipe = UiStyle.box(bg, UiStyle.ACCENT, 5, 3)
	add_theme_stylebox_override("panel", _style_normal)
	custom_minimum_size = UiStyle.CARD_SIZE
	size = UiStyle.CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _build(title: String, tag: String, meta: String) -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var name_label := _label(title, 13, UiStyle.CARD_TEXT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)
	if tag != "":
		var tag_label := _label(tag, 10, UiStyle.CARD_MUTED)
		tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(tag_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	if meta != "":
		box.add_child(_label(meta, 11, UiStyle.CARD_MUTED))


static func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = false
		elif not _dragging:
			if place_id != &"":
				GameSession.state.travel_to(place_id)
			else:
				GameSession.state.select_card(uid)


# --- Arrastar e soltar ------------------------------------------------------

func _get_drag_data(_at: Vector2) -> Variant:
	if not _draggable:
		return null
	_dragging = true
	# A carta inteira acompanha o mouse, centrada nele, como no arrastar do navegador.
	var ghost := PanelContainer.new()
	ghost.add_theme_stylebox_override("panel", _style_normal)
	ghost.custom_minimum_size = UiStyle.CARD_SIZE
	ghost.size = UiStyle.CARD_SIZE
	ghost.position = -UiStyle.CARD_SIZE / 2.0
	ghost.modulate.a = 0.9
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var copy := _label(_title_text(), 13, UiStyle.CARD_TEXT)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(copy)
	ghost.add_child(pad)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ghost)
	set_drag_preview(holder)
	return {"uid": uid}


func _title_text() -> String:
	var first := get_child(0).get_child(0).get_child(0) as Label
	return first.text if first != null else ""


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			var data = get_viewport().gui_get_drag_data()
			if data is Dictionary and int(data.get("uid", -1)) == uid:
				modulate.a = 0.35 # a carta de origem fica apagada enquanto arrasta
		NOTIFICATION_DRAG_END:
			modulate.a = 1.0
			_hint_cache.clear()
			_set_hint("")
		NOTIFICATION_MOUSE_EXIT:
			_set_hint("")


func _set_hint(kind: String) -> void:
	if _style_normal == null:
		return
	var s: StyleBoxFlat = _style_normal
	if kind == "recipe":
		s = _style_recipe
	elif kind == "move":
		s = _style_hint
	if get_theme_stylebox("panel") != s:
		add_theme_stylebox_override("panel", s)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if place_id != &"" or not (data is Dictionary) or not data.has("uid") or int(data["uid"]) == uid:
		return false
	var dragged := int(data["uid"])
	if not _hint_cache.has(dragged):
		_hint_cache[dragged] = "recipe" if not GameSession.state.recipe_preview(dragged, uid).is_empty() else "move"
	_set_hint(_hint_cache[dragged]) # contorno amarelo: vai executar uma receita
	return true


func _drop_data(_at: Vector2, data: Variant) -> void:
	_set_hint("")
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


## Propriedades da carta em texto, no tooltip (US-3.1).
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
