class_name GameState
extends RefCounted
## Estado do jogo (SV1). Motor puro: sem Node, cena ou UI (Z1).
## Guarda o local atual e, por local, a lista ordenada de cartas (Z3).
## Cada carta é um Dictionary de dados, para as propriedades crescerem
## sem reescrever (Z8).

const FORMAT_VERSION := 1
const START_LOCATION := &"fazenda"

## Locais do jogo (L4). Conteúdo novo é dado.
const LOCATION_NAMES := {
	&"fazenda": "Fazenda",
	&"floresta": "Floresta",
	&"cidade": "Cidade",
}

## Emitido ao chegar a um local (SV2 liga o autosave a ele).
signal arrived(location_id: StringName)

var current_location: StringName = START_LOCATION
## location_id (String) -> Array[Dictionary] de cartas, na ordem.
var cards: Dictionary = {}
var rng := RandomNumberGenerator.new()


static func new_game(seed_value: int = 0) -> GameState:
	var s := GameState.new()
	s.rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	for id in LOCATION_NAMES:
		s.cards[String(id)] = []
	return s


func has_location(id: StringName) -> bool:
	return LOCATION_NAMES.has(id)


## Comando: anda para um local. Devolve falso se o local não existe.
## O tempo gasto (T1) ainda é zero, porque não há relógio.
func travel_to(id: StringName) -> bool:
	if not has_location(id):
		return false
	current_location = id
	arrived.emit(id)
	return true


## Cartas do local, na ordem. Devolve a própria lista (não copia).
func cards_at(id: StringName) -> Array:
	return cards[String(id)]


func to_dict() -> Dictionary:
	return {
		"version": FORMAT_VERSION,
		"current_location": String(current_location),
		"cards": cards.duplicate(true),
		# Inteiros de 64 bits viram texto: JSON só garante 53 bits.
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}


## Reconstrói a partir de dados. Devolve null se algo estiver errado (SV4).
static func from_dict(data: Variant) -> GameState:
	if not (data is Dictionary):
		return null
	if int(data.get("version", -1)) != FORMAT_VERSION:
		return null
	var loc := StringName(str(data.get("current_location", "")))
	var raw_cards = data.get("cards")
	if not LOCATION_NAMES.has(loc) or not (raw_cards is Dictionary):
		return null
	var s := GameState.new()
	s.current_location = loc
	for id in LOCATION_NAMES:
		var list = raw_cards.get(String(id), [])
		if not (list is Array):
			return null
		for card in list:
			if not (card is Dictionary):
				return null
		s.cards[String(id)] = list.duplicate(true)
	var seed_text := str(data.get("rng_seed", ""))
	var state_text := str(data.get("rng_state", ""))
	if not seed_text.is_valid_int() or not state_text.is_valid_int():
		return null
	s.rng.seed = seed_text.to_int()
	s.rng.state = state_text.to_int()
	return s
