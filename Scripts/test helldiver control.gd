extends CharacterBody3D

# Настройки движения
@export var speed : float = 5.0
@export var jump_force : float = 4.5

var stratagem_display : Node3D = null
var direction_labels : Array = []
var input_spheres : Array = []

# Настройки стрельбы
@export var fire_rate : float = 0.2
@export var bullet_damage : int = 10
@export var max_ammo : int = 30
@export var ammo_per_shot : int = 1

# Настройки здоровья
@export var max_health : int = 100
@export var health_regeneration : float = 0.5

# Настройки стратагем
@export var stratagem_input_timeout : float = 3.0
@export var stratagem_max_input_length : int = 4

# Ссылки на ноды
@onready var mesh_instance = $MeshInstance3D
@onready var camera = get_viewport().get_camera_3d()
@onready var raycast = $MeshInstance3D/RayCast3D

# Переменные
var current_ammo : int
var current_health : int
var can_shoot : bool = true
var shoot_cooldown : float = 0.0
var is_alive : bool = true
var last_health : int = 0
var last_ammo : int = 0

# Система стратагем
enum StratagemDirection {UP, DOWN, LEFT, RIGHT, NONE}

var available_stratagems = {}
var current_stratagem = null
var stratagem_input_sequence = []
var stratagem_input_timer = 0.0
var is_stratagem_input_active : bool = false
var ctrl_pressed : bool = false

# Гравитация
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	current_ammo = max_ammo
	current_health = max_health
	last_health = current_health
	last_ammo = current_ammo
	initialize_stratagems()
	create_3d_ui()  # ← ДОБАВЬТЕ ЭТУ СТРОЧКУ
	update_ui()

func create_3d_ui():
	# Создаем контейнер для UI над головой игрока
	stratagem_display = Node3D.new()
	stratagem_display.name = "StratagemDisplay"
	add_child(stratagem_display)
	stratagem_display.position = Vector3(0, 2.5, 0)  # 2.5 метра над игроком
	stratagem_display.visible = false
	
	# Поворачиваем весь UI на 90 градусов вокруг оси X, чтобы смотреть вверх
	stratagem_display.rotation_degrees.x = -90
	
	# Правильное соответствие стрелок и направлений:
	# 0: Вверх (W) - ↑
	# 1: Вправо (D) - →  
	# 2: Вниз (S) - ↓
	# 3: Влево (A) - ←
	
	var directions = [
		{"pos": Vector3(0, 1.2, 0), "rot": 0,    "key": "W"},    # Вверх
		{"pos": Vector3(1.2, 0, 0), "rot": 90,   "key": "D"},    # Вправо
		{"pos": Vector3(0, -1.2, 0), "rot": 180, "key": "S"},    # Вниз  
		{"pos": Vector3(-1.2, 0, 0), "rot": 270, "key": "A"}     # Влево
	]
	
	for i in range(4):
		var arrow = MeshInstance3D.new()
		var arrow_mesh = BoxMesh.new()
		arrow_mesh.size = Vector3(0.3, 0.1, 0.8)  # Длинная стрелка
		arrow.mesh = arrow_mesh
		
		# Позиция и поворот из массива directions
		arrow.position = directions[i].pos
		arrow.rotation_degrees.z = directions[i].rot
		
		# Материал - серый по умолчанию
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.5, 0.5, 0.5, 0.8)
		arrow.material_override = material
		
		stratagem_display.add_child(arrow)
		input_spheres.append(arrow)
	
	# Создаем центральный текст для отображения последовательности
	var center_text = TextMesh.new()
	center_text.text = ""
	center_text.pixel_size = 0.04
	center_text.depth = 0.05
	center_text.font_size = 64
	
	var text_mesh = MeshInstance3D.new()
	text_mesh.mesh = center_text
	text_mesh.position.y = 0.2
	
	var text_material = StandardMaterial3D.new()
	text_material.albedo_color = Color.WHITE
	text_material.flags_unshaded = true
	text_material.flags_no_depth_test = true
	text_mesh.material_override = text_material
	
	stratagem_display.add_child(text_mesh)
	direction_labels.append(text_mesh)
	
	print("3D UI создан (вертикальный для камеры сверху)")

func initialize_stratagems():
	# Только физический куб
	available_stratagems["cube"] = {
		"name": "Физический куб",
		"sequence": [StratagemDirection.LEFT, StratagemDirection.UP, StratagemDirection.UP, StratagemDirection.RIGHT],
		"cooldown": 10.0
	}

