extends Node2D

var placed = true
var selected_tower
var entered_bodies = 0
var towers = []
var i

@onready var parent = $".."
@onready var Hitbox = $Area2D
@onready var Anim = $"../AnimationPlayer"

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if not placed:
		_place_tower(selected_tower)
	if entered_bodies > 0:
		$Sprite2D.modulate = Color(1,0,0)
	else:
		$Sprite2D.modulate = Color(1,1,1)

func _place_tower(instance):
	# Gömmer eventuella upgradepaneler samt outlines ifall man vill placera ett till torn
	for panel in get_tree().get_nodes_in_group("UpgradePanel"):
		panel.visible = false
	for outline in get_tree().get_nodes_in_group("TowerOutline"):
		outline.visible = false
	instance.global_position = get_global_mouse_position()
	$Sprite2D.global_position = get_global_mouse_position()
	$Area2D.global_position = get_global_mouse_position()
	z_index = int(get_global_mouse_position().y)
	if Input.is_action_just_pressed("Left_click") and entered_bodies == 0 and selected_tower.place_cost <= Globals.cash:
		#Beräkna placeringskostnaden
		var CostFactor: float = 1.0
		if selected_tower.get_meta("Trait") == "Singularity": # Singularity gör tornen dyrare
			CostFactor += 0.5
		if Globals.SelectedModifiers["Expensive Towers"][0] == true:
			CostFactor += 0.5
		if Globals.SelectedModifiers["Economic Depression"][0] == true:
				CostFactor += 1
		
		if Globals.cash >= selected_tower.place_cost * CostFactor:
			placed = true
			parent.get_node("PlacedTowers").add_child(instance)
			$Sprite2D.texture = null
			instance.set_meta("PlayerInventoryIndexReference",i)
			Hitbox.get_child(0).queue_free()
			
			Anim.play_backwards("RemoveHotbarAnim")
			
			# Bekräftar köpet
			Globals.cash -= selected_tower.place_cost * CostFactor
			parent.quickswap = false
			
			# Sparar tornets referens i en separat variabel för att ändå ge XP
			# Ifall tornet tas bort i efterhand.
			if Globals.PlacedTowers.has(instance.get_meta("PlayerInventoryIndexReference")):
				Globals.PlacedTowers[instance.get_meta("PlayerInventoryIndexReference")][0] += 1
			else:
				Globals.PlacedTowers[instance.get_meta("PlayerInventoryIndexReference")] = [1,0]
		else:
			pass
			#Eventuellt spela något ljud här
	elif Input.is_action_just_pressed("Q"): # Avbryt placement
		cancel_placement()

func cancel_placement():
	placed = true
	$Sprite2D.texture = null
	Hitbox.get_child(0).queue_free()
	Anim.play_backwards("RemoveHotbarAnim")

func preview_tower(TowerInstance) -> void:
	var instance = TowerInstance.duplicate()
	placed = false
	selected_tower = instance
	$Sprite2D.texture = instance.get_node("TowerSprite").texture
	$Sprite2D.hframes = instance.get_node("TowerSprite").hframes
	$Sprite2D.frame = instance.get_node("TowerSprite").frame
	var InstanceHitbox = instance.get_node("TowerCollider").get_node("TowerHitbox")
	Hitbox.add_child(InstanceHitbox.duplicate())

func _on_area_2d_body_entered(_body: Node2D) -> void:
	entered_bodies += 1

func _on_area_2d_body_exited(_body: Node2D) -> void:
	entered_bodies -= 1

func _on_area_2d_area_entered(_area: Area2D) -> void:
	entered_bodies += 1

func _on_area_2d_area_exited(_area: Area2D) -> void:
	entered_bodies -= 1
