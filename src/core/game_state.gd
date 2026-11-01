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
	&"vila": "Vila",
	&"cidade_grande": "Cidade grande",
	&"casa": "Casa",
	&"acude": "Açude",
	&"ferragem": "Ferragem",
	&"feira": "Feira",
}
## Local onde cada local fica (L4, L6, L8). Sem entrada = primeiro nível.
## A casa fica dentro da fazenda; as lojas e a feira, dentro da cidade.
const LOCATION_PARENTS := {
	&"casa": &"fazenda",
	&"acude": &"fazenda",
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
## A falência encerrou o jogo (F1, D7).
signal game_over(reason: String)
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
## Correspondência que ainda vai chegar (T6): {day, title, text, ...}.
var mail_queue: Array = []
## Promoções ativas (M5): {item, percent, until_day}.
var promotions: Array = []
## Última carta lida, para a interface mostrar o texto: {title, text}.
var last_read: Dictionary = {}
## Locais e itens liberados (U1). Só valem os que estão em `gated`.
var unlocked: Array = []
## Ids que começam bloqueados (U1, U2). Vazio = nada bloqueado.
var gated: Array = []
## Cartas guardadas no achados e perdidos (H4, H5), com since_day.
var lost_and_found: Array = []
## Pragas sorteadas na virada do dia (Y2). Ligadas só em jogo com estado
## inicial; testes de outras regras usam jogo em branco, sem sorteios.
var pests_enabled := false
## Ocorrências da última virada de dia, para a interface avisar ("fox:1").
var last_events: Array = []
## Pontos de skill por atividade (K1): {"lavoura": 12}.
var skills: Dictionary = {}
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
	&"fazenda|vila": 15,
	&"floresta|vila": 30,
	&"vila|cidade": 45,
	# A cidade grande é longe: a pé é inviável (Q3) e exige veículo.
	&"fazenda|cidade_grande": 240,
	&"floresta|cidade_grande": 270,
	&"vila|cidade_grande": 225,
	&"cidade|cidade_grande": 180,
}
## Locais dentro da fazenda que ficam longe da sede: ir até eles ou vir deles
## custa estes minutos a pé, mesmo sendo da mesma raiz (L6). Provisório.
const WALK_MINUTES := {
	&"acude": 10,
}
## Locais que só se alcança com veículo (Q3).
const NEEDS_VEHICLE: Array[StringName] = [&"cidade_grande"]

## Limite de m² da fazenda, somando todos os seus locais (L7). Valor
## provisório; cresce por expansão no futuro.
var farm_area_limit := 100

## Falência (D7, F1). O gatilho e a consequência estão em aberto (F2): por
## ora, se a dívida vencida passar de `bankruptcy_debt_limit` na virada do
## dia, o jogo acaba. 0 desliga o gatilho. Sem outra consequência além do fim.
var bankruptcy_debt_limit := 0
var is_game_over := false
var game_over_reason := ""

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
	day_ended.connect(_on_day_ended)
	woke_up.connect(_on_woke_up)
	event_due.connect(_on_event_due)


## Eventos agendados que o próprio estado entende: liberar algo (U1).
func _on_event_due(kind: String, data: Dictionary) -> void:
	if kind == "unlock":
		unlock(StringName(data["id"]))


## Quando o jogador acorda chega a correspondência (T6).
func _on_woke_up(_day: int) -> void:
	Mail.deliver(self)


## Sistemas que rodam na virada do dia. É um método (não uma lambda) para
## o estado não segurar a si mesmo e poder ser liberado.
func _on_day_ended(_day: int) -> void:
	last_events.clear()
	Pests.run_helpers(self) # a rega do ajudante conta para o crescimento da noite
	Machines.on_day_start_of_night(self) # e a da irrigação
	Farming.on_day_end(self)
	Economy.on_day_end(self)
	Animals.on_day_end(self)
	Buildings.on_day_end(self)
	Pests.on_day_end(self)
	LostFound.on_day_end(self)
	_check_bankruptcy()


const INITIAL_STATE_PATH := "res://data/initial_state.json"
const PROGRESSION_PATH := "res://data/progression.json"