func _physics_process(delta):
	if not is_alive:
		return
	
	# Регенерация здоровья
	if current_health < max_health:
		current_health = min(current_health + health_regeneration * delta, max_health)
		if current_health != last_health:
			update_ui()
			last_health = current_health
	
	# Обработка перезарядки
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	elif not can_shoot:
		can_shoot = true
	
	# Таймер ввода стратагем
	if is_stratagem_input_active:
		stratagem_input_timer -= delta
		if stratagem_input_timer <= 0:
			stratagem_fail()
	
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
	
	# Получаем input движения (только если не вводим стратагему)
	if not is_stratagem_input_active:
		var direction = Vector3.ZERO
		if Input.is_action_pressed("move_forward"):
			direction.z -= 1
		if Input.is_action_pressed("move_back"):
			direction.z += 1
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
		if Input.is_action_pressed("move_right"):
			direction.x += 1
		
		direction = direction.normalized()
		
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	
	# Поворачиваем модель к курсору
	rotate_mesh_towards_mouse()
	
	# Стрельба (только если не вводим стратагему)
	if not is_stratagem_input_active and Input.is_action_pressed("shoot") and can_shoot and current_ammo >= ammo_per_shot:
		shoot()
	
	# Перезарядка
	if Input.is_action_just_pressed("reload"):
		reload()
	
	# Активация ввода стратагем (зажать CTRL)
	if Input.is_key_pressed(KEY_CTRL):
		if not ctrl_pressed:
			ctrl_pressed = true
			if not is_stratagem_input_active:
				stratagem_start_input()
	else:
		ctrl_pressed = false
	
	move_and_slide()

func _input(event):
	if not is_stratagem_input_active or not is_alive:
		return
	
	if event is InputEventKey and event.pressed:
		# Обработка ввода стратагем
		match event.keycode:
			KEY_W:
				stratagem_handle_input(StratagemDirection.UP)
			KEY_S:
				stratagem_handle_input(StratagemDirection.DOWN)
			KEY_A:
				stratagem_handle_input(StratagemDirection.LEFT)
			KEY_D:
				stratagem_handle_input(StratagemDirection.RIGHT)
			KEY_ESCAPE:
				stratagem_cancel()

func stratagem_start_input():
	is_stratagem_input_active = true
	stratagem_input_sequence.clear()
	stratagem_input_timer = stratagem_input_timeout
	
	# Показываем 3D UI
	if stratagem_display:
		stratagem_display.visible = true
		update_3d_ui_display()
	
	print("Начало ввода стратагемы - используйте W, A, S, D")

func stratagem_handle_input(direction):
	if not is_stratagem_input_active:
		return
	
	stratagem_input_sequence.append(direction)
	stratagem_input_timer = stratagem_input_timeout
	
	# Обновляем 3D UI
	update_3d_ui_display()
	
	# Отображаем ввод в консоли
	var direction_names = {
		StratagemDirection.UP: "↑",
		StratagemDirection.DOWN: "↓", 
		StratagemDirection.LEFT: "←",
		StratagemDirection.RIGHT: "→"
	}
	var input_display = ""
	for dir in stratagem_input_sequence:
		input_display += direction_names[dir] + " "
	print("Ввод стратагемы: ", input_display)
	
	# Проверяем совпадение
	stratagem_check_match()

func stratagem_check_match():
	for stratagem_id in available_stratagems:
		var stratagem = available_stratagems[stratagem_id]
		if stratagem_input_sequence.size() > stratagem.sequence.size():
			continue
		
		var matches = true
		for i in range(stratagem_input_sequence.size()):
			if stratagem_input_sequence[i] != stratagem.sequence[i]:
				matches = false
				break
		
		if matches and stratagem_input_sequence.size() == stratagem.sequence.size():
			stratagem_complete(stratagem_id)
			return
	
	if stratagem_input_sequence.size() >= stratagem_max_input_length:
		stratagem_fail()

func stratagem_complete(stratagem_id):
	var stratagem = available_stratagems[stratagem_id]
	current_stratagem = stratagem
	
	print("Стратагема активирована: ", stratagem.name)
	
	# Мигание зеленым при успехе
	if stratagem_display and direction_labels.size() > 0:
		var text_mesh = direction_labels[0]
		var original_material = text_mesh.material_override.duplicate()
		var green_material = StandardMaterial3D.new()
		green_material.albedo_color = Color.GREEN
		green_material.flags_unshaded = true
		green_material.flags_no_depth_test = true
		
		text_mesh.material_override = green_material
		
		# Также подсвечиваем все стрелки зеленым
		for arrow in input_spheres:
			var arrow_mat = arrow.material_override.duplicate()
			arrow_mat.albedo_color = Color(0.2, 0.8, 0.2)
			arrow.material_override = arrow_mat
		
		await get_tree().create_timer(0.5).timeout
		text_mesh.material_override = original_material
	
	stratagem_reset_input()
	spawn_physics_cube()


