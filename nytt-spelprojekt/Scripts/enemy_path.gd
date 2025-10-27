extends PathFollow2D

@export var speed = 100
@onready var enemy: Enemy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if get_child_count() != 0:
		progress += speed * delta



func _on_brigde_entered_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.z_index = -95



func _on_bridge_left_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.z_index = -89
