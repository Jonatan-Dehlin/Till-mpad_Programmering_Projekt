extends Node2D

var placed = true
var selected_tower
var entered_bodies = 0
var towers = []

@onready var parent = $".."
@onready var Hitbox = $Area2D

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
	instance.global_position = get_global_mouse_position()
	$Sprite2D.global_position = get_global_mouse_position()
	$Area2D.global_position = get_global_mouse_position()
	z_index = int(get_global_mouse_position().y)
	if Input.is_action_just_pressed("Left_click") and entered_bodies == 0 and selected_tower.place_cost <= Globals.cash:
		placed = true
		parent.get_node("PlacedTowers").add_child(instance)
		$Sprite2D.texture = null
		Hitbox.get_child(0).queue_free()
		
		if selected_tower.get_meta("Trait") == "Singularity": # Singularity gör tornen dyrare
			Globals.cash -= selected_tower.place_cost * 1.5
		else:
			Globals.cash -= selected_tower.place_cost

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
