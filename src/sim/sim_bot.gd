class_name SimBot
extends RefCounted
## Bot que joga um dia de fazenda usando só os comandos do GameState (Z2).
## `diligence` é a chance de ir pagar uma conta quando ela existe e há
## dinheiro; é o que gera atrasos na simulação (Z6).

var diligence := 0.7


static func _find(state: GameState, id: String) -> Dictionary:
	for area in state.open_areas():
		for c in state.area_cards(area):
			if c["id"] == id:
				return c
	return {}


## Joga um dia inteiro, terminando com dormir.
func play_day(state: GameState) -> void:
	if state.is_game_over:
		return
	var letter := _find(state, "carta_boas_vindas")
	if not letter.is_empty():
		state.select_card(letter["uid"])
	_farm(state)
	_sell(state)
	_pay(state)
	state.sleep()


func _farm(state: GameState) -> void:
	state.travel_to(&"roca")
	var hoe := _find(state, "enxada")
	var soil := _find(state, "terra_bruta")
	if not hoe.is_empty() and not soil.is_empty():
		state.apply_recipe(hoe["uid"], soil["uid"]) # falha sozinho se não couber
	var pot := _find(state, "regador")
	# Colhe o que está pronto.
	var ready := _find(state, "terra_pronta")
	while not ready.is_empty() and state.use_card(ready["uid"]):
		ready = _find(state, "terra_pronta")
	# Semeia o que der.
	var seeds := _find(state, "semente")
	var plowed := _find(state, "terra_arada")
	while not seeds.is_empty() and not plowed.is_empty() and state.apply_recipe(seeds["uid"], plowed["uid"]):
		seeds = _find(state, "semente")
		plowed = _find(state, "terra_arada")
	# Rega semeado e broto.
	if not pot.is_empty():
		for id in ["terra_semeada", "terra_broto"]:
			var plant := _find(state, id)
			if not plant.is_empty():
				state.apply_recipe(pot["uid"], plant["uid"])
	# Leva a colheita na mão.
	var crop := _find(state, "colheita")
	if not crop.is_empty():
		state.move_card(crop["uid"], GameState.HAND)


func _sell(state: GameState) -> void:
	var crop := _find(state, "colheita")
	if crop.is_empty():
		return
	state.travel_to(&"fazenda")
	var box := _find(state, "caixa_venda")
	crop = _find(state, "colheita")
	if not box.is_empty() and not crop.is_empty():
		state.apply_recipe(crop["uid"], box["uid"])


func _pay(state: GameState) -> void:
	var bills := Economy.open_bills(state)
	if bills.is_empty() or state.rng.randf() > diligence:
		return
	state.travel_to(&"cidade")
	for b in bills:
		state.pay_bill(b["uid"]) # só paga se houver dinheiro
