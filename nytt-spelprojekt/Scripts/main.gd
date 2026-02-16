extends Control

@onready var MainMenu = $MainMenu
@onready var MapContainers = $ChooseMap/ScrollContainer/HBoxContainer.get_children()
@onready var TestChest = $Shop/ScrollContainer/Chests/Chest1/Chest1Button

# Inventory
@onready var InventoryButton: TextureButton = $MainMenu/BottomPanel/Buttons/Inventory
@onready var InventoryButtonPlaceholder: TextureRect = $Inventory/InventoryPlaceHolderBackground
@onready var InventoryGrid: GridContainer = $Inventory/ScrollContainer/InventoryGrid
@onready var HotbarSlotButtons = $Inventory/PreviewTower/EquipHotbar.get_children()
@onready var HotbarSwapResponse: Label = $Inventory/PreviewTower/HBoxContainer/Label3
@onready var HotbarSwapButton: Button = $Inventory/PreviewTower/HBoxContainer/HotbarSelectButton

# Trait
@onready var TraitInventoryGrid: GridContainer = $Traits/ScrollContainer/GridContainer
@onready var TraitSelectedTower: CenterContainer = $Traits/CenterContainer
@onready var CurrentTraitLabel: Label = $Traits/PurchaseTraitReroll2/CenterContainer/CurrentTrait
@onready var TraitCostLabel: Label = $Traits/PurchaseTraitReroll/HBoxContainer/HBoxContainer/TraitCost

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


# Player Stat Labels (och EXP bar)
@onready var PlayerNameLabel = $MainMenu/PlayerStats/PlayerUsername
@onready var PlayerLevelLabel = $MainMenu/PlayerStats/Level
@onready var PlayerEXPLabel = $MainMenu/PlayerStats/ProgressBar/Label
@onready var EXPProgressBar = $MainMenu/PlayerStats/ProgressBar
@onready var PlayerLevelBackground = $MainMenu/PlayerStats/PlayerPrestige
@onready var PlayerLevelSymbol = $MainMenu/PlayerStats/PlayerPrestige/PlayerIconSymbol

# Konstanter
const TRAIT_COST: int = 1000
const CHEST_COSTS: Dictionary = {
	"Chest1": 100,
	"Chest2": 500,
	"Chest3": 1000,
	"Chest4": 2000,
	"Chest5": 5000,
	"Chest6": 10000,
	"Chest7": 25000,
	"Chest8": 50000}

# Gamble variables
var Gamble = preload("res://Scenes/Menus/gamble.tscn").instantiate()
var GambleMenu: Control

# Tower Directory
var tower_directory = DirAccess.open("res://Scenes/Towers/")

# Trait Reroll variables
var selected_trait_reroll_tower

# Inventory selected tower
var selected_inventory_tower_ID = null
var selected_hotbar_id = null
var selected_tower_is_equipped: bool = false

# Game variables
var PlayMode = preload("res://Scenes/playing.tscn")

var selected_menu: String = "Main"


################# GENERAL FUNCTIONS ############
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
	
	# Koppla HotbarSelect knapparna
	for button in HotbarSlotButtons:
		button.pressed.connect(_select_hotbar_slot.bind(str(button.get_meta("ID")),button))
		pass
	
	#Ladda information från spelarens fil
	_load_player_stats()
	_load_inventory()
	Globals.update_save_file()
	_update_tower_buttons()
	_color_hotbar_buttons()
	
	if Globals.PlayerUser == "":
		$MainMenu/EnterUsername.visible = true
		$MainMenu/ColorRect.visible = true
		get_tree().paused = true
		
		await $MainMenu/EnterUsername.text_submitted
		
		Globals.PlayerUser = $MainMenu/EnterUsername.text
		$MainMenu/EnterUsername.visible = false
		$MainMenu/ColorRect.visible = false
		get_tree().paused = false
		Globals.update_save_file()

func _process(_delta: float) -> void:
	_update_labels()

################ INVENTORY FUNCTIONS #############
func _select_tower_from_inventory(TowerID):
	selected_inventory_tower_ID = TowerID
	_preview_selected_tower()
	_color_hotbar_buttons()

func _select_hotbar_slot(ButtonID, button):
	selected_hotbar_id = ButtonID
	for buttons in HotbarSlotButtons:
		if buttons == button:
			button.self_modulate.a = 1.0
			HotbarSwapResponse.text = "Slot Selected: " + str(button.get_meta("ID") + 1)
		else:
			buttons.self_modulate.a = 0.5

