class_name Multipliers
extends RefCounted
## Multiplicadores do que as ações produzem (V3, V4, V5, R8, E2, E3).
## O resultado é produto de: qualidade da ferramenta × skill × construção
## (o local onde se trabalha). Valores provisórios, para balancear (Z7).

## A skill (K1 a K3) cresce como 1 - e^(-x): cada ponto vale menos que o
## anterior. SKILL_SCALE é quantos pontos levam a ~63% do máximo.
const SKILL_SCALE := 50.0
## Bônus máximo da skill: com nível 1,0 o resultado vira 1 + SKILL_BONUS vezes.
const SKILL_BONUS := 1.0
## Construção danificada rende menos (S4).
const DAMAGE_FACTOR := 0.5


## Qualidade da ferramenta (V3): extra["quality"] da definição, 1.0 por padrão.
static func tool_quality(state: GameState, tool_card: Dictionary) -> float:
	if tool_card.is_empty():
		return 1.0
	var d := state.def_of(tool_card)
	return float(d.extra.get("quality", 1.0)) if d != null else 1.0


## Nível de skill de 0 a 1 numa atividade (K3).
static func skill_level(state: GameState, activity: StringName) -> float:
	var points := float(state.skills.get(String(activity), 0))
	return 1.0 - exp(-points / SKILL_SCALE)


static func skill_multiplier(state: GameState, activity: StringName) -> float:
	if activity == &"":
		return 1.0
	return 1.0 + skill_level(state, activity) * SKILL_BONUS


## Multiplicador do local onde se trabalha (V5, R8). Roça construída tem o
## dela; dano reduz (S4).
static func location_multiplier(state: GameState, id: StringName) -> float:
	var m := float(state.extra_locations.get(String(id), {}).get("multiplier", 1.0))
	if state.is_damaged(id):
		m *= DAMAGE_FACTOR
	return m


## Multiplicador total de uma ação feita agora com a ferramenta dada.
static func total(state: GameState, tool_card: Dictionary, activity: StringName) -> float:
	return tool_quality(state, tool_card) * skill_multiplier(state, activity) \
		* location_multiplier(state, state.current_location) * state.buff_multiplier("yield_mult")


## Quantidade final de um resultado "scaled".
static func scaled(base: int, mult: float) -> int:
	return maxi(1, roundi(base * mult)) if base > 0 else 0
