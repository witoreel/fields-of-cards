class_name Mail
extends RefCounted
## Correio (M1 a M5, T6). A caixa de correio é um storage cujas cartas são
## cartas de correspondência. As cartas chegam quando o jogador acorda (T6),
## lidas ao clicar sem gastar tempo (M2). Uma carta lida pode trazer item
## anexo (M4) e promoções (M5).
##
## Carta = card {id: "carta", state: {title, text, attachments, promo, unlock}}.
## Entrada de data/mail.json = {day, title, text, attachments?, promo?, unlock?}.

const DATA_PATH := "res://data/mail.json"
const LETTER := &"carta"


## Fila inicial de correspondência (de dados).
static func load_schedule() -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return data if data is Array else []


## uid da caixa de correio, ou 0 se não há (alguma carta com "mailbox").
static func mailbox_uid(state: GameState) -> int:
	for loc in state.cards:
		for c in state.cards[loc]:
			if state.has_prop(c, &"mailbox"):
				return int(c["uid"])
	for c in state.hand:
		if state.has_prop(c, &"mailbox"):
			return int(c["uid"])
	return 0


## Enfileira uma carta para chegar no começo do dia `day` (ou do próximo).
static func send(state: GameState, entry: Dictionary, day: int = 0) -> void:
	var e := entry.duplicate(true)
	e["day"] = day if day > 0 else state.day_number() + 1
	state.mail_queue.append(e)


## Entrega na caixa tudo que venceu até hoje (T6). Sem caixa, a fila espera.
static func deliver(state: GameState) -> int:
	var box := mailbox_uid(state)
	if box == 0:
		return 0
	var today := state.day_number()
	var due: Array = state.mail_queue.filter(func(e: Dictionary) -> bool: return int(e["day"]) <= today)
	state.mail_queue = state.mail_queue.filter(func(e: Dictionary) -> bool: return int(e["day"]) > today)
	var contents: Array = state.storages[str(box)]
	for e in due:
		var letter := state.new_card(LETTER)
		var st := {"title": e.get("title", "Carta"), "text": e.get("text", "")}
		for key in ["attachments", "promo", "unlock"]:
			if e.has(key):
				st[key] = e[key].duplicate(true) if e[key] is Array or e[key] is Dictionary else e[key]
		letter["state"] = st
		contents.append(letter)
	if not due.is_empty():
		state.areas_changed.emit()
	return due.size()


## Cartas ainda não lidas na caixa.
static func unread(state: GameState) -> int:
	var box := mailbox_uid(state)
	if box == 0:
		return 0
	var n := 0
	for c in state.storages[str(box)]:
		if not c.get("state", {}).get("read", false):
			n += 1
	return n


## Carta de uma conta (M4): ao ler, a conta aparece com prazo de `due_days`.
static func send_bill(state: GameState, amount: int, due_days: int, day: int = 0) -> void:
	send(state, {
		"title": "Conta a pagar",
		"text": "Você tem uma conta de %d para pagar em até %d dias, na cidade." % [amount, due_days],
		"attachments": [{"id": "conta", "bill": {"amount": amount, "due_days": due_days}}],
	}, day)
