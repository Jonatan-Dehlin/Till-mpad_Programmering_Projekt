extends Node2D

var TowerName = "Ballista Tower"

var XP_earned: int = 0

var enemies_in_range: Array = []
var is_attacking: bool = false
var targeted_enemy
var hovering_over_tower: bool = false

#Tower Stats
var Trait: String
var Level: int
var stats = {"damage":100,
			"range":300,
			"cooldown":0.5,
			"projectile_velocity": 500.0,
			"projectile_lifetime": 5.0,
			"AOESize": 6.0,
			"DamageDealt": 0}

var place_cost: int = 100
var total_cash_spent: int = 100

var pierce: int = 5

var targeting: String = "First"
var damage_frame: int = 1

@export var sell_value: int = int(place_cost * 0.7) #70% sellback
@export var max_placement: int = 5

var upgrade_level = 1

var UpgradeA = 0
var UpgradeB = 0

var weapon_sprite2 = ImageTexture.create_from_image(preload("res://Assets/Towers/Towers Weapons/Tower 06/Spritesheets/Tower 06 - Level 02 - Weapon.png").get_image())
var weapon_sprite3 = ImageTexture.create_from_image(preload("res://Assets/Towers/Towers Weapons/Tower 06/Spritesheets/Tower 06 - Level 03 - Weapon.png").get_image())

var projectile_sprite2 = ImageTexture.create_from_image(preload("res://Assets/Towers/Towers Weapons/Tower 06/Spritesheets/Tower 06 - Level 02 - Projectile.png").get_image())
var projectile_sprite3 = ImageTexture.create_from_image(preload("res://Assets/Towers/Towers Weapons/Tower 06/Spritesheets/Tower 06 - Level 03 - Projectile.png").get_image())

#Upgrade Stats. Allting är additivt
var UpgradesA = {
	1: {"damage": +5,  "range": 0, "cooldown": +0.01, "projectile_velocity": -20, "projectile_lifetime": -0.3, "name": "Quickspark"},
	2: {"damage": +8,  "range": 0, "cooldown": +0.05, "projectile_velocity": -15, "projectile_lifetime": -0.2, "name": "Arcane Flurry"},
	3: {"damage": +12, "range": -10,  "cooldown": +1.0, "projectile_velocity": -10, "projectile_lifetime": -0.1, "name": "Mystic Barrage"},
	4: {"damage": +18, "range": 0,   "cooldown": +1.5, "projectile_velocity": 0,    "projectile_lifetime": 0,   "name": "Eldritch Haste"},
	5: {"damage": +25, "range": +10, "cooldown": +2.0, "projectile_velocity": +10,  "projectile_lifetime": +0.1, "name": "Arcane Hyperflux"}
	}

var UpgradesB = {
	1: {"damage": 0, "range": +50,  "cooldown": +0.1, "projectile_velocity": +80,  "projectile_lifetime": +0.5, "name": "Longshot Initiate"},
	2: {"damage": 0, "range": +60,  "cooldown": +0.1, "projectile_velocity": +120, "projectile_lifetime": +0.5, "name": "Skybolt Adept"},
	3: {"damage": +40, "range": +75,  "cooldown": +0.2, "projectile_velocity": +150, "projectile_lifetime": +0.5, "name": "Aether Pierce"},
	4: {"damage": +50, "range": +90,  "cooldown": +0.2, "projectile_velocity": +200, "projectile_lifetime": +0.6, "name": "Astral Sniper"},
	5: {"damage": +65, "range": +100, "cooldown": +0.3, "projectile_velocity": +250, "projectile_lifetime": +0.7, "name": "Celestial Railshot"}
	}

var UpgradeAPrices = {1:50,2:100,3:1400,4:5900,5:11000}
var UpgradeBPrices = {1:50,2:100,3:1400,4:5900,5:11000}

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var Weapon: Node2D = $Weapon
@onready var TowerSprite: Sprite2D = $TowerSprite
@onready var TowerOutline: Sprite2D = $TowerOutline
@onready var UpgradePanel: Control = $UpgradePanel.get_child(0)
@onready var RangeShape: CircleShape2D = $Range/CollisionShape2D.shape
@onready var UniqueRangeShape: CircleShape2D


func _ready() -> void: # Används för att ställa in stats, när tornet placeras och när det upgraderas
	Trait = self.get_meta("Trait")
	Level = self.get_meta("Level")
	z_index = int(position.y) # Z index anpassas för att torn ska kunna placeras nära varandra i y-led utan överlappningsproblem
	UniqueRangeShape = RangeShape.duplicate() # Range shapen dupliceras för att alla torn inte ska dela samma range
	$Range/CollisionShape2D.shape = UniqueRangeShape # Den nya duplicerade range shapen appliceras
	_apply_trait_and_level_modifiers()
	_apply_modifiers()
	_update_stats(null) # Uppdaterar stats utan hänsyn till A eller B upgrade paths

func _apply_trait_and_level_modifiers():
	var TraitModifiers = Globals.TraitModifiers[Trait]
	var LevelModifiers = Globals.LevelModifiers
	for stat in stats: # Applicerar traiteffekter på stats
		if stat != "DamageDealt":
			stats[stat] *= (TraitModifiers[stat] + (LevelModifiers[stat] * Level))
	if Trait == "Singularity":
		max_placement = 1