func spawn_physics_cube():
	var cube = RigidBody3D.new()
	cube.mass = 100.0
	cube.gravity_scale = 1.0
	
	# Меш
	var mesh_instance_3d = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(2, 2, 2)
	mesh_instance_3d.mesh = cube_mesh
	
	# Материал
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance_3d.set_surface_override_material(0, material)
	
	cube.add_child(mesh_instance_3d)
	
	# Коллизия
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 2, 2)
	collision_shape.shape = shape
	cube.add_child(collision_shape)
	
	# Добавляем на сцену
	get_tree().current_scene.add_child(cube)
	
	# Позиционируем перед игроком
	var spawn_position = global_position
	spawn_position += -transform.basis.z * 3.0  # 3 метра перед игроком
	spawn_position.y += 2.0  # Немного выше
	cube.global_position = spawn_position
	
	print("Физический куб создан!")

func stratagem_fail():
	print("Ошибка ввода стратагемы!")
	
	# Мигание красным при ошибке
	if stratagem_display and direction_labels.size() > 0:
		var text_mesh = direction_labels[0]
		var original_material = text_mesh.material_override.duplicate()
		var red_material = StandardMaterial3D.new()
		red_material.albedo_color = Color.RED
		red_material.flags_unshaded = true
		red_material.flags_no_depth_test = true
		
		text_mesh.material_override = red_material
		
		# Также подсвечиваем все стрелки красным
		for arrow in input_spheres:
			var arrow_mat = arrow.material_override.duplicate()
			arrow_mat.albedo_color = Color(0.8, 0.2, 0.2)
			arrow.material_override = arrow_mat
		
		await get_tree().create_timer(0.5).timeout
		text_mesh.material_override = original_material
	
	stratagem_reset_input()

func stratagem_cancel():
	print("Ввод стратагемы отменен")
	stratagem_reset_input()

func stratagem_reset_input():
	is_stratagem_input_active = false
	stratagem_input_sequence.clear()
	stratagem_input_timer = 0.0
	
	# Скрываем 3D UI
	if stratagem_display:
		stratagem_display.visible = false

func rotate_mesh_towards_mouse():
	if camera == null:
		camera = get_viewport().get_camera_3d()
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var floor_height = global_position.y
	
	var world_pos = camera.project_position(mouse_pos, camera.global_position.y - floor_height)
	
	if world_pos:
		mesh_instance.look_at(Vector3(world_pos.x, floor_height, world_pos.z), Vector3.UP)

func shoot():
	if current_ammo < ammo_per_shot:
		return
	
	can_shoot = false
	shoot_cooldown = fire_rate
	current_ammo -= ammo_per_shot
	
	if current_ammo != last_ammo:
		update_ui()
		last_ammo = current_ammo
	
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		var hit_object = raycast.get_collider()
		
		if hit_object and hit_object.has_method("take_damage"):
			hit_object.take_damage(bullet_damage)

func take_damage(damage: int):
	if not is_alive:
		return
	
	current_health -= damage
	
	if current_health != last_health:
		update_ui()
		last_health = current_health
	
	print("Игрок получил урон: ", damage, ". Здоровье: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	is_alive = false
	get_tree().change_scene_to_file("res://Scenes/MAIN.tscn")
	print("Игрок умер!")

func reload():
	current_ammo = max_ammo
	if current_ammo != last_ammo:
		update_ui()
		last_ammo = current_ammo
	print("Перезарядка!")

func update_ui():
	print("Здоровье: ", current_health, "/", max_health, " | Патроны: ", current_ammo, "/", max_ammo)


func update_3d_ui_display():
	if not stratagem_display:
		return
	
	# Обновляем центральный текст
	var direction_symbols = ""
	for dir in stratagem_input_sequence:
		match dir:
			StratagemDirection.UP: direction_symbols += "↑ "  # Вверх
			StratagemDirection.DOWN: direction_symbols += "↓ "  # Вниз
			StratagemDirection.LEFT: direction_symbols += "← "  # Влево
			StratagemDirection.RIGHT: direction_symbols += "→ "  # Вправо
	
	if direction_labels.size() > 0:
		var text_mesh = direction_labels[0].mesh as TextMesh
		if text_mesh:
			text_mesh.text = direction_symbols
	
	# Подсвечиваем активные стрелки
	for i in range(4):
		var arrow = input_spheres[i]
		var material = arrow.material_override as StandardMaterial3D
		
		if material:
			# Правильное соответствие:
			# i=0: Вверх (W) - StratagemDirection.UP
			# i=1: Вправо (D) - StratagemDirection.RIGHT  
			# i=2: Вниз (S) - StratagemDirection.DOWN
			# i=3: Влево (A) - StratagemDirection.LEFT
			
			var is_active = false
			for dir in stratagem_input_sequence:
				if (i == 0 and dir == StratagemDirection.UP) or \
				   (i == 1 and dir == StratagemDirection.RIGHT) or \
				   (i == 2 and dir == StratagemDirection.DOWN) or \
				   (i == 3 and dir == StratagemDirection.LEFT):
					is_active = true
					break
			
			# Меняем цвет в зависимости от активности
			if is_active:
				material.albedo_color = Color(0.2, 0.8, 0.2)  # Зеленый
			else:
				material.albedo_color = Color(0.5, 0.5, 0.5)  # Серый
