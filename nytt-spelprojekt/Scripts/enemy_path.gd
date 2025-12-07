extends PathFollow2D

@export var speed: int
@onready var enemy: Enemy

var z: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_child_count() > 0:
		enemy = get_child(0)
		z = enemy.z_index
	if enemy != null:
		speed = Globals.enemies_speed[enemy.name]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if get_child_count() != 0:
		progress += speed * delta

func _on_brigde_entered_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.z_index = $"../../Details".z_index - 1

func _on_bridge_left_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.z_index = z
