extends CheckBase
## Feature 2: relógio e dia (T1-T5, T7-T9).
## godot --headless --path . -s tests/check_clock.gd


func _initialize() -> void:
	label = "Verificações do relógio"
	var s := GameState.new_game(1, false)
	var woke := []
	var ended := []
	var events := []
	s.woke_up.connect(func(d: int) -> void: woke.append(d))
	s.day_ended.connect(func(d: int) -> void: ended.append(d))
	s.event_due.connect(func(k: String, d: Dictionary) -> void: events.append([k, d, s.minutes]))

	# US-2.1: começa às 06:00 do dia 1
	_check(s.clock_text() == "Dia 1, 06:00", "começa às 06:00 (%s)" % s.clock_text())
	# US-2.2: ações gastam minutos
	s.advance_time(90)
	_check(s.clock_text() == "Dia 1, 07:30", "avança 90 min")
	s.advance_time(0)
	_check(s.minutes == 450, "custo zero não muda o relógio")
	_check(s.travel_minutes(&"fazenda", &"cidade") == 60 and s.travel_minutes(&"cidade", &"fazenda") == 60, "tabela de viagem é simétrica")
	_check(s.travel_minutes(&"cidade", &"feira") == 0, "dentro da mesma raiz custa 0")
	s.travel_to(&"cidade")
	_check(s.minutes == 450 + 60, "viajar gasta minutos")
	s.travel_to(&"ferragem")
	_check(s.minutes == 510, "ir da cidade à ferragem não gasta")

	# US-2.3: eventos agendados vencem em ordem com o relógio
	s.schedule(s.minutes + 30, "b", {"x": 2})
	s.schedule(s.minutes + 10, "a", {"x": 1})
	s.advance_time(5)
	_check(events.is_empty(), "nada venceu ainda")
	s.advance_time(30)
	_check(events.size() == 2 and events[0][0] == "a" and events[1][0] == "b", "venceram em ordem")
	_check(s.scheduled.is_empty(), "agenda esvaziada")

	# US-2.4: dormir leva às 06:00 do dia seguinte
	s.sleep()
	_check(s.clock_text() == "Dia 2, 06:00", "acorda às 06:00 do dia 2 (%s)" % s.clock_text())
	_check(ended == [1] and woke == [2], "sinais de fim de dia e de acordar")
	_check(not s.is_tired(), "dormir antes das 22:00 não cansa (US-2.7)")

	# US-2.7: depois das 22:00 acordado, acorda cansado
	s.advance_time(16 * 60 + 30) # 22:30
	_check(s.clock_text() == "Dia 2, 22:30", "22:30")
	s.sleep()
	_check(s.clock_text() == "Dia 3, 06:00" and s.is_tired(), "acorda cansado")
	s.sleep()
	_check(not s.is_tired(), "o cansaço passa depois de dormir cedo")

	# US-2.6: meia-noite é inevitável, e o que sobra da ação se perde
	s.advance_time(17 * 60) # 23:00 do dia 4... 06:00 + 17h
	_check(s.clock_text() == "Dia 4, 23:00", "23:00 do dia 4")
	s.advance_time(120)
	_check(s.clock_text() == "Dia 5, 06:00" and s.is_tired(), "a meia-noite fez dormir (%s)" % s.clock_text())
	# Ação que termina exatamente à meia-noite também vira o dia
	s.advance_time(18 * 60)
	_check(s.clock_text() == "Dia 6, 06:00", "00:00 exata vira o dia (%s)" % s.clock_text())
	# Acordar longe de casa: o jogador fica onde está (aberto)
	_check(s.current_location == &"ferragem", "continua no mesmo local")
	# Dormir de madrugada não existe: sleep às 06:00 pula o dia
	var before := s.minutes
	s.sleep()
	_check(s.minutes == before + 1440, "dormir às 06:00 leva ao dia seguinte")

	# Eventos que vencem durante a noite
	s.schedule(s.minutes + 1100, "madrugada") # 00:20
	events.clear()
	s.advance_time(2000)
	_check(events.size() == 1 and events[0][2] % 1440 == 360, "evento da noite dispara ao acordar")

	# T5/US-2.5: tempos de crescimento são dados (campo extra da definição)
	_check(s.catalog.get_def(&"semente").extra.get("grow_minutes", -1) != -1, "crescimento da semente é dado")

	# Save guarda relógio, buffs e agenda
	s.schedule(s.minutes + 5, "k", {"a": 1})
	s.sleep()
	s.advance_time(17 * 60 + 5)
	s.sleep()
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.minutes == s.minutes and r.is_tired() == s.is_tired(), "relógio e debuff salvos")
	s.schedule(s.minutes + 5, "k", {"a": 1})
	r = GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(r.scheduled.size() == 1 and r.scheduled[0]["at"] == s.scheduled[0]["at"] and r.scheduled[0]["data"]["a"] == 1, "agenda salva")
	_finish()
