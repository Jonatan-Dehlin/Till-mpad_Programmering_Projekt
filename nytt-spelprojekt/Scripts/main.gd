extends Control

@onready var MainMenu = $MainMenu
@onready var MapContainers = $ChooseMap/ScrollContainer/HBoxContainer.get_children()
@onready var TestChest = $Shop/ScrollContainer/Chests/Chest1/Chest1Button

# Inventory
@onready var InventoryButton: TextureButton = $MainMenu/BottomPanel/Buttons/Inventory
@onready var InventoryButtonPlaceholder: TextureRect = $Inventory/InventoryPlaceHolderBackground
@onready var InventoryGrid: GridContainer = $Inventory/ScrollContainer/InventoryGrid

# Trait
@onready var TraitInventoryGrid: GridContainer = $Traits/ScrollContainer/GridContainer
@onready var TraitSelectedTower: CenterContainer = $Traits/CenterContainer
@onready var CurrentTraitLabel: Label = $Traits/PurchaseTraitReroll2/CenterContainer/CurrentTrait

@onready var PlayButton: TextureButton = $MainMenu/BottomPanel/Buttons/Play
@onready var ShopButton: TextureButton = $MainMenu/BottomPanel/Buttons/Shop
@onready var transitions: AnimationPlayer = $MenuTransitions
@onready var Shop = $Shop
@onready var Chests = $Shop/ScrollContainer/Chests

# Modifiers
@onready var SelectModifiers = $ChooseMap/SelectModifiers
@onready var DifficultyLabel: Button = $ChooseMap/SelectModifiers/VBoxContainer/HBoxContainer/DifficultyLabel
@onready var DifficultyButtons = $ChooseMap/SelectModifiers/VBoxContainer/Difficulty.get_children()
@onready var SilverModifierLabel = $ChooseMap/SelectModifiers/VBoxContainer/HBoxContainer/HBoxContainer/SilverModifier
@onready var GoldModifierLabel = $ChooseMap/SelectModifiers/VBoxContainer/HBoxContainer/HBoxContainer/GoldModifier
@onready var CheckBoxes = $ChooseMap/SelectModifiers/CheckBoxContainer.get_children()
@onready var FinalModifers = $ChooseMap/SelectModifiers/FinalModifiers
@onready var StartButton: Button = $ChooseMap/SelectModifiers/FinalModifiers/StartMapButton


#Player Stat Labels (och EXP bar)
@onready var PlayerNameLabel = $MainMenu/PlayerStats/PlayerUsername
@onready var CoinLabel = $MainMenu/PlayerWallet/SilverAmount/Currency/Silver/SilverLabel
@onready var DiamondLabel = $MainMenu/PlayerWallet/GoldAmount/Currency/Gold/GoldLabel
@onready var PlayerLevelLabel = $MainMenu/PlayerStats/Level
@onready var PlayerEXPLabel = $MainMenu/PlayerStats/ProgressBar/Label
@onready var EXPProgressBar = $MainMenu/PlayerStats/ProgressBar

#Saker som är användbara ingame

#Gamble variables
var Gamble = preload("res://Scenes/Menus/gamble.tscn").instantiate()
var GambleMenu: Control

#Tower Directory
var tower_directory = DirAccess.open("res://Scenes/Towers/")

#Player Stats
var PlayerStatFile = "user://PlayerData.txt"
var PlayerName: String
var PlayerStats = {"Coins": 0, "Diamonds": 0, "Level": 0, "EXP": 0}
var PlayerInventory = []

#Trait Reroll variables
var selected_trait_reroll_tower

#Game variables
var PlayMode = preload("res://Scenes/playing.tscn")

var selected_menu: String = "Main"