func _switch_hotbar_tower(Equipped: bool) -> void:
	if not Equipped: #
		if selected_inventory_tower_ID == null:
			HotbarSwapResponse.text = "No Tower Is Selected!"
		elif selected_hotbar_id == null:
			HotbarSwapResponse.text = "No Hotbar Slot Selected!"
		elif _is_slot_occupied():
			HotbarSwapResponse.text = "This Slot Is Already Occupied!"
			print("ändrade text")
		else:
			var NewSlotString = "SLOT:" + str(selected_hotbar_id)
			var NewString = Globals.get_string_from_id(selected_inventory_tower_ID).replace("SLOT:n/a",NewSlotString)
			HotbarSwapButton.text = "Unequip"
			HotbarSwapResponse.text = "This Tower Is Already Equipped!"
			Globals.EquippedTowers.append([NewString,selected_hotbar_id])
			Globals.inventory_replace_tower(NewString)
			Globals.update_save_file()
			_update_inventory()
			_color_hotbar_buttons()
			_preview_selected_tower()
			
	else:
		var oldSlot = _unequip_selected_tower()
		if oldSlot != -1:
			var OldSlotString = "SLOT:" + str(oldSlot)
			var NewString = Globals.get_string_from_id(selected_inventory_tower_ID).replace(OldSlotString,"SLOT:n/a")
			HotbarSwapButton.text = "Equip"
			HotbarSwapResponse.text = "This Tower Is Not Equipped!"
			Globals.inventory_replace_tower(NewString)
			Globals.update_save_file()
			_update_inventory()
			_color_hotbar_buttons()
			_preview_selected_tower()

func _unequip_selected_tower() -> int:
	for i in range(Globals.EquippedTowers.size()):
		var tower = Globals.EquippedTowers[i]
		var TowerID = Globals.get_tower_id(tower[0])
		if TowerID == selected_inventory_tower_ID:
			var oldSlot = tower[1]  # spara den gamla slot-positionen
			Globals.EquippedTowers.pop_at(i)
			return int(oldSlot)  # returnerar sloten
	return -1  # returnerar -1 om tornet inte var equippat

func _is_slot_occupied() -> bool:
	for tower in Globals.EquippedTowers:
		if str(tower[1]) == selected_hotbar_id:
			return true
	return false

func _is_tower_equipped() -> bool:
	for tower in Globals.EquippedTowers:
		var TowerID = Globals.get_tower_id(tower[0])
		if selected_inventory_tower_ID == TowerID:
			return true
	return false

func _preview_selected_tower() -> void:
	var PreviewContainer = $Inventory/PreviewTower/PreviewContainer
	var towerpanel_found = null
	for item in InventoryGrid.get_children():
		if item.get_meta("TowerID") == selected_inventory_tower_ID:
			towerpanel_found = item
			break
	
	var Duplicate = towerpanel_found.duplicate()
	selected_hotbar_id = null
	
	PreviewContainer.get_child(0).queue_free()
	PreviewContainer.add_child(Duplicate)
	
	if _is_tower_equipped():
		HotbarSwapButton.text = "Unequip"
		HotbarSwapResponse.text = "This Tower Is Already Equipped!"
		selected_tower_is_equipped = true
		Duplicate.self_modulate = Color(1,0,0)
	else:
		HotbarSwapButton.text = "Equip"
		HotbarSwapResponse.text = "This Tower Is Not Equipped!"
		selected_tower_is_equipped = false
		Duplicate.self_modulate = Color(1,1,1)

func _color_hotbar_buttons() -> void:
	for button in HotbarSlotButtons:
		
		var slotTaken: bool = false # Är slotet i fråga upptaget?
		var ButtonHotbarID = button.get_meta("ID") # Knappens ID (0 - 5)
		
		for tower in Globals.EquippedTowers:
			
			var TowerHotbarID = tower[1] # Vilken plats tornet har i hotbaren
			var TowerInventoryID = Globals.get_tower_id(tower[0]) # Tornets unika ID
			
			# Ifall tornets hotbarplats och unika ID matchar målas den blå
			if TowerInventoryID == selected_inventory_tower_ID and ButtonHotbarID == int(TowerHotbarID):
				button.self_modulate = Color(1,1,0,0.5)
				slotTaken = true
				break
				
			elif ButtonHotbarID == int(TowerHotbarID):
				button.self_modulate = Color(1,0,0,0.5)
				slotTaken = true
				break
				
		if not slotTaken:
			button.self_modulate = Color(0,1,0,0.5)
