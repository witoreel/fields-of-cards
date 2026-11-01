class_name Farming
extends RefCounted
## Crescimento das plantas (R4, R9). Roda na virada do dia (T7).
## O ritmo é dado na definição da carta: extra["grow"] = {days, to} (T5).
## Cada estágio é uma carta diferente; a que não foi regada fica congelada.


static func on_day_end(state: GameState) -> void:
	for loc in state.cards:
		_grow_list(state, state.cards[loc])
	for loc in state.stages:
		_grow_list(state, state.stages[loc])


static func _grow_list(state: GameState, list: Array) -> void:
	var changed := false
	for card in list:
		var d := state.def_of(card)
		if d == null or not d.extra.has("grow"):
			continue
		var st: Dictionary = card.get("state", {})
		if not st.get("watered", false):
			continue # R9: sem rega, sem crescimento
		var grown := int(st.get("grown", 0)) + 1
		var rule: Dictionary = d.extra["grow"]
		if grown >= int(rule["days"]):
			card["id"] = String(rule["to"])
			card.erase("state")
		else:
			card["state"] = {"grown": grown}
		changed = true
	if changed:
		state.restack(list)
