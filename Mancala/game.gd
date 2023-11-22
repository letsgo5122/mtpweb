extends Node3D

var P2P
var limit_time_en = false#true Timer = start, false = No Timer
@onready var limit_sec = int($"GameMenu/bg/VB/LimitTimeSec".text)
@onready var diamond_org = preload("res://Mancala/Diamond.tscn")
var bowl_array = ["B1","B2","B3","B4","B5","B6","Depot_b","R6","R5","R4","R3","R2","R1","Depot_r"]
var tween
var Current_player:String
@onready var Player_Color = {"Blue":str(GameManager.Players[0]), "Red":str(GameManager.Players[1])}
var move_again = false
var GameOn = false
var Col = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW, Color.BROWN, Color.LIGHT_PINK]
var hero#puppet
var Me
var Robot
var first_player 

func _ready():
	P2P = GameManager.P2P
	if P2P:
		Me = str(multiplayer.get_unique_id())
	else:
		Me = "1"
		Robot = "2"
		Player_Color = {"Blue":"1", "Red":"2"}
	randomize()
	$GameMenu.visible = true
	$GameMenu.play.connect(Play)
	$GameMenu.quit_game.connect(Quit_Game)
	$GameMenu.gameMenuSetting.connect(gameMenu)
	for sel in range(0, $Board.get_child_count()):
		var sel_name = $Board.get_child(sel)
		if (sel_name.name != "Depot_b") and (sel_name.name != "Depot_r"):
			var sel_node = "Board/" + sel_name.name + "/bowl"
			#print(get_node(sel_node))
			get_node(sel_node).selected_bowl.connect(Move_Diamond)
	
	$Score_board/RestOfTime.text = str(limit_sec)
	#Default Current_player
	Current_player = Player_Color["Blue"]
	
func gameMenu(CkBt, limitTime, firstPlayer):
	Current_player = Player_Color[firstPlayer]
	#default is false
	limit_time_en = CkBt
	#limitTime default 20 seconds
	limit_sec = limitTime if limit_time_en else 0
	$Score_board/RestOfTime.text = str(limit_sec)
	print("gameMenu Current_player ",Current_player," limit_time_en",limit_time_en," limit_sec",limit_sec)

#game_menu play button
func Play():
	#$GameMenu.gameMenuSetting include parameters(Current_player,limit_time_en,limit_sec)
	Start_Game.rpc(Current_player,limit_time_en,limit_sec)
	
@rpc("any_peer","call_local")
func Start_Game(Current_player,limit_time_en,limit_sec):
	$GameMenu.visible = false
	print("Start_Game :" ,Current_player,"  limit_time_en: ",limit_time_en,"  limit_sec: ",limit_sec)
	GameOn = true
	One_Sec_timer()
	Puppet()
	#Clean all diamonds
	if $Diamonds.get_child_count() > 0:
		for d in $Diamonds.get_children():
			d.queue_free()
	prepare_Diamond("B", 6, 4)
	prepare_Diamond("R", 6, 4)
	get_node(Current_player).get_node("Anim").play("Idle")
	UpdateScore.rpc()
	bowl_click_enable(true,Current_player)
	#Start game with Robot first
	if !P2P and Current_player=="2":
		Move_Diamond($Board.get_node("R4"))
	
