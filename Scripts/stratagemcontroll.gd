# StratagemUI.gd
extends Control

class_name StratagemUI

var input_display_time = 1.0
var input_labels = []
var current_inputs = []

func _ready():
	# Создаем метки для отображения ввода
	for i in range(6):  # максимум 6 вводов
		var label = Label.new()
		label.name = "InputLabel%d" % i
		label.position = Vector2(50 + i * 40, 50)
		label.size = Vector2(30, 30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		add_child(label)
		input_labels.append(label)
	
	hide()

func show_input_sequence():
	show()

func hide_input_sequence():
	hide()

func add_input_direction(direction):
	var direction_symbol = get_direction_symbol(direction)
	current_inputs.append(direction_symbol)
	update_display()

func update_display():
	for i in range(input_labels.size()):
		if i < current_inputs.size():
			input_labels[i].text = current_inputs[i]
			input_labels[i].modulate = Color(1, 1, 1, 1)
		else:
			input_labels[i].text = ""

func clear_inputs():
	current_inputs.clear()
	update_display()

func get_direction_symbol(direction):
	# Используем числовые значения вместо enum
	match direction:
		0: return "↑"  # UP
		1: return "↓"  # DOWN  
		2: return "←"  # LEFT
		3: return "→"  # RIGHT
		_: return ""
