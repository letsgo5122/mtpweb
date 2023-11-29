extends CanvasLayer

signal play
signal quit_game
signal gameMenuSetting(CkBt, limitTime,firstPlayer,optionBtId)
var CkBt:bool = false
var limitTime:int = 18
var firstPlayer:String = "Blue"
var optionBtId = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	play.emit()
	pass # Replace with function body.


func _on_quit_pressed():
	quit_game.emit()
	pass # Replace with function body.


func _on_check_button_toggled(button_pressed):
	CkBt = button_pressed
	SendGameMenu.rpc(CkBt, limitTime, firstPlayer,optionBtId)
	pass # Replace with function body.


func _on_limit_time_sec_text_changed(new_text):
	limitTime = int(new_text)
	SendGameMenu.rpc(CkBt, limitTime, firstPlayer,optionBtId)
	pass # Replace with function body.


func _on_first_player_item_selected(index):
	var player = $"bg/VB/First Player".get_item_text(index)
	firstPlayer = player
	optionBtId = index
	SendGameMenu.rpc(CkBt, limitTime, firstPlayer, optionBtId)
	

@rpc("any_peer","call_local","reliable")
func SendGameMenu(CkBt, limitTime, firstPlayer, optionBtId):
	gameMenuSetting.emit(CkBt, limitTime, firstPlayer,optionBtId)
