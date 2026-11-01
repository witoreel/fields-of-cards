class_name Economy
extends RefCounted
## Dinheiro, venda, compra e contas (D1-D5, D9, E1). Funções sobre um
## GameState; a API pública fica nos comandos dele.
##
## Dinheiro é uma carta "dinheiro" acumulável; a quantidade é o valor (D9).
## Conta é uma carta com estado {amount, due} (D3). Atraso gera multa uma vez
## (D5); os valores abaixo são provisórios e entram no balanceamento (Z7).

const MONEY := &"dinheiro"
const BILL := &"conta"
const FINE_PERCENT := 10


## Dinheiro que o jogador carrega (mão e mochila).
static func money(state: GameState) -> int:
	return _sum_money(state.hand) + _sum_money(state.backpack)


static func _sum_money(list: Array) -> int:
	var total := 0
	for c in list:
		if c["id"] == String(MONEY):
			total += int(c["n"])
	return total


## Entrega dinheiro na mão (soma à nota que já está lá).
static func give(state: GameState, amount: int) -> void:
	if amount > 0:
		state.spawn(MONEY, GameState.HAND, amount)


## Gasta dinheiro, primeiro da mão e depois da mochila (D2). Falso se faltar.
static func spend(state: GameState, amount: int) -> bool:
	if amount < 0 or money(state) < amount:
		return false
	var left := amount
	for list in [state.hand, state.backpack]:
		for i in range(list.size() - 1, -1, -1):
			if left == 0:
				break
			var c: Dictionary = list[i]
			if c["id"] != String(MONEY):
				continue
			var take := mini(int(c["n"]), left)
			c["n"] = int(c["n"]) - take
			left -= take
			if c["n"] == 0:
				list.remove_at(i)
	state.areas_changed.emit()
	return true


## Vende a pilha inteira (venda em lote, E1) numa carta caixa de venda.
## O dinheiro vai para a mão.
static func sell(state: GameState, uid: int, box_uid: int) -> bool:
	var l := state.find_card(uid)
	var lb := state.find_card(box_uid)
	if l.is_empty() or lb.is_empty():
		return false
	var card: Dictionary = state.area_cards(l["area"])[l["index"]]
	var box: Dictionary = state.area_cards(lb["area"])[lb["index"]]
	if not state.has_prop(box, &"sell_box"):
		return false
	var d := state.def_of(card)
	if d == null or not d.extra.has("sell_value"):
		return false
	var value := int(d.extra["sell_value"]) * int(card["n"])
	state.area_cards(l["area"]).remove_at(l["index"])
	give(state, value)
	state.areas_changed.emit()
	return true


## Compra uma carta da loja do local atual (D2). A compra vai para a mão.
static func buy(state: GameState, card_id: StringName) -> bool:
	var d := state.catalog.get_def(card_id)
	if d == null or not d.extra.has("price"):
		return false
	if StringName(d.extra.get("shop", "")) != state.current_location:
		return false
	if not spend(state, int(d.extra["price"])):
		return false
	state.spawn(card_id, GameState.HAND)
	return true


## Itens à venda no local atual: [{id, price}].
static func shop_items(state: GameState) -> Array:
	var out := []
	for id in state.catalog.defs:
		var d: CardDef = state.catalog.defs[id]
		if d.extra.has("price") and StringName(d.extra.get("shop", "")) == state.current_location:
			out.append({"id": id, "price": int(d.extra["price"])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return out


## Cria uma conta de `amount` com vencimento no minuto absoluto `due` (D3).
## Vai para a mão (até o correio existir, ver pendências).
static func issue_bill(state: GameState, amount: int, due: int) -> Dictionary:
	var c := state.spawn(BILL, GameState.HAND)
	c["state"] = {"amount": amount, "due": due}
	state.areas_changed.emit()
	return c


## Paga uma conta (D4). Precisa estar na cidade, onde se paga; ir até lá já
## gasta o tempo da viagem. Falta de dinheiro recusa.
static func pay_bill(state: GameState, uid: int) -> bool:
	if state.root_of(state.current_location) != &"cidade":
		return false
	var l := state.find_card(uid)
	if l.is_empty():
		return false
	var bill: Dictionary = state.area_cards(l["area"])[l["index"]]
	if bill["id"] != String(BILL) or not spend(state, int(bill["state"]["amount"])):
		return false
	var list := state.area_cards(l["area"])
	list.remove_at(list.find(bill))
	state.areas_changed.emit()
	return true


static func is_overdue(state: GameState, bill: Dictionary) -> bool:
	return state.minutes > int(bill["state"]["due"])


## Contas em aberto que o jogador carrega (mão e mochila).
static func open_bills(state: GameState) -> Array:
	var out := []
	for list in [state.hand, state.backpack]:
		for c in list:
			if c["id"] == String(BILL):
				out.append(c)
	return out


## Na virada do dia: conta atrasada ganha multa, uma vez só (D5). O jogo
## continua (sem game over imediato).
static func on_day_end(state: GameState) -> void:
	for bill in open_bills(state):
		var st: Dictionary = bill["state"]
		if state.minutes > int(st["due"]) and not st.get("fined", false):
			st["amount"] = int(st["amount"]) + maxi(1, int(st["amount"]) * FINE_PERCENT / 100)
			st["fined"] = true


## Soma das contas em aberto (D6).
static func total_debt(state: GameState) -> int:
	var total := 0
	for b in open_bills(state):
		total += int(b["state"]["amount"])
	return total


## Soma das contas já vencidas.
static func overdue_debt(state: GameState) -> int:
	var total := 0
	for b in open_bills(state):
		if is_overdue(state, b):
			total += int(b["state"]["amount"])
	return total