## Jogo novo. Com `initial` (padrão), aplica o estado inicial de
## data/initial_state.json (I1-I3). Sem ele, só a mochila na mão.
static func new_game(seed_value: int = 0, initial: bool = true) -> GameState:
	var s := GameState.new()
	s.rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	for id in LOCATION_NAMES:
		s.cards[String(id)] = []
		s.stages[String(id)] = []
	# A carta da mochila fica na mão (AR3, AR7).
	if initial:
		s.pests_enabled = true
		s._apply_initial_state()
	else:
		s.hand.append(s.new_card(&"mochila"))
	return s


## Estado inicial, lido de dados (I1, I2, I3).
func _apply_initial_state() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(INITIAL_STATE_PATH))
	if not (data is Dictionary):
		push_error("estado inicial ilegível: " + INITIAL_STATE_PATH)
		hand.append(new_card(&"mochila"))
		return
	for entry in data.get("new_locations", []):
		add_location(StringName(entry["id"]), entry["name"], StringName(entry["parent"]),
			{"damaged": entry.get("damaged", false), "multiplier": entry.get("multiplier", 1.0),
			 "durability": entry.get("durability", 100), "kind": "roca", "level": 1, "quality": 1.0})
		_fill(cards[entry["id"]], entry.get("cards", []))
	_fill(hand, data.get("hand", []))
	for loc in data.get("locations", {}):
		_fill(cards[loc], data["locations"][loc])
	mail_queue = Mail.load_schedule()
	var prog = JSON.parse_string(FileAccess.get_file_as_string(PROGRESSION_PATH))
	if prog is Dictionary:
		gated = prog.get("gated", []).duplicate()


func _fill(list: Array, entries: Array) -> void:
	for e in entries:
		var c := new_card(StringName(e["id"]), int(e.get("n", 1)))
		if e.has("state"):
			c["state"] = e["state"].duplicate(true)
		if catalog.get_def(StringName(e["id"])).props.has("storage"):
			storages[str(c["uid"])] = []
			_fill(storages[str(c["uid"])], e.get("contents", []))
		list.append(c)


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
func add_location(id: StringName, display_name: String, parent: StringName, extra: Dictionary = {}) -> bool:
	if has_location(id) or not has_location(parent):
		return false
	var entry := extra.duplicate(true)
	entry["name"] = display_name
	entry["parent"] = String(parent)
	extra_locations[String(id)] = entry
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
		if id == current_location or not is_unlocked(id):
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
		if from == to:
			return 0
		return maxi(int(WALK_MINUTES.get(from, 0)), int(WALK_MINUTES.get(to, 0)))
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
	if is_game_over:
		return
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
	if is_game_over:
		return
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
		# O efeito (tempo e rendimento) vem de data/buffs.json.
		player_buffs.append({"id": "cansado", "kind": "debuff"})
	woke_up.emit(day_number())


func is_tired() -> bool:
	return player_buffs.any(func(b: Dictionary) -> bool: return b.get("id") == "cansado")


func _step(amount: int) -> void:
	var from := minutes
	minutes += amount
	_expire_buffs()
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
	if is_game_over:
		return false
	if not has_location(id) or not is_unlocked(id):
		return false
	if root_of(id) in NEEDS_VEHICLE and not Vehicles.has_usable(self):
		return false # a pé é inviável (Q3)
	_close_storage_internal()
	# A viagem gasta minutos (T1). Um veículo na mão reduz o tempo e gasta
	# combustível (Q6, Q8). Se a meia-noite cair no caminho, o dia acaba e o
	# jogador acorda às 06:00 já no destino.
	var base := Vehicles.trip_minutes(self, travel_minutes(current_location, id), true)
	advance_time(ceili(base * buff_multiplier("time_mult") - 0.0001))
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
	Animals.init_card(self, c)
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


## Põe `n` cartas de `id` em uma lista qualquer, somando se possível.
func spawn_into(list: Array, id: StringName, n: int) -> void:
	var c := new_card(id, n)
	if _stack_into(list, c).is_empty():
		list.append(c)


func def_of(card: Dictionary) -> CardDef:
	return catalog.get_def(StringName(card["id"]))


## Propriedade da carta: vem da definição ou de "props" na própria carta (Z8).
func has_prop(card: Dictionary, prop: StringName) -> bool:
	var d := def_of(card)
	if d != null and d.props.has(prop):
		return true
	return (card.get("props", []) as Array).has(String(prop))


