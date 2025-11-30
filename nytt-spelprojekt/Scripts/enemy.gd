extends CharacterBody2D

class_name Enemy

@export var current_health = 0.0
@export var kill_reward = 0

@onready var healthbarprogress: ProgressBar = $ProgressBar

var speed: int

func _ready() -> void:
	current_health = Globals.enemy_health[name]
	kill_reward = Globals.enemy_base_reward[name] * Globals.current_health_factor
	healthbarprogress.max_value = current_health

func _physics_process(_delta: float) -> void:
	healthbarprogress.value = current_health
