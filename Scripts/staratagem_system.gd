# StratagemSystem.gd
extends CharacterBody3D

class_name StratagemSystem


@export var input_timeout: float = 2.0
@export_range(4, 12) var max_input_length: int = 6

# Сигналы
signal stratagem_started(stratagem_name)
signal stratagem_completed(stratagem_name)
signal stratagem_failed()
signal input_received(direction)

# Направления ввода
enum Direction {UP, DOWN, LEFT, RIGHT, NONE}
const DIRECTION_KEYS = {
	KEY_W: Direction.UP,
	KEY_S: Direction.DOWN,
	KEY_A: Direction.LEFT,
	KEY_D: Direction.RIGHT
}

# Настройки

# Данные стратагем
var available_stratagems = {}
var current_stratagem = null
var input_sequence = []
var input_timer = 0.0
var is_input_active = false

func _ready():
	initialize_stratagems()
	set_process_input(true)

func _process(delta):
	if is_input_active:
		input_timer -= delta
		if input_timer <= 0:
			fail_stratagem()

func _input(event):
	if not is_input_active:
		return
	
	if event is InputEventKey and event.pressed:
		if event.scancode in DIRECTION_KEYS:
			var direction = DIRECTION_KEYS[event.scancode]
			handle_direction_input(direction)
		elif event.scancode == KEY_ESCAPE:
			cancel_stratagem()

func initialize_stratagems():
	# Базовые стратагемы
	#available_stratagems["reinforce"] = {
	#	"name": "Подкрепление",
	#	"sequence": [Direction.DOWN, Direction.UP, Direction.RIGHT, Direction.LEFT, Direction.UP],
	#	"scene": preload("res://Stratagems/Reinforce.tscn"),
	#	"cooldown": 30.0
	#}
	
	#available_stratagems["ammo"] = {
	#	"name": "Боеприпасы",
	#	"sequence": [Direction.DOWN, Direction.DOWN, Direction.UP, Direction.RIGHT],
	#	"scene": preload("res://Stratagems/AmmoSupply.tscn"),
	#	"cooldown": 20.0
	#}
	
	#available_stratagems["turret"] = {
	#	"name": "Турель",
	#	"sequence": [Direction.DOWN, Direction.UP, Direction.RIGHT, Direction.RIGHT, Direction.LEFT],
	#	"scene": preload("res://Stratagems/MachinegunTurret.tscn"),
	#	"cooldown": 45.0
	#}
	
	available_stratagems["cube"] = {
		"name": "Физический куб",
		"sequence": [Direction.LEFT, Direction.UP, Direction.UP, Direction.RIGHT],
		"scene": preload("res://Stratagems/PhysicsCube.tscn"),
		"cooldown": 10.0
	}

func start_stratagem_input():
	if is_input_active:
		return
	
	is_input_active = true
	input_sequence.clear()
	input_timer = input_timeout
	emit_signal("stratagem_started", "")

func handle_direction_input(direction):
	if not is_input_active:
		return
	
	input_sequence.append(direction)
	input_timer = input_timeout
	emit_signal("input_received", direction)
	
	# Проверяем совпадение с известными стратагемами
	check_stratagem_match()

func check_stratagem_match():
	for stratagem_id in available_stratagems:
		var stratagem = available_stratagems[stratagem_id]
		if input_sequence.size() > stratagem.sequence.size():
			continue
		
		# Проверяем совпадение текущей последовательности
		var matches = true
		for i in range(input_sequence.size()):
			if input_sequence[i] != stratagem.sequence[i]:
				matches = false
				break
		
		if matches and input_sequence.size() == stratagem.sequence.size():
			complete_stratagem(stratagem_id)
			return
	
	# Если последовательность слишком длинная или не совпадает
	if input_sequence.size() >= max_input_length:
		fail_stratagem()

func complete_stratagem(stratagem_id):
	var stratagem = available_stratagems[stratagem_id]
	current_stratagem = stratagem
	
	emit_signal("stratagem_completed", stratagem.name)
	reset_input()
	
	# Создаем экземпляр стратагемы
	spawn_stratagem(stratagem)

func fail_stratagem():
	emit_signal("stratagem_failed")
	reset_input()

func cancel_stratagem():
	reset_input()

func reset_input():
	is_input_active = false
	input_sequence.clear()
	input_timer = 0.0

func spawn_stratagem(stratagem_data):
	var stratagem_scene = stratagem_data.scene.instance()
	get_tree().current_scene.add_child(stratagem_scene)
	
	# Позиционируем перед игроком
	var player = get_tree().current_scene.find_node("Player")
	if player:
		var spawn_position = player.global_transform.origin
		spawn_position += player.global_transform.basis.z * -3.0  # 3 метра перед игроком
		spawn_position.y += 2.0  # Немного выше
		stratagem_scene.global_transform.origin = spawn_position

func get_current_input_sequence():
	return input_sequence.duplicate()

func is_inputting():
	return is_input_active
