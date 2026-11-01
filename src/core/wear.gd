class_name Wear
extends RefCounted
## Desgaste e manutenção das ferramentas (G1 a G5). Os números são
## provisórios, para balancear depois (Z7).
##
## Durabilidade e fio vão de 100 a 0 em state["durability"] e state["edge"].
## Nada quebra (G1): quanto menor a durabilidade, mais tempo a mesma ação leva.

const MAX := 100
## Com durabilidade 0 a ação leva 1 + SLOWDOWN vezes o tempo normal.
const SLOWDOWN := 3.0
## Idem para o fio, nas ferramentas de corte (propriedade "cutting").
const EDGE_SLOWDOWN := 1.0
## Pontos de durabilidade perdidos ao guardar sujo ou molhado (G5).
const STORE_PENALTY := 5
## Multiplicador da perda de durabilidade por status (G4).
const STATUS_WEAR := {"enferrujada": 1.5, "sujo": 1.25, "oleada": 0.5}


static func durability(card: Dictionary) -> int:
	return int(card.get("state", {}).get("durability", MAX))


static func edge(card: Dictionary) -> int:
	return int(card.get("state", {}).get("edge", MAX))


## Quanto a mais a ação demora com esta ferramenta (1.0 = normal).
static func time_factor(state: GameState, tool_card: Dictionary) -> float:
	if tool_card.is_empty() or not state.has_prop(tool_card, &"tool"):
		return 1.0
	var f := 1.0 + (1.0 - float(durability(tool_card)) / MAX) * SLOWDOWN
	if state.has_prop(tool_card, &"cutting"):
		f *= 1.0 + (1.0 - float(edge(tool_card)) / MAX) * EDGE_SLOWDOWN
	return f


static func _put(card: Dictionary, key: String, value: int) -> void:
	var st: Dictionary = card.get("state", {}).duplicate(true)
	st[key] = clampi(value, 0, MAX)
	card["state"] = st


## Desgasta uma ferramenta por um uso. A perda de fio é maior quando a
## durabilidade é baixa (G3), e os status mudam a perda (G4).
static func apply_use(state: GameState, tool_card: Dictionary, wear: int, edge_wear: int) -> void:
	if tool_card.is_empty() or (wear <= 0 and edge_wear <= 0):
		return
	var mult := 1.0
	for st in state.statuses_of(tool_card):
		mult *= float(STATUS_WEAR.get(st, 1.0))
	var dur := durability(tool_card)
	if wear > 0:
		_put(tool_card, "durability", dur - maxi(1, roundi(wear * mult)))
	if edge_wear > 0 and state.has_prop(tool_card, &"cutting"):
		var low_dur := 1.0 + (1.0 - float(dur) / MAX) # G3
		_put(tool_card, "edge", edge(tool_card) - maxi(1, roundi(edge_wear * low_dur)))


## Guardar ferramenta suja ou molhada na mochila ou storage reduz a
## durabilidade (G5).
static func on_stored(state: GameState, card: Dictionary) -> void:
	if state.has_prop(card, &"tool") and (state.has_status(card, "sujo") or state.has_status(card, "molhado")):
		_put(card, "durability", durability(card) - STORE_PENALTY)
