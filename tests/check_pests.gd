extends CheckBase
## Feature 27: pets, pragas e ajudantes (Y1 a Y3, Z4).
## godot --headless --path . -s tests/check_pests.gd


func _count(list: Array, id: String) -> int:
	var n := 0
	for c in list:
		if c["id"] == id:
			n += int(c["n"])
	return n


## Quantas noites, entre `nights`, tiveram o evento `prefix`.
func _nights_with(seed_value: int, prefix: String, nights: int, setup: Callable) -> int:
	var s := GameState.new_game(seed_value, false)
	s.pests_enabled = true
	setup.call(s)
	var hits := 0
	for i in nights:
		s.sleep()
		for e in s.last_events:
			if e.begins_with(prefix):
				hits += 1
	return hits


func _initialize() -> void:
	label = "Verificações de pragas e ajudantes"
	var with_dog := func(s: GameState) -> void:
		s.spawn(&"cachorro", GameState.LOCATION)

	# US-27.2 / Z4: sorteio reproduzível; sem cachorro há ataques, com cachorro não
	var a := _nights_with(5, "fox", 60, func(s: GameState) -> void: pass)
	var b := _nights_with(5, "fox", 60, func(s: GameState) -> void: pass)
	_check(a == b and a > 0, "mesma seed, mesmos ataques (%d de 60 noites)" % a)
	_check(_nights_with(5, "fox", 60, with_dog) == 0, "com cachorro, nenhum ataque de raposa (Y1)")
	var rats_no_cat := _nights_with(7, "rats", 60, func(s: GameState) -> void: pass)
	var rats_cat := _nights_with(7, "rats", 60, func(s: GameState) -> void: s.spawn(&"gato", GameState.LOCATION))
	_check(rats_no_cat > 0 and rats_cat == 0, "gato afasta ratos (%d contra %d)" % [rats_no_cat, rats_cat])
	_check(_nights_with(5, "rats", 60, with_dog) > 0, "cachorro não afasta rato")

	# Y2: efeito da raposa e dos ratos
	var s := GameState.new_game(1, false)
	s.spawn(&"galinha", GameState.LOCATION)
	s.spawn(&"galinha", GameState.LOCATION)
	s.spawn(&"ovo", GameState.LOCATION, 5)
	_check(Pests.fox_attack(s) == 1 and _count(s.cards_at(&"fazenda"), "galinha") == 1, "a raposa leva uma galinha")
	_check(_count(s.cards_at(&"fazenda"), "ovo") == 2, "e 3 ovos")
	Pests.fox_attack(s)
	_check(_count(s.cards_at(&"fazenda"), "ovo") == 0 and not s.cards_at(&"fazenda").any(func(c: Dictionary) -> bool: return c["id"] == "ovo"), "ovos acabam e a carta some")
	var f := GameState.new_game(2, false)
	f.spawn(&"terra_semeada", GameState.LOCATION, 5)
	_check(Pests.rat_attack(f) == 2, "rato estraga 2 m²")
	_check(_count(f.cards_at(&"fazenda"), "terra_semeada") == 3 and _count(f.cards_at(&"fazenda"), "terra_arada") == 2, "viraram terra arada")
	_check(f.farm_area_used() == 5, "os m² continuam ocupados")

	# US-27.3 / Y3: ajudantes
	var h := GameState.new_game(3, false)
	h.farm_area_limit = 100
	h.spawn(&"dinheiro", GameState.HAND, 100)
	h.spawn(&"terra_semeada", GameState.LOCATION, 10)
	h.spawn(&"ajudante_iniciante", GameState.LOCATION)
	h.sleep() # o ajudante rega 4 m² e eles crescem
	_check(h.money() == 90, "pagou o salário de 10")
	var grown := _count(h.cards_at(&"fazenda"), "terra_broto")
	_check(grown == 4 and _count(h.cards_at(&"fazenda"), "terra_semeada") == 6, "o iniciante regou só 4 m² (cresceram %d)" % grown)
	var pro := GameState.new_game(4, false)
	pro.farm_area_limit = 100
	pro.spawn(&"dinheiro", GameState.HAND, 100)
	pro.spawn(&"terra_semeada", GameState.LOCATION, 10)
	pro.spawn(&"ajudante_experiente", GameState.LOCATION)
	pro.sleep()
	_check(pro.money() == 70 and _count(pro.cards_at(&"fazenda"), "terra_broto") == 10, "o experiente custa 30 e regou os 10 m²")
	var broke := GameState.new_game(5, false)
	broke.spawn(&"terra_semeada", GameState.LOCATION, 10)
	broke.spawn(&"ajudante_iniciante", GameState.LOCATION)
	broke.sleep()
	_check(_count(broke.cards_at(&"fazenda"), "terra_broto") == 0, "sem salário o ajudante não trabalha")
	_finish()
