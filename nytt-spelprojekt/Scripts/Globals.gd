extends Node

var current_wave = 0

var health = 100

var cash = 100000

var GameFinishedMenu

var MapID
var MapDifficulty: String
var TotalMultiplier: PackedFloat64Array = [1.0,1.0]

var Playing: bool = false

var PlayerStatFile = "user://PlayerData.txt"
var EquippedTowers = []
var PlayerStats = {"Silver": 0, "Gold": 0, "Level": 0, "EXP": 0}
var PlayerInventory = {} # Format: {"id": wizard_tower,LVL:62,TRAIT:Singularity,SLOT:0,XP:0,ID:000000000}

################## ENEMY STATS ###################
var enemies = {"FireBug":0,"LeafBug":0,"MagmaCrab":0,"Scorpion":0}
var enemy_base_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemy_base_speed = {"FireBug":100,"LeafBug":50,"MagmaCrab":20,"Scorpion":10}
var enemy_health = {"FireBug":100,"LeafBug":200,"MagmaCrab":1000,"Scorpion":10000}
var enemy_speed = {"FireBug":100,"LeafBug":50,"MagmaCrab":20,"Scorpion":10}
var enemy_base_reward = {"FireBug":10,"LeafBug":20,"MagmaCrab":50,"Scorpion":100}

# Bidrar till spelarens belöningar EFTER spelets slut
var enemy_kill_reward = {"FireBug":[10,0],"LeafBug":[20,0],"MagmaCrab":[50,5],"Scorpion":[100,10]} # Scalar med HP factor. Se _damage()
var map_completed_reward = {"Easy":[1000,100],"Normal":[1500,200],"Advanced":[3000,250],"Expert":[5000,1000]}
var accumulated_reward: Array = [0,0] # [silver, guld]
var accumulated_player_EXP: int = 0


# Speed och HP faktorer för fiender
var current_health_factor: float = 1
var current_speed_factor: float = 1

# konstanter för fienders HP och Speed ökning varje wave
const HEALTH_FACTOR = 1.05
const SPEED_FACTOR = 1.01
const DAMAGE_TO_XP_FACTOR: float = 0.01

var PlacedTowers: Dictionary = {} # {"Specifik tornreference": [antal placerade, total dmg dealt]}

var SelectedDifficulty: String = "Easy"

var SelectedDifficultyModifiers: Dictionary = { # Modifiers beroende på vald difficulty
	"Easy": {"EnemyHP": 1, "EnemySpeed": 1, "BaseHP": 15},
	"Normal": {"EnemyHP": 1.5, "EnemySpeed": 1.1, "BaseHP": 10},
	"Hard": {"EnemyHP": 2, "EnemySpeed": 1.2, "BaseHP": 5},
	"Insane": {"EnemyHP": 5, "EnemySpeed": 1.5, "BaseHP": 2},
	"Impossible": {"EnemyHP": 10, "EnemySpeed": 1.8, "BaseHP": 1.5},
	"Nightmare": {"EnemyHP": 50, "EnemySpeed": 2, "BaseHP": 1}}

var SelectedDifficultyRewardMultipliers: Dictionary = {
	"Easy": [1,1],
	"Normal": [1.5,1],
	"Hard": [2,1.15],
	"Insane": [2.5,1.3],
	"Impossible": [3,1,5],
	"Nightmare": [5,2]}

var SelectedModifiers: Dictionary = { # Valbara modifiers som gör spelet svårare men ger mer belöningar
	"Slow Towers": [false,25,0], # Långsammare attack speed
	"Weak Towers": [false,25,0], # Mindre damage
	"Blind Towers": [false,25,0], # Kortare range
	"Crippled Towers": [false,50,0], # Mindre attack speed, range och damage
	"Expensive Towers": [false,25,0], # Dyrare torn
	"Economic Depression": [false,50,0], # Dyrare torn, mindre belöningar från pengatorn och fiende kills
	"Sudden Death": [false,100,0], # Max HP sätts till 1
	"Only One": [false,100,0]} # Endast 1 placement per torn

