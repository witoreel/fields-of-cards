class_name GameState
extends RefCounted
## Estado do jogo (SV1). Motor puro: sem Node, cena ou UI (Z1).
## Cada carta é um Dictionary de dados ({uid, id, n, ...}), para as
## propriedades crescerem sem reescrever (Z8). A ordem de cada lista é
## parte do estado (Z3).
##
## Áreas (AR1): HAND (mão), BACKPACK (mochila), STORAGE (storage aberto),
## LOCATION (cartas do local atual) e STAGE (o chão do local atual).

const FORMAT_VERSION := 3
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
	&"casa": "Casa",
	&"ferragem": "Ferragem",
	&"feira": "Feira",
}
## Local onde cada local fica (L4, L6, L8). Sem entrada = primeiro nível.
## A casa fica dentro da fazenda; as lojas e a feira, dentro da cidade.
const LOCATION_PARENTS := {
	&"casa": &"fazenda",
	&"ferragem": &"cidade",
	&"feira": &"cidade",
}

## Emitido ao chegar a um local (SV2 liga o autosave a ele).
signal arrived(location_id: StringName)
## Relógio (T2, T3, T7). `from_min` e `to_min` são minutos absolutos.
signal time_advanced(from_min: int, to_min: int)
## À meia-noite o dia termina (T7). `day` é o número do dia que acabou.
signal day_ended(day: int)
## O jogador acordou às 06:00 (T8) no dia `day`.
signal woke_up(day: int)
## Um evento agendado venceu (T3). Sistemas (crescimento, contas) ouvem isto.
signal event_due(kind: String, data: Dictionary)
## Emitido quando cartas mudam de lugar ou de ordem, ou áreas abrem/fecham.
signal areas_changed
## Emitido quando uma carta se soma a outra igual (C4). A interface usa para
## um destaque estático (W6).
signal stacked(target_uid: int)

const MINUTES_PER_DAY := 1440
const WAKE_MINUTE := 360 # 06:00 (T8)
const TIRED_MINUTE := 1320 # 22:00 (T9)

## Minutos desde o início do dia 1, 00:00. O jogo começa às 06:00 do dia 1.
var minutes := WAKE_MINUTE
## Buffs e debuffs do jogador, como na carta (C9). Formato livre.
var player_buffs: Array = []
## Eventos agendados (T3): {at, kind, data}, guardados no save.
var scheduled: Array = []

## Custo de viagem em minutos entre locais de primeiro nível. Valores
## provisórios, para balancear depois (T1). Dentro do mesmo pai custa 0.
const TRAVEL_MINUTES := {
	&"fazenda|floresta": 30,
	&"fazenda|cidade": 60,
	&"floresta|cidade": 90,
}

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
var recipes: RecipeCatalog = RecipeCatalog.default()


func _init() -> void:
	day_ended.connect(func(_day: int) -> void: Farming.on_day_end(self))


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


## Cria um local dentro de outro: veículo (L8) ou construído com nome (L6).
func add_location(id: StringName, display_name: String, parent: StringName) -> bool:
	if has_location(id) or not has_location(parent):
		return false
	extra_locations[String(id)] = {"name": display_name, "parent": String(parent)}
	cards[String(id)] = []
	stages[String(id)] = []
	return true


## Local onde o local está (L8), ou &"" se for um local de primeiro nível.
func parent_of(id: StringName) -> StringName:
	if LOCATION_PARENTS.has(id):
		return LOCATION_PARENTS[id]
	if extra_locations.has(String(id)):
		return StringName(extra_locations[String(id)]["parent"])
	return &""


