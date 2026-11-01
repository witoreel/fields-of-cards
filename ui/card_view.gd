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
