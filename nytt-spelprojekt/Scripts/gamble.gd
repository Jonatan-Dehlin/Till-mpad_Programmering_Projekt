extends Control


@onready var scroll: ScrollContainer = $Panel/ScrollContainer
@onready var chests
@onready var HboxConatiner: HBoxContainer = $Panel/ScrollContainer/HBoxContainer
@onready var ReferencePanel: Panel = $ReferencePanel
@onready var TraitChanceDisplay = get_parent().get_node("Traits").get_node("OddsTable").get_child(0).get_children()

signal GambleFinished

var weight = [["Blue",null],["Purple",null],["Pink",null],["Red",null],["Gold",null]]

var TowerOrTrait: bool = false

var SelectedTower

var TraitIconAtlasDictionary = Globals.TraitIconAtlasDictionary

var TraitBaseTexture: Texture = preload("res://#1 - Transparent Icons.png")
var TowerTextures = { # Förladdar texturerna till tornen
	"wizard_tower.tscn": preload("res://Assets/Towers/Towers bases/PNGs/Tower 05.png")
	
}

var TowersTier1 = ["wizard_tower.tscn"]
var TowersTier2 = ["wizard_tower.tscn"]
var TowersTier3 = ["wizard_tower.tscn"]
var TowersTier4 = ["wizard_tower.tscn"]
var TowersTier5 = ["wizard_tower.tscn"]

