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
