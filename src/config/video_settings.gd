class_name VideoSettings
extends RefCounted
## Configurações de vídeo (regras VD1 a VD6). Sem Node nem cena: só dados,
## leitura/gravação em arquivo e aplicação na janela via DisplayServer.

const SECTION := "video"
const DEFAULT_PATH := "user://settings.cfg"

const MODE_WINDOWED := 0
const MODE_FULLSCREEN := 1

## Tamanhos de janela oferecidos (VD3). Só entram os que cabem no monitor.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

## Limites de FPS oferecidos (VD4). 0 = sem limite.
const FPS_LIMITS: Array[int] = [0, 60, 120, 144, 165, 180, 240, 360]

var screen: int = 0
var window_mode: int = MODE_WINDOWED
var resolution: Vector2i = Vector2i(1280, 720)
var max_fps: int = 0
var vsync: bool = true


func duplicate_settings() -> VideoSettings:
	var copy := VideoSettings.new()
	copy.screen = screen
	copy.window_mode = window_mode
	copy.resolution = resolution
	copy.max_fps = max_fps
	copy.vsync = vsync
	return copy


## Resoluções que cabem num monitor de tamanho `screen_size` (VD3).
## Se nenhuma couber, devolve a menor, para a lista nunca ficar vazia.
static func resolutions_for(screen_size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for r in RESOLUTIONS:
		if r.x <= screen_size.x and r.y <= screen_size.y:
			result.append(r)
	if result.is_empty():
		result.append(RESOLUTIONS[0])
	return result


## Corrige valores que não fazem sentido na máquina atual (monitor
## desconectado, resolução grande demais, limite de FPS desconhecido).
func sanitize(screen_count: int, screen_size: Vector2i) -> void:
	screen = clampi(screen, 0, maxi(screen_count - 1, 0))
	if window_mode != MODE_WINDOWED and window_mode != MODE_FULLSCREEN:
		window_mode = MODE_WINDOWED
	var allowed := resolutions_for(screen_size)
	if not allowed.has(resolution):
		resolution = allowed[allowed.size() - 1]
	if not FPS_LIMITS.has(max_fps):
		max_fps = 0


func save_to(path: String = DEFAULT_PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path) # mantém outras seções, se existirem
	cfg.set_value(SECTION, "screen", screen)
	cfg.set_value(SECTION, "window_mode", window_mode)
	cfg.set_value(SECTION, "resolution", resolution)
	cfg.set_value(SECTION, "max_fps", max_fps)
	cfg.set_value(SECTION, "vsync", vsync)
	return cfg.save(path)


## Lê o arquivo. Se não existir ou estiver quebrado, fica com os padrões.
static func load_from(path: String = DEFAULT_PATH) -> VideoSettings:
	var s := VideoSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return s
	s.screen = int(cfg.get_value(SECTION, "screen", s.screen))
	s.window_mode = int(cfg.get_value(SECTION, "window_mode", s.window_mode))
	var res = cfg.get_value(SECTION, "resolution", s.resolution)
	if res is Vector2i:
		s.resolution = res
	s.max_fps = int(cfg.get_value(SECTION, "max_fps", s.max_fps))
	s.vsync = bool(cfg.get_value(SECTION, "vsync", s.vsync))
	return s


## Aplica na janela principal (VD2, VD3, VD4, VD5). Instantâneo, sem animação.
func apply() -> void:
	var count := DisplayServer.get_screen_count()
	sanitize(count, DisplayServer.screen_get_size(clampi(screen, 0, count - 1)))
	var win := DisplayServer.MAIN_WINDOW_ID

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED, win)
	Engine.max_fps = max_fps

	if window_mode == MODE_FULLSCREEN:
		DisplayServer.window_set_current_screen(screen, win)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, win)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, win)
		DisplayServer.window_set_size(resolution, win)
		var origin := DisplayServer.screen_get_position(screen)
		var area := DisplayServer.screen_get_size(screen)
		DisplayServer.window_set_position(origin + (area - resolution) / 2, win)
