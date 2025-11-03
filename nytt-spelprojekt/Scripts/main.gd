extends Node2D

@onready var current_level = $LevelPlaceHolder
@onready var LevelSelector: MenuButton = $LevelSelector
@onready var MoneyLabel: Label = $HUD/MoneyLabel

var max_wave = 100

var levels = []

var display_cash: int

func _ready() -> void:
	var PopUp = LevelSelector.get_popup()
	PopUp.id_pressed.connect(_on_menu_item_pressed)
	
	var level_directory = DirAccess.open("res://Scenes/Levels/")

	for level in level_directory.get_files():
		levels.append(level)
	print(levels)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Space"):
		Globals.cash += 1000
		print(Globals.cash - display_cash)
		print("display:" + str(display_cash))
		
	#Mjuk övergång mot det riktiga värdet
	if display_cash < Globals.cash:
		if Globals.cash - display_cash > 1000:
			display_cash += 20
		elif Globals.cash - display_cash > 100:
			display_cash += 10
		elif Globals.cash - display_cash > 0:
			display_cash += 1
			
	MoneyLabel.text = "Money: $" + str(int(display_cash))

func _send_wave(enemies: Dictionary) -> void:
	$HUD/WaveLabel.text = "Wave: " + str(Globals.current_wave) + "/" + str(max_wave)
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
			
			get_node("LevelSelector").visible = false
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
		
func _on_menu_item_pressed(id: int) -> void:
	var map = load("res://Scenes/Levels/"+levels[id])
	map = map.instantiate()
	current_level.replace_by(map)
	current_level = map
	_wave_manager(Globals.current_wave)
	
