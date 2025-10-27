extends Node2D

var enemies_in_range: Array = []
var is_attacking: bool = false

#Tower Stats
var damage: int = 50
var range: int = 2 #faktor
var cooldown: float = 1 #faktor. Bas animationen är 1.4 sekunder
var direction_to_enemy
var projectile_velocity: float = 100.0
var projectile_lifetime: float = 5.0
var upgrade_level = 1

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var rangeRadius: Area2D = $Range


func _ready() -> void:
	rangeRadius.scale = Vector2(range,range) #Ställer in range

func _physics_process(_delta: float) -> void:
	#Om tornet inte redan attackerar och det finns fiender inom range: starta en attack
	if not is_attacking and enemies_in_range.size() > 0:
		_attack()
	#Om tornet inte är mitt innne i en attack och det inte finns fiender inom radien: gå till idle
	elif enemies_in_range.size() == 0 and not is_attacking:
		anim.play("Tower_Idle")

func _attack() -> void:
	is_attacking = true
	anim.play("Tower_Firing")

	if enemies_in_range.size() > 0: #Dubbelkollar så att tornet inte gör skada om fienden redan gått ur range
		#Gör skada på den första fienden som kom in in range
		#Globals._damage(damage, enemies_in_range[0])
		direction_to_enemy = get_angle_to(enemies_in_range[0].global_position)
		var projectile_scene = load("res://Scenes/Projectiles/wizard_tower_projectile" + str(upgrade_level) + ".tscn")
		var projectile = projectile_scene.instantiate()
		add_child(projectile)

	await anim.animation_finished

	is_attacking = false

func _on_range_body_entered(body: Node2D) -> void:
	if body is Enemy:
		enemies_in_range.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	if body is Enemy:
		enemies_in_range.erase(body)

func _on_mouse_hover_detector_mouse_entered() -> void:
	$Sprite2D2.visible = true

func _on_mouse_hover_detector_mouse_exited() -> void:
	$Sprite2D2.visible = false
