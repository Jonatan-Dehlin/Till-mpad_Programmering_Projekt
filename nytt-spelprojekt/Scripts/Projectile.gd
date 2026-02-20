
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

var damage_frame: int

var parent: Node2D
var parentID
var Midas: bool = false

@onready var indicator: Marker2D = $LeadIndicator
@onready var AOECollider: CollisionShape2D = $AOECollider

@onready var selected_sprite = $AnimatedSprite2D
@onready var selected_explosion = $HitExplosion

func _ready() -> void:
	z_index = 1000
	damage_frame = parent.damage_frame
	if parent.Trait == "Midas":
		Midas = true
	parentID = parent.get_meta("PlayerInventoryIndexReference")
	
	if parent.UpgradeA == 4 or parent.UpgradeB == 4:
		selected_sprite = $AnimatedSprite2D2
		selected_explosion = $HitExplosion2
		AOECollider.shape.radius = selected_explosion.get_meta("AOESize")
		$AnimatedSprite2D.visible = false
		$AnimatedSprite2D2.visible = true

	elif parent.UpgradeA == 5 or parent.UpgradeB == 5:
		selected_sprite = $AnimatedSprite2D3
		selected_explosion = $HitExplosion3
		AOECollider.shape.radius = selected_explosion.get_meta("AOESize")
		$AnimatedSprite2D.visible = false
		$AnimatedSprite2D2.visible = false
		$AnimatedSprite2D3.visible = true
	
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
	look_at(predicted_pos)

func _physics_process(delta: float) -> void:
	# Projektilen rör sig med hänsyn till vinkeln från _place_indicator(), hastigheten och delta
	position += Vector2(cos(rotation), sin(rotation)) * velocity * delta
	time_passed += delta
	if time_passed >= lifetime:
		# Om projektilen levt länge nog tas den bort
		queue_free()

func _apply_explosion_damage():
	#Gör skada på alla Enemy inom AOE
	var enemies = get_overlapping_bodies()
	for i in enemies:
		if i is Enemy:
			if i.current_health >= damage:
				# Om fienden överlever attacken läggs hela skadan till
				if is_instance_valid(parent):
					parent.stats["DamageDealt"] += damage
				Globals.PlacedTowers[parentID][1] += damage
			else:
				# Om fienden inte överlever läggs endast fiendens HP till
				if is_instance_valid(parent):
					parent.stats["DamageDealt"] += i.current_health
				Globals.PlacedTowers[parentID][1] += i.current_health
			if Midas:
				# Om tornet har midas trait ska de få mer pengar ifall fienden dör
				Globals.damage(damage,i,true)
			else:
				Globals.damage(damage,i,false)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and not has_exploded: #Kontrollerar att det projektilen kolliderar med är en fiende
		# Aktiverar AOE kollisionskroppen, men efter annan physics process för att det blir problem annars
		AOECollider.set_deferred("disabled", false) 
		
		# Väntar en frame för att låta AOE kroppen aktiveras
		await get_tree().process_frame
		
		# Gör Hitexplosion synlig och startar animationen
		selected_explosion.visible = true
		selected_explosion.play()
		
		# Gömmer den vanliga spriten och sätter velocity till 0 så att explosionen inte flyttar på sig
		selected_sprite.visible = false
		velocity = 0

func _on_hit_explosion_frame_changed() -> void:
	if selected_explosion.frame == damage_frame: #frame där explosionen faktiskt händer
		_apply_explosion_damage()

func _on_hit_explosion_animation_finished() -> void:
	queue_free()
