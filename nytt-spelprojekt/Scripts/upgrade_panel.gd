extends Control

#Referenser till intressanta noder
@onready var UpgradeADisplayContainer: HBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathA/UpgradeADisplay
@onready var UpgradeBDisplayContainer: HBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathB/UpgradeBDisplay
@onready var UpgradeAButton: TextureButton = $Panel/VBoxContainer/UpgradePaths/PathA/PathAUpgradeButton
@onready var UpgradeBButton: TextureButton = $Panel/VBoxContainer/UpgradePaths/PathB/PathBUpgradeButton
@onready var UpgradeACost: Label = $Panel/VBoxContainer/UpgradePaths/PathA/PathAUpgradeButton/UpgradeACosts
@onready var UpgradeBCost: Label = $Panel/VBoxContainer/UpgradePaths/PathB/PathBUpgradeButton/UpgradeBCosts
@onready var PathB: VBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathB
@onready var PathA: VBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathA
@onready var PathAName: Label = $Panel/VBoxContainer/UpgradePaths/PathA/PathAUpgradeButton/PathAName
@onready var PathBName: Label = $Panel/VBoxContainer/UpgradePaths/PathB/PathBUpgradeButton/PathBName
@onready var StatValues: VBoxContainer = $Panel/TextureRect/TowerStats/StatValues
@onready var SellButton: Button = $Panel/VBoxContainer/HBoxContainer/SellTower
@onready var ChangeTargetingButton: Button = $Panel/VBoxContainer/HBoxContainer/ChangeTargeting

@onready var TraitIcon: TextureRect = $Panel/TowerName/HBoxContainer/TraitIcon
@onready var LevelLabel: Label = $Panel/TowerName/HBoxContainer/LevelLabel

var parent: Node2D #Referens till parent: tornet

var targeting_options = ["First","Last","Strongest","Weakest","Closest","Furthest","Random"]
var current_targeting_option = 0

var target_region = Rect2(545, 449, 14, 14)

var MaxAUpgrades = 5
var MaxBUpgrades = 5

var UpgradeA = 0
var UpgradeB = 0

#Upgraderingskostnader. Ställs in vid _ready() i tornkoden.
var UpgradeACosts = {1:0,2:0,3:0,4:0,5:0}
var UpgradeBCosts = {1:0,2:0,3:0,4:0,5:0}


func _ready() -> void:
	parent = get_parent().get_parent()
	$Panel/TowerName.text = parent.TowerName
	
	TraitIcon.texture = TraitIcon.texture.duplicate(true)
	TraitIcon.texture.region = Globals.TraitIconAtlasDictionary[parent.get_meta("Trait")][0]
	
	LevelLabel.text = "LVL: " + str(parent.get_meta("Level"))
	
	UpgradeACosts = parent.UpgradeAPrices
	UpgradeBCosts = parent.UpgradeBPrices
	
	#Ser till att alla texturer är unika
	for texture in $Panel/VBoxContainer/UpgradePaths/PathA/UpgradeADisplay.get_children():
		texture.texture = texture.texture.duplicate(true)
	for texture in $Panel/VBoxContainer/UpgradePaths/PathB/UpgradeBDisplay.get_children():
		texture.texture = texture.texture.duplicate(true)

func _process(_delta: float) -> void:
	#Om man inte har råd eller inte kan upgradera så stängs knapparna av
	if UpgradeA == MaxAUpgrades or UpgradeACosts[UpgradeA+1] > Globals.cash:
		UpgradeAButton.disabled = true
	else:
		UpgradeAButton.disabled = false
	if UpgradeB == MaxBUpgrades or UpgradeBCosts[UpgradeB+1] > Globals.cash:
		UpgradeBButton.disabled = true
	else:
		UpgradeBButton.disabled = false
	_display_upgrade_pricing()
	_display_active_stats()
	_display_sell_value()

