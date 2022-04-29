extends Node

var user_token: = ""
var user_id: = ""

var game_id = ""
var rejoining: = false

var current_scene = null
var socket : PhoenixSocket

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func connect_to_server(jwt: String):
	user_token = jwt
	
	if not socket:
		socket = PhoenixSocket.new("ws://127.0.0.1:4000/socket", {
			params = {token = Global.user_token}
		})
		
		get_tree().get_root().call_deferred("add_child", socket, true)
		get_tree().get_root().call_deferred("move_child", socket, 0)
		
		socket.connect_socket()

func _deferred_goto_scene(path):
	current_scene.free()
	
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	
func _log(message):
	
	var time = OS.get_time()
	print(str(time.hour) + ":" + str(time.minute) + ":" + str(time.second) + ": " + str(message) + "\n")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


