extends CheckBase
## Feature 9: arquitetura, API, RNG e simulação (Z1, Z2, Z4, Z6, Z7).
## godot --headless --path . -s tests/check_simulation.gd


func _initialize() -> void:
	label = "Verificações de simulação e arquitetura"

	# US-9.1 / Z1: nada em src/core depende de Node, cena ou UI
	var forbidden := ["extends Node", "extends Control", "extends Node2D", "extends CanvasItem", "extends SceneTree", "extends Window"]
	var files := 0
	for dir in ["res://src/core", "res://src/sim"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			files += 1
			var text := FileAccess.get_file_as_string(dir.path_join(f))
			for bad in forbidden:
				_check(not text.contains(bad), "%s/%s não pode usar '%s'" % [dir, f, bad])
			_check(not text.contains("get_tree()") and not text.contains("get_node("), "%s/%s sem árvore de nós" % [dir, f])
			_check(text.contains("extends RefCounted") or text.contains("extends Resource"), "%s/%s é RefCounted ou Resource" % [dir, f])
	_check(files >= 10, "verificou os arquivos do motor (%d)" % files)

	# US-9.2: a API de comandos faz o jogo andar sem tela
	var s := GameState.new_game(5)
	_check(s.get_state()["current_location"] == "fazenda", "get_state devolve dados simples")
	_check(JSON.stringify(s.get_state()) != "", "get_state serializa")
	var hoe: Dictionary = s.hand.filter(func(c: Dictionary) -> bool: return c["id"] == "enxada")[0]
	s.travel_to(&"roca")
	var soil: Dictionary = s.cards_at(&"roca")[0]
	_check(s.apply_recipe(hoe["uid"], soil["uid"]), "apply_recipe")
	var t := s.minutes
	s.advance_time(10)
	_check(s.minutes == t + 10, "advance_time")

	# US-9.4: mesma seed e mesmos comandos, mesmo resultado; seed diferente muda
	var a := Simulation.run({"seed": 11, "days": 30, "diligence": 0.5})
	var b := Simulation.run({"seed": 11, "days": 30, "diligence": 0.5})
	_check(a == b, "mesma seed, mesmo resultado")
	var differs := false
	for seed_value in [12, 13, 14, 15]:
		if Simulation.run({"seed": seed_value, "days": 30, "diligence": 0.5}) != a:
			differs = true
	_check(differs, "seeds diferentes mudam o resultado")

	# US-9.6: simulação com métricas
	var m := Simulation.run({"seed": 1, "days": 40})
	for key in ["days_survived", "bankrupt", "final_money", "avg_money", "bills_total", "bills_late", "late_rate"]:
		_check(m.has(key), "métrica: " + key)
	_check(m["days_survived"] >= 1 and m["days_survived"] <= 40, "dias dentro do limite")
	_check(m["late_rate"] >= 0.0 and m["late_rate"] <= 1.0, "taxa de atraso entre 0 e 1")
	_check(m["bills_total"] > 0, "gerou contas")

	# Bot descuidado atrasa mais que o diligente
	var careful := Simulation.run({"seed": 2, "days": 40, "diligence": 1.0, "bankruptcy_debt_limit": 0})
	var careless := Simulation.run({"seed": 2, "days": 40, "diligence": 0.0, "bankruptcy_debt_limit": 0})
	_check(careless["late_rate"] > careful["late_rate"], "quem não paga atrasa mais (%s vs %s)" % [careless["late_rate"], careful["late_rate"]])
	_check(careless["late_rate"] > 0.5, "sem pagar, quase tudo atrasa")

	# Sem pagar, a dívida estoura e o jogo acaba por falência
	var broke := Simulation.run({"seed": 3, "days": 200, "diligence": 0.0})
	_check(broke["bankrupt"] and broke["days_survived"] < 200, "bot que não paga fali (dias=%d)" % broke["days_survived"])

	# US-9.7: os valores iniciais são dados (peso em gramas em data/cards)
	var cat := CardCatalog.default()
	_check(cat.get_def(&"enxada").weight == 1200 and cat.get_def(&"mochila").extra["weight_limit"] == 20000, "pesos e limites vêm de dados")
	_finish()
