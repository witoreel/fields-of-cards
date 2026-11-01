class_name Simulation
extends RefCounted
## Simulação longa headless com bots (Z6). Reproduzível: a mesma seed e a
## mesma configuração dão o mesmo resultado (Z4). Os valores padrão são
## suposições de simulação, não regras do jogo: valores e frequência das
## contas estão em aberto, e a água do regador e as sementes ainda não têm
## fonte no jogo (ver "Em aberto"). O bot enche o regador no açude.

const DEFAULTS := {
	"days": 60,
	"seed": 1,
	"bill_amount": 40,
	"bill_period_days": 3,
	"bill_due_days": 4,
	"diligence": 0.7,
	"bankruptcy_debt_limit": 150,
	"daily_seeds": 4, # suposição: sementes que chegam por dia
	"refill_water": false, # suposição opcional: o regador enche sozinho todo dia
}


## Roda uma simulação e devolve as métricas:
## days_survived, bankrupt, final_money, avg_money, bills_total, bills_late,
## late_rate.
static func run(config: Dictionary = {}) -> Dictionary:
	var cfg := DEFAULTS.duplicate()
	cfg.merge(config, true)
	var state := GameState.new_game(int(cfg["seed"]))
	state.bankruptcy_debt_limit = int(cfg["bankruptcy_debt_limit"])
	var bot := SimBot.new()
	bot.diligence = float(cfg["diligence"])
	var bills_total := 0
	var late: Dictionary = {} # uid -> true
	var money_sum := 0
	var days_played := 0
	while days_played < int(cfg["days"]) and not state.is_game_over:
		days_played += 1
		var day := state.day_number()
		if day > 1 and day % int(cfg["bill_period_days"]) == 0:
			state.issue_bill(int(cfg["bill_amount"]), state.minutes + int(cfg["bill_due_days"]) * GameState.MINUTES_PER_DAY)
			bills_total += 1
		if int(cfg["daily_seeds"]) > 0:
			state.spawn(&"semente", GameState.HAND, int(cfg["daily_seeds"]))
		if cfg["refill_water"]:
			for c in state.hand:
				if c["id"] == "regador" and c.has("state"):
					c["state"].erase("volume")
		bot.play_day(state)
		for b in Economy.open_bills(state):
			if b["state"].get("fined", false):
				late[b["uid"]] = true
		money_sum += state.money()
	var played := maxi(days_played, 1)
	return {
		"days_survived": days_played,
		"bankrupt": state.is_game_over,
		"final_money": state.money(),
		"avg_money": float(money_sum) / played,
		"bills_total": bills_total,
		"bills_late": late.size(),
		"late_rate": float(late.size()) / maxi(bills_total, 1),
	}
