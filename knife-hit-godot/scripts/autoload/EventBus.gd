extends Node

# Knife Events
signal knife_thrown
signal knife_hit_target(pos: Vector2, angle: float)
signal knife_hit_knife(pos: Vector2)
signal apple_collected(pos: Vector2)

# Stage & Game State Events
signal stage_started(stage_num: int, is_boss: bool, boss_name: String)
signal stage_cleared(stage_num: int)
signal game_over(stage_num: int, score: int)
signal game_revived

# Economy & UI Events
signal score_changed(new_score: int)
signal apples_changed(total_apples: int)
signal knives_count_changed(remaining: int, total: int)
signal skin_changed(knife_id: String)

# Flow Requests
signal request_restart
signal request_continue
signal request_pause