################ LOAD AND UPDATE FUNCTIONS ################
func _load_player_stats():
	if not FileAccess.file_exists(Globals.PlayerStatFile):
		print("Fatal error: no player data file found.")
	else:
		var file = FileAccess.open(Globals.PlayerStatFile, FileAccess.READ)
		
		while not file.eof_reached():
			var line = file.get_line().replace(" ", "").replace("	", "")
			if line.contains("LEVEL:"):
				Globals.PlayerStats["Level"] = int(line.replace("LEVEL:",""))
			elif line.contains("NAME:"):
				Globals.PlayerUser = line.replace("NAME:","")
			elif line.contains("EXP:"):
				Globals.PlayerStats["EXP"] = int(line.replace("EXP:",""))
			elif line.contains("SILVER:"):
				Globals.PlayerStats["Silver"] = int(line.replace("COINS:",""))
			elif line.contains("GOLD:"):
				Globals.PlayerStats["Gold"] = int(line.replace("DIAMONDS:",""))
		file.close()

func _load_inventory():
	if not FileAccess.file_exists(Globals.PlayerStatFile):
		print("Fatal error: no player data file found.")
		return
	
	var file = FileAccess.open(Globals.PlayerStatFile, FileAccess.READ)
	var TowersFound = false
	
	Globals.PlayerInventory.clear()
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if TowersFound and line != "":
			var id = Globals.get_tower_id(line)
			Globals.PlayerInventory[id] = line
		if line == "TOWERS:":
			TowersFound = true
	
	file.close()
	_update_inventory()

func _update_inventory():
	# Rensar de gamla tornen i Inventory och Traitgrid så att de kan bytas ut
	for child in InventoryGrid.get_children():
		child.queue_free()
	for child in TraitInventoryGrid.get_children():
		child.queue_free()

	Globals.EquippedTowers.clear()

	var inventory_ids: Array = Globals.PlayerInventory.keys()

	for id in inventory_ids:
		var towers: String = Globals.PlayerInventory[id]

		var inventoryTowerDirectory = towers.split(",")[0] + ".tscn"
		var tower_scene = load("res://Scenes/Towers/" + inventoryTowerDirectory)
		var instance = tower_scene.instantiate()

		var Duplicate = InventoryButtonPlaceholder.duplicate()
		var DuplicateButton: Button = Duplicate.get_child(0)

		# Om tornet har en designerad slot i hotbaren: lägg till i equippedtowers
		if not towers.split(",")[3].contains("n/a"):
			var SlotPos = int(towers.split(",")[3].replace("SLOT:",""))
			Globals.EquippedTowers.append([towers, SlotPos])
			

		# Fixar ikon och text till tornen
		var IconAtlas = AtlasTexture.new()
		IconAtlas.atlas = instance.get_node("TowerSprite").texture
		IconAtlas.region = Rect2(0,0,64,128)
		DuplicateButton.icon = IconAtlas
		DuplicateButton.get_node("TowerName").text = instance.name
		DuplicateButton.get_node("TowerLevel").text = towers.split(",")[1]

		# Fixar trait ikonen till tornet
		var TraitAtlas = AtlasTexture.new()
		TraitAtlas.atlas = DuplicateButton.get_node("TraitIcon").texture
		TraitAtlas.region = Globals.TraitIconAtlasDictionary[towers.split(",")[2].replace("TRAIT:","")][0]
		DuplicateButton.get_node("TraitIcon").texture = TraitAtlas

		# Fixar tornets meta ID
		Duplicate.set_meta("TowerID", id)
		Duplicate.visible = true

		# Krävs två duplicates: en för traitmenyn och en för inventoryt
		var Duplicate2 = Duplicate.duplicate()
		
		if not towers.split(",")[3].contains("n/a"): # Om tornet är equippat ska det vara lite rödare
			Duplicate.self_modulate = Color(1,0,0)
			Duplicate2.self_modulate = Color(1,0,0)
		
		# Lägg till dem in deras grids
		InventoryGrid.add_child(Duplicate)
		TraitInventoryGrid.add_child(Duplicate2)
	_update_tower_buttons()

