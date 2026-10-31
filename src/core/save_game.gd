class_name SaveGame
extends RefCounted
## Leitura e gravação do save em arquivo (SV2 a SV5). Um só save (SV3).

const DEFAULT_PATH := "user://save.json"


static func exists(path: String = DEFAULT_PATH) -> bool:
	return load_state(path) != null


static func save_state(state: GameState, path: String = DEFAULT_PATH) -> Error:
	# Grava num arquivo temporário e troca, para um corte no meio da
	# gravação não estragar o save anterior.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(state.to_dict()))
	f.close()
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


## Devolve o estado salvo, ou null se não há save, ele está ilegível ou é de
## outra versão (SV4).
static func load_state(path: String = DEFAULT_PATH) -> GameState:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return GameState.from_dict(json.data)