func _ready() -> void:
	var NewGamblePanel = Gamble.duplicate()
	add_child(NewGamblePanel)
	NewGamblePanel._ready()
	GambleMenu = NewGamblePanel
	
	#Koppla kistknapparna
	var ID = 0
	for chest in Chests.get_children():
		var button: Button = chest.get_child(0)
		ID += 1 #Lista ut chest ID
		button.pressed.connect(_open_chest.bind(ID,false))
	
	#Koppla mapknapparna
	for columns in MapContainers:
		for maps: Button in columns.get_children():
			maps.pressed.connect(_select_modifiers.bind(maps.name))
	
	#Koppla difficultyknapparna
	for difficulty: Button in DifficultyButtons:
		difficulty.pressed.connect(_change_difficulty.bind(difficulty.text,difficulty.get_meta("SilverModifier"),difficulty.get_meta("GoldModifier")))
	
	# Koppla ModifierCheckboxarna
	for checkbox: CheckBox in CheckBoxes:
		checkbox.pressed.connect(_modifier_handler.bind(checkbox.name))
	
	#Ladda information från spelarens fil
	_load_player_stats()
	_load_inventory()
	_update_save_file()
	_update_tower_buttons()

func _process(_delta: float) -> void:
	pass

func _load_player_stats():
	if not FileAccess.file_exists(PlayerStatFile):
		print("Fatal error: no player data file found.")
	else:
		var file = FileAccess.open(PlayerStatFile, FileAccess.READ)
		
		while not file.eof_reached():
			var line = file.get_line().replace(" ", "").replace("	", "")
			if line.contains("LEVEL:"):
				PlayerStats["Level"] = int(line.replace("LEVEL:",""))
			elif line.contains("NAME:"):
				PlayerName = line.replace("NAME:","")
			elif line.contains("EXP:"):
				PlayerStats["EXP"] = int(line.replace("EXP:",""))
			elif line.contains("COINS:"):
				PlayerStats["Coins"] = int(line.replace("COINS:",""))
			elif line.contains("DIAMONDS:"):
				PlayerStats["Diamonds"] = int(line.replace("DIAMONDS:",""))
		file.close()

func _load_inventory():
	if not FileAccess.file_exists(PlayerStatFile):
		print("Fatal error: no player data file found.")
	else:
		var file = FileAccess.open(PlayerStatFile, FileAccess.READ)
		var TowersFound = false
		
		while not file.eof_reached():
			var line = file.get_line().replace(" ", "").replace("	", "")
			if TowersFound and line != "":
				PlayerInventory.append(line)
			if line.contains("TOWERS:"):
				TowersFound = true
		file.close()
		_update_inventory()

func _update_inventory():
	for items in range(InventoryGrid.get_child_count()):
		InventoryGrid.get_child(items).queue_free()
		TraitInventoryGrid.get_child(items).queue_free()
	
	var id = 0
	for towers in PlayerInventory:
		var inventoryTowerDirectory = str(towers.split(",")[0] + ".tscn")
		var tower = load("res://Scenes/Towers/" + inventoryTowerDirectory)
		var instance = tower.instantiate()
		var Duplicate = InventoryButtonPlaceholder.duplicate()
		var DuplicateButton: Button = Duplicate.get_child(0)
		
		if not str(towers.split(",")[3]).contains("n/a"):
			var SlotPos = int(str(towers.split(",")[3]).replace("SLOT:",""))
			Globals.EquippedTowers.append([str(towers.split(",")[0]) + "," + str(towers.split(",")[1]) + "," + str(towers.split(",")[2]),SlotPos])
		
		DuplicateButton.icon.atlas = instance.get_node("TowerSprite").texture
		DuplicateButton.get_node("TowerName").text = instance.name
		DuplicateButton.get_node("TowerLevel").text = str(towers.split(",")[1])
		
		var Atlas = AtlasTexture.new()
		Atlas.atlas = DuplicateButton.get_node("TraitIcon").texture
		Atlas.region = Globals.TraitIconAtlasDictionary[towers.split(",")[2].replace("TRAIT:","")][0]
		DuplicateButton.get_node("TraitIcon").texture = Atlas
		
		Duplicate.set_meta("Index",id)
		id += 1
		Duplicate.visible = true
		
		var Duplicate2 = Duplicate.duplicate()
		
		#Lägg till i inventory, men också listan i Trait-menyn
		InventoryGrid.add_child(Duplicate)
		TraitInventoryGrid.add_child(Duplicate2)

