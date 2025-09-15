extends Node2D

func _ready() -> void:
	pass

func _on_line_edit_text_submitted(new_text: String) -> void:
	if FileAccess.file_exists("res://Scenes/Levels/"+new_text+".tscn"):
		var scen = load("res://Scenes/Levels/"+new_text+".tscn")
		var instance = scen.instantiate()
		add_child(instance)
	else:
		print("Did not find level.")