func bowl_click_enable(en,cur_player):
	if  P2P:#Player vs Player
		if cur_player==Player_Color["Blue"]:
			if cur_player == Me:# Blue
				for a in range(0, 6):
					$Board.get_child(a).get_node("bowl").click_enable = en
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = true
						$Board.get_child(a).get_node("Anim").play("flash")
				for a in range(7, 13):
					$Board.get_child(a).get_node("bowl").click_enable = false #Always disable
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = false
			else:
				for a in range(0, 13):
					$Board.get_child(a).get_node("bowl").click_enable = false #Always disable
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = false
						
		elif cur_player==Player_Color["Red"]:
			if cur_player == Me:# Red
				for a in range(0, 6):
					$Board.get_child(a).get_node("bowl").click_enable = false
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = false
				for a in range(7, 13):
					$Board.get_child(a).get_node("bowl").click_enable = en 
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = true
						$Board.get_child(a).get_node("Anim").play("flash")
			else:
				for a in range(0, 13):
					$Board.get_child(a).get_node("bowl").click_enable = false #Always disable
					if $Board.get_child(a).has_node("ring"):
						$Board.get_child(a).get_node("ring").visible = false

	else:#P2P = false ;7Player vs Robot
		if cur_player == Me:# Blue
			for a in range(0, 6):
				$Board.get_child(a).get_node("bowl").click_enable = en
				if $Board.get_child(a).has_node("ring"):
					$Board.get_child(a).get_node("ring").visible = true
					$Board.get_child(a).get_node("Anim").play("flash")
			for a in range(7, 13):
				$Board.get_child(a).get_node("bowl").click_enable = false #Always disable
				if $Board.get_child(a).has_node("ring"):
					$Board.get_child(a).get_node("ring").visible = false
		if cur_player == Robot:
			for a in range(0, 6):
				$Board.get_child(a).get_node("bowl").click_enable = false #Always disable
		


@rpc("any_peer","call_local","reliable")
func Move_Diamond(bowl):
	if !GameOn:
		return
	$OneSec.stop()
	bowl_click_enable(false,Current_player) #Avoid double click 
	var num_diamond = 0
	var bowl_index = bowl_array.find(bowl.name)
	for a in range(0, $Diamonds.get_child_count()):
		if $Diamonds.get_child(a).bowl_tag == bowl.name:
			num_diamond += 1
			bowl_index += 1
			if bowl_index >= bowl_array.size():
				bowl_index = 0
			if Current_player == Player_Color["Blue"] and bowl_array[bowl_index]=="Depot_r":
				#Depot_b is the end of bowl_array'element,
				bowl_index = 0
			elif Current_player == Player_Color["Red"] and bowl_array[bowl_index]=="Depot_b":
				#Depot_b is the bowl_array[6],so +1 = "R6"
				bowl_index += 1
			#$Acrons.get_child(a).position = $Mancala.get_node(bowl_array[bowl_index]).position + Rnd_pos()
			$Diamonds.get_child(a).bowl_tag = bowl_array[bowl_index]
			Pos_parabola($Diamonds.get_child(a), $Board.get_node(bowl_array[bowl_index]).position + Rnd_pos())
			
			await tween.finished
		UpdateScore()#UpdateScore each acron moving
	if num_diamond == 0:#Check if player select a empty bowl,num_dismond will be 0
		bowl_click_enable(true,Current_player)
		return
	#Get last acron to check status 
	Check_Last_Bowl(bowl_array[bowl_index])
	Check_Side_Empty()
	UpdateScore()#After update score ,check GameOn = false will show Winner message
	Change_Player()
	
func Check_Side_Empty():
	#Check if any player's all bowls are empty
	var B_array = []
	var R_array = []
	for d in $Diamonds.get_children():
		var diamond = d.bowl_tag.split("",true,1)
		if diamond[0]=="B":
			B_array.append(d)
		if diamond[0]=="R":
			R_array.append(d)
	if B_array.size()==0 or R_array.size()==0:
		if B_array.size()==0:
			for r in R_array:
				r.bowl_tag = "Depot_r"
				Pos_parabola(r, $Board.get_node("Depot_r").position + Rnd_pos())
		elif R_array.size()==0:
			for b in B_array:
				b.bowl_tag = "Depot_b"
				Pos_parabola(b, $Board.get_node("Depot_b").position + Rnd_pos())
		Stop_Game()
		GameOn = false


