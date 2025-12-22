extends Control

@onready var TowerPlacer = $TowerPlacer
@onready var MainMenu = $MainMenu
@onready var MapContainers = $ChooseMap/ScrollContainer/HBoxContainer.get_children()
@onready var TestChest = $Shop/ScrollContainer/Chests/Chest1/Chest1Button

@onready var InventoryButton: TextureButton = $MainMenu/BottomPanel/Buttons/Inventory
@onready var InventoryButtonPlaceholder: TextureRect = $Inventory/InventoryPlaceHolderBackground
@onready var InventoryGrid: GridContainer = $Inventory/ScrollContainer/InventoryGrid

@onready var TraitInventoryGrid: GridContainer = $Traits/ScrollContainer/GridContainer
@onready var TraitSelectedTower: CenterContainer = $Traits/CenterContainer
@onready var CurrentTraitLabel: Label = $Traits/PurchaseTraitReroll2/CenterContainer/CurrentTrait

@onready var PlayButton: TextureButton = $MainMenu/BottomPanel/Buttons/Play
@onready var ShopButton: TextureButton = $MainMenu/BottomPanel/Buttons/Shop
@onready var transitions: AnimationPlayer = $MenuTransitions
@onready var Shop = $Shop
@onready var Chests = $Shop/ScrollContainer/Chests

#Hotbar
@onready var EquippedTowersButtons = $HUD/TowerHotbar/HBoxContainer.get_children()

#Player Stat Labels (och EXP bar)
@onready var PlayerNameLabel = $MainMenu/PlayerStats/PlayerUsername
@onready var CoinLabel = $MainMenu/PlayerWallet/SilverAmount/Currency/Silver/SilverLabel
@onready var DiamondLabel = $MainMenu/PlayerWallet/GoldAmount/Currency/Gold/GoldLabel
@onready var PlayerLevelLabel = $MainMenu/PlayerStats/Level
@onready var PlayerEXPLabel = $MainMenu/PlayerStats/ProgressBar/Label
@onready var EXPProgressBar = $MainMenu/PlayerStats/ProgressBar

#Saker som är användbara ingame
@onready var current_level = $LevelPlaceHolder
@onready var MoneyLabel: Label = $HUD/WHMdisplay/Numbers/MoneyLabel
@onready var HealthLabel: Label = $HUD/WHMdisplay/Numbers/HealthLabel
@onready var WaveTimer: Timer = $HUD/NextWaveTimer
@onready var SkipTimer: Timer = $HUD/SkipTimer

#Gamble variables
var Gamble = preload("res://Scenes/gamble.tscn").instantiate()
var GambleMenu: Control

#Tower Directory
var tower_directory = DirAccess.open("res://Scenes/Towers/")

#Player Stats
var PlayerStatFile = "user://PlayerData.txt"
var PlayerName: String
var PlayerStats = {"Coins": 0, "Diamonds": 0, "Level": 0, "EXP": 0}
var PlayerInventory = []
var EquippedTowers = []

#Trait Reroll variables
var selected_trait_reroll_tower

#Game variables
var WaveDataFile = "user://WaveData.txt"
var StartOrSkipPressed: bool = false

var Playing: bool = false
var Finished_sending_wave: bool = false
var Skip_availiable: bool = false
var BetweenWaves: bool = false

var max_wave = 100

var display_cash: int

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
			maps.pressed.connect(_start_map.bind(maps.name))
	
	#Ladda information från spelarens fil
	_load_player_stats()
	_load_inventory()
	_update_equipped_towers_buttons()
	_update_save_file()
	_update_tower_buttons()
	_read_wave_data(1)

func _process(_delta: float) -> void:
	if Playing:
		var diff = Globals.cash - display_cash

		# animerar cash visaren
		var amount := 1
		var abs_diff = abs(diff)

		if abs_diff > 50000:
			amount = 2000
		elif abs_diff > 20000:
			amount = 1000
		elif abs_diff > 10000:
			amount = 500
		elif abs_diff > 1000:
			amount = 100
		elif abs_diff > 100:
			amount = 50

		# sign gör att ovanstående fungerar oavsett om diff är negativ eller positiv
		display_cash += sign(diff) * amount
		
		MoneyLabel.text = "Money: $" + str(Globals._format_number(display_cash))
		HealthLabel.text = "HP: " + str(Globals.health)