func _apply_modifiers():
	if Globals.SelectedModifiers["Weak Towers"][0]:
		stats["damage"] = round(stats["damage"] * 0.8)
	if Globals.SelectedModifiers["Crippled Towers"][0]:
		stats["damage"] = round(stats["damage"] * 0.8)
		stats["range"] = round(stats["range"] * 0.8)
		stats["cooldown"] = snapped(stats["cooldown"] * 0.8, 0.01)
	if Globals.SelectedModifiers["Blind Towers"][0]:
		stats["range"] = round(stats["range"] * 0.8)
	if Globals.SelectedModifiers["Slow Towers"][0]:
		stats["cooldown"] = snapped(stats["cooldown"] * 0.8, 0.01)

func _update_stats(AorB):
	UniqueRangeShape.radius = stats["range"] # Ställer in range
	anim.speed_scale = stats["cooldown"] # Ställer in attack speed
	if UpgradeA > 3 and AorB == "A":
		TowerSprite.frame = UpgradeA - 3
		TowerOutline.frame = TowerSprite.frame
		if UpgradeA == 4:
			Weapon.position.y -= 8 # Eftersom den nya tornbasen är lite högre måste vapnets plats anpassas
			Weapon.get_node("WeaponSprite").texture = weapon_sprite2 # Vapnets sprite ändras ifall uppgraderingsnivån är 4 eller 5
		elif UpgradeA == 5:
			Weapon.position.y -= 7
			Weapon.get_node("WeaponSprite").texture = weapon_sprite3
	elif UpgradeB > 3 and AorB == "B":
		TowerSprite.frame = UpgradeB - 3
		TowerOutline.frame = TowerSprite.frame
		if UpgradeB == 4:
			Weapon.position.y -= 8
			Weapon.get_node("WeaponSprite").texture = weapon_sprite2
		elif UpgradeB == 5:
			Weapon.position.y -= 7
			Weapon.get_node("WeaponSprite").texture = weapon_sprite3

func _physics_process(_delta: float) -> void:
	#Om tornet inte redan attackerar och det finns fiender inom range: starta en attack
	if not is_attacking and enemies_in_range.size() > 0:
		_attack()
	#Om tornet inte är mitt innne i en attack och det inte finns fiender inom radien: gå till idle
	elif enemies_in_range.size() == 0 and not is_attacking:
		anim.play("Tower_Idle")
	
	if Input.is_action_just_pressed("Left_click") and hovering_over_tower:
		UpgradePanel.visible = true
		if global_position.x >= get_viewport().get_visible_rect().size.x / 2:
			UpgradePanel.global_position = Vector2(0,get_viewport_rect().size.y / 1.5 - UpgradePanel.get_node("Panel").size.y)
			UpgradePanel.get_node("Panel").get_node("TextureRect").position.x = 459
		else:
			UpgradePanel.global_position = Vector2(get_viewport().get_visible_rect().size.x-UpgradePanel.get_node("Panel").size.x*UpgradePanel.scale.x,get_viewport_rect().size.y / 1.5 - UpgradePanel.get_node("Panel").size.y)
			UpgradePanel.get_node("Panel").get_node("TextureRect").position.x = -399
	var overlapping_enemies = $Range.get_overlapping_bodies()
	enemies_in_range = overlapping_enemies.filter(func(b): return b is Enemy)
	
	queue_redraw()
	if targeted_enemy != null and is_instance_valid(targeted_enemy):
		Weapon.get_child(0).look_at(targeted_enemy.global_position)
		Weapon.get_child(0).rotation += PI/2

func _choose_targeted_enemy():
	# Filtrera bort null fiender
	var valid_enemies: Array = []
	for e in enemies_in_range:
		if e != null and e.is_inside_tree() and e.current_health > 0:
			valid_enemies.append(e)

	if valid_enemies.is_empty():
		targeted_enemy = null
		return

	match targeting:
		"First":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if e.get_parent().progress > best.get_parent().progress:
					best = e
			targeted_enemy = best

		"Last":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if e.get_parent().progress < best.get_parent().progress:
					best = e
			targeted_enemy = best

		"Strongest":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if e.current_health > best.current_health:
					best = e
			targeted_enemy = best

		"Weakest":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if e.current_health < best.current_health:
					best = e
			targeted_enemy = best

		"Closest":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if global_position.distance_to(e.global_position) < global_position.distance_to(best.global_position):
					best = e
			targeted_enemy = best

		"Furthest":
			var best = valid_enemies[0]
			for e in valid_enemies:
				if global_position.distance_to(e.global_position) > global_position.distance_to(best.global_position):
					best = e
			targeted_enemy = best

		"Random":
			var best = valid_enemies.pick_random()
			targeted_enemy = best

func _spawn_projectile():
	#Anpassar vilken fiende tornet ska skjuta på
	if enemies_in_range.size() > 0: #Dubbelkollar så att tornet inte gör skada om fienden redan gått ur range
		_choose_targeted_enemy()
		
		#skapar en projektil
		var projectile_scene = load("res://Scenes/Projectiles/ballista_tower_projectile.tscn")
		var projectile = projectile_scene.instantiate()
		projectile.global_position = Weapon.global_position - Vector2(0,0)
		projectile.parent = self
		get_tree().current_scene.get_node("TowerProjectiles").add_child(projectile)

func _attack() -> void:
	is_attacking = true
	anim.play("Tower_Firing")

	await anim.animation_finished

	is_attacking = false

func _draw():
	#Ritar range
	if UniqueRangeShape is CircleShape2D and (hovering_over_tower or UpgradePanel.visible):
		draw_circle(Vector2.ZERO, UniqueRangeShape.radius, Color(0, 0, 1, 0.1))

func _on_mouse_hover_detector_mouse_entered() -> void:
	TowerOutline.visible = true
	hovering_over_tower = true

func _on_mouse_hover_detector_mouse_exited() -> void:
	if not UpgradePanel.visible:
		TowerOutline.visible = false
	hovering_over_tower = false
