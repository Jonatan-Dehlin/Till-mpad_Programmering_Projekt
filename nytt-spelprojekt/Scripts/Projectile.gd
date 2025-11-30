extends Area2D

#Stats
var damage: int
var velocity: float
var lifetime: float

#Fiende stats
var enemy: CharacterBody2D
var enemy_rotation


var time_passed: float = 0.0

var has_exploded = false

var parent: Node2D

@onready var indicator: Marker2D = $LeadIndicator
@onready var AOECollider: CollisionShape2D = $AOECollider

func _ready() -> void:
	z_index = 1000
	damage = parent.stats["damage"]
	velocity = parent.stats["projectile_velocity"]
	lifetime = parent.stats["projectile_lifetime"]
	if parent.targeted_enemy != null:
		enemy = parent.targeted_enemy
		_place_indicator()
	

func _place_indicator(): #Gör så att projektilen anpassar sin bana för att inte missa
	#Avstånd till fienden
	var distance: float = global_position.distance_to(enemy.global_position)
	#Referens till den PathFollow som fienden flyttas av
	var enemy_path: PathFollow2D = enemy.get_parent()
	
	#Beräknar hur mycket längre fram på vägen som tornet måste sikta för att träffa
	#Tar till hänsyn projektilens och fiendens hastighet, samt avståndet mellan dem
	var offset: float = enemy_path.speed * (distance / velocity)

	#Path2D har ett enkelt sätt att få progress från path -> global_position
	#.curve ger själva banan, och om man sen kör sample_baked() med
	#den progress man fick ur prediction, får man global_position
	var prediction = enemy_path.progress + offset
	var curve: Curve2D = enemy_path.get_parent().curve
	var predicted_pos = curve.sample_baked(prediction)

	#Indikatorn placeras på dessa koordinater, och riktas mot dem.
	indicator.global_position = predicted_pos
	rotation = get_angle_to(predicted_pos)

func _physics_process(delta: float) -> void:
	position += Vector2(cos(rotation), sin(rotation)) * velocity * delta
	time_passed += delta
	if time_passed >= lifetime:
		queue_free()
	
	$AnimatedSprite2D.global_rotation = 0

func _apply_explosion_damage():
	#Gör skada på alla Enemy inom AOE
	var enemies = get_overlapping_bodies()
	for i in enemies:
		if i is Enemy and is_instance_valid(parent):
			if i.current_health >= damage:
				parent.stats["DamageDealt"] += damage
			else:
				parent.stats["DamageDealt"] += i.current_health
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
