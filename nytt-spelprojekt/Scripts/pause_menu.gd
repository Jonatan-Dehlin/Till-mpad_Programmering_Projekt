extends Control

var main = load("res://Scenes/main.tscn")

func _ready() -> void:
	Globals.connect_UI_sounds()
	for panels in get_tree().get_nodes_in_group("UpgradePanel"):
		panels.visible = false

func _process(_delta) -> void:
	await get_tree().create_timer(0.05).timeout
	if Input.is_action_just_pressed("Esc"):
		_on_resume_button_pressed()

################# SIGNALS ########################
func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(main)
	Globals.Playing = false
	Globals.reset()

func _on_replay_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Globals.reset()
