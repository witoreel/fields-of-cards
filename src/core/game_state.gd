class_name GameState
extends RefCounted
## Estado do jogo (SV1). Motor puro: sem Node, cena ou UI (Z1).
## Cada carta é um Dictionary de dados ({uid, id, n, ...}), para as
## propriedades crescerem sem reescrever (Z8). A ordem de cada lista é
## parte do estado (Z3).
##
## Áreas (AR1): HAND (mão), BACKPACK (mochila), STORAGE (storage aberto),
## LOCATION (cartas do local atual) e STAGE (o chão do local atual).

const FORMAT_VERSION := 2
const START_LOCATION := &"fazenda"

const HAND := &"hand"
const BACKPACK := &"backpack"
const STORAGE := &"storage"
const LOCATION := &"location"
const STAGE := &"stage"
const AREAS: Array[StringName] = [HAND, BACKPACK, STORAGE, LOCATION, STAGE]

## Locais do jogo (L4). Conteúdo novo é dado.
const LOCATION_NAMES := {
	&"fazenda": "Fazenda",
	&"floresta": "Floresta",
	&"cidade": "Cidade",
}

## Emitido ao chegar a um local (SV2 liga o autosave a ele).
signal arrived(location_id: StringName)
## Emitido quando cartas mudam de lugar ou de ordem, ou áreas abrem/fecham.
signal areas_changed
## Emitido quando uma carta se soma a outra igual (C4). A interface usa para
## um destaque estático (W6).
signal stacked(target_uid: int)

var current_location: StringName = START_LOCATION
## location_id (String) -> Array[Dictionary] de cartas, na ordem.
var cards: Dictionary = {}
## Chão de cada local (String -> Array).
var stages: Dictionary = {}
var hand: Array = []
var backpack: Array = []
## uid do storage (String) -> conteúdo.
var storages: Dictionary = {}
## Locais criados em jogo, como veículos (L8): id (String) -> {name, parent}.
var extra_locations: Dictionary = {}
var backpack_open := false
## uid do storage aberto, ou 0.
var open_storage_uid := 0
var next_uid := 1
## uid da última carta que recebeu uma soma, para o destaque (C4, W6).
var last_stacked_uid := 0
var rng := RandomNumberGenerator.new()
var catalog: CardCatalog = CardCatalog.default()


static func new_game(seed_value: int = 0) -> GameState:
	var s := GameState.new()
	s.rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	for id in LOCATION_NAMES:
		s.cards[String(id)] = []
		s.stages[String(id)] = []
	# A carta da mochila fica na mão (AR3, AR7).
	s.hand.append(s.new_card(&"mochila"))
	return s


# --- Locais ---------------------------------------------------------------

func has_location(id: StringName) -> bool:
	return LOCATION_NAMES.has(id) or extra_locations.has(String(id))


func location_name(id: StringName) -> String:
	if LOCATION_NAMES.has(id):
		return LOCATION_NAMES[id]
	return extra_locations[String(id)]["name"]


## Todos os ids de local, os fixos primeiro.
func location_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in LOCATION_NAMES:
		out.append(id)
	for id in extra_locations:
		out.append(StringName(id))
	return out


## Veículo é um local que tem uma localização dentro de outro local (L8).
func add_vehicle_location(id: StringName, display_name: String, parent: StringName) -> bool:
	if has_location(id) or not has_location(parent):
		return false
	extra_locations[String(id)] = {"name": display_name, "parent": String(parent)}
	cards[String(id)] = []
	stages[String(id)] = []
	return true


## Local onde o local está (L8), ou &"" se for um local de primeiro nível.
func parent_of(id: StringName) -> StringName:
	if extra_locations.has(String(id)):
		return StringName(extra_locations[String(id)]["parent"])
	return &""


## Comando: anda para um local. Devolve falso se o local não existe.
## O tempo gasto (T1) ainda é zero, porque não há relógio.
func travel_to(id: StringName) -> bool:
	if not has_location(id):
		return false
	_close_storage_internal()
	current_location = id
	arrived.emit(id)
	areas_changed.emit()
	return true


## Cartas do local, na ordem. Devolve a própria lista (não copia).
func cards_at(id: StringName) -> Array:
	return cards[String(id)]


# --- Cartas ---------------------------------------------------------------

## Cria uma carta nova (com uid) sem colocá-la em área nenhuma.
func new_card(id: StringName, n: int = 1) -> Dictionary:
	var c := {"uid": next_uid, "id": String(id), "n": n}
	next_uid += 1
	return c