## Locais que ficam dentro de `id`.
func children_of(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in location_ids():
		if parent_of(c) == id:
			out.append(c)
	return out


## Para onde dá para ir daqui (US-4.1, US-4.4): os locais de primeiro nível,
## o que fica dentro do local atual, o que divide o mesmo pai e o próprio pai.
## Escolher a ferragem estando na cidade não exige voltar ao mapa.
func destinations() -> Array[StringName]:
	var out: Array[StringName] = []
	var parent := parent_of(current_location)
	for id in location_ids():
		if id == current_location:
			continue
		var p := parent_of(id)
		if p == &"" or p == current_location or id == parent or (parent != &"" and p == parent):
			out.append(id)
	return out


## Primeiro nível de um local (a cidade, para a ferragem).
func root_of(id: StringName) -> StringName:
	while parent_of(id) != &"":
		id = parent_of(id)
	return id


## Minutos para ir de um local a outro (T1). Entre locais da mesma raiz é
## zero; entre raízes, vem da tabela TRAVEL_MINUTES (simétrica).
func travel_minutes(from: StringName, to: StringName) -> int:
	var a := root_of(from)
	var b := root_of(to)
	if a == b:
		return 0
	var key := StringName("%s|%s" % [a, b])
	var rkey := StringName("%s|%s" % [b, a])
	return int(TRAVEL_MINUTES.get(key, TRAVEL_MINUTES.get(rkey, 0)))


# --- Relógio --------------------------------------------------------------

func day_number() -> int:
	return minutes / MINUTES_PER_DAY + 1


func minute_of_day() -> int:
	return minutes % MINUTES_PER_DAY


## "Dia 1, 06:00".
func clock_text() -> String:
	var m := minute_of_day()
	return "Dia %d, %02d:%02d" % [day_number(), m / 60, m % 60]


## Comando: avança o relógio (T1, T3). Se a meia-noite for atingida, o dia
## termina de forma inevitável (T7): o jogador dorme e acorda às 06:00, e o
## que sobrar da ação se perde.
func advance_time(amount: int) -> void:
	if amount <= 0:
		return
	var to_midnight := (minutes / MINUTES_PER_DAY + 1) * MINUTES_PER_DAY - minutes
	if amount < to_midnight:
		_step(amount)
		return
	_step(to_midnight)
	_end_day_and_wake(true)


## Comando: dorme até as 06:00 (T4, T8). Quem dormiu depois das 22:00 acorda
## cansado (T9). Dormir é possível a qualquer hora (aberto: antes das 22:00).
func sleep() -> void:
	var m := minute_of_day()
	var tired := m >= TIRED_MINUTE
	if m < WAKE_MINUTE:
		_step(WAKE_MINUTE - m)
		_wake(tired)
		return
	_step(MINUTES_PER_DAY - m)
	_end_day_and_wake(tired)


func _end_day_and_wake(tired: bool) -> void:
	day_ended.emit(day_number() - 1)
	_step(WAKE_MINUTE)
	_wake(tired)


func _wake(tired: bool) -> void:
	player_buffs = player_buffs.filter(func(b: Dictionary) -> bool: return b.get("id") != "cansado")
	if tired:
		# O efeito do "cansado" está em aberto; por ora é só o marcador.
		player_buffs.append({"id": "cansado", "kind": "debuff"})
	woke_up.emit(day_number())


func is_tired() -> bool:
	return player_buffs.any(func(b: Dictionary) -> bool: return b.get("id") == "cansado")


func _step(amount: int) -> void:
	var from := minutes
	minutes += amount
	_fire_due_events()
	time_advanced.emit(from, minutes)
	areas_changed.emit()


## Agenda um evento para um minuto absoluto (T3).
func schedule(at: int, kind: String, data: Dictionary = {}) -> void:
	scheduled.append({"at": at, "kind": kind, "data": data.duplicate(true)})


func _fire_due_events() -> void:
	var due: Array = scheduled.filter(func(e: Dictionary) -> bool: return e["at"] <= minutes)
	if due.is_empty():
		return
	scheduled = scheduled.filter(func(e: Dictionary) -> bool: return e["at"] > minutes)
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	for e in due:
		event_due.emit(e["kind"], e["data"])


## Comando: anda para um local. Devolve falso se o local não existe.
## O tempo gasto (T1) ainda é zero, porque não há relógio.
func travel_to(id: StringName) -> bool:
	if not has_location(id):
		return false
	_close_storage_internal()
	# A viagem gasta minutos (T1). Se a meia-noite cair no caminho, o dia
	# acaba e o jogador acorda às 06:00 já no destino.
	advance_time(travel_minutes(current_location, id))
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
	return _identity(a) == _identity(b)


## O que distingue uma carta além de uid e quantidade: id, propriedades,
## buffs e estado (um estágio de plantio diferente é outra carta).
func _identity(c: Dictionary) -> Dictionary:
	var d := c.duplicate()
	d.erase("uid")
	d.erase("n")
	return d


## Junta as cartas iguais de uma lista, mantendo a ordem da primeira de cada.
func restack(list: Array) -> void:
	var out: Array = []
	for c in list:
		var merged := false
		for o in out:
			if cards_match(o, c):
				o["n"] = int(o["n"]) + int(c["n"])
				merged = true
				break
		if not merged:
			out.append(c)
	list.assign(out)


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


# --- Receitas -------------------------------------------------------------

## Comando: arrasta a carta `a_uid` sobre `b_uid` (C2). Se existe receita para
## o par (em qualquer ordem), executa; senão, nada muda. Devolve se executou.
func apply_recipe(a_uid: int, b_uid: int) -> bool:
	var la := find_card(a_uid)
	var lb := find_card(b_uid)
	if la.is_empty() or lb.is_empty() or a_uid == b_uid:
		return false
	var ca: Dictionary = area_cards(la["area"])[la["index"]]
	var cb: Dictionary = area_cards(lb["area"])[lb["index"]]
	var r := recipes.find(StringName(ca["id"]), StringName(cb["id"]))
	if r != null:
		return _run(r, ca, cb, lb["area"])
	r = recipes.find(StringName(cb["id"]), StringName(ca["id"]))
	if r != null:
		return _run(r, cb, ca, la["area"])
	return false


## Comando: usa uma carta sozinha (receita de clique, como colher).
func use_card(uid: int) -> bool:
	var l := find_card(uid)
	if l.is_empty():
		return false
	var card: Dictionary = area_cards(l["area"])[l["index"]]
	var r := recipes.find(&"", StringName(card["id"]))
	return r != null and _run(r, {}, card, l["area"])


func _run(r: RecipeDef, a: Dictionary, b: Dictionary, area_b: StringName) -> bool:
	if (r.a_use > 0 and int(a["n"]) < r.a_use) or (r.b_use > 0 and int(b["n"]) < r.b_use):
		return false
	if r.a_use > 0:
		_consume(a, r.a_use)
	if r.b_use > 0:
		_consume(b, r.b_use)
	if not r.set_state_b.is_empty() and r.b_use == 0:
		var st: Dictionary = b.get("state", {}).duplicate()
		st.merge(r.set_state_b, true)
		b["state"] = st
		# A carta mudou de identidade: pode precisar somar ou separar.
		restack(area_cards(area_b))
	for res in r.results:
		spawn(StringName(res["id"]), area_b, int(res.get("n", 1)))
	advance_time(r.minutes) # T1
	areas_changed.emit()
	return true


func _consume(card: Dictionary, amount: int) -> void:
	card["n"] = int(card["n"]) - amount
	if card["n"] <= 0:
		var l := find_card(int(card["uid"]))
		if not l.is_empty():
			area_cards(l["area"]).remove_at(l["index"])


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
	return use_card(uid)


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
		"minutes": minutes,
		"player_buffs": player_buffs.duplicate(true),
		"scheduled": scheduled.duplicate(true),
		# Inteiros de 64 bits viram texto: JSON só garante 53 bits.
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}


## Reconstrói a partir de dados. Devolve null se algo estiver errado (SV4).
## Aceita versões antigas, preenchendo o que faltava.
static func from_dict(data: Variant) -> GameState:
	if not (data is Dictionary):
		return null
	var version := int(data.get("version", -1))
	if version < 1 or version > FORMAT_VERSION:
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
	s.minutes = int(data.get("minutes", WAKE_MINUTE))
	var pb = data.get("player_buffs", [])
	var sc = data.get("scheduled", [])
	if not (pb is Array) or not (sc is Array):
		return null
	s.player_buffs = pb.duplicate(true)
	for e in sc:
		if not (e is Dictionary) or not e.has("at") or not (e.get("kind") is String):
			return null
		s.scheduled.append({"at": int(e["at"]), "kind": e["kind"], "data": e.get("data", {})})
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