func Check_Last_Bowl(tag):
	move_again = false
	var count = 0
	for d in $Diamonds.get_children():
		if d.bowl_tag == tag:
			count += 1
	
	if count == 1 and tag != "Depot_b" and tag!="Depot_r" :
		var tag_arr = tag.split("",true,1)
		#print("Grab all diamonds",tag_arr[0],tag_arr[1])
		#tag B current Player must be Player_color[0]=Blue ,tag R current player must be =Player_color[1]=Red
		if (tag_arr[0]=="B" and Current_player==Player_Color["Blue"]) or (tag_arr[0]=="R" and Current_player==Player_Color["Red"]):
			var diamonds_temp_array = []
			for a in range(0, $Diamonds.get_child_count()):
			#Get B# and R# both of bowls diamonds
				if $Diamonds.get_child(a).bowl_tag == "B"+tag_arr[1] or $Diamonds.get_child(a).bowl_tag == "R"+tag_arr[1]:
					diamonds_temp_array.append($Diamonds.get_child(a))
			#The opponent must not be zero,so tatol diamonds must greater than 1
			if diamonds_temp_array.size() > 1:
				for a in range(0,diamonds_temp_array.size()):
					if tag_arr[0]=="B":
						diamonds_temp_array[a].bowl_tag = "Depot_b"
						Pos_parabola(diamonds_temp_array[a], $Board.get_node("Depot_b").position + Rnd_pos())
					if tag_arr[0]=="R":
						diamonds_temp_array[a].bowl_tag = "Depot_r"
						Pos_parabola(diamonds_temp_array[a], $Board.get_node("Depot_r").position + Rnd_pos())
		
	elif (tag == "Depot_b" and Current_player==Player_Color["Blue"]) or (tag == "Depot_r"and Current_player==Player_Color["Red"]):
		move_again = true

func Change_Player():
	if !GameOn:
		return
	if limit_time_en:
		#Reset Rest Of Time
		$"Score_board/RestOfTime".text = str(limit_sec)
		One_Sec_timer()
		#$OneSec.start()
	#Stop Avatar flash
	get_node(Current_player).get_node("Anim").stop()
	#Stop all bowls flash
	for bowl in $Board.get_children():
		bowl.get_node("Anim").stop()
		
	if move_again != true:
		if Current_player == Player_Color.get("Blue"):
			Current_player = Player_Color.get("Red")
		else :
			Current_player = Player_Color.get("Blue")
		move_again = false
	#Start Avatar flash
	get_node(Current_player).get_node("Anim").play("Idle")
	bowl_click_enable(true,Current_player)
	
	if !P2P and Current_player == Player_Color.get("Red"):
		Robot_Move()

