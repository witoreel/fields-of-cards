class_name Buffs
extends RefCounted
## Efeitos de buffs e debuffs do jogador (C9, P4, S3, T9), lidos de
## data/buffs.json. Os números são provisórios: o efeito do "cansado" e do
## "sobrecarregado" está em aberto.
##
## Campos de efeito: time_mult (tempo das ações) e yield_mult (resultado).

const PATH := "res://data/buffs.json"
## Acima desta fração do limite de peso da mochila, o jogador fica sobrecarregado (P4).
const LOAD_RATIO := 0.8
static var _table: Dictionary


static func effect(id: String) -> Dictionary:
	if _table == null or _table.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_table = data if data is Dictionary else {}
	return _table.get(id, {})


## Buffs ativos do jogador: os guardados mais os que vêm do estado (peso).
static func active(state: GameState) -> Array:
	var out: Array = state.player_buffs.duplicate()
	if is_overloaded(state):
		out.append({"id": "sobrecarregado"})
	return out


static func is_overloaded(state: GameState) -> bool:
	var limit := state.area_limit(GameState.BACKPACK)
	return limit > 0 and state.area_weight(GameState.BACKPACK) > limit * LOAD_RATIO


## Produto de um campo de efeito entre todos os buffs ativos. Um campo escrito
## no próprio buff vale mais que o da tabela.
static func multiplier(state: GameState, key: String) -> float:
	var m := 1.0
	for b in active(state):
		var fx := effect(str(b.get("id", "")))
		m *= float(b.get(key, fx.get(key, 1.0)))
	return m
