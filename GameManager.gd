extends Node

var Players = []
var P2P = true : set = P2P_mode

var tween
# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	

func P2P_mode(val):
	P2P = val
	
func RTCPeerDisconnected(id):
	print("GameManager client :RTCPeerDisconnected ",id)
	for pl in Players:
		if pl == id:
			#print("I Can't not erase id,so erase pl instead ",pl)
			Players.erase(pl)
			#print("client:RTCPeerDisconnected"," Players",Players," Im ",User_Info.id)
			if $"/root/Game".has_node(str(pl)):
				var pl_leave = $"/root/Game".get_node(str(pl))
				tween = get_tree().create_tween()
				var pl_color = pl_leave.get_node("Mesh").get("surface_material_override/0").albedo_color
				#tween.tween_property(pl_leave, "pl_color", Color.DEEP_PINK, 1)
				tween.tween_property(pl_leave, "scale", Vector3(), 1)
				tween.tween_callback(pl_leave.queue_free)
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
