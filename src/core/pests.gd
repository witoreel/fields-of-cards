class_name Pests
extends RefCounted
## Pets, pragas e ajudantes (Y1 a Y3). Na virada do dia, com chance sorteada
## pelo RNG com seed (Z4), uma raposa ataca galinhas e ovos e ratos estragam
## plantações. Cachorro (Y1) protege contra raposa e gato contra ratos, em
## qualquer local da fazenda. Chances e preços são provisórios (Z7).

const FOX_CHANCE := 0.25
const RAT_CHANCE := 0.25
const FOX_KILLS := 1
const EGG_LOSS := 3
const RAT_SPOIL := 2 # m² de plantio estragados
const HELPER_TASKS := ["regar"]
## Ervas daninhas (O1): chance por noite, em cada local da fazenda com terra
## arada ou plantio, de nascerem 1 a 3 m² de erva. Com erva no local, o plantio
## não cresce na noite (provisório).
const WEED_CHANCE := 0.3
const WEED := &"erva_daninha"


static func has_pet(state: GameState, prop: StringName) -> bool:
	for loc in state.farm_locations():
		for c in state.cards[String(loc)]:
			if state.has_prop(c, prop):
				return true
	return false


## Raposa: come ovos e uma galinha em cada local com animais.
static func fox_attack(state: GameState) -> int:
	var lost := 0
	for loc in state.farm_locations():
		var list: Array = state.cards[String(loc)]
		var hens: Array = list.filter(func(c: Dictionary) -> bool: return c["id"] == "galinha")
		if hens.is_empty():
			continue
		for i in mini(FOX_KILLS, hens.size()):
			list.erase(hens[i])
			lost += 1
		for c in list:
			if c["id"] == "ovo":
				c["n"] = maxi(0, int(c["n"]) - EGG_LOSS)
		list.assign(list.filter(func(c: Dictionary) -> bool: return not (c["id"] == "ovo" and int(c["n"]) <= 0)))
	return lost


## Rato: estraga m² de plantio (terra semeada, broto ou pronta vira terra arada).
static func rat_attack(state: GameState) -> int:
	var spoiled := 0
	for loc in state.farm_locations():
		var list: Array = state.cards[String(loc)]
		for c in list.duplicate():
			if not ["terra_semeada", "terra_broto", "terra_pronta"].has(c["id"]):
				continue
			var n := mini(int(c["n"]), RAT_SPOIL - spoiled)
			if n <= 0:
				break
			c["n"] = int(c["n"]) - n
			spoiled += n
			state.spawn_into(list, &"terra_arada", n)
		list.assign(list.filter(func(c: Dictionary) -> bool: return int(c["n"]) > 0))
		state.restack(list)
	return spoiled


static func weeds_at(state: GameState, loc: StringName) -> int:
	var n := 0
	for c in state.cards[String(loc)]:
		if c["id"] == String(WEED):
			n += int(c["n"])
	return n


static func _spawn_weeds(state: GameState) -> void:
	for loc in state.farm_locations():
		var list: Array = state.cards[String(loc)]
		var tilled := list.any(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("terra_") and c["id"] != "terra_bruta")
		if tilled and state.rng.randf() < WEED_CHANCE:
			var n := mini(state.rng.randi_range(1, 3), maxi(0, state.farm_area_free()))
			if n > 0:
				state.spawn_into(list, WEED, n)
				state.last_events.append("weeds:%d" % n)


static func on_day_end(state: GameState) -> void:
	if not state.pests_enabled:
		return
	_spawn_weeds(state)
	if not has_pet(state, &"dog") and state.rng.randf() < FOX_CHANCE:
		state.last_events.append("fox:%d" % fox_attack(state))
	if not has_pet(state, &"cat") and state.rng.randf() < RAT_CHANCE:
		state.last_events.append("rats:%d" % rat_attack(state))


## Ajudantes (Y3): na virada do dia, antes do crescimento, cada um rega até
## `m2_per_day` m² de plantio se o salário for pago. Os melhores custam mais e rendem mais (menos
## minutos de rega por m², aqui traduzido em quantos m² regam por dia).
static func run_helpers(state: GameState) -> void:
	for loc in state.farm_locations():
		for h in state.cards[String(loc)].duplicate():
			if not state.has_prop(h, &"helper"):
				continue
			var rule: Dictionary = state.def_of(h).extra.get("helper", {})
			if not Economy.spend(state, int(rule.get("wage", 0))):
				continue # sem pagar o ajudante não trabalha
			Machines.water(state, loc, int(rule.get("m2_per_day", 4)))
