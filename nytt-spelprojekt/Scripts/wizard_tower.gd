extends Node2D

var enemies_in_range: Array = []
var is_attacking: bool = false
var targeted_enemy
var hovering_over_tower: bool = false

var TowerName = "Wizard Tower"

#Tower Stats
var stats = {"damage":50,
			"range":250,
			"cooldown":1,
			"projectile_velocity": 320.0,
			"projectile_lifetime": 5.0,
			"AOESize": 100.0}

var place_cost: int = 100
var total_cash_spent: int = 100

var targeting: String = "First"

@export var sell_value: int = 70


var upgrade_level = 1

#Upgrade Stats. Allting är additivt
var UpgradesA = {1:{"damage":50,"range":50,"cooldown":0.1,"projectile_velocity":0,"projectile_lifetime":0}
				,2:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,3:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,4:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,5:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}}

var UpgradesB = {1:{"damage":50,"range":50,"cooldown":0.1,"projectile_velocity":0,"projectile_lifetime":0}
				,2:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,3:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,4:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}
				,5:{"damage":50,"range":50,"cooldown":1.1,"projectile_velocity":0,"projectile_lifetime":0}}

var UpgradeAPrices = {1:50,2:100,3:1400,4:5900,5:11000}
var UpgradeBPrices = {1:50,2:100,3:1400,4:5900,5:11000}

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var TowerSprite: Sprite2D = $TowerSprite
@onready var TowerOutline: Sprite2D = $TowerOutline
@onready var UpgradePanel: Control = $UpgradePanel
@onready var RangeShape: CircleShape2D = $Range/CollisionShape2D.shape


func _ready() -> void: #Används för att ställa in stats, när tornet placeras och när det upgraderas
	if global_position.x >= get_window().size.x / 2:
		UpgradePanel.global_position = Vector2(0,0)
	else:
		UpgradePanel.global_position = Vector2(get_window().size.x-UpgradePanel.get_node("Panel").size.x*UpgradePanel.scale.x,0)
	_update_stats()

func _update_stats():
	RangeShape.radius = stats["range"] #Ställer in range
	anim.speed_scale = stats["cooldown"]

func _physics_process(_delta: float) -> void:
	#Om tornet inte redan attackerar och det finns fiender inom range: starta en attack
	if not is_attacking and enemies_in_range.size() > 0:
		_attack()
	#Om tornet inte är mitt innne i en attack och det inte finns fiender inom radien: gå till idle
	elif enemies_in_range.size() == 0 and not is_attacking:
		anim.play("Tower_Idle")
	
	if Input.is_action_just_pressed("Left_click") and hovering_over_tower:
		UpgradePanel.visible = true	
		print("öppnade upgradepanelen")
	
	var overlapping_enemies = $Range.get_overlapping_bodies()
	enemies_in_range = overlapping_enemies.filter(func(b): return b is Enemy)
	
	queue_redraw()

func _choose_targeted_enemy():
	if targeting == "First":
		var first_enemy: Enemy
	
		for i in enemies_in_range:
			if first_enemy == null:
				first_enemy = i 
			elif i.get_parent().progress > first_enemy.get_parent().progress:
				first_enemy = i
		targeted_enemy = first_enemy
		
	elif targeting == "Last":
		var last_enemy: Enemy
		for i in enemies_in_range:
			if last_enemy == null:
				last_enemy = i 
			if i.get_parent().progress < last_enemy.get_parent().progress:
				last_enemy = i
		targeted_enemy = last_enemy
		
	elif targeting == "Strongest":
		var strongest_enemy = null
		for enemy in enemies_in_range:
			if strongest_enemy == null or enemy.current_health > strongest_enemy.current_health:
				strongest_enemy = enemy
		targeted_enemy = strongest_enemy
		
	elif targeting == "Weakest":
		var weakest_enemy = null
		for enemy in enemies_in_range:
			if weakest_enemy == null or enemy.current_health < weakest_enemy.current_health:
				weakest_enemy = enemy
		targeted_enemy = weakest_enemy

func _spawn_projectile():
	#Anpassar vilken fiende tornet ska skjuta på
	if enemies_in_range.size() > 0: #Dubbelkollar så att tornet inte gör skada om fienden redan gått ur range
		_choose_targeted_enemy()
		
		#skapar en projektil
		var projectile_scene = load("res://Scenes/Projectiles/wizard_tower_projectile" + str(upgrade_level) + ".tscn")
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position - Vector2(0,25)
		projectile.parent = self
		get_tree().current_scene.get_node("TowerProjectiles").add_child(projectile)

func _attack() -> void:
	is_attacking = true
	anim.play("Tower_Firing")

	await anim.animation_finished

	is_attacking = false

func _draw():
	#Ritar range
	if RangeShape is CircleShape2D and (hovering_over_tower or UpgradePanel.visible):
		draw_circle(Vector2.ZERO, RangeShape.radius, Color(0, 0, 1, 0.1))


func _on_mouse_hover_detector_mouse_entered() -> void:
	TowerOutline.visible = true
	hovering_over_tower = true

func _on_mouse_hover_detector_mouse_exited() -> void:
	if not UpgradePanel.visible:
		TowerOutline.visible = false
		hovering_over_tower = false
