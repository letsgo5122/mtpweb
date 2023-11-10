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
var Users = {} #connected websocket
var User_Info = {}
var Players = [] #join room players
var Rooms = {}
var rndRoom = "23456789abcdefghjkmnprstuvwxyz"

var rtcPeer = WebRTCMultiplayerPeer.new()

@onready var args = Array(OS.get_cmdline_args())
func _ready():
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
	$"../ConnectHost".visible = false
	
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
			
		# Connecting user received self id from host
		if dataPack.msg == Msg.ID:
			if dataPack.id ==1:
				return
			if ! dataPack.has("roomNum"):
				User_Info["id"] = dataPack.id
				#For webrtc 
				rtc_CreateMesh(User_Info["id"])
			#If user joined room
			else :
				hostId = dataPack.hostId
				User_Info["hostId"] = hostId
				User_Info["roomNum"] = dataPack.roomNum
				
			print("Msg.ID User_info: ",User_Info," hostId:",hostId)
			$"../Msg".add_text("Msg."+ Msg.keys()[Msg.ID]+" "+str(dataPack.id))
			
		# Form wsServer send back ROOM_NUM to Creator ,display on host's app 
		if dataPack.msg == Msg.ROOM_NUM:
			if dataPack.has("roomNum") and User_Info.id != 1:
				$"../RoomNum".text = dataPack.roomNum
				hostId = dataPack.hostId
				User_Info["hostId"] = hostId
				User_Info["roomNum"] = dataPack.roomNum
			print("Msg.ROOM_NUM User_info: ",User_Info," hostId:",hostId)
	
		
		if dataPack.msg == Msg.MATCH:
			if User_Info.id != 1 :
				Players = dataPack.players
				print("Msg.MATCH Players ",dataPack.id," myId: ",User_Info.id)
				create_Rtc_Peer(dataPack.id)
			
		if dataPack.msg == Msg.CANDIDATE:
			if rtcPeer.has_peer(dataPack.orgPeer):
				print("Got Candididate: " + str(dataPack.orgPeer) + " my id is " + str(User_Info.id))
				rtcPeer.get_peer(dataPack.orgPeer).connection.add_ice_candidate(dataPack.mid, dataPack.index, dataPack.sdp)
			
		if dataPack.msg == Msg.OFFER:
			if rtcPeer.has_peer(dataPack.orgPeer):
				rtcPeer.get_peer(dataPack.orgPeer).connection.set_remote_description("offer", dataPack.data)
		
		if dataPack.msg == Msg.ANSWER:
			if rtcPeer.has_peer(dataPack.orgPeer):
				rtcPeer.get_peer(dataPack.orgPeer).connection.set_remote_description("answer", dataPack.data)
			
		if dataPack.msg == Msg.TEST:
			print("------------------Test Message: ",dataPack)
			
func create_Rtc_Peer(id):
	print("create_Rtc_Peer:",id,"  My ID :" ,User_Info.id)
	var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	print("binding id:" + str(id) + "   my id:" + str(User_Info.id))
	peer.session_description_created.connect(self.offerCreated.bind(id))
	peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
	rtcPeer.add_peer(peer, id)
	print("hostId: ",hostId)
	if id > rtcPeer.get_unique_id():
		peer.create_offer()
	return peer
	
func offerCreated(type, data, id):
	print("offerCreated: ", " type:",type, " data:"+data," id:", id)
	if !rtcPeer.has_peer(id):
		return
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)

func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.OFFER,
		"data": data,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.ANSWER,
		"data": data,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	
func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : User_Info.id,
		"msg" : Msg.CANDIDATE,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"room": User_Info["roomNum"]
	}
	wsPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func rtc_CreateMesh(id):
	print(id," CreateMesh")
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer
	
func generate_room_number():
	var num = ""
	for i in range(5):
		var index = randi() % rndRoom.length()
		num += rndRoom[index]
	return num

#Server send back to connected user id 
func _on_ws_connected(id):
	#print("connected id:",id)
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
	$"..".visible = false
	for i in Players:
		var p_hero = load("res://Mtprtc/p_hero.tscn")
		var hero = p_hero.instantiate()
		hero.name = str(i)
		add_child(hero)
		var rnd_x = randi_range(10,20)
		hero.global_position = Vector2(500+rnd_x,200)
		

