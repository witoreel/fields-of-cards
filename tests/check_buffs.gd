extends CheckBase
## Feature 15: buffs e debuffs (P4, S3, S4, T9, C9).
## godot --headless --path . -s tests/check_buffs.gd


func _initialize() -> void:
	label = "Verificações de buffs"
	var s := GameState.new_game(1, false)
	s.farm_area_limit = 1000
	_check(Buffs.multiplier(s, "time_mult") == 1.0 and Buffs.active(s).is_empty(), "sem buffs, tudo normal")

	# US-15.1: mochila pesada dá debuff
	s.select_card(s.hand[0]["uid"])
	var wood := s.spawn(&"madeira", GameState.BACKPACK, 7) # 14000 de 20000 = 70%
	_check(not Buffs.is_overloaded(s), "70% da mochila: leve")
	wood["n"] = 9 # 18000 = 90%
	_check(Buffs.is_overloaded(s), "90% da mochila: sobrecarregado")
	_check(Buffs.active(s).any(func(b: Dictionary) -> bool: return b["id"] == "sobrecarregado"), "debuff aparece")
	var t := s.minutes
	s.travel_to(&"floresta")
	_check(s.minutes - t == ceili(30 * 1.25), "sobrecarregado viaja 25%% mais devagar (%d min)" % (s.minutes - t))
	wood["n"] = 1
	_check(not Buffs.is_overloaded(s), "aliviou, o debuff some sozinho")

	# T9: cansado vem da tabela de efeitos (tempo maior e rendimento menor)
	s.advance_time(60)
	s.sleep()
	s.advance_time(17 * 60) # 23:00
	s.sleep()
	_check(s.is_tired() and s.buff_multiplier("time_mult") == 1.25 and absf(s.buff_multiplier("yield_mult") - 0.9) < 0.0001, "cansado: 1,25x tempo, 0,9x rendimento")
	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)
	t = s.minutes
	s.apply_recipe(hoe["uid"], soil["uid"])
	_check(s.minutes - t == ceili(30 * 1.25), "arar cansado leva 38 min")
	var plowed: Dictionary = s.cards_at(&"floresta").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(plowed["n"] == 4, "4 m² x 0,9 = 3,6 -> arredonda para 4")

	# US-15.2: alimentos dão buff, que expira
	s.sleep() # descansa
	_check(not s.is_tired(), "descansado")
	var bread := s.spawn(&"pao", GameState.HAND, 2)
	_check(s.select_card(bread["uid"]), "comer clicando")
	_check(bread["n"] == 1 and s.player_buffs.size() == 1 and s.player_buffs[0]["id"] == "energizado", "comeu 1 pão e ganhou energizado")
	_check(s.buff_multiplier("time_mult") == 0.9 and s.buff_multiplier("yield_mult") == 1.1, "energizado: 0,9x tempo, 1,1x rendimento")
	s.eat(bread["uid"])
	_check(s.player_buffs.size() == 1 and not s.hand.has(bread), "comer de novo renova, não acumula")
	_check(not s.eat(hoe["uid"]), "ferramenta não se come")
	s.advance_time(10)
	_check(s.player_buffs.size() == 1, "dura o dia")
	s.advance_time(1440)
	_check(s.player_buffs.filter(func(b: Dictionary) -> bool: return b["id"] == "energizado").is_empty(), "expirou depois de 1 dia")

	# S4: construção danificada rende menos
	var g := GameState.new_game(2)
	var half := Multipliers.location_multiplier(g, &"roca")
	g.extra_locations["roca"]["damaged"] = false
	_check(half == 0.5 * Multipliers.location_multiplier(g, &"roca"), "danificada vale metade da conservada")

	# C9: o buff escrito direto no jogador sobrepõe a tabela
	var base := s.buff_multiplier("time_mult")
	s.player_buffs.append({"id": "custom", "time_mult": 2.0})
	_check(absf(s.buff_multiplier("time_mult") - base * 2.0) < 0.0001, "buff com campo próprio")
	var r := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	_check(absf(r.buff_multiplier("time_mult") - base * 2.0) < 0.0001, "buffs sobrevivem ao save")
	_finish()
