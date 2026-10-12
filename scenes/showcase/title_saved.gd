extends "res://scenes/title/title.gd"
## For review renders: the title with a save to continue (day 4, 18:40, in
## Millbrook), written to a review-only file, never the real save.


func _ready() -> void:
	save_path = "user://review_title_save.json"
	travels = false
	var state: GameState = GameState.new_game()
	state.save_path = save_path
	state.clock.total_minutes += 3 * GameClock.MINUTES_PER_DAY + 12 * 60 + 40
	state.travel(GameState.MILLBROOK, GameState.AT_GATE)
	state.save()
	super()
