class_name BossData
extends EnemyData

## Datele specifice pentru un boss (ex: Tengu).
## Extinde EnemyData și adaugă pragul pentru Faza 2.
## Contract: docs/contracts.md, secțiunea 10.

@export var phase2_hp_ratio: float = 0.5     # Faza 2 începe când HP-ul ajunge la sau sub această fracțiune din max_hp
