extends CheckBase
## Feature 1: receitas por arrastar (C2, C3, C6, R1-R7, R9).
## godot --headless --path . -s tests/check_recipes.gd


func _count(list: Array, id: String) -> int:
	var total := 0
	for c in list:
		if c["id"] == id:
			total += int(c["n"])
	return total


func _initialize() -> void:
	label = "Verificações de receitas"
	var s := GameState.new_game(1)

	# US-1.4: receitas e cartas vêm de dados
	_check(s.recipes.recipes.size() >= 8, "receitas carregadas de data/recipes")
	_check(s.recipes.find(&"enxada", &"terra_bruta") != null, "receita de arar existe")

	var soil := s.spawn(&"terra_bruta", GameState.LOCATION)
	var hoe := s.spawn(&"enxada", GameState.HAND)
	var pot := s.spawn(&"regador", GameState.HAND)
	var seed_c := s.spawn(&"semente", GameState.HAND, 3)

	# US-1.1: sem receita nada muda
	var t0 := s.minutes
	_check(not s.apply_recipe(hoe["uid"], pot["uid"]), "enxada + regador não faz nada")
	_check(not s.apply_recipe(seed_c["uid"], soil["uid"]), "semente + terra bruta não faz nada")
	_check(s.hand.size() == 4 and s.minutes == t0 and seed_c["n"] == 3, "estado intacto após recusa")
	_check(not s.apply_recipe(hoe["uid"], hoe["uid"]), "carta sobre si mesma")

	# US-1.5 / 1.2 / 1.3: arar, com custo e ferramenta mantida
	_check(s.apply_recipe(hoe["uid"], soil["uid"]), "arar")
	_check(_count(s.cards_at(&"fazenda"), "terra_arada") == 4, "4 m² de terra arada")
	_check(s.minutes == t0 + 30, "arar gastou 30 min")
	_check(s.hand.any(func(c: Dictionary) -> bool: return c["uid"] == hoe["uid"]), "enxada não é consumida")
	_check(s.cards_at(&"fazenda").any(func(c: Dictionary) -> bool: return c["uid"] == soil["uid"]), "terra bruta é infinita (N1)")
	# Arar de novo soma à carta existente (C4)
	s.apply_recipe(soil["uid"], hoe["uid"]) # ordem invertida também vale
	_check(_count(s.cards_at(&"fazenda"), "terra_arada") == 8 and s.cards_at(&"fazenda").size() == 2, "somou 8 m² numa carta")

	# US-1.6: semear consome 1 semente e 1 m²
	var plowed: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_arada")[0]
	_check(s.apply_recipe(seed_c["uid"], plowed["uid"]), "semear")
	_check(seed_c["n"] == 2 and plowed["n"] == 7, "gastou 1 semente e 1 m²")
	_check(_count(s.cards_at(&"fazenda"), "terra_semeada") == 1, "terra semeada criada")
	s.apply_recipe(seed_c["uid"], plowed["uid"])
	s.apply_recipe(seed_c["uid"], plowed["uid"])
	_check(not s.hand.any(func(c: Dictionary) -> bool: return c["id"] == "semente"), "semente acabou e saiu da mão")
	_check(not s.apply_recipe(seed_c["uid"], plowed["uid"]), "sem semente não semeia")

	# US-1.7 / 1.8 / R9: rega e crescimento por dia
	var sown: Dictionary = s.cards_at(&"fazenda").filter(func(c: Dictionary) -> bool: return c["id"] == "terra_semeada")[0]
	_check(sown["n"] == 3, "3 m² semeados")
	s.sleep() # sem rega: congelada
	_check(sown["id"] == "terra_semeada", "sem rega não cresce (R9)")
	_check(s.apply_recipe(pot["uid"], sown["uid"]), "regar")
	_check(sown["state"]["watered"] == true, "marcada como regada")
	s.sleep()
	_check(sown["id"] == "terra_broto", "regada, virou broto")
	_check(not sown.has("state"), "estado de rega zerado")
	s.sleep()
	_check(sown["id"] == "terra_broto", "broto sem rega fica congelado")
	s.apply_recipe(pot["uid"], sown["uid"])
	s.sleep()
	_check(sown["id"] == "terra_pronta", "regado, ficou pronto")

	# US-1.9: colher
	_check(s.use_card(sown["uid"]), "colher")
	_check(_count(s.cards_at(&"fazenda"), "colheita") == 1 and sown["n"] == 2, "1 colheita, 2 m² prontos")
	_check(_count(s.cards_at(&"fazenda"), "terra_arada") == 6, "o m² colhido volta a ser terra arada")
	s.select_card(sown["uid"]) # clique na carta também colhe
	s.select_card(sown["uid"])
	_check(_count(s.cards_at(&"fazenda"), "colheita") == 3 and _count(s.cards_at(&"fazenda"), "terra_pronta") == 0, "colheu tudo")

	# Estágios diferentes somam por estágio (um estágio é uma carta)
	var a := s.spawn(&"terra_semeada", GameState.STAGE, 2)
	var b := s.spawn(&"terra_semeada", GameState.STAGE, 1)
	_check(a["uid"] == b["uid"] and a["n"] == 3, "mesmo estágio soma")
	s.spawn(&"terra_broto", GameState.STAGE, 1)
	_check(s.stages["fazenda"].size() == 2, "estágio diferente é outra carta")
	# Rega só nos regados: uma parte regada, outra não, depois de somar
	s.spawn(&"terra_semeada", GameState.LOCATION)

	# US-1.10: cortar árvore (machado ou serrote); árvore infinita
	s.travel_to(&"floresta")
	var tree := s.spawn(&"arvore", GameState.LOCATION)
	var axe := s.spawn(&"machado", GameState.HAND)
	var saw := s.spawn(&"serrote", GameState.HAND)
	_check(s.apply_recipe(axe["uid"], tree["uid"]) and s.apply_recipe(saw["uid"], tree["uid"]), "machado e serrote cortam")
	_check(_count(s.cards_at(&"floresta"), "madeira") == 2 and s.cards_at(&"floresta").has(tree), "2 madeiras e a árvore continua")

	# US-1.11: construir com martelo + madeira
	var hammer := s.spawn(&"martelo", GameState.HAND)
	var wood: Dictionary = s.cards_at(&"floresta").filter(func(c: Dictionary) -> bool: return c["id"] == "madeira")[0]
	_check(s.apply_recipe(hammer["uid"], wood["uid"]), "construir")
	_check(wood["n"] == 1 and _count(s.cards_at(&"floresta"), "construcao") == 1, "gastou 1 madeira e criou construção")

	# Receita de data externa: conteúdo novo sem código (US-1.4)
	var extra := RecipeDef.new()
	extra.id = &"teste"
	extra.a = &"enxada"
	extra.b = &"regador"
	extra.minutes = 5
	extra.results = [{"id": "madeira", "n": 2}]
	s.recipes.recipes.append(extra)
	var t1 := s.minutes
	_check(s.apply_recipe(hoe["uid"], pot["uid"]) and s.minutes == t1 + 5, "receita nova funciona sem mexer em código")
	s.recipes.recipes.pop_back()
	_finish()
