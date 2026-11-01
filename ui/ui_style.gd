class_name UiStyle
extends RefCounted
## Estilo visual da tela do jogo (vem do mockup/tela-jogo.html). Cores,
## tamanhos e fontes ficam aqui para ajustar num lugar só.

const BG := Color("#1d2420")
const PANEL := Color("#26302a")
const PANEL_LINE := Color("#3a483f")
const TEXT := Color("#cfd8cf")
const MUTED := Color("#8b998f")
const ACCENT := Color("#e0c15a")
const CARD := Color("#e9e1c8")
const CARD_LINE := Color("#b9ad86")
const CARD_TEXT := Color("#2b2a22")
const CARD_MUTED := Color("#5a5a48")
const CARD_FIXED := Color("#cfd8c4")
const CARD_MONEY := Color("#c8dcc0")
const CARD_PLACE := Color("#c4d3dc")

const GAP := 8
const MARGIN := 8
const CARD_SIZE := Vector2(130, 158)
const FONT := 12
const DOCK_BUTTON := Vector2(64, 64)
const GROUND_PADDING := 18
const GROUND_MAX_WIDTH := 760


static func box(bg: Color, border: Color, radius: int = 5, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	return s


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_stylebox("normal", "Button", box(PANEL, PANEL_LINE, 4))
	t.set_stylebox("hover", "Button", box(PANEL, ACCENT, 4))
	t.set_stylebox("pressed", "Button", box(Color("#3d4d43"), ACCENT, 4))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 4, 2))
	return t
