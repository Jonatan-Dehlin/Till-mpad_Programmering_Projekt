extends Control

#Saker som är användbara ingame
@onready var current_level = get_child(3)
@onready var MoneyLabel: Label = $HUD/WHMdisplay/Numbers/MoneyLabel
@onready var HealthLabel: Label = $HUD/WHMdisplay/Numbers/HealthLabel
@onready var WaveTimer: Timer = $HUD/NextWaveTimer
@onready var WaveLabel: Label = $HUD/WHMdisplay/Numbers/WaveLabel
@onready var SkipTimer: Timer = $HUD/SkipTimer
@onready var TowerPlacer = $TowerPlacer
@onready var EquippedTowersButtons = $HUD/TowerHotbar/HBoxContainer.get_children()
@onready var PlacedTowers = $PlacedTowers
@onready var Anim = $AnimationPlayer
@onready var PauseMenu = $HUD/PauseMenu

@onready var HUD = $HUD
@onready var FinishedMenu = $HUD/GameFinishedMenu
@onready var Hotbar = $HUD/TowerHotbar
@onready var WHMdisplay = $HUD/WHMdisplay
@onready var StartWaveButton = $HUD/StartWaveButton

var WaveDataFile = "user://WaveData.txt"
var StartOrSkipPressed: bool = false
var Playing: bool = false
var WaitingForModifierFinished: bool = true
var Finished_sending_wave: bool = false
var Skip_availiable: bool = false
var BetweenWaves: bool = false


var victory: bool = false
var max_wave = 100
var display_cash: int
var replay: bool = false

func _ready() -> void:
	_update_equipped_towers_buttons()
	_read_wave_data(1)
	_start_map(Globals.MapID, replay)

func _process(_delta: float) -> void:
	if Globals.Playing:
		display_cash = Globals.fancy_increment(display_cash, Globals.cash)
		
		MoneyLabel.text = "Money: $" + str(Globals.format_number(display_cash))
		HealthLabel.text = "HP: " + str(Globals.health)
		WaveLabel.text = "Wave: " + str(Globals.current_wave) + "/" + str(max_wave)
		
		if Input.is_action_just_pressed("Esc"):
			PauseMenu.visible = true
			PauseMenu._ready()
			
			# Väntar en frame för att pausemenyn ska dyka upp korrekt
			await get_tree().physics_frame
			get_tree().paused = true

func _input(event: InputEvent) -> void: # Hotkeys för hotbaren
	#not event.echo förhindrar problem ifall knappen hålls ner, annars skulle knappen tryckas flera gånger per sekund
	if event is InputEventKey and event.pressed and not event.echo and TowerPlacer.placed:
		match event.keycode:
			KEY_1:
				_hotbar_hotkey(0)
			KEY_2:
				_hotbar_hotkey(1)
			KEY_3:
				_hotbar_hotkey(2)
			KEY_4:
				_hotbar_hotkey(3)
			KEY_5:
				_hotbar_hotkey(4)
			KEY_6:
				_hotbar_hotkey(5)

func _hotbar_hotkey(slot: int) -> void: # Hjälpfunktion till hotkeys för hotbaren
	if slot < 0 or slot >= EquippedTowersButtons.size(): # Ifall t.ex. man inte har ett torn equippat på en av hotbarslotsen
		return
	
	var button: Button = EquippedTowersButtons[slot]
	if button.disabled: # Av samma anledning som ovanstående
		return
	
	button.emit_signal("pressed")

func _physics_process(_delta: float) -> void:
	if _detect_every_enemy_defeated():
		if not BetweenWaves:
			BetweenWaves = true
			WaveTimer.start()
			$HUD/StartWaveButton.visible = true
		$HUD/StartWaveButton.text = "Next wave in: " + str(round(WaveTimer.time_left))
	
	_detect_game_over()

func _detect_game_over():
	if victory == true or Globals.health <= 0:
		FinishedMenu.visible = true
		Hotbar.visible = false
		StartWaveButton.visible = false
		if victory:
			Globals.accumulated_reward[0] += Globals.map_completed_reward[Globals.MapDifficulty][0]
			Globals.accumulated_reward[1] += Globals.map_completed_reward[Globals.MapDifficulty][1]

		FinishedMenu._ready()
		Globals.grant_exp()
		get_tree().paused = true

func _detect_every_enemy_defeated() -> bool:
	if get_node(str(current_level.name)).get_node("EnemyPath").get_child_count() <= 1 and Finished_sending_wave:
		return true
	else:
		return false

func _start_map(MapID, Replay: bool):
	if not Replay:
		var map = load("res://Scenes/Levels/"+ str(MapID) + ".tscn")
		map = map.instantiate()
		current_level.replace_by(map)
		current_level = map
	else:
		replay = false