func _update_save_file():
	if not FileAccess.file_exists(PlayerStatFile):
		print("Fatal error: no player data file found.")
	else:
		var lines = []
		
		var file = FileAccess.open(PlayerStatFile, FileAccess.READ)
		while not file.eof_reached():
			lines.append(file.get_line())
		file.close()
		
		#Save Player Stats
		for line in range(lines.size()):
			var stripped: String = lines[line].replace(" ", "").replace("	","")
			
			if stripped.begins_with("LEVEL:"):
				lines[line] = "	LEVEL: " + str(PlayerStats["Level"])
			elif stripped.begins_with("EXP:"):
				lines[line] = "	EXP: " + str(PlayerStats["EXP"])
			elif stripped.begins_with("COINS:"):
				lines[line] = "	COINS: " + str(PlayerStats["Coins"])
			elif stripped.begins_with("DIAMONDS:"):
				lines[line] = "	DIAMONDS: " + str(PlayerStats["Diamonds"])
		#Save Tower Stats
		var TowersFound = false
		var index = 0
		for line in range(lines.size()):
			var stripped: String = lines[line].replace(" ", "").replace("	","")
			
			if TowersFound and stripped != "":
				lines[line] = PlayerInventory[index]
				index += 1
			if stripped.contains("TOWERS:"):
				TowersFound = true
		file.close()
		
		file = FileAccess.open(PlayerStatFile, FileAccess.WRITE)
		for line in lines:
			file.store_line(line)
		file.close()
		
		#Uppdatera visade värden i spelet
		CoinLabel.text = str(Globals._format_number(PlayerStats["Coins"]))
		DiamondLabel.text = str(Globals._format_number(PlayerStats["Diamonds"]))
		PlayerNameLabel.text = PlayerName
		PlayerLevelLabel.text = str(PlayerStats["Level"])
		EXPProgressBar.max_value = Globals.calculate_required_EXP(PlayerStats["Level"])
		EXPProgressBar.value = PlayerStats["EXP"]
		PlayerEXPLabel.text = str(PlayerStats["EXP"]) + "/" + str(Globals.calculate_required_EXP(PlayerStats["Level"]))

func _update_tower_buttons():
	for towers in TraitInventoryGrid.get_children():
		var button: Button = towers.get_child(0)
		
		if not button.is_connected("pressed", Callable(self, "_trait_reroll")):
			button.pressed.connect(_trait_reroll.bind(towers))

func _open_chest(chestID, reset: bool):
	if reset == false:
		var chest: Button = Chests.get_node("Chest" + str(chestID)).get_child(0)
		for i in range(3):
			
			chest.icon.region.position.y += 32
			await get_tree().create_timer(0.1).timeout
		
		if not has_node("Gamble"):
			var NewGamblePanel = Gamble.duplicate()
			add_child(NewGamblePanel)
			NewGamblePanel._ready()
			GambleMenu = NewGamblePanel
		GambleMenu.visible = true
		GambleMenu.gamble(chestID)
	else:
		var chest: Button = Chests.get_node("Chest" + str(chestID)).get_child(0)
		chest.icon.region.position.y -= 96

func _trait_reroll(tower: TextureRect):
	var Duplicate = tower.duplicate()
	
	if TraitSelectedTower.get_child_count() != 0:
		TraitSelectedTower.get_child(0).queue_free()
	TraitSelectedTower.add_child(Duplicate)
	selected_trait_reroll_tower = tower
	
	var TraitLabel: String
	if PlayerInventory[tower.get_meta("Index")].split(",")[2].contains("_"):
		TraitLabel = PlayerInventory[tower.get_meta("Index")].split(",")[2].replace("_"," ")
	else:
		TraitLabel = PlayerInventory[tower.get_meta("Index")].split(",")[2]
	CurrentTraitLabel.text = TraitLabel.replace("TRAIT:","")

func _trait_change(NewTrait, tower):
	var split = PlayerInventory[tower.get_meta("Index")].split(",")   # ["TOWER_NAME", "LVL:XXX", "TRAIT:XXX", "SLOT:XX"]
	
	for i in range(split.size()):
		if split[i].begins_with("TRAIT:"):
			split[i] = "TRAIT:" + NewTrait
			CurrentTraitLabel.text = NewTrait.replace("_"," ")
			
	
	var joined = ",".join(split)
	PlayerInventory[tower.get_meta("Index")] = joined

	_update_save_file()
	_update_inventory()
	_update_tower_buttons()
	
	#Sparar tornets index i inventoryt, väntar en frame så att
	#De gamla inventoryreferenserna hinner bytas ut i _update_inventory()
	#Simulerar sedan ett tryck med _trait_reroll() för att uppdatera
	#TraitIkonen för det stora tornet till höger i traitmenyn
	var tower_index = tower.get_meta("Index")
	await get_tree().process_frame
	
	_trait_reroll(TraitInventoryGrid.get_child(tower_index))

