class_name Vehicles
extends RefCounted
## Veículos (Q3, Q5 a Q9, L8). O veículo é uma carta com a propriedade
## "vehicle" e, por ser também um storage, tem depósito próprio (Q6, Q7): o
## que está no depósito só vai junto se for carregado, e para usá-lo é preciso
## descarregar. Para viajar com ele, a carta fica na mão (AR9).
##
## extra["vehicle"] = {travel_mult, fuel: bool, fuel_per_trip}. Os números
## são provisórios (Z7). Combustível é um só (Q9), guardado em state["fuel"].

const MAX_FUEL := 100
const FUEL := &"combustivel"


static func rule(state: GameState, card: Dictionary) -> Dictionary:
	var d := state.def_of(card)
	return d.extra.get("vehicle", {}) if d != null else {}


static func fuel_of(card: Dictionary) -> int:
	return int(card.get("state", {}).get("fuel", 0))


## Veículos na mão que conseguem fazer a viagem (os motorizados precisam de
## combustível).
static func usable(state: GameState) -> Array:
	var out := []
	for c in state.hand:
		if not state.has_prop(c, &"vehicle"):
			continue
		var r := rule(state, c)
		if r.get("fuel", false) and fuel_of(c) < int(r.get("fuel_per_trip", 1)):
			continue
		out.append(c)
	return out


## O veículo mais rápido que serve agora, ou {}.
static func best(state: GameState) -> Dictionary:
	var pick: Dictionary = {}
	for c in usable(state):
		if pick.is_empty() or float(rule(state, c).get("travel_mult", 1.0)) < float(rule(state, pick).get("travel_mult", 1.0)):
			pick = c
	return pick


## Minutos de uma viagem de `base` minutos a pé, e gasta o combustível.
## Sem veículo, é o tempo a pé. `commit` falso só calcula.
static func trip_minutes(state: GameState, base: int, commit: bool) -> int:
	if base <= 0:
		return base
	var v := best(state)
	if v.is_empty():
		return base
	var r := rule(state, v)
	if commit and r.get("fuel", false):
		var st: Dictionary = v["state"].duplicate(true)
		st["fuel"] = fuel_of(v) - int(r.get("fuel_per_trip", 1))
		v["state"] = st
	return maxi(1, ceili(base * float(r.get("travel_mult", 1.0))))


## Há um veículo utilizável com o jogador? A cidade grande exige (Q3).
static func has_usable(state: GameState) -> bool:
	return not best(state).is_empty()
