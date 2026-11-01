class_name Machines
extends RefCounted
## Maquinário (X1 a X8). Uma máquina é uma ferramenta (propriedade "tool")
## com a propriedade "machine": tem qualidade maior (rende mais, V3), faz o
## trabalho em menos tempo e gasta combustível (Q9), o mesmo dos veículos.
##
## extra["machine"] = {fuel_per_use, time_mult}. Valores provisórios (Z7).

const WATER_FUEL := 2 # combustível da bomba por noite de irrigação


static func rule(state: GameState, card: Dictionary) -> Dictionary:
	var d := state.def_of(card)
	return d.extra.get("machine", {}) if d != null else {}


static func is_machine(state: GameState, card: Dictionary) -> bool:
	return not card.is_empty() and state.has_prop(card, &"machine")


static func fuel_per_use(state: GameState, card: Dictionary) -> int:
	return int(rule(state, card).get("fuel_per_use", 1))


## A máquina é mais rápida que a ferramenta comum.
static func time_factor(state: GameState, card: Dictionary) -> float:
	return float(rule(state, card).get("time_mult", 1.0)) if is_machine(state, card) else 1.0


static func spend_fuel(card: Dictionary, amount: int) -> void:
	var st: Dictionary = card.get("state", {}).duplicate(true)
	st["fuel"] = int(st.get("fuel", 0)) - amount
	card["state"] = st


## Rega até `m2` m² de plantio de um local, separando a pilha se preciso.
## Devolve quantos m² foram regados.
static func water(state: GameState, loc: StringName, m2: int) -> int:
	var list: Array = state.cards[String(loc)]
	var done := 0
	for c in list.duplicate():
		if done >= m2:
			break
		if not (c["id"] in ["terra_semeada", "terra_broto"]) or state.has_status(c, "regada") or state.has_status(c, "encharcada"):
			continue
		var take := mini(int(c["n"]), m2 - done)
		if take < int(c["n"]):
			var part := state.new_card(StringName(c["id"]), take)
			part["state"] = c.get("state", {}).duplicate()
			c["n"] = int(c["n"]) - take
			list.append(part)
			c = part
		state.add_status(c, "regada")
		done += take
	state.restack(list)
	return done


static func has_well(state: GameState) -> bool:
	for id in state.extra_locations:
		if state.extra_locations[id].get("kind") == "poco" and state.root_of(StringName(id)) == &"fazenda":
			return true
	return false


## Irrigação (X7): numa noite, a bomba d'água do local, com combustível e com
## um poço na fazenda, rega o plantio que a irrigação alcança.
static func on_day_start_of_night(state: GameState) -> void:
	if not has_well(state):
		return
	for loc in state.farm_locations():
		var pipes: Array = state.cards[String(loc)].filter(func(c: Dictionary) -> bool: return state.has_prop(c, &"irrigation"))
		if pipes.is_empty():
			continue
		for pump in state.cards[String(loc)]:
			if state.has_prop(pump, &"pump") and int(pump.get("state", {}).get("fuel", 0)) >= WATER_FUEL:
				var reach := int(state.def_of(pipes[0]).extra.get("irrigation", {}).get("m2_per_day", 20))
				if water(state, loc, reach) > 0:
					spend_fuel(pump, WATER_FUEL)
				break