func Robot_Move():
	#R6~R1 = bowl_array 7~12 
	var diamond_dict = {"R6":0,"R5":0,"R4":0,"R3":0,"R2":0,"R1":0}
	var red_empty_bowl = diamond_dict.duplicate()
	for b in range(7,13):
		for d in $Diamonds.get_children():
			if d.bowl_tag == bowl_array[b]:
				#key:value+1
				diamond_dict[bowl_array[b]] += 1
				#red_empty_bowl dict leave empty bowl
				red_empty_bowl.erase(bowl_array[b])
	print("diamond_dict: ", diamond_dict)
	print("red_empty_bowl: ", red_empty_bowl)
	
	#Robot gets holes at Red side to compare Blue side bowl
	var blue_target = {}
	for hole in red_empty_bowl:
		var bowl_num = hole.split("",1)
		#print("bowl_num:",bowl_num[0]," : ",bowl_num[1])
		var blue_bowl = "B"+bowl_num[1]
		var d_num = 0
		for d in $Diamonds.get_children():
			if d.bowl_tag == blue_bowl:
				d_num += 1
				#true=merge keys are copied
				blue_target.merge({blue_bowl:d_num},true)
		print("blue_target: ", blue_target)
	#Sort max diamonds in blue_target_keys
	var max_diamonds = 0
	#var targBowl
	var blue_target_keys = []
	if ! blue_target.is_empty():
		for targ in blue_target:
			if blue_target[targ] > max_diamonds:
				blue_target_keys.push_front(targ)
				max_diamonds = blue_target[targ]
				#targBowl = targ
	else:
		blue_target_keys.push_front("Depot_r")
	
	print("blue_target_keys: ",blue_target_keys)
	#bowl_array = ["B1","B2","B3","B4","B5","B6","Depot_b","R6","R5","R4","R3","R2","R1","Depot_r"]
	# bowl_array.size() = 14 ,index need -1,and "Depot_b" -1 total -2. 
	# find(targBowl)+1 ,need to check right side bowl contain
	#Robot find high num bowl ,the one can moves and the last diamond can stop in target bowl
	var CanMove = []
	for btk in blue_target_keys:
		var idx = 1 
		var RobotWantMoveBowl = ""
		while(RobotWantMoveBowl != "Depot_b"):
			RobotWantMoveBowl = bowl_array[ (bowl_array.size()-2) - (bowl_array.find(btk) + idx)]
			print("RobotWantMoveBowl: ",RobotWantMoveBowl)
			var diamondsNum =0
			for d in $Diamonds.get_children():
				if d.bowl_tag == RobotWantMoveBowl:
					diamondsNum += 1
			#Found th high bowl move 1 step to satisfied
			if diamondsNum == idx:
				CanMove.append(RobotWantMoveBowl)
				break
			idx += 1#Robot test more high bowl number
		print("CanMove:",CanMove," idx:",idx)
		
	if CanMove.size() != 0:
		Move_Diamond($Board.get_node(CanMove[0]))
	elif CanMove.size() == 0:# If best moving not found,select the highest bowl num to move
		var RobotSelectBowl =""
		for k in diamond_dict.keys():
			if diamond_dict[k] > 0 :
				RobotSelectBowl = k
				Move_Diamond($Board.get_node(RobotSelectBowl))
				break
	
		
				
		
				
	
	
		
@rpc("any_peer", "call_local", "reliable",0)
func One_Sec_timer():
	$"Score_board/RestOfTime".text = str(limit_sec)
	$OneSec.start()

@rpc("any_peer","call_local","reliable")
func UpdateScore():
	var bowl_diamonds = {"B1":0,"B2":0,"B3":0,"B4":0,"B5":0,"B6":0,"Depot_b":0,
					"R1":0,"R2":0,"R3":0,"R4":0,"R5":0,"R6":0,"Depot_r":0}
#	for dd in range(0, $Diamonds.get_child_count()):
#		var in_bowl = $Diamonds.get_child(dd).bowl_tag
	for d in $Diamonds.get_children():
		var in_bowl = d.bowl_tag
		if in_bowl == "B1":
			bowl_diamonds.B1 += 1
		elif in_bowl == "B2":
			bowl_diamonds.B2 += 1
		elif in_bowl == "B3":
			bowl_diamonds.B3 += 1
		elif in_bowl == "B4":
			bowl_diamonds.B4 += 1
		elif in_bowl == "B5":
			bowl_diamonds.B5 += 1
		elif in_bowl == "B6":
			bowl_diamonds.B6 += 1
		elif in_bowl == "Depot_b":
			bowl_diamonds.Depot_b += 1
		elif in_bowl == "R1":
			bowl_diamonds.R1 += 1
		elif in_bowl == "R2":
			bowl_diamonds.R2 += 1
		elif in_bowl == "R3":
			bowl_diamonds.R3 += 1
		elif in_bowl == "R4":
			bowl_diamonds.R4 += 1
		elif in_bowl == "R5":
			bowl_diamonds.R5 += 1
		elif in_bowl == "R6":
			bowl_diamonds.R6 += 1
		elif in_bowl == "Depot_r":
			bowl_diamonds.Depot_r += 1
	#print(bowl_diamonds)
	#	$"Score_board/VB/HB/VB/HBb/b1".text = str(bowl_diamonds.B1)
	for c in range(1,7):
		get_node("Score_board/VB/HB/VB/HBb/b" + str(c)).text = str(bowl_diamonds.get("B"+str(c)))
		get_node("Score_board/VB/HB/VB/HBr/r" + str(c)).text = str(bowl_diamonds.get("R"+str(c)))
	$"Score_board/VB/HB/depot_b".text = str(bowl_diamonds.Depot_b)
	$"Score_board/VB/HB/depot_r".text = str(bowl_diamonds.Depot_r)
	
	if GameOn==false:
		var winner = "Blue won!" if bowl_diamonds.Depot_b > bowl_diamonds.Depot_r else "Red won!"
		Winner(winner)
		
