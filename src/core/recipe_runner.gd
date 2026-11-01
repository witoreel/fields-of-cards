class_name RecipeRunner
extends RefCounted
## Execução de uma receita sobre o GameState (C2, C3). Separada do estado
## porque os multiplicadores, o desgaste e o tempo variável passam por aqui.

## Quantas unidades da receita cabem agora (V1): limitadas pelo que se consome,
## pela água, pelos m² livres da fazenda e pelo que resta do dia. Pelo menos 1.
static func max_units(state: GameState, r: RecipeDef, a: Dictionary, b: Dictionary) -> int:
	if not r.variable:
		return 1
	var most := 1000
	if r.a_use > 0:
		most = mini(most, int(a["n"]) / r.a_use)
	if r.b_use > 0:
		most = mini(most, int(b["n"]) / r.b_use)
	var water_per := r.a_volume_per_b * int(b.get("n", 1))
	if water_per > 0:
		most = mini(most, state.volume_of(a) / water_per)
	if state.root_of(state.current_location) == &"fazenda":
		var delta := _area_delta(state, r, a, b, 1)
		if delta > 0:
			most = mini(most, state.farm_area_free() / delta)
	var per_unit := maxi(1, ceili(r.minutes * Wear.time_factor(state, a)))
	var left := GameState.MINUTES_PER_DAY - state.minute_of_day()
	most = mini(most, maxi(1, left / per_unit))
	return maxi(1, most)


## Unidades que cabem em `minutes` minutos (o slider escolhe minutos).
static func units_for_minutes(r: RecipeDef, minutes: int) -> int:
	if not r.variable or r.minutes <= 0:
		return 1
	return maxi(1, minutes / r.minutes)


static func _area_delta(state: GameState, r: RecipeDef, a: Dictionary, b: Dictionary, units: int) -> int:
	var delta := 0
	for res in r.results:
		delta += int(state.catalog.get_def(StringName(res["id"])).extra.get("m2", 0)) * int(res.get("n", 1)) * units
	if r.a_use > 0:
		delta -= state.card_area(a) / int(a["n"]) * r.a_use * units
	if r.b_use > 0:
		delta -= state.card_area(b) / int(b["n"]) * r.b_use * units
	return delta


static func run(state: GameState, r: RecipeDef, a: Dictionary, b: Dictionary, area_b: StringName, units: int = 1) -> bool:
	units = clampi(units, 1, max_units(state, r, a, b)) if r.variable else 1
	if (r.a_use > 0 and int(a["n"]) < r.a_use * units) or (r.b_use > 0 and int(b["n"]) < r.b_use * units):
		return false
	# Ocupar m² além do limite da fazenda não é permitido (L7). Conta o saldo
	# entre o que a receita cria e o que consome.
	if state.root_of(state.current_location) == &"fazenda":
		if _area_delta(state, r, a, b, units) > state.farm_area_free():
			return false
	var water_needed := r.a_volume_per_b * int(b.get("n", 1)) * units
	if water_needed > 0:
		if state.volume_of(a) < water_needed:
			return false
		a["state"] = a.get("state", {}).duplicate()
		a["state"]["volume"] = state.volume_of(a) - water_needed
	var factor := Wear.time_factor(state, a)
	# Estados da ferramenta e do alvo que a receita muda (S1, G1, G4).
	Wear.apply_use(state, a, r.a_wear * units, r.a_edge_wear * units)
	for st in r.a_status_remove:
		state.remove_status(a, st)
	for st in r.a_status_add:
		state.add_status(a, st)
	for st in r.b_status_remove:
		state.remove_status(b, st)
	for st in r.b_status_add:
		state.add_status(b, st)
	state.restack(state.area_cards(area_b)) # status mudam a identidade (S1)
	if r.a_use > 0:
		_consume(state, a, r.a_use * units)
	if r.b_use > 0:
		_consume(state, b, r.b_use * units)
	if not r.set_state_b.is_empty() and r.b_use == 0:
		var st: Dictionary = b.get("state", {}).duplicate()
		st.merge(r.set_state_b, true)
		b["state"] = st
		# A carta mudou de identidade: pode precisar somar ou separar.
		state.restack(state.area_cards(area_b))
	for res in r.results:
		state.spawn(StringName(res["id"]), area_b, int(res.get("n", 1)) * units)
	state.advance_time(ceili(r.minutes * units * factor)) # T1, mais lento com a ferramenta gasta (G1)
	state.areas_changed.emit()
	return true


static func _consume(state: GameState, card: Dictionary, amount: int) -> void:
	card["n"] = int(card["n"]) - amount
	if card["n"] <= 0:
		var l := state.find_card(int(card["uid"]))
		if not l.is_empty():
			state.area_cards(l["area"]).remove_at(l["index"])
