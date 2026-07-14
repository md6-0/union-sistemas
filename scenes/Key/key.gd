extends StaticBody3D

@onready var audioStreamPlayer = $AudioStreamPlayer

func interact(_camera):
	audioStreamPlayer.pitch_scale = randf_range(0.9, 1.1)
	audioStreamPlayer.play()
	if GameManager.inventory.has("key"):
		GameManager.inventory["key"] = 1
		audioStreamPlayer.finished.connect(queue_free)
		
