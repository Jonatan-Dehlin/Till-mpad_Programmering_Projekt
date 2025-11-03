extends Area2D

var damage: int
var velocity: float
var lifetime: float

var time_passed: float = 0.0

func _ready() -> void:
	damage = get_parent().stats["damage"]
	velocity = get_parent().stats["projectile_velocity"]
	rotation = get_parent().direction_to_enemy
	lifetime = get_parent().stats["projectile_lifetime"]

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * velocity * delta
	
	time_passed += delta
	if time_passed >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		Globals._damage(damage,body)
		queue_free()
