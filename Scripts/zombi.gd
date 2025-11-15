extends CharacterBody3D

# Настройки врага
@export var speed : float = 2.0
@export var max_health : int = 50
@export var damage : int = 10
@export var attack_range : float = 8.0
@export var attack_cooldown : float = 2.0

# Ссылки
@onready var player = get_tree().get_first_node_in_group("player")
@onready var mesh_instance = $MeshInstance3D
@onready var attack_raycast = $AttackRayCast

# Переменные
var current_health : int
var can_attack : bool = true
var attack_timer : float = 0.0
var is_alive : bool = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	current_health = max_health
	add_to_group("enemy")
	
	# Настраиваем RayCast
	if attack_raycast:
		attack_raycast.enabled = true
		attack_raycast.target_position = Vector3(0, 0, -attack_range)
		attack_raycast.collision_mask = 1  # Проверяем только слой 1

func _physics_process(delta):
	if not is_alive:
		return
	
	# Добавляем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Таймер атаки
	if attack_timer > 0:
		attack_timer -= delta
	elif not can_attack:
		can_attack = true
	
	if player and is_alive and player.is_alive:
		# Двигаемся к игроку
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0
		
		# Поворачиваемся к игроку
		mesh_instance.look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		# Поворачиваем RayCast в сторону игрока
		if attack_raycast:
			attack_raycast.global_rotation.y = mesh_instance.global_rotation.y
		
		# Проверяем дистанцию для атаки
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > attack_range:
			# Двигаемся к игроку
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Останавливаемся
			velocity.x = 0
			velocity.z = 0
			
			# Атакуем
			if can_attack:
				attack()
		
		move_and_slide()

func is_player_visible() -> bool:
	if not attack_raycast:
		return false
	
	attack_raycast.force_raycast_update()
	
	if attack_raycast.is_colliding():
		var collider = attack_raycast.get_collider()
		if collider and collider.is_in_group("player"):
			return true
	
	return false

func take_damage(damage: int):
	if not is_alive:
		return
	
	current_health -= damage
	print("Враг получил урон: ", damage, ". Здоровье врага: ", current_health)
	
	if current_health <= 0:
		die()

func attack():
	if can_attack and player and player.is_alive:
		can_attack = false
		attack_timer = attack_cooldown
		
		if is_player_visible():
			player.take_damage(damage)
			print("Враг атаковал игрока через RayCast! Урон: ", damage)
		else:
			# Простая проверка дистанции как запасной вариант
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_range * 1.5:
				player.take_damage(damage)
				print("Враг атаковал игрока по дистанции! Урон: ", damage)

func die():
	is_alive = false
	print("Враг умер!")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hide()
	
	await get_tree().create_timer(2.0).timeout
	queue_free()
