class_name CardDef
extends Resource
## Definição de um tipo de carta (C6): é dado, não código.
## As propriedades se combinam (C1): location, tool, stackable, movable,
## fixed (inerente ao local), vehicle. Papéis de recipiente (backpack,
## storage) também são propriedades, para o núcleo crescer sem reescrita (Z8).

@export var id: StringName
@export var display_name: String = ""
@export var props: PackedStringArray = []
## Peso em gramas (P1). Cartas sem peso (dinheiro, locais) ficam em 0.
@export var weight: int = 0
## Campos livres para sistemas futuros (limites, valores, tempos...).
@export var extra: Dictionary = {}