## Cria uma carta e a coloca numa área. Devolve a carta, ou {} se a área
## está fechada ou a definição não existe.
func spawn(id: StringName, area: StringName, n: int = 1) -> Dictionary:
	if not catalog.has_def(id) or not is_open(area):
		return {}
	var c := new_card(id, n)
	if catalog.get_def(id).props.has("storage"):
		storages[str(c["uid"])] = []
	var merged := _stack_into(area_cards(area), c)
	if merged.is_empty():
		area_cards(area).append(c)
	else:
		c = merged
	areas_changed.emit()
	return c


## Duas cartas se somam (C4) se são acumuláveis e iguais: mesmo id e mesmos
## dados extras (propriedades e buffs). Um estágio diferente é outra carta.
## Fica numa função só porque o critério ainda está em aberto.
func cards_match(a: Dictionary, b: Dictionary) -> bool:
	if a["id"] != b["id"] or not has_prop(a, &"stackable"):
		return false
	return a.get("props", []) == b.get("props", []) and a.get("buffs", []) == b.get("buffs", [])


## Soma `card` à primeira carta igual de `list`. Devolve a carta que recebeu
## a soma, ou {} se não havia igual (nada muda nesse caso).
func _stack_into(list: Array, card: Dictionary) -> Dictionary:
	for other in list:
		if int(other["uid"]) != int(card["uid"]) and cards_match(other, card):
			other["n"] = int(other["n"]) + int(card["n"])
			last_stacked_uid = int(other["uid"])
			stacked.emit(last_stacked_uid)
			return other
	return {}


func def_of(card: Dictionary) -> CardDef:
	return catalog.get_def(StringName(card["id"]))


## Propriedade da carta: vem da definição ou de "props" na própria carta (Z8).
func has_prop(card: Dictionary, prop: StringName) -> bool:
	var d := def_of(card)
	if d != null and d.props.has(prop):
		return true
	return (card.get("props", []) as Array).has(String(prop))


## Buffs e debuffs ficam na própria carta (C9). O formato é livre.
func add_buff(uid: int, buff: Dictionary) -> bool:
	var loc := find_card(uid)
	if loc.is_empty():
		return false
	var card: Dictionary = area_cards(loc["area"])[loc["index"]]
	if not card.has("buffs"):
		card["buffs"] = []
	card["buffs"].append(buff.duplicate(true))
	areas_changed.emit()
	return true


# --- Áreas ----------------------------------------------------------------

func is_open(area: StringName) -> bool:
	match area:
		HAND, STAGE:
			return true # a mão e o chão estão sempre disponíveis (AR5)
		BACKPACK:
			return backpack_open
		STORAGE:
			return open_storage_uid != 0
		LOCATION:
			return open_storage_uid == 0 # o storage aberto toma o lugar do local (AR4)
	return false


## Áreas abertas agora.
func open_areas() -> Array[StringName]:
	var out: Array[StringName] = []
	for a in AREAS:
		if is_open(a):
			out.append(a)
	return out


## Lista de cartas da área (a própria lista, não uma cópia). Vazia se fechada.
func area_cards(area: StringName) -> Array:
	match area:
		HAND:
			return hand
		BACKPACK:
			return backpack
		STORAGE:
			return storages.get(str(open_storage_uid), [])
		LOCATION:
			return cards[String(current_location)]
		STAGE:
			return stages[String(current_location)]
	return []


## Onde está a carta, entre as áreas abertas: {area, index} ou {}.
func find_card(uid: int) -> Dictionary:
	for a in open_areas():
		var list := area_cards(a)
		for i in list.size():
			if int(list[i]["uid"]) == uid:
				return {"area": a, "index": i}
	return {}


## Comando: move uma carta móvel para outra área aberta (AR6, C7, C8).
## `index` -1 põe no fim. Dentro da mesma área só reordena (C5).
func move_card(uid: int, to_area: StringName, index: int = -1) -> bool:
	var from := find_card(uid)
	if from.is_empty() or not is_open(to_area):
		return false
	last_stacked_uid = 0
	var src := area_cards(from["area"])
	var card: Dictionary = src[from["index"]]
	if from["area"] != to_area:
		if not has_prop(card, &"movable") or has_prop(card, &"fixed") or card.has("open"):
			return false
		if to_area == BACKPACK and has_prop(card, &"backpack"):
			return false
	var dst := area_cards(to_area)
	src.remove_at(from["index"])
	if from["area"] != to_area and not _stack_into(dst, card).is_empty():
		areas_changed.emit()
		return true
	if index < 0 or index > dst.size():
		index = dst.size()
	dst.insert(index, card)
	areas_changed.emit()
	return true


# --- Abrir e fechar -------------------------------------------------------

