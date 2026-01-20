extends Control

@onready var DifficultyFactors = $"Main Panel/DifficultyFactors".get_children()
@onready var EarnedSilver = $"Main Panel/TotalEarned/Label2"
@onready var EarnedGold = $"Main Panel/TotalEarned/Label3"
@onready var Parent = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for modifiers in DifficultyFactors:
		if Globals.SelectedModifiers[modifiers.name][0] == false:
			modifiers.visible = false
		else:
			modifiers.visible = true
	EarnedSilver.text = str(round(Globals.accumulated_reward[0] * Globals.TotalMultiplier[0]))
	EarnedGold.text = str(round(Globals.accumulated_reward[1] * Globals.TotalMultiplier[1]))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#################### SIGNALS ######################
func _on_return_to_menu_button_pressed() -> void:
	pass # Replace with function body.

func _on_replay_button_pressed() -> void:
	Parent.replay = true
	get_tree().paused = false
	get_tree().reload_current_scene()
	Globals.reset()