func  Pos_parabola(obj, pos_end):
	tween = create_tween()
	var mid_x = obj.position.x + (pos_end.x-obj.position.x)/2
	#var mid_y = obj.position.y + (pos_end.y-obj.position.y)/2
	var mid_z = obj.position.z + (pos_end.z-obj.position.z)/2
	tween.tween_property(obj,"position",Vector3(mid_x,2,mid_z),0.2).set_ease(1)
	tween.tween_property(obj,"position",pos_end,0.3).set_ease(2)
	

func prepare_Diamond(slot_tag:String, slots:int, d:int):
	for i in range(1, slots+1):
		var slot_node_name = slot_tag + str(i)
		var ColIdx = 0
		for j in range(1,d+1):
			var diamond = diamond_org.instantiate()
			diamond.get_node("Mesh").get("surface_material_override/0").albedo_color = Color(Col[ColIdx])
			ColIdx += 1
			var rnd_pos = $Board.get_node(slot_node_name).position + Rnd_pos()
			Rnd_rot(diamond)
			diamond.position = rnd_pos
			diamond.name =  slot_node_name + str(j)
			diamond.bowl_tag = slot_node_name
			diamond.add_to_group("Diamond_g")
			$Diamonds.add_child(diamond)


func Rnd_pos():
	var rnd_pos_x = randf_range(-0.3, 0.3)
	#var rnd_pos_y = randf_range(0, 0)
	var rnd_pos_z = randf_range(-0.3, 0.3)
	var rnd_pos = Vector3(rnd_pos_x, 1,rnd_pos_z)
	return rnd_pos

func Rnd_rot(diamond):
	var rnd_r =  randf_range(-PI/2, PI/2)
	diamond.rotate_x(rnd_r)
	
func Puppet():
	#print("prepare_Players ",GameManager.Players)
	var HeroColIdx = 0
	for pl in GameManager.Players:
		var p_hero = load("res://Mancala/hero.tscn")
		hero = p_hero.instantiate()
		hero.name = str(pl)
		hero.get_node("Mesh").get("surface_material_override/0").albedo_color \
			 = Color(Col[HeroColIdx])
		add_child(hero)
		hero.position = Vector3(7, 3, 3) if HeroColIdx==0 else Vector3(-7, 3, -3) 
		HeroColIdx += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_one_sec_timeout():
	if limit_time_en:
		if int($"Score_board/RestOfTime".text) != 0 and GameOn:
			$"Score_board/RestOfTime".text = str(int($"Score_board/RestOfTime".text) - 1)
		else :
			Stop_Game()
			#If current_player didn't move when time is up ,the opponent won the game
			var winner = "Blue won! Red time exceeds!" \
				if Current_player == Player_Color["Red"] else "Red won! Blue time exceeds!"
			Winner(winner)
		
func Winner(winner):
	$"Score_board/RestOfTime".text = winner
	
func Stop_Game():
	$GameMenu.visible = true
	$OneSec.stop()
	GameOn = false
	
func Quit_Game():
	get_tree().quit()
