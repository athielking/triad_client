extends Control

var channel : PhoenixChannel
var presence : PhoenixPresence
var player_indexes : = []
var game_indexes: = []
var selected_game_id = null

onready var _create_game = get_node("MainContainer/RightContainer/RightControls/CenterContainer/Controls/FormPanel/CreateGame")

onready var _server_name = get_node("MainContainer/RightContainer/RightControls/CenterContainer/Controls/FormPanel/ServerName")
onready var _server_list = get_node("MainContainer/ServerListContainer/ItemList")
onready var _join_game = get_node("MainContainer/ServerListContainer/JoinPanel/JoinGame")

onready var _player_list = get_node("MainContainer/RightContainer/RightControls/CenterContainer/Controls/OnlinePlayers")
onready var _player_name = get_node("MainContainer/RightContainer/RightControls/CenterContainer/Controls/FormPanel/UserName")

# Called when the node enters the scene tree for the first time.
func _ready():	
	Global.socket.connect("on_open", self, "_on_Socket_open")
	
	_create_game.connect("pressed", self, "_on_Create_Game_pressed")
	
	_join_game.connect("pressed", self, "_on_Join_Game_pressed")
	_join_game.disabled = true
		
	_server_list.connect("item_selected", self, "_on_Game_selected")
	_server_list.connect("item_activated", self, "_on_Game_activated")
	
	$LoadingDialog.get_close_button().visible = false
	$ConfirmationDialog.get_close_button().visible = false
	
	if not presence:
		presence = PhoenixPresence.new()

	if not channel:
		channel = Global.socket.channel("room:lobby", {}, presence)
		channel.connect("on_event", self, "_on_Channel_event")
		channel.connect("on_join_result", self, "_on_Channel_join_result")
		channel.connect("on_error", self, "_on_Channel_error")
		channel.connect("on_close", self, "_on_Channel_close")

func _on_Socket_open(payload):
	channel.set_topic("room:lobby")
	channel.join()

func _on_Create_Game_pressed():
	channel.push("create_game", {"game_name": _server_name.get_text()})
	_create_game.disabled = true;
	$LoadingDialog.show_modal();
	
func _on_Game_activated(index: int): 
	Global._log("Game Activated %d" % index )
	selected_game_id = game_indexes[index]
	_on_Join_Game_pressed()
	
func _on_Game_selected(index: int, at_position: Vector2):
	Global._log("Game Selected %d" % index )
	selected_game_id = game_indexes[index]
	_join_game.disabled = false

func _on_Join_Game_pressed():
	if not selected_game_id:
		return
	
	channel.push("join_game", {"game_id": selected_game_id})
	$LoadingDialog/Label.text = "Joining Game"
	$LoadingDialog.show_modal()


func _on_Channel_event(event, payload, status):
	Global._log("_on_Channel_event:  " + event + ", status: " + status + ", payload: " + str(payload))
	
	if event == PhoenixChannel.PRESENCE_EVENTS.diff:
		_on_Presence_join(payload.joins)
		_on_Presence_leave(payload.leaves)
	elif event == PhoenixChannel.PRESENCE_EVENTS.state:
		_on_Presence_state(payload, _player_list, player_indexes)
	elif event == "user_info":
		_on_Channel_user_info(payload)
	elif event == "game_presence_state":
		_on_Presence_state(payload, _server_list, game_indexes)
	elif event == "create_game":
		_on_Channel_create_game(payload)
	elif event == "game_created":
		_on_Channel_game_created(payload)
	elif event == "join_game":
		_on_Channel_join_game(payload)
	elif event == "game_joined":
		_on_Channel_game_joined(payload)
	elif event == "can_rejoin":
		_on_Channel_can_rejoin(payload)
				
func _on_Channel_join_result(status, result):
	if status == PhoenixChannel.STATUS.ok:
		print("Joined - " + channel.get_topic())		
	else:
		print("Not joined")		

	Global._log("_on_Channel_join_result: " + status + ", " + str(result))
	
func _on_Channel_error(error):
	Global._log("_on_Channel_error: " + str(error))
	
func _on_Channel_close(closed):
	Global._log("_on_Channel_close: " + str(closed))

func _on_Presence_join(joins):
	if joins.keys().empty():
		return
		
	for key in joins.keys():
		var metadata = {}
		for meta in joins[key].metas:
			for meta_key in meta.keys():
				metadata[meta_key] = meta[meta_key]
		
		_player_list.add_item(metadata.name)
		player_indexes.append(key)
		
	Global._log("_on_Presence_join: " + str(joins))
	
func _on_Presence_leave(leaves):
	if leaves.keys().empty():
		return
		
	for key in leaves.keys():
		var idx = player_indexes.find(key)
		if idx > 0:
			_player_list.remove_item(idx)
			player_indexes.remove(idx)		

	Global._log("_on_Presence_leave: " + str(leaves))

func _on_Presence_state(payload, item_list: ItemList, indexes: Array):
	Global._log("_on_Presence_state: " + str(payload))
	for key in payload.keys():
		if indexes.has(key):
			continue
		
		var metadata = {}
		for meta in payload[key].metas:
			for meta_key in meta.keys():
				metadata[meta_key] = meta[meta_key]
		
		item_list.add_item(metadata.name, null, true)
		indexes.append(key)

# This event gets fired when this client creates a game
func _on_Channel_create_game(payload):
	Global.game_id = payload.game_id

# This event notifies the client of other games that have been created
func _on_Channel_game_created(payload):
	if game_indexes.has(payload.game_id):
		return
	
	_server_list.add_item(payload.name, null, true)
	game_indexes.append(payload.game_id)

# This event gets fired when this client joins a game
func _on_Channel_join_game(payload):
	Global.game_id = payload.game_id
	channel.leave()
	Global.goto_scene("res://Playspace.tscn")
	

# This event notifies the client of other games that have been joined
func _on_Channel_game_joined(payload):
	var idx = game_indexes.find(payload.game_id)
	game_indexes.remove(idx)
	_server_list.remove_item(idx)
	
	if Global.game_id == payload.game_id:
		channel.leave() #leave the lobby
		Global.goto_scene("res://Playspace.tscn")

func _on_Channel_user_info(payload):
	Global.user_id = payload.user_id
	_player_name.text = payload.name
	
	if(payload.has("active_game")):
		channel.push("can_rejoin", {"game_id": payload.active_game})
		
func _on_Channel_can_rejoin(payload):
	if payload.can_rejoin:
		$ConfirmationDialog.dialog_text = "Game is in progress.  Click OK to rejoin or Cancel to leave."
		$ConfirmationDialog.get_cancel().connect("pressed", self, "on_game_abandoned")
		$ConfirmationDialog.get_ok().connect("pressed", self, "on_game_rejoin")
		Global.rejoining = true
		Global.game_id = payload.game_id
		$ConfirmationDialog.show_modal()
	else:
		# Abandon Game or something
		pass
		
func on_game_rejoin():
	channel.leave()
	Global.goto_scene("res://Playspace.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
