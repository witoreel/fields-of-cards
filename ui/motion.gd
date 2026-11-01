class_name Motion
extends RefCounted
## Animações curtas e suaves, por Tween (baseadas em tempo, W2). Com
## movimento reduzido ligado (W5), nada anima: o efeito é instantâneo.

const DURATION := 0.12


## Aparece com um fade curto. Devolve o Tween, ou null se foi instantâneo.
static func reveal(control: Control, duration: float = DURATION) -> Tween:
	if ComfortSettings.current().reduced_motion or not control.is_inside_tree():
		control.modulate.a = 1.0
		return null
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)
	return tween