## Status da carta (S1): sujo, molhado, enferrujada... ficam em
## state["status"]. São diferentes dos buffs e debuffs (S2, C9), que ficam em
## card["buffs"] e mexem no desempenho.
func statuses_of(card: Dictionary) -> Array:
	return card.get("state", {}).get("status", [])


func has_status(card: Dictionary, status: String) -> bool:
	return statuses_of(card).has(status)


## Acrescenta um status (sem repetir). Devolve se mudou.
func add_status(card: Dictionary, status: String) -> bool:
	if has_status(card, status):
		return false
	var st: Dictionary = card.get("state", {}).duplicate(true)
	var list: Array = st.get("status", [])
	list.append(status)
	st["status"] = list
	card["state"] = st
	return true


func remove_status(card: Dictionary, status: String) -> bool:
	if not has_status(card, status):
		return false
	var st: Dictionary = card["state"].duplicate(true)
	st["status"].erase(status)
	if st["status"].is_empty():
		st.erase("status")
	if st.is_empty():
		card.erase("state")
	else:
		card["state"] = st
	return true


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
			return true # o storage aberto vai para a área contextual, sem fechar o local (AR4)
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
	if is_game_over:
		return false
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
	if from["area"] != to_area:
		var limit := area_limit(to_area)
		if limit > 0 and area_weight(to_area) + card_weight(card) > limit:
			return false # passaria do limite de peso (P2, P3)
	src.remove_at(from["index"])
	if from["area"] != to_area and (to_area == BACKPACK or to_area == STORAGE):
		Wear.on_stored(self, card) # guardar sujo ou molhado desgasta (G5)
	if from["area"] != to_area and not _stack_into(dst, card).is_empty():
		areas_changed.emit()
		return true
	if index < 0 or index > dst.size():
		index = dst.size()
	dst.insert(index, card)
	areas_changed.emit()
	return true


# --- Área da fazenda ------------------------------------------------------

## A fazenda e todos os locais dentro dela (casa, roças, galinheiro...) (L6).
func farm_locations() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in location_ids():
		if root_of(id) == &"fazenda":
			out.append(id)
	return out


## m² que uma carta ocupa na fazenda (N3): extra["m2"] por unidade × quantidade.
## Terra bruta, árvores e água de riacho não ocupam (N1, N2).
func card_area(card: Dictionary) -> int:
	var d := def_of(card)
	return int(d.extra.get("m2", 0)) * int(card.get("n", 1)) if d != null else 0


## m² usados hoje na fazenda, somando todos os seus locais (L7).
func farm_area_used() -> int:
	var total := 0
	for id in farm_locations():
		total += int(extra_locations.get(String(id), {}).get("m2", 0)) # construções ocupam m² (B4)
		for c in cards[String(id)]:
			total += card_area(c)
		for c in stages[String(id)]:
			total += card_area(c)
	return total


func farm_area_free() -> int:
	return farm_area_limit - farm_area_used()


# --- Peso e volume --------------------------------------------------------

## Volume atual de um recipiente como o regador (P5), em gramas. Sem estado
## guardado, está cheio (capacidade em extra["capacity"]).
func volume_of(card: Dictionary) -> int:
	var d := def_of(card)
	var cap := int(d.extra.get("capacity", 0)) if d != null else 0
	return int(card.get("state", {}).get("volume", cap))


## Peso da carta em gramas (P1): peso unitário da definição × quantidade, mais
## o conteúdo se for um storage. Dinheiro e locais têm peso 0 (D9, P1).
func card_weight(card: Dictionary) -> int:
	var d := def_of(card)
	var w := (d.weight if d != null else 0) * int(card.get("n", 1))
	if storages.has(str(card.get("uid", 0))):
		for inner in storages[str(card["uid"])]:
			w += card_weight(inner)
	return w


func list_weight(list: Array) -> int:
	var w := 0
	for c in list:
		w += card_weight(c)
	return w


## Peso das cartas guardadas numa área, em gramas.
func area_weight(area: StringName) -> int:
	return list_weight(area_cards(area))


