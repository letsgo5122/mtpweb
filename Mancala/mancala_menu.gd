extends Control

#func _ready():
#	pass # Replace with function body.
#func _process(delta):
#	pass
func _on_p_2p_pressed():
	GameManager.P2P_mode(true)
	get_tree().change_scene_to_file("res://Mtprtc/Net.tscn")
	pass # Replace with function body.

func _on_p_2_robot_pressed():
	GameManager.P2P_mode(false)
	GameManager.Players = ["1", "2"]
	get_tree().change_scene_to_file("res://Mancala/game.tscn")
	pass # Replace with function body.
	
