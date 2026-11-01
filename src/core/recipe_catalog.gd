class_name RecipeCatalog
extends RefCounted
## Receitas lidas de `data/recipes/*.tres` (C6).

const DEFAULT_DIR := "res://data/recipes"
static var _default: RecipeCatalog

var recipes: Array[RecipeDef] = []


static func default() -> RecipeCatalog:
	if _default == null:
		_default = RecipeCatalog.new()
		_default.load_dir(DEFAULT_DIR)
	return _default


func load_dir(path: String) -> void:
	var files := Array(DirAccess.get_files_at(path))
	files.sort() # ordem estável
	for file in files:
		var name: String = file.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var r = load(path.path_join(name))
			if r is RecipeDef:
				recipes.append(r)


## Receita para o par (a arrastada, b alvo), ou null.
func find(a: StringName, b: StringName) -> RecipeDef:
	for r in recipes:
		if r.a == a and r.b == b:
			return r
	return null
