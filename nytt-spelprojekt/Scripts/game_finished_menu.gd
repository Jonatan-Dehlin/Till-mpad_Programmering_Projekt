extends Control

@onready var DifficultyFactors = $"Main Panel/DifficultyFactors".get_children()
@onready var EarnedSilver = $"Main Panel/TotalEarned/Label2"
@onready var EarnedGold = $"Main Panel/TotalEarned/Label3"
@onready var DefeatedWaves = $"Main Panel/WavesSurvived"
@onready var Difficulty = $"Main Panel/Difficulty"
@onready var Parent = $"../.."

var main = load("res://Scenes/main.tscn")

var DoneAnimating: bool = false
var DisplayedSilverValue: int = 0
var DisplayedGoldValue: int = 0

var TotalEarnedSilver: int = 0
var TotalEarnedGold: int = 0

func _ready() -> void:
	if visible: # Innebär att spelet är avslutat
		Difficulty.get_node("Difficulty").text = Globals.SelectedDifficulty
		Difficulty.get_node("Modifier").text = (str(Globals.SelectedDifficultyRewardMultipliers[Globals.SelectedDifficulty][0] * 100) + "%")
		Difficulty.get_node("Modifier2").text = (str(Globals.SelectedDifficultyRewardMultipliers[Globals.SelectedDifficulty][1] * 100) + "%")

		for modifiers in DifficultyFactors:
			if Globals.SelectedModifiers[modifiers.name][0] == false:
				modifiers.visible = false
			else:
				modifiers.visible = true
				await get_tree().create_timer(0.5).timeout
		DoneAnimating = true
		TotalEarnedSilver = round(Globals.accumulated_reward[0] * Globals.TotalMultiplier[0])
		TotalEarnedGold = round(Globals.accumulated_reward[1] * Globals.TotalMultiplier[1])
		DefeatedWaves.text = "Waves Survived:" + str(Globals.current_wave)

		Globals.PlayerStats["Silver"] += TotalEarnedSilver
		Globals.PlayerStats["Gold"] += TotalEarnedGold
		Globals.update_save_file()

func _process(delta: float) -> void:
	if DoneAnimating:
		if TotalEarnedSilver >= DisplayedSilverValue:
			DisplayedSilverValue = Globals.fancy_increment(DisplayedSilverValue, TotalEarnedSilver)
			EarnedSilver.text = str(Globals.format_number(DisplayedSilverValue)) 
		if TotalEarnedGold >= DisplayedGoldValue:
			DisplayedGoldValue = Globals.fancy_increment(DisplayedGoldValue, TotalEarnedGold)
			EarnedGold.text = str(Globals.format_number(DisplayedGoldValue))

#################### SIGNALS ######################
func _on_return_to_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(main)
	Globals.Playing = false
	Globals.reset()

func _on_replay_button_pressed() -> void:
	Parent.replay = true
	get_tree().paused = false
	get_tree().reload_current_scene()
	Globals.reset()
