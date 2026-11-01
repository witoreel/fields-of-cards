class_name RecipeDef
extends Resource
## Receita como dado (C3, C6): arrastar `a` sobre `b` (ou, se `a` for vazio,
## usar `b` com um clique). Custo em minutos, o que se consome e o resultado.

@export var id: StringName
## Carta arrastada (normalmente a ferramenta). Vazio = receita de clique.
@export var a: StringName
## Carta alvo.
@export var b: StringName
## Unidades gastas de cada uma. 0 = a carta fica (ferramenta que não é consumida).
@export var a_use: int = 0
@export var b_use: int = 0
@export var minutes: int = 0
## Cartas criadas: [{"id": "madeira", "n": 1}]. Vão para a área do alvo.
@export var results: Array = []
## Estado acrescentado à carta alvo, por exemplo {"watered": true}.
@export var set_state_b: Dictionary = {}
## Volume gasto da carta `a` (o regador) por unidade de `b`, em gramas (P5).
## 0 = não usa volume. Sem volume suficiente, a receita não roda.
@export var a_volume_per_b: int = 0
