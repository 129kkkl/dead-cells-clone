extends Node
## Global signals.

signal player_health_changed(current: int, max_hp: int)
signal player_died
signal cells_changed(cells: int)
signal gold_changed(gold: int)
signal weapon_changed(slot: int, weapon_id: String)
signal skill_cooldown_changed(slot: int, ratio: float)
signal enemy_killed(enemy_id: String, pos: Vector2)
signal level_exited
signal collector_opened
signal toast(text: String)
signal biome_title(name: String)
signal hitstop_requested(duration: float)
signal camera_trauma(amount: float)
signal save_completed(slot: int)
signal run_started(seed_value: int)
