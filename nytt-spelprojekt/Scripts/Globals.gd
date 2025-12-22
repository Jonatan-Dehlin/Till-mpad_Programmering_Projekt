extends Node

var current_wave = 0

var health = 100

var cash = 100000

################## ENEMY STATS ###################
var enemies = {"FireBug":0,"LeafBug":0,"MagmaCrab":0,"Scorpion":0}
var enemy_base_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemy_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemies_speed = {"FireBug":1000,"LeafBug":50,"MagmaCrab":20,"Scorpion":10}
var enemy_base_reward = {"FireBug":10,"LeafBug":20,"MagmaCrab":50,"Scorpion":100}

var current_health_factor: float = 1

var TraitIconAtlasDictionary: Dictionary = { #Innehåller atlastexture koordinater och färg för traitikonerna
	"none": [Rect2(230,69,27,22), Color(0.5,0.5,1)],
	"Rapid_I": [Rect2(100,261,27,22), Color(0.5,0.5,1)],
	"Rapid_II": [Rect2(100,261,27,22), Color(1,1,1)],
	"Rapid_III": [Rect2(100,261,27,22), Color(1,0.5,0.5)],
	"Strong_I": [Rect2(131,36,27,25), Color(0.5,0.5,1)],
	"Strong_II": [Rect2(131,36,27,25), Color(1,1,1)],
	"Strong_III": [Rect2(131,36,27,25), Color(1,0.5,0.5)],
	"Vision_I": [Rect2(2,229,27,22), Color(0.5,0.5,1)],
	"Vision_II": [Rect2(2,229,27,22), Color(1,1,1)],
	"Vision_III": [Rect2(2,229,27,22), Color(1,0.5,0.5)],
	"Lightning": [Rect2(260,3,24,26), Color(1,1,1)],
	"Unbeatable": [Rect2(419,100,25,25), Color(1,1,1)],
	"Hawkeye": [Rect2(99,98,26,27), Color(1,1,1)],
	"Midas": [Rect2(355,387,26,26), Color(1,1,1)],
	"Singularity": [Rect2(258,674,28,28), Color(1,1,1)],
}

var TraitModifiers: Dictionary = { #Innehåller förändringsfaktorer som senare appliceras i tornens lokala kod
	"none": {"damage":1, # +0% i allting
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_I": {"damage":1, # 10% snabbare attack speed
			"range":1,
			"cooldown":1.1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_II": {"damage":1, # 25% snabbare attack speed
			"range":1,
			"cooldown":1.25,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_III": {"damage":1, # 50% snabbare attack speed
			"range":1,
			"cooldown":1.5,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_I": {"damage":1.1, # 10% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_II": {"damage":1.25, # 25% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_III": {"damage":1.5, # 50% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_I": {"damage":1, # 10% mer range
			"range":1.1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_II": {"damage":1, # 25% mer range
			"range":1.25,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_III": {"damage":1, # 50% mer range
			"range":1.5,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Lightning": {"damage":1, # 100% snabbare attack speed, 50% snabbare velocity
			"range":1,
			"cooldown":2,
			"projectile_velocity": 1.5,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Unbeatable": {"damage":2, # 100% mer damage, 25% större AOE
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1.25},
	"Hawkeye": {"damage":1, # 200% mer range, 100% snabbare velocity, 33% minskning AOE
			"range":3,
			"cooldown":1,
			"projectile_velocity": 2,
			"projectile_lifetime": 1,
			"AOESize": 2/3},
	"Midas": {"damage":1, # 50% mer pengar från kill, samt 50% mer money generation. Dessa effekter appliceras här i Globals för extra kill money, men lokalt i tornkoden för money generation.
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Singularity": {"damage":5, # 400% mer damage, 100% snabbare attack speed, ,100% större range, 50% större AOE MEN 200% cost, MAX 1 placement.
			"range":2,
			"cooldown":2,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1.5},
}

func _ready() -> void:
	pass

func _apply_health_multiplier(wave) -> void:
	for enemy in enemy_health:
		enemy_health[enemy] = round(enemy_base_health[enemy] * 1.05 ** wave)
	current_health_factor *= 1.05

func _damage(damage_dealt, targeted_enemy, midas: bool) -> void:
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
