extends CharacterBody3D

var text : String = 'hello world'
var count : int = 5
var speed : float = 5.5
var is_gameover : bool = false #true
var items : Array = [5, 0.1, false, count, 'text', [1, 2]]
var bag : Dictionary = {'apple' : 5, 'orange' : 10}
const APPLE_COUNT : int = 20
enum Weather {SUNNY, CLOUDY, RAINY}
var weather_state : int = Weather.SUNNY

func _ready() -> void:
	#var result : String = say_hello_world()
	#print(say_hello_world())
	#cycles()
	weather_state = Weather.RAINY
	match(weather_state):
		#Weather.SUNNY:
			#creatures_lets_walk()
		#Weather.CLOUDY:
			#creatures_lets_walk()
		[Weather.SUNNY, Weather.CLOUDY]:
			creatures_lets_walk()
		Weather.RAINY:
			creatures_lets_hide()

func creatures_lets_walk() -> void:
	print('Creatures are walking')
	
func creatures_lets_hide() -> void:
	print('Creatures saved')

func cycles() -> void:
	while count <= 15:
		if count == 10:
			count = count + 1 # count += 1, count++
			continue #break
		count = count + 1 # count += 1, count++
		#print(count)
	for i in range(20, 5, -1): #'hello', [0, 1, 2, 3], range(20) - 0 ... 19
		print(i)

func say_hello_world() -> String:
	if is_gameover:
		print('Game is over')
	elif count >= 10: #> < == != >= <=
		is_gameover = true
	else:
		print('Game is going')
	print('text: ', text)
	return 'success'
