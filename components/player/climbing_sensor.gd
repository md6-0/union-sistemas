extends Node3D


@onready var ray_surface = $RayCast3D_surface
@onready var ray_chest = $RayCast3D_chest
@onready var ray_arms = $RayCast3D_arms
var ledge_available = false

func _physics_process(_delta):
	if ray_surface.is_colliding() and ray_surface.get_collider().is_in_group("climbeable") and ray_chest.is_colliding() and ray_chest.get_collider().is_in_group("climbeable") and !ray_arms.is_colliding():
		ledge_available = true
	else:
		ledge_available = false

func is_ledge_available():
	if ledge_available:
		return {"available": true, "height": ray_surface.get_collision_point().y} 
	else: 
		return {"available": false, "height": -1} 
