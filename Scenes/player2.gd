extends CharacterBody3D

var text : String = 'hello world'
var count : int = 5
var speed : float = 5.5
var is_gameover : bool = false #true
var items : Array = [5, 0.1, false, count, 'text', [1, 2]]
var bag : Dictionary = {'apple' : 5, 'orange' : 10}
const APPLE_COUNT : int = 20
enum weather {SUNNY, CLOUDY, RAINY}
var weather_state : int = weather.SUNNY


func creatures_lets_walk() -> void:
	print('walk')

func creatures_lets_hide() -> void:
	print('hide')


func _ready() -> void:
	#say_hello()
	#print(say_hello_world())
	#cycles()
	weather_state = weather.RAINY
	match(weather_state):
		[weather.SUNNY, weather.CLOUDY]:
			creatures_lets_walk()
		weather.RAINY:
			creatures_lets_hide()
		





func cycles() -> void:
	while count <= 10:
		if count == 10:
			count = count + 1 # count += 1, count++
			continue #break
		count = count + 1 # count += 1, count++
		#print(count)
		
	#for i in range(20):
		#print(i)
	


func say_hello_world() -> String:
	if  count >= 10: #> < == != >= <=
		is_gameover = true
	if is_gameover:
		print('game over')
	else:
		print ('game not over')
	return 'success'
