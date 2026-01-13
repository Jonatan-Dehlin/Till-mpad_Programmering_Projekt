extends Control

@onready var DifficultyFactors = $TextureRect/DifficultyFactors.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for modifiers in DifficultyFactors:
		if Globals.SelectedModifiers[modifiers.name][0] == false:
			modifiers.visible = false
		else:
			modifiers.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
