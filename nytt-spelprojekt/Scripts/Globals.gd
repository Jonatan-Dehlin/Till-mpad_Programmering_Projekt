extends Node

var current_wave = 0

var cash = 100000

################## ENEMY STATS ###################
var enemies = {"FireBug":0,"LeafBug":0,"MagmaCrab":0,"Scorpion":0}
var enemy_base_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemy_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemies_speed = {"FireBug":100,"LeafBug":50,"MagmaCrab":20,"Scorpion":10}
var enemy_base_reward = {"FireBug":10,"LeafBug":20,"MagmaCrab":50,"Scorpion":100}

var current_health_factor: float = 1

func _ready() -> void:
	pass

func _apply_health_multiplier(wave) -> void:
	for enemy in enemy_health:
		enemy_health[enemy] = round(enemy_base_health[enemy] * 1.05 ** wave)
	current_health_factor *= 1.05

func _damage(damage_dealt, targeted_enemy) -> void:
	if damage_dealt >= targeted_enemy.current_health:
		targeted_enemy.get_parent().queue_free()
		cash += targeted_enemy.kill_reward
	else:
		targeted_enemy.current_health -= damage_dealt

func _format_number(n: int) -> String: #Gör om t.ex. 1000000 -> 1,000,000
	if n < 1000: #Om numret är under 1000 behöver det inte formatteras
		return str(n)
	else:
		var s = str(n)
		var result: String
		var numbers_added = 0
		
		s = s.reverse() #Vänder på stringen för att få "," på rätt ställen
		
		for numbers in s:
			if numbers_added % 3 == 0 and numbers_added != 0: # != 0 för att 0/3 = 0
				result += "," #Om tre siffror blivit tillagda ska ett komma in
			result += numbers
			numbers_added += 1
		result = result.reverse() #Vänder tillbaks string så att det blir rätt håll
		
		return result