func _update_labels():
	#Uppdatera visade värden i spelet
	for labels in get_tree().get_nodes_in_group("SilverAmount"):
		labels.text = str(Globals.format_number(Globals.PlayerStats["Silver"]))
	for labels in get_tree().get_nodes_in_group("GoldAmount"):
		labels.text = str(Globals.format_number(Globals.PlayerStats["Gold"]))
	
	for chests in Chests.get_children():
		var CostLabel: Label = chests.get_node("HBoxContainer").get_node("TraitCost")
		CostLabel.text = Globals.format_number(CHEST_COSTS[chests.name])
	
	PlayerNameLabel.text = Globals.PlayerUser
	PlayerLevelLabel.text = str(Globals.PlayerStats["Level"])
	EXPProgressBar.max_value = Globals.calculate_required_EXP(Globals.PlayerStats["Level"],true)
	EXPProgressBar.value = Globals.PlayerStats["EXP"]
	PlayerEXPLabel.text = str(Globals.format_number(Globals.PlayerStats["EXP"])) + "/" + str(Globals.format_number(Globals.calculate_required_EXP(Globals.PlayerStats["Level"],true)))
	TraitCostLabel.text = str(Globals.format_number(TRAIT_COST))
	
	_update_player_icon()

func _update_player_icon():
	var IconBackgroundPath = "res://Assets/the-cyberpunk-32x32-pixel-rank-icons/2 Frames/"
	var IconSymbolPath = "res://Assets/the-cyberpunk-32x32-pixel-rank-icons/1 Icons/"
	var PlayerLevel = Globals.PlayerStats["Level"]
	
	if PlayerLevel <= 14:
		if PlayerLevel <= 4:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "8.png")
		else:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "16.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "8/Rank-icons_" + str(PlayerLevel) + ".png")
	
	elif PlayerLevel <= 28:
		if PlayerLevel <= 18:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "7.png")
		else:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "15.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "7/Rank-icons_" + str(PlayerLevel - 14) + ".png")
	
	elif PlayerLevel <= 42:
		if PlayerLevel <= 32:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "1.png")
		else:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "9.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "1/Rank-icons_" + str(PlayerLevel - 28) + ".png")
	
	elif PlayerLevel <= 56:
		if PlayerLevel <= 46:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "5.png")
		else:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "13.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "5/Rank-icons_" + str(PlayerLevel - 42) + ".png")
	
	elif PlayerLevel <= 70:
		if PlayerLevel <= 60:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "6.png")
		else:
			PlayerLevelBackground.texture = load(IconBackgroundPath + "14.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "6/Rank-icons_" + str(PlayerLevel - 56) + ".png")
	
	else:
		PlayerLevelBackground.texture = load(IconBackgroundPath + "14.png")
		PlayerLevelSymbol.texture = load(IconSymbolPath + "6/Rank-icons_24.png")

func _update_tower_buttons():
	# Binder knapparna i Traitmenyn
	for towers in TraitInventoryGrid.get_children():
		var button: Button = towers.get_child(0)
		
		if not button.is_connected("pressed", Callable(self, "_trait_reroll")):
			button.pressed.connect(_trait_reroll.bind(towers))
	
	# Binder knapparna i Inventorymenyn
	for towers in InventoryGrid.get_children():
		var button: Button = towers.get_child(0)
		
		if not button.is_connected("pressed", Callable(self, "_select_tower_from_inventory")):
			button.pressed.connect(_select_tower_from_inventory.bind(towers.get_meta("TowerID")))

################ TRAIT AND CHEST FUNCTIONS ###############
func _open_chest(chestID, reset: bool):
	var chest: Button
	# Om spelaren inte har råd:
	if Globals.PlayerStats["Silver"] < CHEST_COSTS["Chest" + str(chestID)]:
		return
	
	# Änvänds för att resetta kistans sprite
	if reset: 
		chest = Chests.get_node("Chest" + str(chestID)).get_child(0)
		chest.icon.region.position.y -= 96
		return

	# Betala
	Globals.PlayerStats["Silver"] -= CHEST_COSTS["Chest" + str(chestID)]

	# Animation
	chest = Chests.get_node("Chest" + str(chestID)).get_child(0)
	for i in range(3):
		chest.icon.region.position.y += 32
		await get_tree().create_timer(0.1).timeout

	# Öppna gamble
	if not is_instance_valid(GambleMenu):
		var NewGamblePanel = Gamble.duplicate()
		add_child(NewGamblePanel)
		NewGamblePanel._ready()
		GambleMenu = NewGamblePanel

	GambleMenu.visible = true
	GambleMenu.gamble(chestID)

	await GambleMenu.GambleFinished
	var reward = GambleMenu._grant_gamble_reward()
	if reward == null:
		return

	# Skapa unikt ID
	var unique_id: String
	while true:
		unique_id = str(randi_range(0, 999_999_999)).pad_zeros(9)
		if not Globals.PlayerInventory.has(unique_id):
			break

	# Bygg TowerString
	var new_tower = reward.to_lower() + ",LVL:0,TRAIT:none,SLOT:n/a,XP:0,ID:" + unique_id

	# Lägg till i inventory och spara till datafilen
	Globals.PlayerInventory[unique_id] = new_tower
	Globals.update_save_file()

	# Uppdatera UI
	_update_inventory()
	_update_tower_buttons()

func _trait_reroll(tower: TextureRect):
	var Duplicate = tower.duplicate()

	# Rensa tidigare valt torn
	if TraitSelectedTower.get_child_count() > 0:
		TraitSelectedTower.get_child(0).queue_free()

	TraitSelectedTower.add_child(Duplicate)
	selected_trait_reroll_tower = tower

	var tower_id: String = tower.get_meta("TowerID")
	var tower_string: String = Globals.PlayerInventory[tower_id]

	var trait_part = tower_string.split(",")[2]
	var trait_name = trait_part.replace("TRAIT:", "").replace("_", " ")

	CurrentTraitLabel.text = trait_name

func _trait_change(NewTrait: String, tower: TextureRect):
	# Hämta tornets ID från UI
	var tower_id: String = tower.get_meta("TowerID")

	# Säkerhetskontroll
	if not Globals.PlayerInventory.has(tower_id):
		push_error("Trait change failed: TowerID not found: " + tower_id)
		return

	# Plocka TowerString
	var split = Globals.PlayerInventory[tower_id].split(",")

	# Byt TRAIT:
	for i in range(split.size()):
		if split[i].begins_with("TRAIT:"):
			split[i] = "TRAIT:" + NewTrait
			break

	var joined := ",".join(split)

	# Uppdatera inventory
	Globals.PlayerInventory[tower_id] = joined

	# Uppdatera EquippedTowers om tornet är equippat
	for i in range(Globals.EquippedTowers.size()):
		if Globals.get_tower_id(Globals.EquippedTowers[i][0]) == tower_id:
			Globals.EquippedTowers[i][0] = joined

	# Uppdaterar datafilen
	Globals.update_save_file()

	# Uppdaterar UI
	_update_inventory()
	_update_tower_buttons()

	# Vänta enframe för att låta spelet hinna återställa
	await get_tree().process_frame

	# Ser till att samma torn väljs igen så att vi ser det på högersidan av traitmenyn
	for item in TraitInventoryGrid.get_children():
		if item.get_meta("TowerID") == tower_id:
			_trait_reroll(item)
			break

############# BEFORE PLAY FUNCTIONS ##############
func _select_modifiers(MapID): # Körs när spelaren trycker på en karta. Avvaktar
	SelectModifiers.visible = true
	Globals.MapID = MapID
	_display_final_modifier()

func _change_difficulty(Difficulty: String, SilverModifier: int, GoldModifier: int):
	DifficultyLabel.text = Difficulty
	Globals.SelectedDifficulty = Difficulty
	SilverModifierLabel.text = "+" + str(SilverModifier) + "%"
	GoldModifierLabel.text = "+" + str(GoldModifier) + "%"

	_display_final_modifier()

func _modifier_handler(modification): # Är kopplad till modifier checkboxes
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
		SelectModifiers.visible = false
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

func _on_reroll_trait_button_pressed() -> void: # När trait reroll knappen trycks
	if selected_trait_reroll_tower != null and Globals.PlayerStats["Gold"] >= TRAIT_COST: # Om spelaren har valt ett torn för trait reroll
		Globals.PlayerStats["Gold"] -= TRAIT_COST # Tar betalt av spelaren
		var NewGamblePanel = Gamble.duplicate() # Skapa en ny gamblepanel
		add_child(NewGamblePanel) # Lägg till den
		NewGamblePanel._ready() # Kör dess _ready()
		GambleMenu = NewGamblePanel
		GambleMenu.visible = true # Gör den synlig
		NewGamblePanel.gamble("Trait")
		
		await GambleMenu.GambleFinished # Avvakta gambleanimationen färdig
		var reward = GambleMenu._grant_gamble_reward() # _grant_gamble_reward() ger vunnen trait
		if reward == null: # Bara för säkerhets skull
			print("Null reward")
		else:
			_trait_change(reward,selected_trait_reroll_tower) # Byter traiten

func _on_start_map_button_pressed() -> void:
	_start_play_mode()

func _on_hotbar_select_button_pressed() -> void:
	_switch_hotbar_tower(selected_tower_is_equipped)
