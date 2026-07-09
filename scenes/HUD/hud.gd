extends CanvasLayer

@onready var progressbar_player_health = %ProgressBar_player_health


func _ready():
	progressbar_player_health.value = GameManager.player_health
	GameManager.health_changed.connect(_handle_health)

func _handle_health(health):
	progressbar_player_health.value = health
