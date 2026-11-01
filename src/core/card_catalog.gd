class_name CardCatalog
extends RefCounted
## Conjunto de definições de carta, lido de `data/cards/*.tres` (C6).

const DEFAULT_DIR := "res://data/cards"
static var _default: CardCatalog

var defs: Dictionary = {} # StringName -> CardDef


static func default() -> CardCatalog:
	if _default == null:
		_default = CardCatalog.new()
		_default.load_dir(DEFAULT_DIR)
	return _default


func load_dir(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		# Em builds exportados o arquivo aparece com sufixo .remap.
		var name := file.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var d = load(path.path_join(name))
			if d is CardDef:
				add(d)


func add(def: CardDef) -> void:
	defs[def.id] = def


func get_def(id: StringName) -> CardDef:
	return defs.get(id)


func has_def(id: StringName) -> bool:
	return defs.has(id)
