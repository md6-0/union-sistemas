extends StaticBody3D

func interact(_camera):
	if GameManager.inventory.has("key"):
		GameManager.inventory["key"] = 1
		queue_free()