var TraitsTier1 = ["Rapid_I", "Strong_I", "Vision_I"]
var TraitsTier2 = ["Rapid_II", "Strong_II", "Vision_II"]
var TraitsTier3 = ["Rapid_III", "Strong_III", "Vision_III"]
var TraitsTier4 = ["Lightning", "Unbeatable", "Hawkeye", "Midas"]
var TraitsTier5 = ["Singularity"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var index
	TraitChanceDisplay = get_parent().get_node("Traits").get_node("OddsTable").get_child(0).get_children()
	for Chests in get_parent().get_node("Shop").get_child(0).get_child(0).get_children():
		_modify_drop_rates(int(Chests.name.replace("chest","")))
		index = 0
		for colors in Chests.get_child(1).get_children():
			colors.get_child(1).text = "%0.1f%%" % (float(weight[index][1]) / 10)
			index += 1
	_modify_drop_rates("Trait")
	index = 0
	for colors in TraitChanceDisplay:
		colors.get_child(1).text = "%0.1f%%" % (float(weight[index][1]) / 10)
		index += 1

func _add_panels(Trait: bool):
	print("Kom till add panel")
	for panels in range(200):
		var cumulative = []
		var total = 0
		
		for w in weight:
			total += w[1]
			cumulative.append(total)
		
		var NewPanel = ReferencePanel.duplicate(true)
		NewPanel.add_to_group("GamblePanel")
		var NewPanelColor: ColorRect = NewPanel.get_child(0)
		var NewPanelTexture: TextureRect = NewPanel.get_child(0).get_child(0).get_child(0)
		NewPanelTexture.texture = NewPanelTexture.texture.duplicate() #Ser till att Texturen är unik
		
		var NewPanelText: Label = NewPanel.get_child(0).get_child(0).get_child(1)
		var num = randi_range(1,total) 
		if Trait: # Om trait
			if num <= cumulative[0]:
				var ChosenTrait = TraitsTier1.pick_random()
				
				NewPanelColor.color = Color(0,0,1) #Blå
				NewPanelTexture.texture.region = TraitIconAtlasDictionary[ChosenTrait][0]
				NewPanelTexture.self_modulate = TraitIconAtlasDictionary[ChosenTrait][1]
				NewPanelText.text = ChosenTrait.replace("_"," ")
			
			elif num <= cumulative[1]:
				var ChosenTrait = TraitsTier2.pick_random()
				
				NewPanelColor.color = Color(0.6,0,1) #Lila
				NewPanelTexture.texture.region = TraitIconAtlasDictionary[ChosenTrait][0]
				NewPanelTexture.self_modulate = TraitIconAtlasDictionary[ChosenTrait][1]
				NewPanelText.text = ChosenTrait.replace("_"," ")
				
			elif num <= cumulative[2]:
				var ChosenTrait = TraitsTier3.pick_random()
				
				NewPanelColor.color = Color(1,0,1) #Rosa
				NewPanelTexture.texture.region = TraitIconAtlasDictionary[ChosenTrait][0]
				NewPanelTexture.self_modulate = TraitIconAtlasDictionary[ChosenTrait][1]
				NewPanelText.text = ChosenTrait.replace("_"," ")
				
			elif num <= cumulative[3]:
				var ChosenTrait = TraitsTier4.pick_random()
				
				NewPanelColor.color = Color(1,0,0) #Röd
				NewPanelTexture.texture.region = TraitIconAtlasDictionary[ChosenTrait][0]
				NewPanelTexture.self_modulate = TraitIconAtlasDictionary[ChosenTrait][1]
				NewPanelText.text = ChosenTrait.replace("_"," ")
				
			else:
				var ChosenTrait = TraitsTier5.pick_random()
				
				NewPanelColor.color = Color(1,0.843,0) #Guld
				NewPanelTexture.texture.region = TraitIconAtlasDictionary[ChosenTrait][0]
				NewPanelTexture.self_modulate = TraitIconAtlasDictionary[ChosenTrait][1]
				NewPanelText.text = ChosenTrait.replace("_"," ")
		
		else: # Om torn
			if num <= cumulative[0]:
				var ChosenTower = TowersTier1.pick_random()
				var texture = TowerTextures[ChosenTower]
				NewPanelColor.color = Color(0,0,1) #Blå
				NewPanelTexture.texture.atlas = texture
				NewPanelTexture.texture.region = Rect2(0,0,64,128)
				NewPanelText.text = ChosenTower.replace("_"," ").replace(".tscn","").capitalize()
			
			elif num <= cumulative[1]:
				var ChosenTower = TowersTier2.pick_random()
				var texture = TowerTextures[ChosenTower]
				NewPanelColor.color = Color(0.6,0,1) # Lila
				NewPanelTexture.texture.atlas = texture
				NewPanelTexture.texture.region = Rect2(0,0,64,128)
				NewPanelText.text = ChosenTower.replace("_"," ").replace(".tscn","").capitalize()
				
			elif num <= cumulative[2]:
				var ChosenTower = TowersTier3.pick_random()
				var texture = TowerTextures[ChosenTower]
				NewPanelColor.color = Color(1,0,1) #Rosa
				NewPanelTexture.texture.atlas = texture
				NewPanelTexture.texture.region = Rect2(0,0,64,128)
				NewPanelText.text = ChosenTower.replace("_"," ").replace(".tscn","").capitalize()
				
			elif num <= cumulative[3]:
				var ChosenTower = TowersTier4.pick_random()
				var texture = TowerTextures[ChosenTower]
				NewPanelColor.color = Color(1,0,0) # Röd
				NewPanelTexture.texture.atlas = texture
				NewPanelTexture.texture.region = Rect2(0,0,64,128)
				NewPanelText.text = ChosenTower.replace("_"," ").replace(".tscn","").capitalize()
				
			else:
				var ChosenTower = TowersTier5.pick_random()
				var texture = TowerTextures[ChosenTower]
				NewPanelColor.color = Color(1,0.843,0) #Guld
				NewPanelTexture.texture.atlas = texture
				NewPanelTexture.texture.region = Rect2(0,0,64,128)
				NewPanelText.text = ChosenTower.replace("_"," ").replace(".tscn","").capitalize()


		NewPanel.visible = true
		HboxConatiner.add_child(NewPanel)

func gamble(ChestID):
	ChestID = str(ChestID)
	
	_modify_drop_rates(ChestID)
	if ChestID == "Trait":
		_add_panels(true)
		print("Trait")
	else:
		_add_panels(false)
		print("Chest")

	scroll.get_h_scroll_bar().visible = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	var spin_duration = 8.0
	var start_speed = float(randi_range(150, 300))
	var elapsed_time = 0.0
	var speed = start_speed

	while speed > 0.01:
		var t = clamp(elapsed_time / spin_duration, 0.0, 1.0)

		# Hastigheten avtar mot noll för att scrollen ska kännas naturlig
		var Ease = 1.0 - (1.0 - t) * (1.0 - t)
		speed = lerp(start_speed, 0.0, Ease)

		# Uppdatera scroll med hänsyn till delta (Vi änvänder get_process_delta_time() för att vi inte har tillgång till vanliga delta)
		scroll.scroll_horizontal += speed
		await get_tree().create_timer(0).timeout
		elapsed_time += get_process_delta_time()
	
	await get_tree().create_timer(0.1).timeout
	if ChestID != "Trait":
		get_parent()._open_chest(ChestID, true)
	
	GambleFinished.emit()

func _modify_drop_rates(ChestID):
	ChestID = str(ChestID)
	
	if ChestID == "1":
		weight = [["Blue",500],["Purple",250],["Pink",200],["Red",40],["Gold",10]]
	elif ChestID == "2":
		weight = [["Blue",450],["Purple",250],["Pink",200],["Red",70],["Gold",30]]
	elif ChestID == "3":
		weight = [["Blue",400],["Purple",250],["Pink",200],["Red",100],["Gold",50]]
	elif ChestID == "4":
		weight = [["Blue",350],["Purple",250],["Pink",200],["Red",130],["Gold",70]]
	elif ChestID == "5":
		weight = [["Blue",300],["Purple",250],["Pink",200],["Red",180],["Gold",70]]
	elif ChestID == "6":
		weight = [["Blue",250],["Purple",250],["Pink",200],["Red",200],["Gold",100]]
	elif ChestID == "7":
		weight = [["Blue",200],["Purple",250],["Pink",200],["Red",250],["Gold",100]]
	elif ChestID == "8":
		weight = [["Blue",150],["Purple",200],["Pink",200],["Red",300],["Gold",150]]
	
	elif ChestID == "Trait": #För traits
		weight = [["Blue",250],["Purple",250],["Pink",200],["Red",200],["Gold",100]]

func _grant_gamble_reward():
	var centerpos = Vector2(960,425)  # Vector2, globalt
	for panel in get_tree().get_nodes_in_group("GamblePanel"):
		# Om panel ligger direkt under den globala positionen
		var global_rect = Rect2(panel.global_position, panel.size)
		if global_rect.has_point(centerpos):
			queue_free()
			print(panel.get_child(0).get_child(0).get_child(1).text.replace(" ","_"))
			return panel.get_child(0).get_child(0).get_child(1).text.replace(" ","_")
			
