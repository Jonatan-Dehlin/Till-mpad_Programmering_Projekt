extends Node

var current_wave = 0

var health = 100

var cash = 100000

################## ENEMY STATS ###################
var enemies = {"FireBug":0,"LeafBug":0,"MagmaCrab":0,"Scorpion":0}
var enemy_base_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemy_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemies_speed = {"FireBug":100,"LeafBug":50,"MagmaCrab":20,"Scorpion":10}
var enemy_base_reward = {"FireBug":10,"LeafBug":20,"MagmaCrab":50,"Scorpion":100}

var current_health_factor: float = 1

var SelectedDifficulty: String = "Easy"

var SelectedDifficultyModifiers: Dictionary = { # Modifiers beroende på vald difficulty
	"Easy": {"EnemyHP": 1, "EnemySpeed": 1, "BaseHP": 15},
	"Normal": {"EnemyHP": 1.5, "EnemySpeed": 1.1, "BaseHP": 10},
	"Hard": {"EnemyHP": 2, "EnemySpeed": 1.2, "BaseHP": 5},
	"Insane": {"EnemyHP": 5, "EnemySpeed": 1.5, "BaseHP": 2},
	"Impossible": {"EnemyHP": 10, "EnemySpeed": 1.8, "BaseHP": 1.5},
	"Nightmare": {"EnemyHP": 50, "EnemySpeed": 2, "BaseHP": 1}
}

var SelectedModifiers: Dictionary = { # Valbara modifiers som gör spelet svårare men ger mer belöningar
	"Slow Towers": [false,25,0], # Långsammare attack speed
	"Weak Towers": [false,25,0], # Mindre damage
	"Blind Towers": [false,25,0], # Kortare range
	"Crippled Towers": [false,50,0], # Mindre attack speed, range och damage
	"Expensive Towers": [false,25,0], # Dyrare torn
	"Economic Depression": [false,50,0], # Dyrare torn, mindre belöningar från pengatorn och fiende kills
	"Sudden Death": [false,100,0], # Max HP sätts till 1
	"Only One": [false,100,0], # Endast 1 placement per torn
}

var TraitIconAtlasDictionary: Dictionary = { # Innehåller atlastexture koordinater och färg för traitikonerna
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

var TraitModifiers: Dictionary = { # Innehåller förändringsfaktorer som senare appliceras i tornens lokala kod
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
	current_health_factor = 1

func return_cost_factor(): # Räknar ut costfactor för torn beroende på modifiers
	var CostFactor: float = 0
	if Globals.SelectedModifiers["Expensive Towers"][0] == true:
			CostFactor += 0.5
	if Globals.SelectedModifiers["Economic Depression"][0] == true:
			CostFactor += 1
	return CostFactor

func _apply_health_multiplier(wave) -> void:
	current_health_factor = 1.05 ** (wave-1) * SelectedDifficultyModifiers[SelectedDifficulty]["EnemyHP"]
	print(wave)
	print(current_health_factor)
	
	# Ändrar HP för fienden så att de får mer HP fler rundor in
	for enemy in enemy_health:
		enemy_health[enemy] = round(enemy_base_health[enemy] * current_health_factor)
	
	# Ser till att korrigera kill-belöningen för att hålla den proportionelig med fiendens HP
	for enemy in enemy_base_reward:
		enemy_base_reward[enemy] *= current_health_factor

func _damage(damage_dealt, targeted_enemy, midas: bool) -> void:
	if damage_dealt >= targeted_enemy.current_health:
		targeted_enemy.get_parent().queue_free()
		cash += targeted_enemy.kill_reward
	else:
		targeted_enemy.current_health -= damage_dealt

func _format_number(n: int) -> String: # Gör om t.ex. 1000000 -> 1,000,000
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
