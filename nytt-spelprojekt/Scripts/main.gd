extends Control

@onready var TowerPlacer = $TowerPlacer
@onready var MainMenu = $MainMenu
@onready var MapContainers = $ChooseMap/ScrollContainer/HBoxContainer.get_children()
@onready var TestChest = $Shop/ScrollContainer/Chests/Chest1/Chest1Button
@onready var InventoryButton: Button = $MainMenu/Panel/Buttons/Inventory
@onready var PlayButton: Button = $MainMenu/Panel/Buttons/Play
@onready var ShopButton: Button = $MainMenu/Panel/Buttons/Shop
@onready var transitions: AnimationPlayer = $MenuTransitions
@onready var Shop = $Shop
@onready var Chests = $Shop/ScrollContainer/Chests
@onready var EquippedTowersButtons = $TowerHotbar/HBoxContainer.get_children()

#Player Stat Labels (och EXP bar)
@onready var PlayerNameLabel = $MainMenu/HBoxContainer/PlayerStats/VBoxContainer/HBoxContainer/PlayerUsername
@onready var CoinLabel = $MainMenu/HBoxContainer/Panel2/VBoxContainer/HBoxContainer/CoinLabel
@onready var DiamondLabel = $MainMenu/HBoxContainer/Panel2/VBoxContainer/HBoxContainer2/DiamondLabel
@onready var PlayerLevelLabel =$MainMenu/HBoxContainer/PlayerStats/VBoxContainer/HBoxContainer/Level
@onready var PlayerEXPLabel = $MainMenu/HBoxContainer/PlayerStats/VBoxContainer/ProgressBar/Label
@onready var EXPProgressBar = $MainMenu/HBoxContainer/PlayerStats/VBoxContainer/ProgressBar


@onready var current_level = $LevelPlaceHolder
@onready var MoneyLabel: Label = $HUD/Panel/Numbers/MoneyLabel

var Gamble = preload("res://Scenes/gamble.tscn").instantiate()
var GambleMenu: Control

var PlayerStatFile = "user://PlayerData.txt"
var tower_directory = DirAccess.open("res://Scenes/Towers/")

var PlayerName: String

var PlayerStats = {"Coins": 0, "Diamonds": 0, "Level": 0, "EXP": 0}

var PlayerInventory = []

var EquippedTowers = [["wizard_tower,LVL:1,TRAIT:none", 0],["wizard_tower,LVL:1,TRAIT:none",1]]

var max_wave = 100

var display_cash: int

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
	_update_selected_towers()
	_update_save_file()

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

func _update_selected_towers():
	print("all towers: " + str(tower_directory.get_files()))
	
	for button: Button in EquippedTowersButtons:
		for i in range(EquippedTowers.size()):
			if button.get_meta("Index") == EquippedTowers[i][1]:
				var tower = load("res://Scenes/Towers/" + str(EquippedTowers[i][0]).split(",")[0]+".tscn")
				var instance = tower.instantiate()
				button.icon.atlas = instance.get_node("TowerSprite").texture
				button.text = "$" + str(instance.place_cost)
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
		
		file = FileAccess.open(PlayerStatFile, FileAccess.WRITE)
		for line in lines:
			file.store_line(line)
		file.close()
		
		#Uppdatera visade värden i spelet
		CoinLabel.text = str(PlayerStats["Coins"])
		DiamondLabel.text = str(PlayerStats["Diamonds"])
		PlayerNameLabel.text = PlayerName
		PlayerLevelLabel.text = str(PlayerStats["Level"])
		EXPProgressBar.max_value = _calculate_required_EXP()
		EXPProgressBar.value = PlayerStats["EXP"]
		PlayerEXPLabel.text = str(PlayerStats["EXP"]) + "/" + str(_calculate_required_EXP())

func _start_play_mode():
	MainMenu.visible = false
	Shop.visible = false
	$ChooseMap.visible = false

func _start_map(MapID):
	var map = load("res://Scenes/Levels/"+ str(MapID) + ".tscn")
	map = map.instantiate()
	current_level.replace_by(map)
	current_level = map
	
	_start_play_mode()
	_wave_manager(Globals.current_wave)

func _place_tower(TowerID, TowerInstance):
	var TowerName = str(TowerID).split(",")[0]
	if Globals.cash >= TowerInstance.place_cost:
		TowerPlacer.preview_tower(TowerName)

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

func _process(delta: float) -> void:
	#Mjuk övergång mot det riktiga värdet
	if display_cash < Globals.cash:
		if Globals.cash - display_cash > 1000:
			display_cash += 20
		elif Globals.cash - display_cash > 100:
			display_cash += 10
		elif Globals.cash - display_cash > 0:
			display_cash += 1
	elif display_cash > Globals.cash:
		if Globals.cash - display_cash < -1000:
			display_cash -= 20
		elif Globals.cash - display_cash < -100:
			display_cash -= 10
		elif Globals.cash - display_cash < -0:
			display_cash -= 1
			
	MoneyLabel.text = "Money: $" + str(int(display_cash))

func _send_wave(enemies: Dictionary) -> void:
	$HUD/Panel/Numbers/WaveLabel.text = "Wave: " + str(Globals.current_wave) + "/" + str(max_wave)
	for enemy in enemies:
		
		#Kollar om fienden existerar
		if FileAccess.file_exists("res://Scenes/Enemies/"+enemy+".tscn"):
			
			#Laddar enemyn
			var enemy_scene = load("res://Scenes/Enemies/"+enemy+".tscn")
			
			#Definerar levelns path och dess pathfollow2D template
			var Path = current_level.get_node("EnemyPath")
			var PathFollowTemplate = current_level.get_node("EnemyPath").get_node("PathFollow2D")
			
			for i in range(enemies[enemy]):
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
				await get_tree().create_timer(2).timeout
			
		else:
			print((enemy+".tscn") + " is not found in res://Scenes/Enemies/")

func _wave_manager(wave) -> void:
	Globals.current_wave += 1
	if Globals.current_wave % 2 == 0:
		Globals.enemies["FireBug"] = 1
		Globals.enemies["LeafBug"] = 1
	else:
		Globals.enemies["FireBug"] = 2
		Globals.enemies["LeafBug"] = 2
	Globals._apply_health_multiplier(wave)
	_send_wave(Globals.enemies)

func _calculate_required_EXP() -> int:
	var BaseEXPRequirement: int = 100
	var EXPScalingFactor: float = 1.3
	return BaseEXPRequirement * EXPScalingFactor ** PlayerStats["Level"]

################# SIGNALS #################
func _on_shop_pressed() -> void:
	transitions.play("ShopTransition")

func _on_play_pressed() -> void:
	transitions.play("PlayTransition")

func _on_return_to_main_menu_button_pressed() -> void:
	transitions.play("ResetShop")

func _on_return_to_main_menu_from_play_pressed() -> void:
	transitions.play("ResetPlay")