## Comando: seleciona uma carta. A mochila abre/fecha (AR3, AR8), um storage
## do local ou do chão abre (AR4) e o ícone de storage aberto na mão o fecha.
func select_card(uid: int) -> bool:
	var from := find_card(uid)
	if from.is_empty():
		return false
	var card: Dictionary = area_cards(from["area"])[from["index"]]
	if has_prop(card, &"backpack"):
		backpack_open = not backpack_open
		areas_changed.emit()
		return true
	if card.has("open"):
		_close_storage_internal()
		areas_changed.emit()
		return true
	if has_prop(card, &"storage") and (from["area"] == LOCATION or from["area"] == STAGE):
		_close_storage_internal()
		from = find_card(uid) # a posição pode ter mudado ao fechar o outro
		var list := area_cards(from["area"])
		var c: Dictionary = list[from["index"]]
		list.remove_at(from["index"])
		c["open"] = true
		c["open_from"] = {"area": String(from["area"]), "index": from["index"]}
		hand.append(c) # o ícone aberto vai para a mão (AR10)
		open_storage_uid = int(c["uid"])
		areas_changed.emit()
		return true
	return false


func _close_storage_internal() -> void:
	if open_storage_uid == 0:
		return
	for i in hand.size():
		if int(hand[i]["uid"]) == open_storage_uid:
			var c: Dictionary = hand[i]
			hand.remove_at(i)
			var origin: Dictionary = c.get("open_from", {})
			c.erase("open")
			c.erase("open_from")
			var area := StringName(origin.get("area", "location"))
			var list: Array = area_cards(area) if area == STAGE else cards[String(current_location)]
			list.insert(clampi(int(origin.get("index", list.size())), 0, list.size()), c)
			break
	open_storage_uid = 0


# --- Persistência ---------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": FORMAT_VERSION,
		"current_location": String(current_location),
		"cards": cards.duplicate(true),
		"stages": stages.duplicate(true),
		"hand": hand.duplicate(true),
		"backpack": backpack.duplicate(true),
		"storages": storages.duplicate(true),
		"extra_locations": extra_locations.duplicate(true),
		"backpack_open": backpack_open,
		"open_storage_uid": open_storage_uid,
		"next_uid": next_uid,
		# Inteiros de 64 bits viram texto: JSON só garante 53 bits.
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}


## Reconstrói a partir de dados. Devolve null se algo estiver errado (SV4).
## Aceita a versão 1 (sem mão, chão e storages).
static func from_dict(data: Variant) -> GameState:
	if not (data is Dictionary):
		return null
	var version := int(data.get("version", -1))
	if version != FORMAT_VERSION and version != 1:
		return null
	var s := GameState.new()
	var extras = data.get("extra_locations", {})
	if not (extras is Dictionary):
		return null
	for id in extras:
		var e = extras[id]
		if not (e is Dictionary) or not (e.get("name") is String) or not (e.get("parent") is String):
			return null
		s.extra_locations[String(id)] = {"name": e["name"], "parent": e["parent"]}
	var loc := StringName(str(data.get("current_location", "")))
	if not s.has_location(loc) or not (data.get("cards") is Dictionary):
		return null
	s.current_location = loc
	for id in s.location_ids():
		var cl = _read_list(data["cards"].get(String(id), []))
		var sl = _read_list((data.get("stages", {}) as Dictionary).get(String(id), []))
		if cl == null or sl == null:
			return null
		s.cards[String(id)] = cl
		s.stages[String(id)] = sl
	var h = _read_list(data.get("hand", []))
	var b = _read_list(data.get("backpack", []))
	if h == null or b == null or not (data.get("storages", {}) is Dictionary):
		return null
	s.hand = h
	s.backpack = b
	for k in data.get("storages", {}):
		var sl2 = _read_list(data["storages"][k])
		if sl2 == null:
			return null
		s.storages[String(k)] = sl2
	s.backpack_open = bool(data.get("backpack_open", false))
	s.open_storage_uid = int(data.get("open_storage_uid", 0))
	s.next_uid = int(data.get("next_uid", 1))
	if s.open_storage_uid != 0 and not s.storages.has(str(s.open_storage_uid)):
		return null
	var seed_text := str(data.get("rng_seed", ""))
	var state_text := str(data.get("rng_state", ""))
	if not seed_text.is_valid_int() or not state_text.is_valid_int():
		return null
	s.rng.seed = seed_text.to_int()
	s.rng.state = state_text.to_int()
	return s


## Copia e normaliza uma lista de cartas (JSON devolve números como float).
## Devolve null se algum item não for carta.
static func _read_list(raw: Variant) -> Variant:
	if not (raw is Array):
		return null
	var out := []
	for c in raw:
		if not (c is Dictionary):
			return null
		var card: Dictionary = c.duplicate(true)
		for key in ["uid", "n"]:
			if card.has(key):
				card[key] = int(card[key])
		if card.has("open_from"):
			card["open_from"]["index"] = int(card["open_from"].get("index", 0))
		out.append(card)
	return out
