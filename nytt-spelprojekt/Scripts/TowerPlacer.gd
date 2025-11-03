extends Node2D

var placed = true
var selected_tower
var entered_bodies = 0
var towers = []

@onready var parent = $".."
@onready var Hitbox = $Area2D
@onready var TowerSelector = $TowerSelector

func _ready() -> void:
	var PopUp = TowerSelector.get_popup()
	PopUp.id_pressed.connect(_on_menu_item_pressed)
	
	var tower_directory = DirAccess.open("res://Scenes/Towers/")

	for tower in tower_directory.get_files():
		towers.append(tower)
	print(towers)

func _physics_process(delta: float) -> void:
	if not placed:
		_place_tower(selected_tower)
	if entered_bodies > 0:
		$Sprite2D.modulate = Color(1,0,0)
	else:
		$Sprite2D.modulate = Color(1,1,1)
		
func _place_tower(instance):
	instance.position = get_global_mouse_position()
	$Sprite2D.position = get_global_mouse_position()
	$Area2D.position = get_global_mouse_position()
	if Input.is_action_just_pressed("Left_click") and entered_bodies == 0:
		placed = true
		parent.get_node("PlacedTowers").add_child(instance)
		$Sprite2D.texture = null
		Hitbox.get_child(0).queue_free()
		

func _on_menu_item_pressed(id: int) -> void:
	if FileAccess.file_exists("res://Scenes/Towers/"+towers[id]):
		var scen = load("res://Scenes/Towers/"+towers[id])
		var instance = scen.instantiate()
		placed = false
		selected_tower = instance
		$Sprite2D.texture = instance.get_node("TowerSprite").texture
		$Sprite2D.hframes = instance.get_node("TowerSprite").hframes
		$Sprite2D.frame = instance.get_node("TowerSprite").frame
		var InstanceHitbox = instance.get_node("TowerCollider").get_node("TowerHitbox")
		Hitbox.add_child(InstanceHitbox.duplicate())
		
		$TowerSelector.visible = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	entered_bodies += 1


func _on_area_2d_body_exited(body: Node2D) -> void:
	entered_bodies -= 1


func _on_area_2d_area_entered(area: Area2D) -> void:
	entered_bodies += 1


func _on_area_2d_area_exited(area: Area2D) -> void:
	entered_bodies -= 1
