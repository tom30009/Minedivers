# PhysicsCube.gd - прикрепите этот скрипт к RigidBody3D
extends RigidBody3D

@export var life_time = 30.0


var timer = 0.0

func _ready():
	mass = mass
	gravity_scale = 1.0
	linear_damp = 0.1
	angular_damp = 0.1
	timer = life_time
	
	# Создаем визуал куба
	var mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(2, 2, 2)
	mesh_instance.mesh = cube_mesh
	
	# Материал
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)
	
	add_child(mesh_instance)
	
	# Коллизия
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 2, 2)
	collision_shape.shape = shape
	add_child(collision_shape)

func _process(delta):
	timer -= delta
	if timer <= 0:
		queue_free()
