extends Control


@onready var scroll: ScrollContainer = $Panel/ScrollContainer
@onready var chests
@onready var HboxConatiner: HBoxContainer = $Panel/ScrollContainer/HBoxContainer
@onready var ReferencePanel: Panel = $ReferencePanel

var weight = [["Blue",null],["Purple",null],["Pink",null],["Red",null],["Gold",null]]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for Chests in get_parent().get_node("Shop").get_child(0).get_child(0).get_children():
		_modify_drop_rates(int(Chests.name.replace("chest","")))
		var index = 0
		for colors in Chests.get_child(1).get_children():
			colors.get_child(1).text = "%0.1f%%" % (float(weight[index][1]) / 10)
			index += 1
			
func _add_panels():
	for panels in range(200):
		var cumulative = []
		var total = 0
		
		for w in weight:
			total += w[1]
			cumulative.append(total)
		
		var NewPanel = ReferencePanel.duplicate()
		var num = randi_range(1,total) 
		
		if num <= cumulative[0]:
			NewPanel.get_child(0).color = Color(0,0,1)
		elif num <= cumulative[1]:
			NewPanel.get_child(0).color = Color(0.6,0,1)
		elif num <= cumulative[2]:
			NewPanel.get_child(0).color = Color(1,0,1)
		elif num <= cumulative[3]:
			NewPanel.get_child(0).color = Color(1,0,0)
		else:
			NewPanel.get_child(0).color = Color(1,0.843,0)


		NewPanel.visible = true
		HboxConatiner.add_child(NewPanel)

func gamble(ChestID):
	_modify_drop_rates(ChestID)
	_add_panels()

	scroll.get_h_scroll_bar().visible = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	var spin_duration = 8.0
	var start_speed = float(randi_range(150, 300))
	var elapsed_time = 0.0
	var speed = start_speed

	while speed > 0.01:
		var t = clamp(elapsed_time / spin_duration, 0.0, 1.0)

		# Ease-out quad: hastigheten avtar mjukt mot noll
		var Ease = 1.0 - (1.0 - t) * (1.0 - t)
		speed = lerp(start_speed, 0.0, Ease)

		# Uppdatera scroll med delta-time
		scroll.scroll_horizontal += speed
		await get_tree().create_timer(0).timeout
		elapsed_time += get_process_delta_time()
	
	await get_tree().create_timer(2).timeout
	get_parent()._open_chest(ChestID, true)
	_grant_gamble_reward()

func _modify_drop_rates(ChestID):
	if ChestID == 1:
		weight = [["Blue",500],["Purple",250],["Pink",200],["Red",40],["Gold",10]]
	elif ChestID == 2:
		weight = [["Blue",450],["Purple",250],["Pink",200],["Red",70],["Gold",30]]
	elif ChestID == 3:
		weight = [["Blue",400],["Purple",250],["Pink",200],["Red",100],["Gold",50]]
	elif ChestID == 4:
		weight = [["Blue",350],["Purple",250],["Pink",200],["Red",130],["Gold",70]]
	elif ChestID == 5:
		weight = [["Blue",300],["Purple",250],["Pink",200],["Red",180],["Gold",70]]
	elif ChestID == 6:
		weight = [["Blue",250],["Purple",250],["Pink",200],["Red",200],["Gold",100]]
	elif ChestID == 7:
		weight = [["Blue",200],["Purple",250],["Pink",200],["Red",250],["Gold",100]]
	elif ChestID == 8:
		weight = [["Blue",150],["Purple",200],["Pink",200],["Red",300],["Gold",150]]

func _grant_gamble_reward():
	var centerpos = Vector2(960,425)  # Vector2, globalt
	for panel in get_tree().get_nodes_in_group("GamblePanel"):
		# Om panel ligger direkt under den globala positionen
		var global_rect = Rect2(panel.global_position, panel.size)
		if global_rect.has_point(centerpos):
			print("Panel under punkten:", panel.name)
			print("Du fick en:",panel.get_child(0).color)
			break
	queue_free()
