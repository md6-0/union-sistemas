extends Node


signal health_changed(new_health)
signal weapon_fired
signal enemy_hit

var inventory = {
	"key": 0
}

var player_health: int = 100: 
	set(value):
		player_health = value
		health_changed.emit(player_health)


var hitstop_end_time = 0

func hitstop(duration := .075, scale := 0.05):
	Engine.time_scale = scale
	hitstop_end_time = max(hitstop_end_time, Time.get_ticks_msec() + duration * 1000)

func _process(_delta):
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() >= hitstop_end_time:
		Engine.time_scale = 1.0
