extends Control

#Referenser till intressanta noder
@onready var UpgradeADisplayContainer: HBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathA/UpgradeADisplay
@onready var UpgradeBDisplayContainer: HBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathB/UpgradeBDisplay
@onready var UpgradeAButton: Button = $Panel/VBoxContainer/UpgradePaths/PathA/PathAUpgradeButton
@onready var UpgradeBButton: Button = $Panel/VBoxContainer/UpgradePaths/PathB/PathBUpgradeButton
@onready var PathB: VBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathB
@onready var PathA: VBoxContainer = $Panel/VBoxContainer/UpgradePaths/PathA
@onready var StatValues: VBoxContainer = $Panel/VBoxContainer/TowerStats/StatValues
@onready var SellButton: Button = $Panel/VBoxContainer/HBoxContainer/SellTower
@onready var ChangeTargetingButton: Button = $Panel/VBoxContainer/HBoxContainer/ChangeTargeting

var parent: Node2D #Referens till parent: tornet

var targeting_options = ["First","Last","Strongest","Weakest","Closest","Furthest"]
var current_targeting_option = 0

var MaxAUpgrades = 5
var MaxBUpgrades = 5

var UpgradeA = 0
var UpgradeB = 0

#Upgraderingskostnader. Ställs in vid _ready() i tornkoden.
var UpgradeACosts = {1:0,2:0,3:0,4:0,5:0}
var UpgradeBCosts = {1:0,2:0,3:0,4:0,5:0}


func _ready() -> void:
	parent = get_parent()
	$Panel/VBoxContainer/HBoxContainer2/TowerName.text = parent.TowerName
	
	UpgradeACosts = parent.UpgradeAPrices
	UpgradeBCosts = parent.UpgradeBPrices

func _process(delta: float) -> void:
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

func _unhandled_input(event: InputEvent) -> void:
	if visible and Input.is_action_just_pressed("Left_click"):
		# Kolla om musen inte är över UpgradePanel
		if not get_global_rect().has_point(event.position) and not parent.hovering_over_tower:
			visible = false
			parent.hovering_over_tower = false
			parent._on_mouse_hover_detector_mouse_exited()

func _display_sell_value():
	SellButton.text = "Sell: $" + str(parent.sell_value)

func _display_active_stats():
	for stats in parent.stats:
		if StatValues.has_node(stats):
			StatValues.get_node(stats).text = str(parent.stats[stats])

func _display_upgrade_pricing():
	#Ritar ut kostnaden för uppgraderingsväg A
	if UpgradeA == MaxAUpgrades:
		if MaxAUpgrades == 2:
			UpgradeAButton.text = "Path capped"
		elif MaxAUpgrades == 5:
			UpgradeAButton.text = "MAX"
	else:
		UpgradeAButton.text = "$" + str(UpgradeACosts[UpgradeA+1])
	
	#Ritar ut kostnaden för uppgraderingsväg B
	if UpgradeB == MaxBUpgrades:
		if MaxBUpgrades == 2:
			UpgradeBButton.text = "Path capped"
		elif MaxBUpgrades == 5:
			UpgradeBButton.text = "MAX"
	else:
		UpgradeBButton.text = "$" + str(UpgradeBCosts[UpgradeB+1])

func _upgrade(AorB):
	var Upgrade
	if AorB == "A":
		Upgrade = parent.UpgradesA[UpgradeA]
	else:
		Upgrade = parent.UpgradesB[UpgradeB]
	for upgrades in Upgrade:
			parent.stats[upgrades] += Upgrade[upgrades]
	parent._update_stats()

func _update_sell_prices(upgrade_cost):
	parent.total_cash_spent += upgrade_cost
	parent.sell_value = floor(parent.total_cash_spent * 0.7)

func _on_path_b_upgrade_button_pressed() -> void:
	if UpgradeB < MaxBUpgrades and UpgradeBCosts[UpgradeB+1] <= Globals.cash:
		UpgradeBDisplayContainer.get_child(UpgradeB).modulate = Color(1,1,1)
		UpgradeB += 1
		if UpgradeB == 3:
			MaxAUpgrades = 2

		Globals.cash -= UpgradeBCosts[UpgradeB] 

		_upgrade("B")
		_update_sell_prices(UpgradeBCosts[UpgradeB])

func _on_path_a_upgrade_button_pressed() -> void:
	if UpgradeA < MaxAUpgrades and UpgradeACosts[UpgradeA+1] <= Globals.cash:
		
		UpgradeADisplayContainer.get_child(UpgradeA).modulate = Color(1,1,1)
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
