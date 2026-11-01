class_name ComfortSettings
extends RefCounted
## Conforto de movimento (W5). Movimento reduzido troca as animações por
## trocas instantâneas. Fica no mesmo arquivo das configurações de vídeo.

const SECTION := "comfort"
const DEFAULT_PATH := "user://settings.cfg"

static var _current: ComfortSettings

var reduced_motion := false


## Configuração em vigor, lida do arquivo na primeira chamada.
static func current() -> ComfortSettings:
	if _current == null:
		_current = load_from()
	return _current


static func set_current(s: ComfortSettings) -> void:
	_current = s


func duplicate_settings() -> ComfortSettings:
	var c := ComfortSettings.new()
	c.reduced_motion = reduced_motion
	return c


func save_to(path: String = DEFAULT_PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path) # mantém a seção de vídeo
	cfg.set_value(SECTION, "reduced_motion", reduced_motion)
	return cfg.save(path)


## Se o arquivo não existir ou estiver quebrado, fica o padrão (animações ligadas).
static func load_from(path: String = DEFAULT_PATH) -> ComfortSettings:
	var s := ComfortSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		s.reduced_motion = bool(cfg.get_value(SECTION, "reduced_motion", false))
	return s