############# BEFORE PLAY FUNCTIONS ##############
func _select_modifiers(MapID): # Körs när spelaren trycker på en karta. Avvaktar
	SelectModifiers.visible = true
	Globals.MapID = MapID
	_display_final_modifier()

	await StartButton.pressed
	_start_play_mode()

func _change_difficulty(Difficulty: String, SilverModifier: int, GoldModifier: int):
	DifficultyLabel.text = Difficulty
	Globals.SelectedDifficulty = Difficulty
	SilverModifierLabel.text = "+" + str(SilverModifier) + "%"
	GoldModifierLabel.text = "+" + str(GoldModifier) + "%"

	_display_final_modifier()

func _modifier_handler(modification):
	if Globals.SelectedModifiers[modification][0] == false:
		Globals.SelectedModifiers[modification][0] = true
	else:
		Globals.SelectedModifiers[modification][0] = false
		
	_display_final_modifier()

func _display_final_modifier(): # Visar den totala modifiern
	var SilverModifier = FinalModifers.get_node("SilverModifier")
	var GoldModifier = FinalModifers.get_node("GoldModifier")
	var FinalSilverModifier = 0
	var FinalGoldModifier = 0
	
	for items in DifficultyButtons:
		if items.name == Globals.SelectedDifficulty:
			FinalSilverModifier += items.get_meta("SilverModifier")
			FinalGoldModifier += items.get_meta("GoldModifier")
	
	for items in Globals.SelectedModifiers:
		if Globals.SelectedModifiers[items][0] == true:
			FinalSilverModifier += Globals.SelectedModifiers[items][1]
			FinalGoldModifier += Globals.SelectedModifiers[items][2]
	SilverModifier.text = "+" + str(FinalSilverModifier) + "%"
	GoldModifier.text = "+" + str(FinalGoldModifier) + "%"
	
	Globals.TotalMultiplier[0] = 1 + float(FinalSilverModifier) / 100
	Globals.TotalMultiplier[1] = 1 + float(FinalSilverModifier) / 100

func _start_play_mode():
	Globals.Playing = true
	get_tree().change_scene_to_packed(PlayMode)

####################### SIGNALS #######################
func _on_shop_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("ShopTransition")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Shop"

func _on_play_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("PlayTransition")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Play"

func _on_inventory_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("InventoryTransition")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Inventory"

func _on_trait_menu_button_pressed() -> void:
	if selected_menu == "Shop":
		transitions.play("TraitTransition")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Trait"

func _on_return_to_main_menu_button_pressed() -> void:
	if selected_menu == "Shop":
		transitions.play("ResetShop")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Main"

func _on_return_to_main_menu_from_play_pressed() -> void:
	if selected_menu == "Play":
		transitions.play("ResetPlay")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Main"

func _on_return_to_main_menu_from_inventory_button_pressed() -> void:
	if selected_menu == "Inventory":
		transitions.play("ResetInventory")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Main"

func _on_return_to_shop_menu_pressed() -> void:
	if selected_menu == "Trait":
		transitions.play("ResetTrait")
		selected_menu = "animating..."
		await transitions.animation_finished
		selected_menu = "Shop"

func _on_reroll_trait_button_pressed() -> void:
	if selected_trait_reroll_tower != null:
		var NewGamblePanel = Gamble.duplicate()
		add_child(NewGamblePanel)
		NewGamblePanel._ready()
		GambleMenu = NewGamblePanel
		GambleMenu.visible = true
		if ((await GambleMenu.gamble("Trait")) == "ScrollFinished"):
			var reward = GambleMenu._grant_gamble_reward()
			if reward == null:
				print("Null reward")
			else:
				_trait_change(reward,selected_trait_reroll_tower)
