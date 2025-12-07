extends CharacterBody2D

class_name Enemy

@export var current_health = 0.0
@export var kill_reward = 0

@onready var healthbarprogress: ProgressBar = $ProgressBar
@onready var healthbarlabel: Label = $ProgressBar/Label

var speed: int

func _ready() -> void:
	current_health = Globals.enemy_health[name]
	kill_reward = Globals.enemy_base_reward[name] * Globals.current_health_factor
	healthbarprogress.max_value = current_health
	z_index = round(Globals.enemy_base_health[name]/10)

func _physics_process(_delta: float) -> void:
	healthbarprogress.global_position = global_position + Vector2(0,-20)
	healthbarprogress.rotation = - get_parent().rotation
	healthbarprogress.value = current_health
	if healthbarlabel != null:
		healthbarlabel.text = str(round(healthbarprogress.value))
