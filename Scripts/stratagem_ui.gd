extends CanvasLayer

class_name StratagemDisplay 

@onready var input_label = $Control/InputDisplayLabel

func _ready():
	hide_input_display()

func show_input_display():
	visible = true
	input_label.text = ""
	input_label.visible = true

func hide_input_display():
	visible = false
	input_label.visible = false

func update_input_display(input_sequence: Array):
	var direction_symbols = ""
	for direction in input_sequence:
		match direction:
			0: direction_symbols += "↑ "  # UP
			1: direction_symbols += "↓ "  # DOWN
			2: direction_symbols += "← "  # LEFT
			3: direction_symbols += "→ "  # RIGHT
	
	input_label.text = direction_symbols

func clear_input_display():
	input_label.text = ""