func _physics_process(delta: float) -> void:
	if Playing and _detect_every_enemy_defeated():
		if not BetweenWaves:
			BetweenWaves = true
			WaveTimer.start()
			$HUD/StartWaveButton.visible = true
		$HUD/StartWaveButton.text = "Next wave in: " + str(round(WaveTimer.time_left))
	$HUD/Label.text = str(round(1/delta))
	#print("uppdaterade FPS: " + str(round(1/delta)))

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
		print("Tog bort child nr: " + str(items))
	
	var id = 0
	for towers in PlayerInventory:
		var inventoryTowerDirectory = str(towers.split(",")[0] + ".tscn")
		var tower = load("res://Scenes/Towers/" + inventoryTowerDirectory)
		var instance = tower.instantiate()
		var Duplicate = InventoryButtonPlaceholder.duplicate()
		var DuplicateButton: Button = Duplicate.get_child(0)
		
		if not str(towers.split(",")[3]).contains("n/a"):
			var SlotPos = int(str(towers.split(",")[3]).replace("SLOT:",""))
			EquippedTowers.append([str(towers.split(",")[0]) + "," + str(towers.split(",")[1]) + "," + str(towers.split(",")[2]),SlotPos])
		
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

func _update_equipped_towers_buttons(): #Hotbaren
	for button: Button in EquippedTowersButtons:
		for i in range(EquippedTowers.size()):
			if button.get_meta("Index") == EquippedTowers[i][1]:
				var tower = load("res://Scenes/Towers/" + str(EquippedTowers[i][0]).split(",")[0]+".tscn")
				var instance: Node2D = tower.instantiate()
				
				if EquippedTowers[i][0].split(",")[2].replace("TRAIT:","") == "Singularity":
					instance.place_cost *= 1.5
				
				button.icon.atlas = instance.get_node("TowerSprite").texture
				button.text = "$" + str(instance.place_cost)
			
				# Ställer in metadata för de torn som är i hotbaren
				instance.set_meta("Level",int(EquippedTowers[i][0].split(",")[1].replace("LEVEL:","")))
				instance.set_meta("Trait",EquippedTowers[i][0].split(",")[2].replace("TRAIT:",""))
				
				#Ställer in leveltexten
				button.get_node("LevelLabel").text = str(instance.get_meta("Level"))
				
				#Ställer in traitikonens texture
				button.get_node("TraitIcon").texture = button.get_node("TraitIcon").texture.duplicate(true)
				button.get_node("TraitIcon").texture.region = Globals.TraitIconAtlasDictionary[instance.get_meta("Trait")][0]

				
				if not button.is_connected("pressed", Callable(self, "_place_tower")):
					button.pressed.connect(_place_tower.bind(EquippedTowers[i][0],instance))

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
		EXPProgressBar.max_value = _calculate_required_EXP()
		EXPProgressBar.value = PlayerStats["EXP"]
		PlayerEXPLabel.text = str(PlayerStats["EXP"]) + "/" + str(_calculate_required_EXP())

func _update_tower_buttons():
	for towers in TraitInventoryGrid.get_children():
		var button: Button = towers.get_child(0)
		
		if not button.is_connected("pressed", Callable(self, "_trait_reroll")):
			button.pressed.connect(_trait_reroll.bind(towers))

func _calculate_required_EXP() -> int:
	var BaseEXPRequirement: int = 100
	var EXPScalingFactor: float = 1.3
	return BaseEXPRequirement * EXPScalingFactor ** PlayerStats["Level"]

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

############# PLAY FUNCTIONS ##############
func _start_play_mode():
	Playing = true
	MainMenu.visible = false
	Shop.visible = false
	$ChooseMap.visible = false
	$HUD.visible = true

func _start_map(MapID):
	var map = load("res://Scenes/Levels/"+ str(MapID) + ".tscn")
	map = map.instantiate()
	current_level.replace_by(map)
	current_level = map
	
	_start_play_mode()

func _place_tower(TowerID, TowerInstance):
	if Globals.cash >= TowerInstance.place_cost:
		TowerPlacer.preview_tower(TowerInstance)

func _detect_every_enemy_defeated() -> bool:
	if get_node(str(current_level.name)).get_node("EnemyPath").get_child_count() <= 1 and Finished_sending_wave:
		return true
	else:
		return false