func _unhandled_input(event: InputEvent) -> void: #Stänger panelen ifall man klickar utanför den
	if visible and Input.is_action_just_pressed("Left_click"):
		# Kolla om musen inte är över UpgradePanel
		if not get_global_rect().has_point(event.position) and not parent.hovering_over_tower:
			visible = false
			parent.hovering_over_tower = false
			parent._on_mouse_hover_detector_mouse_exited()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and visible == true:
		match event.keycode:
			KEY_BACKSPACE: # Sälj torn
				_on_sell_tower_pressed()
			KEY_TAB: # ändra targeting
				_on_change_targeting_pressed()
			KEY_W: # Uppgraderingsväg A
				_on_path_a_upgrade_button_pressed()
			KEY_E: # Uppgraderingsväg B
				_on_path_b_upgrade_button_pressed()

func _display_sell_value(): #Visar tornets sell-värde
	SellButton.text = "Sell: $" + str(parent.sell_value)

func _display_active_stats():
	for stats in parent.stats:
		if StatValues.has_node(stats):
			StatValues.get_node(stats).text = str(Globals.format_number(parent.stats[stats]))

func _display_upgrade_pricing():
	#Ritar ut kostnaden för uppgraderingsväg A
	if UpgradeA == MaxAUpgrades:
		if MaxAUpgrades == 2:
			UpgradeACost.text = "Path capped"
		elif MaxAUpgrades == 5:
			UpgradeACost.text = "MAX"
	else:
		UpgradeACost.text = "$" + str(UpgradeACosts[UpgradeA+1])
		PathAName.text = parent.UpgradesA[UpgradeA+1]["name"]
	
	#Ritar ut kostnaden för uppgraderingsväg B
	if UpgradeB == MaxBUpgrades:
		if MaxBUpgrades == 2:
			UpgradeBCost.text = "Path capped"
		elif MaxBUpgrades == 5:
			UpgradeBCost.text = "MAX"
	else:
		UpgradeBCost.text = "$" + str(UpgradeBCosts[UpgradeB+1])
		PathBName.text = parent.UpgradesB[UpgradeB+1]["name"]

func _upgrade(AorB):
	var Upgrade
	if AorB == "A":
		Upgrade = parent.UpgradesA[UpgradeA]
		
		parent.UpgradeA += 1
	else:
		Upgrade = parent.UpgradesB[UpgradeB]
		parent.UpgradeB += 1
	for upgrades in Upgrade:
		if upgrades != "name":
			parent.stats[upgrades] += Upgrade[upgrades]
	if AorB == "A":
		parent._update_stats("A")
	else:
		parent._update_stats("B")

func _update_sell_prices(upgrade_cost):
	parent.total_cash_spent += upgrade_cost
	parent.sell_value = floor(parent.total_cash_spent * 0.7)

func _on_path_b_upgrade_button_pressed() -> void:
	if UpgradeB < MaxBUpgrades and UpgradeBCosts[UpgradeB+1] <= Globals.cash:
		
		UpgradeBDisplayContainer.get_child(UpgradeB).texture.region = target_region
		UpgradeBDisplayContainer.get_child(UpgradeB).modulate = Color(0,1,0)
		
		UpgradeB += 1
		if UpgradeB == 3:
			MaxAUpgrades = 2

		Globals.cash -= UpgradeBCosts[UpgradeB] 

		_upgrade("B")
		_update_sell_prices(UpgradeBCosts[UpgradeB])

func _on_path_a_upgrade_button_pressed() -> void:
	if UpgradeA < MaxAUpgrades and UpgradeACosts[UpgradeA+1] <= Globals.cash:

		var child = UpgradeADisplayContainer.get_child(UpgradeA)
		
		child.texture = child.texture.duplicate()
		child.texture.region = target_region
		child.modulate = Color(0, 1, 0)
		
		UpgradeA += 1
		if UpgradeA == 3:
			MaxBUpgrades = 2
			
		Globals.cash -= UpgradeACosts[UpgradeA] 
		
		_upgrade("A")
		_update_sell_prices(UpgradeACosts[UpgradeA])

func _on_close_menu_button_pressed() -> void:
	visible = false
	parent.TowerOutline.visible = false
	parent.hovering_over_tower = false

func _on_sell_tower_pressed() -> void:
	Globals.cash += parent.sell_value
	parent.queue_free()

func _on_change_targeting_pressed() -> void:
	if current_targeting_option < len(targeting_options)-1:
		current_targeting_option += 1
	else:
		current_targeting_option = 0
	ChangeTargetingButton.text = str(targeting_options[current_targeting_option])
	parent.targeting = str(targeting_options[current_targeting_option])
