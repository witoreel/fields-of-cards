class_name Animals
extends RefCounted
## Animais (A1 a A6). Um animal é uma carta com a propriedade "animal" e
## medidores em state: food, clean, happy (0 a 100), mais contagens de dias.
## O ritmo é dado na definição: extra["animal"]. Os números são provisórios
## (T5, Z7): o ovo é de um por dia, como a regra T5 pede.
##
## extra["animal"] = {
##   food_per_day, clean_per_day, happy_per_day: quanto cada medidor cai por dia,
##   starve_days, sad_days: dias seguidos no zero até morrer (A3),
##   product: {id, min_wellness}: o que produz por dia se estiver bem (A4),
##   meat: {id, n}: o que dá no corte (A6),
##   grows_to, grow_points: filhote que vira adulto com ração de crescimento }

const MAX := 100
## Cada esterco no local aumenta a queda de limpeza (A2: limpar o celeiro).
const DUNG_CLEAN_PENALTY := 3
const DUNG_CAP := 5
const DUNG := &"esterco"


static func is_animal(state: GameState, card: Dictionary) -> bool:
	return state.has_prop(card, &"animal")


static func rule(state: GameState, card: Dictionary) -> Dictionary:
	var d := state.def_of(card)
	return d.extra.get("animal", {}) if d != null else {}


## Medidores iniciais de um animal novo.
static func init_card(state: GameState, card: Dictionary) -> void:
	if not is_animal(state, card) or card.get("state", {}).has("food"):
		return
	card["state"] = {"food": MAX, "clean": MAX, "happy": MAX, "hungry_days": 0, "sad_days": 0}


static func meter(card: Dictionary, key: String) -> int:
	return int(card.get("state", {}).get(key, 0))


## Quão bem o animal está, de 0 a 100 (A4).
static func wellness(card: Dictionary) -> int:
	return (meter(card, "food") + meter(card, "clean") + meter(card, "happy")) / 3


static func add_meter(card: Dictionary, key: String, amount: int) -> void:
	var st: Dictionary = card.get("state", {}).duplicate(true)
	var cap := MAX if key in ["food", "clean", "happy"] else 1000000
	st[key] = clampi(int(st.get(key, 0)) + amount, 0, cap)
	card["state"] = st


static func _count_dung(state: GameState, list: Array) -> int:
	var n := 0
	for c in list:
		if c["id"] == String(DUNG):
			n += int(c["n"])
	return mini(n, DUNG_CAP)


## Virada do dia: os medidores caem, o animal produz, cresce ou morre.
static func on_day_end(state: GameState) -> void:
	for loc in state.cards:
		var list: Array = state.cards[loc]
		var dung := _count_dung(state, list)
		var born: Array = []
		var animals := 0
		for card in list.duplicate():
			if not is_animal(state, card):
				continue
			animals += 1
			var r := rule(state, card)
			var st: Dictionary = card["state"].duplicate(true)
			var fed_before := int(st["food"]) > 0
			st["food"] = maxi(0, int(st["food"]) - int(r.get("food_per_day", 30)))
			st["clean"] = maxi(0, int(st["clean"]) - int(r.get("clean_per_day", 15)) - dung * DUNG_CLEAN_PENALTY)
			st["happy"] = maxi(0, int(st["happy"]) - int(r.get("happy_per_day", 10)))
			st["hungry_days"] = int(st["hungry_days"]) + 1 if st["food"] == 0 else 0
			st["sad_days"] = int(st["sad_days"]) + 1 if st["happy"] == 0 else 0
			card["state"] = st
			if int(st["hungry_days"]) >= int(r.get("starve_days", 3)) or int(st["sad_days"]) >= int(r.get("sad_days", 4)):
				list.erase(card) # morre (A3)
				continue
			if r.has("grows_to") and int(st.get("growth", 0)) >= int(r.get("grow_points", 2)):
				card["id"] = String(r["grows_to"])
				card["state"].erase("growth")
				continue
			var prod: Dictionary = r.get("product", {})
			if not prod.is_empty() and fed_before and wellness(card) >= int(prod.get("min_wellness", 50)):
				var n := 2 if int(st.get("boost", 0)) > 0 else 1 # ração de postura
				if st.has("boost"):
					card["state"] = card["state"].duplicate(true)
					card["state"].erase("boost")
				_put(state, list, StringName(prod["id"]), n)
		if animals > 0:
			_put(state, list, DUNG, animals) # sujeira do dia
		state.restack(list)


static func _put(state: GameState, list: Array, id: StringName, n: int) -> void:
	var c := state.new_card(id, n)
	list.append(c)


## Comando: manda o animal para o corte (A6). Gordura (ração de engorda) rende
## mais carne.
static func slaughter(state: GameState, uid: int) -> bool:
	var l := state.find_card(uid)
	if l.is_empty():
		return false
	var list := state.area_cards(l["area"])
	var card: Dictionary = list[l["index"]]
	if not is_animal(state, card):
		return false
	var meat: Dictionary = rule(state, card).get("meat", {})
	if meat.is_empty():
		return false
	var n := int(meat.get("n", 1)) + meat_bonus(card)
	list.remove_at(l["index"])
	state.spawn(StringName(meat["id"]), GameState.STAGE, n)
	state.advance_time(20)
	state.areas_changed.emit()
	return true


static func meat_bonus(card: Dictionary) -> int:
	return meter(card, "fat") / 50
