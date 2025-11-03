extends Node2D

var enemies_in_range: Array = []
var is_attacking: bool = false
var direction_to_enemy
var hovering_over_tower: bool = false

#Tower Stats
var stats = {"damage":1,
			"range":1000,
			"cooldown":10,
			"projectile_velocity": 1260.0,
			"projectile_lifetime": 5.0}

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
	UpgradePanel.global_position = Vector2(0,0)
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
	queue_redraw()

func _attack() -> void:
	is_attacking = true
	anim.play("Tower_Firing")

	if enemies_in_range.size() > 0: #Dubbelkollar så att tornet inte gör skada om fienden redan gått ur range
		
		#Anpassar vilken fiende tornet ska skjuta på
		if targeting == "First":
			direction_to_enemy = get_angle_to(enemies_in_range[0].global_position)
		elif targeting == "Last":
			direction_to_enemy = get_angle_to(enemies_in_range[enemies_in_range.size() - 1].global_position)
		elif targeting == "Strongest":
			var strongest_enemy = null
			for enemy in enemies_in_range:
				if enemy.current_health > strongest_enemy.current_health or strongest_enemy == null:
					strongest_enemy = enemy
			direction_to_enemy = get_angle_to(strongest_enemy.global_position)
			
		
		#skapar en projektil
		var projectile_scene = load("res://Scenes/Projectiles/wizard_tower_projectile" + str(upgrade_level) + ".tscn")
		var projectile = projectile_scene.instantiate()
		projectile.position -= Vector2(0,25)
		add_child(projectile)

	await anim.animation_finished

	is_attacking = false

func _draw():
	if RangeShape is CircleShape2D and (hovering_over_tower or UpgradePanel.visible):
		draw_circle(Vector2.ZERO, RangeShape.radius, Color(0, 0, 1, 0.1))

func _on_range_body_entered(body: Node2D) -> void:
	if body is Enemy:
		enemies_in_range.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	if body is Enemy:
		enemies_in_range.erase(body)

func _on_mouse_hover_detector_mouse_entered() -> void:
	TowerOutline.visible = true
	hovering_over_tower = true

func _on_mouse_hover_detector_mouse_exited() -> void:
	if not UpgradePanel.visible:
		TowerOutline.visible = false
		hovering_over_tower = false
