extends CheckBase
## Feature 25: skills (K1 a K3; K4 em aberto).
## godot --headless --path . -s tests/check_skills.gd


func _initialize() -> void:
	label = "Verificações de skills"
	var s := GameState.new_game(1, false)
	# K1: pontos por atividade, independentes
	_check(Multipliers.skill_summary(s).is_empty(), "sem pontos, nada a mostrar")
	s.add_skill(&"lavoura", 10)
	s.add_skill(&"madeira", 50)
	var sum := Multipliers.skill_summary(s)
	_check(sum.size() == 2 and sum[0]["activity"] == "lavoura" and sum[1]["activity"] == "madeira", "duas atividades, ordenadas")
	_check(sum[0]["points"] == 10 and sum[1]["points"] == 50, "pontos separados")
	# K2/K3: nível cresce com ganho decrescente, em porcentagem
	_check(sum[0]["percent"] == 18 and sum[1]["percent"] == 63, "10 pts -> 18%, 50 pts -> 63% (1 - e^-x)")
	s.add_skill(&"lavoura", 190)
	_check(Multipliers.skill_summary(s)[0]["percent"] == 98, "200 pontos -> 98%, nunca 100")
	# usar a atividade dá pontos
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)
	s.farm_area_limit = 100000
	s.apply_recipe(hoe["uid"], soil["uid"], 3)
	_check(s.skills["lavoura"] == 203, "arar 3 unidades deu 3 pontos")
	_finish()
