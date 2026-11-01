class_name RecipeRunner
extends RefCounted
## Execução de uma receita sobre o GameState (C2, C3). Separada do estado
## porque os multiplicadores, o desgaste e o tempo variável passam por aqui.

static func run(state: GameState, r: RecipeDef, a: Dictionary, b: Dictionary, area_b: StringName) -> bool:
	if (r.a_use > 0 and int(a["n"]) < r.a_use) or (r.b_use > 0 and int(b["n"]) < r.b_use):
		return false
	# Ocupar m² além do limite da fazenda não é permitido (L7). Conta o saldo
	# entre o que a receita cria e o que consome.
	if state.root_of(state.current_location) == &"fazenda":
		var delta := 0
		for res in r.results:
			delta += int(state.catalog.get_def(StringName(res["id"])).extra.get("m2", 0)) * int(res.get("n", 1))
		if r.a_use > 0:
			delta -= state.card_area(a) / int(a["n"]) * r.a_use
		if r.b_use > 0:
			delta -= state.card_area(b) / int(b["n"]) * r.b_use
		if delta > state.farm_area_free():
			return false
	var water_needed := r.a_volume_per_b * int(b.get("n", 1))
	if water_needed > 0:
		if state.volume_of(a) < water_needed:
			return false
		a["state"] = a.get("state", {}).duplicate()
		a["state"]["volume"] = state.volume_of(a) - water_needed
	if r.a_use > 0:
		_consume(state, a, r.a_use)
	if r.b_use > 0:
		_consume(state, b, r.b_use)
	if not r.set_state_b.is_empty() and r.b_use == 0:
		var st: Dictionary = b.get("state", {}).duplicate()
		st.merge(r.set_state_b, true)
		b["state"] = st
		# A carta mudou de identidade: pode precisar somar ou separar.
		state.restack(state.area_cards(area_b))
	for res in r.results:
		state.spawn(StringName(res["id"]), area_b, int(res.get("n", 1)))
	state.advance_time(r.minutes) # T1
	state.areas_changed.emit()
	return true


static func _consume(state: GameState, card: Dictionary, amount: int) -> void:
	card["n"] = int(card["n"]) - amount
	if card["n"] <= 0:
		var l := state.find_card(int(card["uid"]))
		if not l.is_empty():
			state.area_cards(l["area"]).remove_at(l["index"])
