extends Node

#Server port
var Server_Port = 5122
#For Client 
var Godot_Debug = "ws://" + "127.0.0.1:5122"
var Docker_server = "ws://" + "127.0.0.1/gd/"
var Svr_addr = Godot_Debug
enum Msg{
		ID,
		NEW_ROOM,
		ROOM_NUM,
		JOIN,
		MATCH,
		ANSWER,
		OFFER,
		CANDIDATE,
		TEST
	}
var wsPeer := WebSocketMultiplayerPeer.new()
var buffer =""
var hostId = 0
var Peers = [] #connected websocket
var User_Info = {}
var Players = [] #join room players
var Rooms = {}
var rndRoom = "abc23def45stghjkuv67mnp89rwxyz"
var rtcPeer = WebRTCMultiplayerPeer.new()

@onready var args = Array(OS.get_cmdline_args())
func _ready():
	
	if args.has("-s"):
		print("starting server...\n")
		ServerStart()
	if OS.get_name() == "Web":
		$"../Host".visible = false
	wsPeer.connect("peer_connected",_on_ws_connected)
	wsPeer.connect("peer_disconnected",_on_ws_disconnected)
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
func RTCServerConnected():
	print("RTC server connected")
func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	#wsPeer.close()
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))
	
func ServerStart():
	_on_host_pressed()
	
func _on_host_pressed():
	$"../Host".visible = false
	var err = wsPeer.create_server(Server_Port)
	if err == OK:
		User_Info = {"id":wsPeer.get_unique_id(),"name":"WsSvr"}
		$"../RoomNum".text = "id:" + str(User_Info.id)+"\n"
	if OS.get_name() ==  "Windows":
		var lan_ip
		for n in range(0, IP.get_local_interfaces().size()):
			if IP.get_local_interfaces()[n].friendly == "Wi-Fi":
				lan_ip = JSON.stringify(IP.get_local_interfaces()[n]).split("\"")
	#			for i in range(0,lan_ip.size()):
	#				print(lan_ip[5])
		$"../RoomNum".text += str(lan_ip[5])
	#Users[User_Info.id]=User_Info
	#print("state", Peer.get_connection_status())
	
func _on_connect_host_button_down():
	$"../Host".visible = false
	$MenuBg/ConnectHost.visible = false
	
	var err = wsPeer.create_client(Svr_addr)
	#$MenuBg/Ip.text = str(userId)
	User_Info = {"name":$"../Name".text}
	#$MenuBg/Msg.add_text(str(userId))
	$"../Msg".add_text($"../Name".text+" Connect Host!")
	$"../Msg".newline()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	wsPeer.poll()
	buffer = []
	while wsPeer.get_available_packet_count():
		buffer = wsPeer.get_packet().get_string_from_utf8()
		var dataPack = JSON.parse_string(buffer)
			
			
		# Host Side  Host Side  Host Side  Host Side  Host Side  Host Side  Host Side 
		# Host Side  Host Side  Host Side  Host Side  Host Side  Host Side  Host Side 
		if dataPack.msg == Msg.NEW_ROOM:
			var new_hostId = dataPack.id
			var Players = []
			Players.append(new_hostId)
			var roomNum  = generate_room_number()
			Rooms[roomNum] = {
				"hostId" : new_hostId,
				"players" : Players
				}
			$"../RoomNum".text = roomNum
			print("Rooms:",Rooms)
			var data = {
				"id" : new_hostId,
				"msg" : Msg.ROOM_NUM,
				"roomNum" : roomNum,
				"hostId" : Rooms[roomNum]["hostId"],
				"players" : Players
			}
			#send New room num back to creater
			Send_One(data)
		
		if dataPack.msg == Msg.JOIN:
			var roomNum = dataPack.roomNum
			if Rooms.has(roomNum):#Check Svr Rooms
				Rooms[roomNum]["players"].append(dataPack.id)
				#Players.append(dataPack.id)
				print("Rooms:",Rooms)
			#Send Info back to join user 
			var data = {
				"id": dataPack.id,
				"msg" : Msg.ID,
				"roomNum" : roomNum,
				"hostId" : Rooms[roomNum]["hostId"],
				"players" : Rooms[roomNum]["players"]
			}
			Send_One(data)
			
			if Rooms[roomNum]["players"].size() >= 2:
				for pl_id in Rooms[roomNum]["players"]:
					var data_1 = {
						"id": dataPack.id,
						"msg" : Msg.MATCH,
						"players" : Rooms[roomNum]["players"]
					}
					#Send back to joiner
					wsPeer.get_peer(pl_id).put_packet(JSON.stringify(data_1).to_utf8_buffer())

					var data_2 = {
						"id": pl_id,
						"msg" : Msg.MATCH,
						"players" : Rooms[roomNum]["players"]
					}
					wsPeer.get_peer(dataPack.id).put_packet(JSON.stringify(data_2).to_utf8_buffer())
		#---------------------------------------------------------------------------------------------
		if dataPack.msg == Msg.OFFER || dataPack.msg == Msg.ANSWER || dataPack.msg == Msg.CANDIDATE:
			if User_Info.id == 1:
				wsPeer.get_peer(dataPack.peer).put_packet(JSON.stringify(dataPack).to_utf8_buffer())
				
		if dataPack.msg == Msg.TEST:
			print("------------------Test Message: ",dataPack)
			
	
func generate_room_number():
	var num = ""
	for i in range(5):
		var index = randi() % rndRoom.length()
		num += rndRoom[index]
	return num

#Server send back to connected user id 
func _on_ws_connected(id):
	Peers.append(id)
	
	var Data = {
		"id":id,
		"msg":Msg.ID
		}
	Send_One(Data)
	#Send back to connected user id  

func Send_All(data):
	wsPeer.put_packet(JSON.stringify(data).to_utf8_buffer())
	
func Send_One(data):
	wsPeer.get_peer(data.id).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func sendHost(data):
	wsPeer.get_peer(1).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func _on_ws_disconnected(id):
	pass


func _on_room_button_down():
	$"../Room".visible = false
	$"../Join Room".visible = false
	var data = {
		"msg" : Msg.NEW_ROOM,
		"id" : User_Info.id
	}
	sendHost(data)
	
func _on_join_room_button_down():
	if $"../RoomNum".text=="":
		return
	$"../Join Room".visible = false
	if User_Info.has("id"):
		var data = {
			"id" : User_Info.id,
			"msg" : Msg.JOIN,
			"roomNum" : $"../RoomNum".text
		}
		$"../Msg".add_text(str(User_Info.id))
		$"../Msg".newline()
		sendHost(data)


func _on_start_game_button_down():
	Game.rpc()
@rpc("any_peer", "call_local")
func Game():
	$MenuBg.visible = false
	for i in Players:
		var p_hero = load("res://Mtprtc/p_hero.tscn")
		var hero = p_hero.instantiate()
		hero.name = str(i)
		add_child(hero)
		var rnd_x = randi_range(10,20)
		hero.global_position = Vector2(500+rnd_x,200)
		
