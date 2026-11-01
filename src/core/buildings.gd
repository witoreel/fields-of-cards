class_name Buildings
extends RefCounted
## Construções (B1 a B12). Uma construção é um local dentro da fazenda
## (L6, B8) com m², qualidade, nível, durabilidade e multiplicador. Os tipos
## vêm de data/buildings.json. Todos os números são provisórios (Z7).
##
## Quem constrói: o profissional (B1, B2) entrega qualidade mediana por
## dinheiro; o jogador (B3) paga em madeira e tempo, e a qualidade começa
## ruim e melhora com a skill "construcao", podendo passar a do profissional.

const PATH := "res://data/buildings.json"
const MAX_LEVEL := 3 # poucos níveis (B7)
## Qualidade (multiplica a base). Mediana do profissional, e faixa do jogador.
const PRO_QUALITY := 1.0
const PLAYER_MIN_QUALITY := 0.6
const PLAYER_MAX_QUALITY := 1.4
## Pontos de skill de construção por obra feita pelo jogador.
const BUILD_SKILL_POINTS := 10
## Perda de durabilidade por dia (B5), limite do dano (B6) e custo do reparo.
const DECAY_PER_DAY := 2
const DAMAGE_BELOW := 50
const REPAIR_WOOD := 2
const REPAIR_MINUTES := 60
const UPGRADE_COST_PER_LEVEL := 100
static var _table: Dictionary


static func kinds() -> Dictionary:
	if _table == null or _table.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_table = data if data is Dictionary else {}
	return _table


## Qualidade que o jogador conseguiria hoje (B3).
static func player_quality(state: GameState) -> float:
	return PLAYER_MIN_QUALITY + (PLAYER_MAX_QUALITY - PLAYER_MIN_QUALITY) * Multipliers.skill_level(state, &"construcao")


## Tira `n` cartas `id` da mão ou da mochila. Falso (e nada muda) se faltar.
static func take(state: GameState, id: String, n: int) -> bool:
	var have := 0
	for list in [state.hand, state.backpack]:
		for c in list:
			if c["id"] == id:
				have += int(c["n"])
	if have < n:
		return false
	var left := n
	for list in [state.hand, state.backpack]:
		for i in range(list.size() - 1, -1, -1):
			if left == 0:
				break
			if list[i]["id"] == id:
				var t := mini(int(list[i]["n"]), left)
				list[i]["n"] = int(list[i]["n"]) - t
				left -= t
				if list[i]["n"] == 0:
					list.remove_at(i)
	return true


## Comando: constrói um `kind` com o nome dado. `professional` contrata.
## Devolve o id do local, ou &"" se não deu (m², dinheiro ou madeira faltando).
static func build(state: GameState, kind: StringName, display_name: String, professional: bool) -> StringName:
	var k: Dictionary = kinds().get(String(kind), {})
	if k.is_empty() or display_name.strip_edges() == "" or state.is_game_over:
		return &""
	if int(k["m2"]) > state.farm_area_free():
		return &"" # a área de dentro é igual à de fora, e cabe na fazenda (B4)
	var quality := PRO_QUALITY
	if professional:
		if not Economy.spend(state, int(k["pro_cost"])):
			return &""
	else:
		if not take(state, "madeira", int(k["wood"])):
			return &""
		quality = player_quality(state)
		state.add_skill(&"construcao", BUILD_SKILL_POINTS)
		state.advance_time(int(k["build_minutes"]))
	var id := StringName("%s_%d" % [kind, state.next_uid])
	state.next_uid += 1
	state.add_location(id, display_name.strip_edges(), &"fazenda", {
		"kind": String(kind), "m2": int(k["m2"]), "quality": quality, "level": 1,
		"multiplier": float(k["base_multiplier"]) * quality, "durability": 100, "damaged": false,
		"built_by": "profissional" if professional else "jogador",
	})
	state.areas_changed.emit()
	return id


static func info(state: GameState, id: StringName) -> Dictionary:
	return state.extra_locations.get(String(id), {})


## Capacidade da construção no nível atual (B7), por tipo.
static func capacity(state: GameState, id: StringName) -> int:
	var e := info(state, id)
	if not e.has("kind"):
		return 0
	var caps: Array = kinds()[e["kind"]]["capacity"]
	return int(caps[clampi(int(e["level"]) - 1, 0, caps.size() - 1)])


static func _refresh_damage(e: Dictionary) -> void:
	e["damaged"] = int(e["durability"]) < DAMAGE_BELOW


## Comando: conserta (B5). Gasta madeira, tempo e um martelo carregado.
static func repair(state: GameState, id: StringName) -> bool:
	var e := info(state, id)
	if e.is_empty() or not e.has("durability") or state.is_game_over:
		return false
	if int(e["durability"]) >= 100:
		return false
	var hammer: Dictionary = {}
	for list in [state.hand, state.backpack]:
		for c in list:
			if c["id"] == "martelo":
				hammer = c
	if hammer.is_empty() or not take(state, "madeira", REPAIR_WOOD):
		return false
	Wear.apply_use(state, hammer, 2, 0)
	e["durability"] = 100
	_refresh_damage(e)
	state.advance_time(REPAIR_MINUTES)
	state.areas_changed.emit()
	return true


## Comando: sobe um nível, pagando (B7).
static func upgrade(state: GameState, id: StringName) -> bool:
	var e := info(state, id)
	if not e.has("kind") or int(e["level"]) >= MAX_LEVEL or state.is_game_over:
		return false
	if not Economy.spend(state, UPGRADE_COST_PER_LEVEL * int(e["level"])):
		return false
	e["level"] = int(e["level"]) + 1
	e["multiplier"] = float(kinds()[e["kind"]]["base_multiplier"]) * float(e["quality"]) * (1.0 + 0.1 * (int(e["level"]) - 1))
	state.areas_changed.emit()
	return true


## Virada do dia: tudo que tem durabilidade se gasta (B5), e o dano segue (B6).
static func on_day_end(state: GameState) -> void:
	for id in state.extra_locations:
		var e: Dictionary = state.extra_locations[id]
		if e.has("durability"):
			e["durability"] = maxi(0, int(e["durability"]) - DECAY_PER_DAY)
			_refresh_damage(e)
