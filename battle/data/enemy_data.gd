class_name EnemyData
extends Resource

## Datele statistice și vizuale ale unui inamic obișnuit.
## Contract: docs/contracts.md, secțiunea 10.

@export var id: String = ""
@export var name_key: String = ""            # Cheie din ui.csv, de ex. BATTLE_ENEMY_KAPPA
@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 0
@export var sprite: Texture2D