func _send_wave(enemy: String, amount: int, cooldown: float, startcooldown: float, last: bool) -> void:
	$HUD/WHMdisplay/Numbers/WaveLabel.text = "Wave: " + str(Globals.current_wave) + "/" + str(max_wave)
	Finished_sending_wave = false
	BetweenWaves = false
	#Kollar om fienden existerar
	if FileAccess.file_exists("res://Scenes/Enemies/" + enemy):
		#Cooldown innan fienden börjar spawnas
		await get_tree().create_timer(startcooldown).timeout
		
		#Laddar enemyn
		var enemy_scene = load("res://Scenes/Enemies/" + enemy)
		
		#Definerar levelns path och dess pathfollow2D template
		var Path = current_level.get_node("EnemyPath")
		var PathFollowTemplate = current_level.get_node("EnemyPath").get_node("PathFollow2D")
		
		for i in range(amount):
			#Instantierar fienden
			var spawn = enemy_scene.instantiate()
			
			#Kopierar PathFollow2D och lägger till fienden i den
			var PathFollow = PathFollowTemplate.duplicate()
			PathFollow.add_child(spawn)
			
			#Nollställer progress så att de inte spawnar på samma ställe
			PathFollow.progress = 0
			
			#Lägger in PathFollow2D med dess enemy i pathen
			Path.add_child(PathFollow)
			
			#Cooldown mellan varje spawn
			await get_tree().create_timer(cooldown).timeout
	else:
		print(enemy + " is not found in res://Scenes/Enemies/")
	if last:
		Finished_sending_wave = true

func _wave_manager(wave) -> void:
	Globals.current_wave += 1
	var enemies
	if Globals.current_wave <= max_wave:
		enemies = _read_wave_data(Globals.current_wave)
	else:
		enemies = _generate_wave(Globals.current_wave)
	for enemy in enemies:
		var e = str_to_var(enemy)
		
		var EnemyName = e[0]
		var EnemyAmount = e[1]
		var EnemyCooldown = e[2]
		var EnemyStartCooldown = e[3]
		var EnemyLast = e[4]

		_send_wave(EnemyName, EnemyAmount, EnemyCooldown, EnemyStartCooldown, EnemyLast)
		#print("skickade: " + str(EnemyAmount) + " st " + str(EnemyName) + " Med cooldown på: " + str(EnemyCooldown))

func _read_wave_data(wave: int) -> Array: #Läser wave-data fram till max_wave
	if not FileAccess.file_exists(WaveDataFile):
		print("Fatal error: no player data file found.")
	else:
		var file = FileAccess.open(WaveDataFile, FileAccess.READ)
		var WaveDataFound = false
		var WaveData: Array
		
		while not file.eof_reached():
			var line = file.get_line().replace(" ", "").replace("	", "")
			if WaveDataFound:
				WaveData.append(line.split(";"))
			if line.contains("#WAVEDATA#"):
				WaveDataFound = true
		for waves in WaveData:
			if waves[0] == str(wave):
				var new: PackedStringArray = waves
				new.remove_at(0)
				return new
	return []

func _generate_wave(wave: int) -> Array: #Genererar infinite waves
	#format exempel: ["[\"FireBug.tscn\",10,1,false]", "[\"FireBug.tscn\",10,0.1,false]"]
	#Tillgängliga fiender: FireBug.tscn, LeafBug.tscn, MagmaCrab.tscn, Scorpion.tscn
	
	
	return []

################# SIGNALS #################
func _on_shop_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("ShopTransition")
		selected_menu = "Shop"

func _on_play_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("PlayTransition")
		selected_menu = "Play"

func _on_inventory_pressed() -> void:
	if selected_menu == "Main":
		transitions.play("InventoryTransition")
		selected_menu = "Inventory"

func _on_return_to_main_menu_button_pressed() -> void:
	if selected_menu == "Shop":
		transitions.play("ResetShop")
		selected_menu = "Main"

func _on_return_to_main_menu_from_play_pressed() -> void:
	if selected_menu == "Play":
		transitions.play("ResetPlay")
		selected_menu = "Main"

func _on_return_to_main_menu_from_inventory_button_pressed() -> void:
	if selected_menu == "Inventory":
		transitions.play("ResetInventory")
		selected_menu = "Main"

func _on_start_wave_button_pressed() -> void:
	_wave_manager(Globals.current_wave)
	$HUD/StartWaveButton.visible = false
	SkipTimer.start()

func _on_skip_timer_timeout() -> void:
	$HUD/StartWaveButton.text = "Skip wave?"
	$HUD/StartWaveButton.visible = true

func _on_next_wave_timer_timeout() -> void:
	_wave_manager(Globals.current_wave)
	$HUD/StartWaveButton.visible = false
	SkipTimer.start()

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

func _on_trait_menu_button_pressed() -> void:
	if selected_menu == "Shop":
		transitions.play("TraitTransition")
		selected_menu = "Trait"

func _on_return_to_shop_menu_pressed() -> void:
	if selected_menu == "Trait":
		transitions.play("ResetTrait")
		selected_menu = "Shop"
