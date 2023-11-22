extends StaticBody3D

signal selected_bowl
var click_enable = true
# Called when the node enters the scene tree for the first time.
func _ready():
	if has_node("../ring"):
		$"../ring".visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_input_event(camera, event, position, normal, shape_idx):
	if click_enable:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				#print(get_parent().name)
				#selected_bowl.emit(get_parent())
				rpc_send_signal.rpc()
				
@rpc("any_peer","call_local","reliable")
func rpc_send_signal():
	selected_bowl.emit(get_parent())

func _on_mouse_entered():
	if click_enable:
		if has_node("../ring"):
			$"../ring".visible = true
		
	pass # Replace with function body.

func _on_mouse_exited():
#	if has_node("../ring"):
#		$"../ring".visible = false
	pass # Replace with function body.
