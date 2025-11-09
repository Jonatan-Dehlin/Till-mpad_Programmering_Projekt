extends Area2D

#Stats
var damage: int
var velocity: float
var lifetime: float

#Fiende stats
var enemy
var enemy_rotation

var offset: float

var time_passed: float = 0.0

var has_exploded = false

var parent: Node2D

@onready var indicator: Marker2D = $LeadIndicator
@onready var AOECollider: CollisionShape2D = $AOECollider

func _ready() -> void:
	damage = parent.stats["damage"]
	velocity = parent.stats["projectile_velocity"]
	lifetime = parent.stats["projectile_lifetime"]
	enemy = parent.targeted_enemy
	if enemy != null:
		enemy_rotation = enemy.global_rotation
	
	
		var distance = global_position.distance_to(enemy.global_position)
		
		offset = enemy.get_parent().speed * (distance / velocity)
		
		indicator.global_position = enemy.global_position + Vector2(cos(enemy_rotation), sin(enemy_rotation)) * offset
		rotation = get_angle_to(indicator.global_position)
	
	
func _physics_process(delta: float) -> void:
	position += Vector2(cos(rotation), sin(rotation)) * velocity * delta
	time_passed += delta
	if time_passed >= lifetime:
		queue_free()
	if enemy != null:
		indicator.global_position = enemy.global_position + Vector2(cos(enemy_rotation), sin(enemy_rotation)) * offset

	$Sprite2D.global_position = indicator.global_position
	$AnimatedSprite2D.global_rotation = 0

func _apply_explosion_damage():
	#Gör skada på alla Enemy inom AOE
	var enemies = get_overlapping_bodies()
	for i in enemies:
		if i is Enemy:
			Globals._damage(damage,i)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and not has_exploded: #Kontrollerar att det projektilen kolliderar med är en fiende
		#Aktiverar AOE kollisionskroppen, men efter annan physics process för att det blir problem annars
		AOECollider.set_deferred("disabled", false) 
		
		#Väntar en frame för att låta AOE kroppen aktiveras
		await get_tree().process_frame
		
		#Gör Hitexplosion synlig och startar animationen
		$HitExplosion.visible = true
		$HitExplosion.play()
		

		
		#Gömmer den vanliga spriten och sätter velocity till 0
		$AnimatedSprite2D.visible = false
		velocity = 0


func _on_hit_explosion_frame_changed() -> void:
	if $HitExplosion.frame == 5: #frame där explosionen faktiskt händer
		_apply_explosion_damage()


func _on_hit_explosion_animation_finished() -> void:
	queue_free()