var TraitIconAtlasDictionary: Dictionary = { # Innehåller atlastexture koordinater och färg för traitikonerna
	"none": [Rect2(230,69,27,22), Color(0.5,0.5,1)],
	"Rapid_I": [Rect2(100,261,27,22), Color(0.5,0.5,1)],
	"Rapid_II": [Rect2(100,261,27,22), Color(1,1,1)],
	"Rapid_III": [Rect2(100,261,27,22), Color(1,0.5,0.5)],
	"Strong_I": [Rect2(131,36,27,25), Color(0.5,0.5,1)],
	"Strong_II": [Rect2(131,36,27,25), Color(1,1,1)],
	"Strong_III": [Rect2(131,36,27,25), Color(1,0.5,0.5)],
	"Vision_I": [Rect2(2,229,27,22), Color(0.5,0.5,1)],
	"Vision_II": [Rect2(2,229,27,22), Color(1,1,1)],
	"Vision_III": [Rect2(2,229,27,22), Color(1,0.5,0.5)],
	"Lightning": [Rect2(260,3,24,26), Color(1,1,1)],
	"Unbeatable": [Rect2(419,100,25,25), Color(1,1,1)],
	"Hawkeye": [Rect2(99,98,26,27), Color(1,1,1)],
	"Midas": [Rect2(355,387,26,26), Color(1,1,1)],
	"Singularity": [Rect2(258,674,28,28), Color(1,1,1)],
}

