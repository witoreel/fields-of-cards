class_name GameSession
extends RefCounted
## Guarda o jogo em andamento entre as telas e liga o autosave (SV2).
## Fica fora do motor de regras porque conhece o arquivo de save.

static var state: GameState


static func start_new() -> void:
	_set_state(GameState.new_game())


## Carrega o save. Devolve falso se não houver um válido (SV5).
static func continue_saved() -> bool:
	var loaded := SaveGame.load_state()
	if loaded == null:
		return false
	_set_state(loaded)
	return true


static func _set_state(s: GameState) -> void:
	state = s
	state.arrived.connect(_on_arrived)


static func _on_arrived(_location_id: StringName) -> void:
	var err := SaveGame.save_state(state)
	if err != OK:
		push_warning("Autosave falhou: %s" % error_string(err))
