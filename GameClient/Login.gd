extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var _username = get_node("MainContainer/ControlContainer/LoginContainer/EmailContainer/ControlContainer/tbUsername")
onready var _password = get_node("MainContainer/ControlContainer/LoginContainer/PasswordContainer/ControlContainer/tbPassword")

# Called when the node enters the scene tree for the first time.
func _ready():
	$HTTPRequest.connect("request_completed", self, "_http_request_completed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_btnLogin_pressed():
	print("Logging into http://127.0.0.1:4000")
	
	var params = {"email": _username.text, "password": _password.text}
	var json = JSON.print(params)
	
	var headers = ["Content-Type: application/json"]
	$HTTPRequest.request("http://127.0.0.1:4000/api/v1/sign_in", headers, false, HTTPClient.METHOD_POST, json)
	

func _http_request_completed(result, response_code, headers, body):
	print("HTTP Request Completed")
	print("Status Code: %s" % response_code)
	
	if response_code != 200:
		push_error('Unable to login')
		return
	
	var json = JSON.parse(body.get_string_from_utf8())
	if typeof(json.result) == TYPE_DICTIONARY:
		Global.connect_to_server(json.result["jwt"])
	
	Global.goto_scene("res://Lobby.tscn")
