extends StaticBody3D

@onready var elevator = $".."

func interact(_camera):
	elevator.activate()