func _place_tower(TowerInstance, i):
	if Globals.cash >= TowerInstance.place_cost:
		
		#Beräkna placeringskostnaden
		var CostFactor: float = 1.0
		if TowerInstance.get_meta("Trait") == "Singularity": # Singularity gör tornen dyrare
			CostFactor += 0.5
		if Globals.SelectedModifiers["Expensive Towers"][0] == true:
			CostFactor += 0.5
		if Globals.SelectedModifiers["Economic Depression"][0] == true:
			CostFactor += 1
		if Globals.cash >= TowerInstance.place_cost * CostFactor: # Avbryter ifall spelaren inte har råd
			
			# Ser till att man inte kan placera fler av samma torn än Max placement värdet
			var MaxPlace
			if Globals.SelectedModifiers["Only One"][0]:
				MaxPlace = 1
			elif TowerInstance.get_meta("Trait") == "Singularity":
				MaxPlace = 1
			else:
				MaxPlace = TowerInstance.get_meta("MaxPlace")
				
			var CurrentPlacement = 0
			var Towers = PlacedTowers.get_children()
			for tower in Towers:
				if tower.get_meta("PlayerInventoryIndexReference") == i:
					CurrentPlacement += 1
			
			if CurrentPlacement < MaxPlace:
				# Preview lyckades: Spelaren har råd och och inte max placement
				TowerPlacer.preview_tower(TowerInstance)
				TowerPlacer.i = i
				Anim.play("RemoveHotbarAnim")
				
			else:
				pass
				# Ljud här

func _update_equipped_towers_buttons(): # Hotbaren
	for button: Button in EquippedTowersButtons:
		for i in range(Globals.EquippedTowers.size()):
			if str(button.get_meta("Index")) == str(Globals.EquippedTowers[i][1]):
				var tower = load("res://Scenes/Towers/" + str(Globals.EquippedTowers[i][0]).split(",")[0]+".tscn")
				var instance: Node2D = tower.instantiate()

				# Räknar ut CostFactor för torn
				var CostFactor: float = 1.0
				if Globals.EquippedTowers[i][0].split(",")[2].replace("TRAIT:","") == "Singularity":
					CostFactor += 0.5
				CostFactor += Globals.return_cost_factor()
				instance.place_cost *= CostFactor
				
				button.icon.atlas = instance.get_node("TowerSprite").texture
				button.text = "$" + str(instance.place_cost)
			
				# Ställer in metadata för de torn som är i hotbaren
				instance.set_meta("Level",int(Globals.EquippedTowers[i][0].split(",")[1].replace("LEVEL:","")))
				instance.set_meta("Trait",Globals.EquippedTowers[i][0].split(",")[2].replace("TRAIT:",""))
				instance.set_meta("XP",Globals.EquippedTowers[i][0].split(",")[3].replace("XP:",""))
				
				#Ställer in leveltexten
				button.get_node("LevelLabel").text = str(instance.get_meta("Level"))
				
				#Ställer in traitikonens texture
				button.get_node("TraitIcon").texture = button.get_node("TraitIcon").texture.duplicate(true)
				button.get_node("TraitIcon").texture.region = Globals.TraitIconAtlasDictionary[instance.get_meta("Trait")][0]

				# Kopplar hotbarknapparna till _place_tower funktionen
				if not button.is_connected("pressed", Callable(self, "_place_tower")):
					button.pressed.connect(_place_tower.bind(instance,i))

func _send_wave(enemy: String, amount: int, cooldown: float, startcooldown: float, last: bool) -> void:
	$HUD/WHMdisplay/Numbers/WaveLabel.text = "Wave: " + str(Globals.current_wave) + "/" + str(max_wave)
	Finished_sending_wave = false
	BetweenWaves = false
	#Kollar om fienden existerar
	if FileAccess.file_exists("res://Scenes/Enemies/" + enemy):
		#Cooldown innan fienden börjar spawnas
		await get_tree().create_timer(startcooldown, false).timeout
		
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
			await get_tree().create_timer(cooldown, false).timeout
	else:
		print(enemy + " is not found in res://Scenes/Enemies/")
	if last:
		Finished_sending_wave = true

func _wave_manager() -> void:
	Globals.current_wave += 1
	var enemies
	if Globals.current_wave <= max_wave:
		enemies = _read_wave_data(Globals.current_wave)
	else:
		enemies = _generate_wave(Globals.current_wave)
	Globals._apply_enemy_multipliers(Globals.current_wave)
	for enemy in enemies:
		var e = str_to_var(enemy)
		
		var EnemyName = e[0]
		var EnemyAmount = e[1]
		var EnemyCooldown = e[2]
		var EnemyStartCooldown = e[3]
		var EnemyLast = e[4]
		
		#Globals._apply_health_multiplier(Globals.current_wave)
		_send_wave(EnemyName, EnemyAmount, EnemyCooldown, EnemyStartCooldown, EnemyLast)
		#print("skickade: " + str(EnemyAmount) + " st " + str(EnemyName) + " Med cooldown på: " + str(EnemyCooldown))

func _read_wave_data(wave: int) -> Array: #Läser wave-data fram till max_wave
	if not FileAccess.file_exists(WaveDataFile):
		print("Fatal error: no wave data file found.")
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

func _generate_wave(_wave: int) -> Array: #Genererar infinite waves
	#format exempel: ["[\"FireBug.tscn\",10,1,false]", "[\"FireBug.tscn\",10,0.1,false]"]
	#Tillgängliga fiender: FireBug.tscn, LeafBug.tscn, MagmaCrab.tscn, Scorpion.tscn
	
	
	return []

################# SIGNALS #################

func _on_start_wave_button_pressed() -> void:
	_wave_manager()
	$HUD/StartWaveButton.visible = false
	SkipTimer.start()

func _on_skip_timer_timeout() -> void:
	$HUD/StartWaveButton.text = "Skip wave?"
	$HUD/StartWaveButton.visible = true

func _on_next_wave_timer_timeout() -> void:
	_wave_manager()
	$HUD/StartWaveButton.visible = false
	SkipTimer.start()
