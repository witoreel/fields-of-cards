class_name LostFound
extends RefCounted
## Achados e perdidos (H4, H5). Na virada do dia, tudo que sobrou no chão dos
## locais vai para o achados e perdidos, que guarda por 7 dias e avisa por
## carta. A vila ainda não existe: até lá ele fica na cidade (ver pendências).

const DAYS := 7
const PLACE := &"cidade"


## Roda na virada do dia, depois que `day_number()` já é o do dia novo.
static func on_day_end(state: GameState) -> void:
	var moved := 0
	for loc in state.stages:
		var list: Array = state.stages[loc]
		for card in list:
			card["since_day"] = state.day_number()
			state.lost_and_found.append(card)
			moved += 1
		list.clear()
	var kept: Array = []
	var expired := 0
	for card in state.lost_and_found:
		if state.day_number() - int(card["since_day"]) >= DAYS:
			expired += 1
		else:
			kept.append(card)
	state.lost_and_found = kept
	if moved > 0:
		Mail.send(state, {
			"title": "Achados e perdidos",
			"text": "Você deixou %d carta(s) no chão. Elas foram para o achados e perdidos da cidade e ficam lá por %d dias." % [moved, DAYS],
		}, state.day_number())


## Dias que ainda restam para uma carta guardada.
static func days_left(state: GameState, card: Dictionary) -> int:
	return DAYS - (state.day_number() - int(card["since_day"]))


## Comando: pega uma carta de volta, na mão. Só dá na cidade.
static func claim(state: GameState, uid: int) -> bool:
	if state.root_of(state.current_location) != PLACE:
		return false
	for i in state.lost_and_found.size():
		var card: Dictionary = state.lost_and_found[i]
		if int(card["uid"]) == uid:
			state.lost_and_found.remove_at(i)
			card.erase("since_day")
			if state._stack_into(state.hand, card).is_empty():
				state.hand.append(card)
			state.areas_changed.emit()
			return true
	return false