var TraitModifiers: Dictionary = { # Innehåller förändringsfaktorer som senare appliceras i tornens lokala kod
	"none": {"damage":1, # +0% i allting
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_I": {"damage":1, # 10% snabbare attack speed
			"range":1,
			"cooldown":1.1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_II": {"damage":1, # 25% snabbare attack speed
			"range":1,
			"cooldown":1.25,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Rapid_III": {"damage":1, # 50% snabbare attack speed
			"range":1,
			"cooldown":1.5,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_I": {"damage":1.1, # 10% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_II": {"damage":1.25, # 25% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Strong_III": {"damage":1.5, # 50% mer damage
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_I": {"damage":1, # 10% mer range
			"range":1.1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_II": {"damage":1, # 25% mer range
			"range":1.25,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Vision_III": {"damage":1, # 50% mer range
			"range":1.5,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Lightning": {"damage":1, # 100% snabbare attack speed, 50% snabbare velocity
			"range":1,
			"cooldown":2,
			"projectile_velocity": 1.5,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Unbeatable": {"damage":2, # 100% mer damage, 25% större AOE
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1.25},
	"Hawkeye": {"damage":1, # 200% mer range, 100% snabbare velocity, 33% minskning AOE
			"range":3,
			"cooldown":1,
			"projectile_velocity": 2,
			"projectile_lifetime": 1,
			"AOESize": 0.6667},
	"Midas": {"damage":1, # 50% mer pengar från kill, samt 50% mer money generation. Dessa effekter appliceras här i Globals för extra kill money, men lokalt i tornkoden för money generation.
			"range":1,
			"cooldown":1,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1},
	"Singularity": {"damage":5, # 400% mer damage, 100% snabbare attack speed, ,100% större range, 50% större AOE MEN 200% cost, MAX 1 placement.
			"range":2,
			"cooldown":2,
			"projectile_velocity": 1,
			"projectile_lifetime": 1,
			"AOESize": 1.5},
}

var LevelModifiers: Dictionary = { # Faktor per tornets Level
	"damage": 0.02, 
	"range": 0.005, 
	"cooldown": 0.005,
	"projectile_velocity": 0,
	"projectile_lifetime": 0,
	"AOESize": 0
} 

#################### GENERAL FUNCTIONS ####################
func _ready() -> void:
	current_health_factor = 1
	current_speed_factor = 1

func get_tower_id(TowerString: String) -> String:
	for parts in TowerString.split(","):
		if parts.contains("ID:"):
			return parts.replace("ID:","")
	return ""

func get_string_from_id(TowerID: String) -> String:
	return PlayerInventory[TowerID]

func inventory_replace_tower(TowerString: String) -> void:
	PlayerInventory[get_tower_id(TowerString)] = TowerString

func update_save_file():
	if not FileAccess.file_exists(PlayerStatFile):
		print("Fatal error: no player data file found.")
		return

	var lines: Array = []

	# Läs fil
	var file = FileAccess.open(PlayerStatFile, FileAccess.READ)
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()

	# Uppdatera player stats
	for i in range(lines.size()):
		var stripped = lines[i].replace(" ", "").replace("	","")

		if stripped.begins_with("LEVEL:"):
			lines[i] = "	LEVEL: " + str(PlayerStats["Level"])
		elif stripped.begins_with("EXP:"):
			lines[i] = "	EXP: " + str(PlayerStats["EXP"])
		elif stripped.begins_with("SILVER:"):
			lines[i] = "	SILVER: " + str(PlayerStats["Silver"])
		elif stripped.begins_with("GOLD:"):
			lines[i] = "	GOLD: " + str(PlayerStats["Gold"])

	# Hitta TOWERS:
	var tower_index = -1
	for i in range(lines.size()):
		if lines[i].strip_edges() == "TOWERS:":
			tower_index = i
			break

	if tower_index == -1:
		push_error("TOWERS: hittades inte i save-filen")
		return

	# Behåll allt fram till TOWERS:
	lines = lines.slice(0, tower_index + 1)

	# Lägg till inventory (ID → TowerString)
	var ids := PlayerInventory.keys()
	ids.sort()

	for id in ids:
		lines.append(PlayerInventory[id])

	# Skriv fil
	file = FileAccess.open(PlayerStatFile, FileAccess.WRITE)
	for line in lines:
		file.store_line(line)
	file.close()

func fancy_increment(StartValue, TargetValue) -> int: # Skapar fina uppräkningar av värden
	var diff = TargetValue - StartValue
	var EndValue
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
	elif StartValue > TargetValue:
		EndValue = TargetValue

	# sign gör att ovanstående fungerar oavsett om diff är negativ eller positiv
	EndValue = StartValue + sign(diff) * amount
	return EndValue

func calculate_required_EXP(Level, player: bool) -> int: # Räknar ut hur mycket EXP som krävs för nästa spelarnivå
	const MAX_LEVEL: int = 100
	const XP_TO_MAX_PLAYER_LEVEL = 10000000
	const XP_TO_MAX_TOWER_LEVEL = 1000000
	# Vid level 90 har hälften av all XP tjänats:
	var EXPScalingFactor: float = log(0.5) / log(0.9)
	var BaseEXPRequirement: int = 10
	
	if player:
		return BaseEXPRequirement + XP_TO_MAX_PLAYER_LEVEL * pow(float(Level) / MAX_LEVEL, EXPScalingFactor)
	else:
		return BaseEXPRequirement + XP_TO_MAX_TOWER_LEVEL * pow(float(Level) / MAX_LEVEL, EXPScalingFactor)

func format_number(n: int) -> String: # Gör om t.ex. 1000000 -> 1,000,000
	if n < 1000: #Om numret är under 1000 behöver det inte formatteras
		return str(n)
	else:
		var s = str(n)
		var result: String = ""
		var numbers_added = 0
		
		s = s.reverse() #Vänder på stringen för att få "," på rätt ställen
		
		for numbers in s:
			if numbers_added % 3 == 0 and numbers_added != 0: # != 0 för att 0/3 = 0
				result += "," #Om tre siffror blivit tillagda ska ett komma in
			result += numbers
			numbers_added += 1
		result = result.reverse() #Vänder tillbaks string så att det blir rätt håll
		
		return result

func grant_exp(): # Ger XP till torn och spelare vid game over
	GameFinishedMenu = get_tree().current_scene.get_node("HUD").get_node("GameFinishedMenu")
	var PlayerEXP: int = 0
	for i in range(EquippedTowers.size()): # [Towers har formatet "tower_name,LVL:x,TRAIT:x,SLOT:x,XP:x,ID:x, num]
		var Towers = EquippedTowers[i]
		if PlacedTowers.has(Towers[1]): # Ifall tornet har placerats någon gång under spelets gång
			var split = Towers[0].split(",") # Plockar isär towersträngen så att vi kan komma åt t.ex XP
			var PreviousXP = int(split[4].replace("XP:","")) # Plockar ut XP delen av strängen
			var GainedXP = PlacedTowers[Towers[1]][1] + 0 # Kollar i PlacedTowers, där totala skadan för något torn sparas
			var TotalXP = PreviousXP + GainedXP # Totala XPn för tornet
			var PreviousLVL = int(split[1].replace("LVL:","")) # Föregående nivån
			
			var GainedLVL: int = 0 # Levels tjänade
			var OverflowXP: int = TotalXP # XP som är över efter levelup
			while check_level_up(OverflowXP, PreviousLVL + GainedLVL): # Så länge OverflowXP räcker för att levla upp
				
				OverflowXP -= calculate_required_EXP(PreviousLVL + GainedLVL, false) # Drar av XP som krävs för levelup från overflow
				GainedLVL += 1 # Ökar leveln med 1
			
			var RemainingXP = OverflowXP # XP som är över efter levelup är klar
			split[1] = "LVL:" + str(PreviousLVL + GainedLVL) # Byter ut LVL delen av Towerstringen
			split[4] = "XP:" + str(RemainingXP) # Byter ut XP delen av Towerstringen
			var NewTowerString = ",".join(split) # Bygger ihop den nya Towerstringen
			
			EquippedTowers[i] = [NewTowerString,Towers[1]] # Uppdaterar towerstringen i Equippedtowers
			GameFinishedMenu.fancy_display_xp(PreviousLVL, PreviousXP, GainedXP, Towers[0])
			PlayerEXP += TotalXP
			
			inventory_replace_tower(NewTowerString) # Uppdaterar tornet i spelarens inventory
	PlayerStats["EXP"] += round(PlayerEXP / 1000)
	level_up_player()
	update_save_file() # Sparar allting i save filen

func check_level_up(TotalXP, level): # Kollar ifall det finns nog med XP för att levla upp
	if TotalXP >= calculate_required_EXP(level, false):
		return true
	else:
		return false

func level_up_player():
	while PlayerStats["EXP"] >= calculate_required_EXP(PlayerStats["Level"], true):
		PlayerStats["EXP"] -= calculate_required_EXP(PlayerStats["Level"], true)
		PlayerStats["Level"] += 1
	
	update_save_file()

###################### PLAY FUNCTIONS #####################
func reset() -> void:
	current_wave = 0
	cash = 100000
	health = 100
	accumulated_reward = [0,0]
	PlacedTowers = {}
	if not Playing:
		for modifiers in SelectedModifiers:
			SelectedModifiers[modifiers][0] = false

func return_cost_factor(): # Räknar ut costfactor för torn beroende på modifiers
	var CostFactor: float = 0
	if Globals.SelectedModifiers["Expensive Towers"][0] == true:
			CostFactor += 0.5
	if Globals.SelectedModifiers["Economic Depression"][0] == true:
			CostFactor += 1
	return CostFactor

func _apply_enemy_multipliers(wave) -> void: # Applicerar fiendes multipliers
	current_health_factor = HEALTH_FACTOR ** (wave-1) * SelectedDifficultyModifiers[SelectedDifficulty]["EnemyHP"]
	current_speed_factor = SPEED_FACTOR ** (wave-1)
	
	current_health_factor = pow(HEALTH_FACTOR, wave - 1) * SelectedDifficultyModifiers[SelectedDifficulty]["EnemyHP"]
	current_speed_factor = pow(SPEED_FACTOR, wave - 1)

	for enemy in enemy_health:
		enemy_health[enemy] = round(enemy_base_health[enemy] * current_health_factor)
		enemy_speed[enemy] = enemy_base_speed[enemy] * current_speed_factor

func damage(damage_dealt, targeted_enemy, midas: bool) -> void:
	if damage_dealt >= targeted_enemy.current_health: # Om attacken besegrar fienden:
		targeted_enemy.get_parent().queue_free() # Ta bort fienden genom att ta bort dess förälder, PathFollow2D
		if midas:
			cash += targeted_enemy.kill_reward * 1.5
		else:
			cash += targeted_enemy.kill_reward
		# Lägger till värden i accumulated_reward[silver] och [guld] som sedan visas vid game over
		# Ser även till att anpassa kill reward så att den är proportionelig til fiendernas HP-ökning.
		accumulated_reward[0] += enemy_kill_reward[targeted_enemy.name][0] * current_health_factor * 0.1
		accumulated_reward[1] += enemy_kill_reward[targeted_enemy.name][1] * current_health_factor * 1
	else:
		# Om fienden inte besegras drar vi helt enkelt av skadan från fiendens HP
		targeted_enemy.current_health -= damage_dealt
