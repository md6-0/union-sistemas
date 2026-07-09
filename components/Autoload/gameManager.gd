extends Node

var inventory = {
	"key": 0
}

signal health_changed(new_health)

var player_health: int = 100: 
	set(value):
		player_health = value
		health_changed.emit(player_health)
