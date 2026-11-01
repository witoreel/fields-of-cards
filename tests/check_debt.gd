extends CheckBase
## Feature 8: dívida e falência (D5-D8, F1).
## godot --headless --path . -s tests/check_debt.gd


func _initialize() -> void:
	label = "Verificações de dívida e falência"
	var s := GameState.new_game(1)
	var overs := []
	s.game_over.connect(func(r: String) -> void: overs.append(r))

	# US-8.1: dívida evolui com o relógio
	var b1 := s.issue_bill(100, s.minutes + 1000)
	var b2 := s.issue_bill(200, s.minutes + 5000)
	_check(Economy.total_debt(s) == 300 and Economy.overdue_debt(s) == 0, "300 em aberto, 0 vencido")
	s.advance_time(1020)
	_check(Economy.overdue_debt(s) == 100, "a primeira venceu")
	s.sleep()
	_check(b1["state"]["amount"] == 110, "multa na virada do dia")
	_check(not s.is_game_over, "atraso não é game over (D5)")
	_check(Economy.total_debt(s) == 310, "dívida total 310")

	# Sem gatilho configurado, nunca falimos sozinhos (F2 em aberto)
	for i in 10:
		s.sleep()
	_check(not s.is_game_over and overs.is_empty(), "gatilho desligado por padrão")

	# US-8.2: falência encerra o jogo
	s.bankruptcy_debt_limit = 250
	s.sleep()
	_check(s.is_game_over and overs.size() == 1, "dívida vencida acima do limite faliu")
	_check("dívida" in s.game_over_reason, "motivo registrado")

	# Depois da falência os comandos são recusados
	var t := s.minutes
	s.sleep()
	s.advance_time(60)
	_check(s.minutes == t, "o relógio parou")
	_check(not s.travel_to(&"floresta") and s.current_location == &"fazenda", "não viaja")
	var hoe := s.spawn(&"enxada", GameState.HAND)
	_check(not s.move_card(hoe["uid"], GameState.STAGE), "não move cartas")
	_check(not s.select_card(hoe["uid"]) and not s.buy(&"enxada"), "não seleciona nem compra")
	s.declare_bankruptcy("outra")
	_check(overs.size() == 1, "falir duas vezes emite uma vez só")

	# Estado de fim de jogo persiste
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.is_game_over and r.game_over_reason == s.game_over_reason and r.bankruptcy_debt_limit == 250, "falência sobrevive ao save")
	r.sleep()
	_check(r.minutes == s.minutes, "jogo carregado continua encerrado")

	# Falência declarada diretamente (gatilho futuro)
	var s2 := GameState.new_game(2)
	s2.declare_bankruptcy("teste")
	_check(s2.is_game_over, "declare_bankruptcy encerra")
	_finish()
