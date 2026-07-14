extends CanvasLayer

@onready var progressbar_player_health = %ProgressBar_player_health
@onready var colorRect_reticula = $ColorRect_reticula
@onready var colorRect_reticula_color = $ColorRect_reticula.color
var reticula_tween_fired

func _ready():
	progressbar_player_health.value = GameManager.player_health
	GameManager.health_changed.connect(_handle_health)
	GameManager.weapon_fired.connect(_handle_weapon_fired)
	GameManager.enemy_hit.connect(_handle_enemy_hit)
	colorRect_reticula.pivot_offset = colorRect_reticula.size / 2
	
func _handle_health(health):
	progressbar_player_health.value = health

func _handle_weapon_fired():
	if reticula_tween_fired and reticula_tween_fired.is_running():
		reticula_tween_fired.kill()
	reticula_tween_fired = create_tween().set_parallel(true)
	reticula_tween_fired.tween_property(colorRect_reticula, "scale", Vector2(2,2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.tween_property(colorRect_reticula, "color", Color.BLACK, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.chain().tween_property(colorRect_reticula, "color", colorRect_reticula_color, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.tween_property(colorRect_reticula, "scale", Vector2(1,1), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	
func _handle_enemy_hit():
	if reticula_tween_fired and reticula_tween_fired.is_running():
		reticula_tween_fired.kill()
	reticula_tween_fired = create_tween().set_parallel(true)
	reticula_tween_fired.tween_property(colorRect_reticula, "scale", Vector2(6,6), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.tween_property(colorRect_reticula, "color", Color.RED, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.chain().tween_property(colorRect_reticula, "color", colorRect_reticula_color, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	reticula_tween_fired.tween_property(colorRect_reticula, "scale", Vector2(1,1), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