## Limite de peso da área em gramas (P2, P3), ou 0 se não tem. Vem do
## extra["weight_limit"] da carta da mochila ou do storage aberto.
func area_limit(area: StringName) -> int:
	var holder: Dictionary = {}
	if area == BACKPACK:
		var best := 0
		for c in hand:
			if has_prop(c, &"backpack") and int(def_of(c).extra.get("weight_limit", 0)) >= best:
				best = int(def_of(c).extra.get("weight_limit", 0))
				holder = c # usa a maior mochila na mão (Q10)
	elif area == STORAGE:
		for c in hand:
			if int(c["uid"]) == open_storage_uid:
				holder = c
				break
	if holder.is_empty():
		return 0
	return int(def_of(holder).extra.get("weight_limit", 0))


# --- Skills e multiplicadores ----------------------------------------------

## Pontos de skill numa atividade (K1). Cada ponto vale menos que o anterior
## (K3, ver Multipliers).
func add_skill(activity: StringName, points: int) -> void:
	skills[String(activity)] = int(skills.get(String(activity), 0)) + points


## Produto de um campo de efeito dos buffs e debuffs do jogador (1.0 se não há).
func buff_multiplier(key: String) -> float:
	return Buffs.multiplier(self, key)


## Comando: come um alimento (S3), que dá o buff dele. O buff dura `days` dias.
func eat(uid: int) -> bool:
	if is_game_over:
		return false
	var l := find_card(uid)
	if l.is_empty():
		return false
	var card: Dictionary = area_cards(l["area"])[l["index"]]
	var d := def_of(card)
	if d == null or not d.extra.has("food"):
		return false
	var food: Dictionary = d.extra["food"]
	_consume_card_for_build(l)
	player_buffs = player_buffs.filter(func(b: Dictionary) -> bool: return b.get("id") != food["buff"])
	player_buffs.append({"id": food["buff"], "expires": minutes + int(food.get("days", 1)) * MINUTES_PER_DAY})
	areas_changed.emit()
	return true


func _expire_buffs() -> void:
	player_buffs = player_buffs.filter(func(b: Dictionary) -> bool: return not b.has("expires") or int(b["expires"]) > minutes)


## Comando: transforma uma carta de construção num local novo (R8, L6).
## A carta precisa ter extra["builds"] = {parent, multiplier, m2}. Devolve o
## id do local criado, ou &"" se não deu.
func build_location(uid: int, display_name: String) -> StringName:
	if is_game_over:
		return &""
	var l := find_card(uid)
	if l.is_empty() or display_name.strip_edges() == "":
		return &""
	var card: Dictionary = area_cards(l["area"])[l["index"]]
	var d := def_of(card)
	if d == null or not d.extra.has("builds"):
		return &""
	var b: Dictionary = d.extra["builds"]
	var id := StringName("%s_%d" % [String(b.get("kind", "local")), next_uid])
	next_uid += 1
	if not add_location(id, display_name.strip_edges(), StringName(b["parent"]),
			{"multiplier": b.get("multiplier", 1.0), "m2": b.get("m2", 0)}):
		return &""
	_consume_card_for_build(l)
	areas_changed.emit()
	return id


func _consume_card_for_build(l: Dictionary) -> void:
	var list := area_cards(l["area"])
	var card: Dictionary = list[l["index"]]
	card["n"] = int(card["n"]) - 1
	if card["n"] <= 0:
		list.remove_at(l["index"])


# --- Falência -------------------------------------------------------------

func _check_bankruptcy() -> void:
	if bankruptcy_debt_limit > 0 and Economy.overdue_debt(self) > bankruptcy_debt_limit:
		declare_bankruptcy("dívida vencida de %d" % Economy.overdue_debt(self))


