extends Node

var current_wave = 0

var coins = 0

var cash = 0

var enemies = {"FireBug":0,"LeafBug":0,"MagmaCrab":0,"Scorpion":0}

var enemies_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}

var enemy_base_reward = {"FireBug":10,"LeafBug":20,"MagmaCrab":50,"Scorpion":100}

func _ready() -> void:
	pass


func _apply_health_multiplier(wave) -> void:
	for enemy in enemies_health:
		enemies_health[enemy] *= 2.05 ** wave
	print(enemies_health)
	
func _damage(damage_dealt, targeted_enemy) -> void:
	if damage_dealt >= targeted_enemy.current_health:
		targeted_enemy.get_parent().queue_free()
		cash += targeted_enemy.kill_reward
	else:
		targeted_enemy.current_health -= damage_dealt
	
	
	
