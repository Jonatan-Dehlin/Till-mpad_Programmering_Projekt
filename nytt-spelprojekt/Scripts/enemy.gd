extends CharacterBody2D

class_name Enemy

@export var current_health = 0.0
@export var kill_reward = 0

@onready var healthbarprogress: ProgressBar = $ProgressBar
@onready var healthbarlabel: Label = $ProgressBar/Label

var speed: int

func _ready() -> void:
	current_health = Globals.enemy_health[name]
	kill_reward = Globals.enemy_base_reward[name]
	healthbarprogress.max_value = current_health
	z_index = round(Globals.enemy_base_health[name]/10)

func _physics_process(_delta: float) -> void:
	healthbarprogress.position = Vector2(-35.5, -6)
	healthbarprogress.rotation = -get_parent().rotation
	healthbarprogress.value = current_health
	if healthbarlabel != null:
		healthbarlabel.text = str(round(healthbarprogress.value))

func _on_mouse_entered() -> void:
	#healthbarprogress.visible = true
	pass

func _on_mouse_exited() -> void:
	#healthbarprogress.visible = false
	pass