## Comando: encerra o jogo por falência (D7, F1). Depois disso os comandos
## que mudam o jogo são recusados.
func declare_bankruptcy(reason: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_reason = reason
	game_over.emit(reason)
	areas_changed.emit()


## Comando: constrói um tipo de construção (B1 a B3). Devolve o id do local.
func build(kind: StringName, display_name: String, professional: bool = false) -> StringName:
	return Buildings.build(self, kind, display_name, professional)


## Comando: conserta uma construção (B5).
func repair_location(id: StringName) -> bool:
	return Buildings.repair(self, id)


## Comando: sobe o nível de uma construção (B7).
func upgrade_location(id: StringName) -> bool:
	return Buildings.upgrade(self, id)


## Comando: paga a hospedagem e dorme na vila (Q4).
const INN_PRICE := 30


func sleep_at_inn() -> bool:
	if is_game_over or current_location != &"vila" or not Economy.spend(self, INN_PRICE):
		return false
	sleep()
	return true


## Comando: manda um animal para o corte (A6).
func slaughter(uid: int) -> bool:
	return not is_game_over and Animals.slaughter(self, uid)


## Comando: pega uma carta do achados e perdidos (H5), na cidade.
func claim_lost(uid: int) -> bool:
	return not is_game_over and LostFound.claim(self, uid)


# --- Economia -------------------------------------------------------------

func money() -> int:
	return Economy.money(self)


## Comando: compra uma carta da loja do local atual (D2).
func buy(card_id: StringName) -> bool:
	if is_game_over:
		return false
	return Economy.buy(self, card_id)


## Comando: vende a pilha `uid` numa caixa de venda `box_uid` (D1, E1).
func sell(uid: int, box_uid: int) -> bool:
	if is_game_over:
		return false
	return Economy.sell(self, uid, box_uid)


## Comando: cria uma conta (D3).
func issue_bill(amount: int, due: int) -> Dictionary:
	return Economy.issue_bill(self, amount, due)


## Comando: paga uma conta, na cidade (D4).
func pay_bill(uid: int) -> bool:
	if is_game_over:
		return false
	return Economy.pay_bill(self, uid)


# --- Receitas -------------------------------------------------------------

## Comando: arrasta a carta `a_uid` sobre `b_uid` (C2). Se existe receita para
## o par (em qualquer ordem), executa; senão, nada muda. Devolve se executou.
func apply_recipe(a_uid: int, b_uid: int, units: int = 1) -> bool:
	if is_game_over:
		return false
	var la := find_card(a_uid)
	var lb := find_card(b_uid)
	if la.is_empty() or lb.is_empty() or a_uid == b_uid:
		return false
	var ca: Dictionary = area_cards(la["area"])[la["index"]]
	var cb: Dictionary = area_cards(lb["area"])[lb["index"]]
	if has_prop(cb, &"sell_box") and Economy.sell(self, a_uid, b_uid):
		return true
	var r := recipes.find_for(self, ca, cb)
	if r != null:
		return _run(r, ca, cb, lb["area"], units)
	r = recipes.find_for(self, cb, ca)
	if r != null:
		return _run(r, cb, ca, la["area"], units)
	return false


## Para a interface (V2): a receita do par é de tempo variável? Devolve
## {variable, minutes (por unidade), max_units}, ou {} se não há receita.
func recipe_preview(a_uid: int, b_uid: int) -> Dictionary:
	var la := find_card(a_uid)
	var lb := find_card(b_uid)
	if la.is_empty() or lb.is_empty() or a_uid == b_uid:
		return {}
	var ca: Dictionary = area_cards(la["area"])[la["index"]]
	var cb: Dictionary = area_cards(lb["area"])[lb["index"]]
	for pair in [[ca, cb], [cb, ca]]:
		var r := recipes.find_for(self, pair[0], pair[1])
		if r != null:
			return {"variable": r.variable, "minutes": r.minutes, "max_units": RecipeRunner.max_units(self, r, pair[0], pair[1])}
	return {}


## Comando: usa uma carta sozinha (receita de clique, como colher).
func use_card(uid: int, units: int = 1) -> bool:
	if is_game_over:
		return false
	var l := find_card(uid)
	if l.is_empty():
		return false
	var card: Dictionary = area_cards(l["area"])[l["index"]]
	var r := recipes.find_for(self, {}, card)
	return r != null and _run(r, {}, card, l["area"], units)


func _run(r: RecipeDef, a: Dictionary, b: Dictionary, area_b: StringName, units: int = 1) -> bool:
	return RecipeRunner.run(self, r, a, b, area_b, units)


# --- Abrir e fechar -------------------------------------------------------

## Comando: seleciona uma carta. A mochila abre/fecha (AR3, AR8), um storage
## do local ou do chão abre (AR4) e o ícone de storage aberto na mão o fecha.
func select_card(uid: int) -> bool:
	if is_game_over:
		return false
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
	if has_prop(card, &"mail"):
		return read_letter(card)
	if def_of(card) != null and def_of(card).extra.has("food"):
		return eat(uid) # clicar num alimento o come (S3)
	if card["id"] == String(Economy.BILL):
		return Economy.pay_bill(self, uid) # clicar na conta tenta pagá-la (D4)
	return use_card(uid)


## Lê uma carta de correspondência (M2): não gasta tempo. O item anexo vai
## para a mão (M4; o destino é uma pendência), uma promoção passa a valer
## (M5) e a carta pode liberar coisas (U1). Ler de novo não faz nada.
func read_letter(card: Dictionary) -> bool:
	var st: Dictionary = card.get("state", {})
	if st.get("read", false):
		last_read = {"title": st.get("title", ""), "text": st.get("text", "")}
		areas_changed.emit()
		return false
	st["read"] = true
	card["state"] = st
	last_read = {"title": st.get("title", ""), "text": st.get("text", "")}
	for att in st.get("attachments", []):
		if att.has("bill"):
			Economy.issue_bill(self, int(att["bill"]["amount"]), minutes + int(att["bill"]["due_days"]) * MINUTES_PER_DAY)
		else:
			spawn(StringName(att["id"]), HAND, int(att.get("n", 1)))
	st.erase("attachments")
	if st.has("promo"):
		var p: Dictionary = st["promo"]
		promotions.append({"item": p["item"], "percent": int(p["percent"]), "until_day": day_number() + int(p["days"])})
	for id in st.get("unlock", []):
		unlock(StringName(id))
	areas_changed.emit()
	return true


## Está liberado (U1)? Só o que está em `gated` pode estar bloqueado.
func is_unlocked(id: StringName) -> bool:
	return not gated.has(String(id)) or unlocked.has(String(id))


## Libera um local ou item (U1), por carta ou por evento agendado.
func unlock(id: StringName) -> void:
	if not unlocked.has(String(id)):
		unlocked.append(String(id))


## A roça ou outro local está danificado (I2)?
func is_damaged(id: StringName) -> bool:
	return bool(extra_locations.get(String(id), {}).get("damaged", false))


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

## Comando: retrato do estado como dados simples (Z2). A interface e os testes
## leem por aqui ou pelas consultas; é o mesmo que vai para o save.
func get_state() -> Dictionary:
	return to_dict()


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
		"farm_area_limit": farm_area_limit,
		"skills": skills.duplicate(true),
		"mail_queue": mail_queue.duplicate(true),
		"last_events": last_events.duplicate(),
		"pests_enabled": pests_enabled,
		"lost_and_found": lost_and_found.duplicate(true),
		"promotions": promotions.duplicate(true),
		"last_read": last_read.duplicate(true),
		"unlocked": unlocked.duplicate(),
		"gated": gated.duplicate(),
		"bankruptcy_debt_limit": bankruptcy_debt_limit,
		"game_over_reason": game_over_reason,
		"is_game_over": is_game_over,
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
		s.extra_locations[String(id)] = e.duplicate(true)
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
	s.farm_area_limit = int(data.get("farm_area_limit", 100))
	s.pests_enabled = bool(data.get("pests_enabled", false))
	var laf = _read_list(data.get("lost_and_found", []))
	if laf == null:
		return null
	s.lost_and_found = laf
	for key in ["mail_queue", "promotions", "unlocked", "gated"]:
		if not (data.get(key, []) is Array):
			return null
	s.mail_queue = data.get("mail_queue", []).duplicate(true)
	s.promotions = data.get("promotions", []).duplicate(true)
	s.unlocked = data.get("unlocked", []).duplicate()
	s.gated = data.get("gated", []).duplicate()
	s.last_read = data.get("last_read", {}).duplicate(true) if data.get("last_read", {}) is Dictionary else {}
	var sk = data.get("skills", {})
	if not (sk is Dictionary):
		return null
	for k in sk:
		s.skills[String(k)] = int(sk[k])
	s.bankruptcy_debt_limit = int(data.get("bankruptcy_debt_limit", 0))
	s.is_game_over = bool(data.get("is_game_over", false))
	s.game_over_reason = str(data.get("game_over_reason", ""))
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
