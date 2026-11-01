class_name CheckBase
extends SceneTree
## Base das verificações headless: `_check` conta falhas e `_finish` sai com
## código 1 se houver alguma. Cada tests/check_*.gd estende esta classe.

var failures := 0
var label := "Verificações"


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FALHOU: ", msg)


func _finish() -> void:
	print("%s concluídas, falhas: %d" % [label, failures])
	quit(1 if failures > 0 else 0)
