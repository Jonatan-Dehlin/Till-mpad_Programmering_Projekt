extends Control

@onready var DifficultyFactors = $"Main Panel/DifficultyFactors".get_children()
@onready var EarnedSilver = $"Main Panel/TotalEarned/Label2"
@onready var EarnedGold = $"Main Panel/TotalEarned/Label3"
@onready var DefeatedWaves = $"Main Panel/WavesSurvived"
@onready var Difficulty = $"Main Panel/Difficulty"
@onready var Parent = $"../.."
@onready var LevelUpPlaceholder = $"Main Panel/TextureRect2/ScrollContainer/Placeholder"
@onready var LevelUpContainer: VBoxContainer = $"Main Panel/TextureRect2/ScrollContainer/LevelUpContainer"

var main = load("res://Scenes/main.tscn")

var DoneAnimating: bool = false
var DisplayedSilverValue: int = 0
var DisplayedGoldValue: int = 0

var TotalEarnedSilver: int = 0
var TotalEarnedGold: int = 0

func _ready() -> void:
	if visible: # Innebär att spelet är avslutat
		for children in LevelUpContainer.get_children(): # Tar bort gamla XP progressbars och sånt
			children.queue_free()
		
		for UpgradePanels in get_tree().get_nodes_in_group("UpgradePanel"): # Ser till att gömma alla upgradepanels så att de inte skulle skymma gamefinishedmenyn
			UpgradePanels.visible = false
		
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

func _process(_delta: float) -> void:
	if DoneAnimating:
		if TotalEarnedSilver >= DisplayedSilverValue:
			DisplayedSilverValue = Globals.fancy_increment(DisplayedSilverValue, TotalEarnedSilver)
			EarnedSilver.text = str(Globals.format_number(DisplayedSilverValue)) 
		if TotalEarnedGold >= DisplayedGoldValue:
			DisplayedGoldValue = Globals.fancy_increment(DisplayedGoldValue, TotalEarnedGold)
			EarnedGold.text = str(Globals.format_number(DisplayedGoldValue))

func fancy_display_xp(StartLevel, PreviousXP, GainedXP, TowerString):
	var pattern = LevelUpPlaceholder.duplicate()
	var TowerIcon: TextureRect = pattern.get_node("TowerIcon")
	var TraitIcon: TextureRect = TowerIcon.get_node("TraitIcon")
	var tower = load("res://Scenes/Towers/" + TowerString.split(",")[0] + ".tscn")
	var instance: Node2D = tower.instantiate()
	TowerIcon.texture.atlas = instance.get_node("TowerSprite").texture
	instance.queue_free()
	TraitIcon.texture = TraitIcon.texture.duplicate(true)
	TraitIcon.texture.region = Globals.TraitIconAtlasDictionary[TowerString.split(",")[2].replace("TRAIT:","")][0]
	
	LevelUpContainer.add_child(pattern)
	pattern.visible = true
	var progressbar: ProgressBar = pattern.get_node("ProgressBar")
	var progressbarLabel: Label = progressbar.get_node("Label")
	var totalXPlabel: Label = pattern.get_node("Double").get_node("XPLabel")
	var LVLLabel: Label = pattern.get_node("Double").get_node("LevelLabel")
	
	var currentLVL: int = StartLevel
	var currentOverflow: int = GainedXP
	progressbar.value = PreviousXP
	progressbar.max_value = Globals.calculate_required_EXP(StartLevel, false)
	progressbar.value = PreviousXP
	progressbarLabel.text = str(progressbar.value) + "/" + str(progressbar.max_value)
	totalXPlabel.text = "+0"
	LVLLabel.text = str(StartLevel) + " -> " + str(StartLevel)
	
	while currentOverflow > 0:
		progressbar.max_value = Globals.calculate_required_EXP(currentLVL, false)
		
		if progressbar.value + currentOverflow >= progressbar.max_value: # Kontrollerar ifall XP kommer räcka för levelup
			progressbar.value += round(progressbar.max_value / 10)
		
			if progressbar.value >= progressbar.max_value: # Ifall baren är fylld
				@warning_ignore("narrowing_conversion")
				currentOverflow -= progressbar.max_value
				currentLVL += 1
				progressbar.value = 0
		else: # Ifall XP inte räcker till levelup
			var completionSteps: int = 100 # Hur många iterations för att fylla baren
			@warning_ignore("narrowing_conversion")
			var targetValue: int = currentOverflow
			@warning_ignore("integer_division")
			var stepSize: int = targetValue / completionSteps
			var rest: int = targetValue % completionSteps
			
			for i in range(completionSteps):
				progressbar.value += stepSize
				currentOverflow -= stepSize
			# Tar sedan bort resten
			progressbar.value += rest
			currentOverflow -= rest
			if progressbar.value >= currentOverflow:
				currentOverflow = 0
		
		totalXPlabel.text = "+" + str(Globals.format_number(currentOverflow))
		progressbarLabel.text = str(progressbar.value) + "/" + str(progressbar.max_value)
		LVLLabel.text = str(StartLevel) + " -> " + str(currentLVL)
		
		await get_tree().create_timer(0.01).timeout

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
