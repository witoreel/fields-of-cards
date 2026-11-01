extends SceneTree
## Simulação headless. Exemplo:
##   godot --headless --path . -s tools/simulate.gd -- days=90 seed=3 diligence=0.5
## Parâmetros: ver Simulation.DEFAULTS. Imprime as métricas.


func _initialize() -> void:
	var cfg := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=")
		if parts.size() == 2:
			var v: Variant = parts[1]
			if parts[1].is_valid_int():
				v = parts[1].to_int()
			elif parts[1].is_valid_float():
				v = parts[1].to_float()
			elif parts[1] in ["true", "false"]:
				v = parts[1] == "true"
			cfg[parts[0]] = v
	var m := Simulation.run(cfg)
	for k in m:
		print("%s: %s" % [k, m[k]])
	quit(0)
