extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const CardBase = preload("res://Cards/CardBase.tscn")
const CardState = preload("res://Cards/CardState.gd")

onready var CenterCardOval = get_viewport().size * Vector2(0.5, 1.25)
onready var HorizontalRadius = get_viewport().size.x *0.45
onready var VerticalRadius = get_viewport().size.y*0.4

var active_player := "";

var angle = deg2rad(90) - .5
var CardSpread = 0.25

const CARD_SIZE = Vector2(125, 175)

var game_channel: PhoenixChannel

var selected_card = null
var selected_slot = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$Deck.rect_position = $DeckReference.rect_position
	$Deck.rect_size = CARD_SIZE
	$Deck.texture_normal = load("res://assets/images/CardBack.png")
	$Deck.texture_pressed = load("res://assets/images/CardBack.png")	
	$Deck.rect_scale = CARD_SIZE / $Deck.texture_normal.get_size()
	
	$OpponentDeck.rect_rotation = 180
	$OpponentDeck.rect_position = $OpponentDeckReference.rect_position
	$OpponentDeck.texture_normal = load("res://assets/images/CardBack.png")
	$OpponentDeck.texture_disabled = load("res://assets/images/CardBack.png")
	$OpponentDeck.rect_size = CARD_SIZE
	$OpponentDeck.rect_scale = CARD_SIZE / $OpponentDeck.texture_normal.get_size()
	
	
	$TweenDraw.connect("tween_completed", self, "_on_tween_draw_completed")
	
	$TweenPlay.connect("tween_started", self, "_on_tween_play_started")
	$TweenPlay.connect("tween_completed", self, "_on_tween_play_completed")
	
	$TweenOpponentPlay.connect("tween_started", self, "_on_tween_opponent_play_started")
	$TweenOpponentPlay.connect("tween_completed", self, "_on_tween_opponent_play_completed")
	
	if not game_channel:
		game_channel = Global.socket.channel("game:%s" % Global.game_id)
		game_channel.connect("on_event", self, "_on_Channel_event")
		game_channel.connect("on_join_result", self, "_on_Channel_join_result")
		game_channel.connect("on_error", self, "_on_Channel_error")
		game_channel.connect("on_close", self, "_on_Channel_close")
		game_channel.join()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Channel_event(event, payload, status):
	Global._log("_on_Channel_event:  " + event + ", status: " + status + ", payload: " + str(payload))
	
	if(event == "game_started"):
		active_player = payload.active_player
	elif event == "draw_card":
		initialize_card(payload.card)
		$Deck.disabled = payload.deck_count == 0
	elif event == "card_drawn":
		initialize_opponent_card(payload)
	elif event == "rejoin":
		handle_player_rejoined(payload)
	elif event == "place_card":
		handle_place_card(payload)
		
func _on_Channel_join_result(status, result):
	if status == PhoenixChannel.STATUS.ok:
		print("Joined - " + game_channel.get_topic())
		
		if(Global.rejoining):
			game_channel.push("rejoin")
		else:
			game_channel.push("connect")	
	else:
		print("Not joined")		

	Global._log("_on_Channel_join_result: " + status + ", " + str(result))
	
func _on_Channel_error(error):
	Global._log("_on_Channel_error: " + str(error))
	
func _on_Channel_close(closed):
	Global._log("_on_Channel_close: " + str(closed))

func _on_card_selected(card):
	if(selected_card != null):
		selected_card.set_state(CardState.InHand)
	
	selected_card = card
	game_channel.push("valid_placements", card)

func card_slot_selected(slot):
	if(selected_card == null):
		return
	
	selected_slot = slot
	$TweenPlay.interpolate_property(selected_card, "rect_position", 
		selected_card.rect_position, selected_slot.rect_global_position, .5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TweenPlay.start()
	
	pass

func _on_Deck_pressed():
	game_channel.push("draw_card")

func initialize_card(card):
	var new_card = CardBase.instance()
	new_card.init(card.id, card.name, card.power_top, card.power_right, card.power_bottom, card.power_left)
	new_card.rect_position = $Deck.rect_position - CARD_SIZE / 2
	new_card.State = CardState.Drawing
	new_card.get_node("CardBack").visible = false
	new_card.connect("card_selected", self, "_on_card_selected")
	
	$Hand.add_child(new_card)
	
	var handCount = $Hand.get_child_count()	
	$TweenDraw.interpolate_property(new_card, "rect_position", 
		$Deck.rect_position - CARD_SIZE / 2, Vector2(handCount * CARD_SIZE.x, 760), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TweenDraw.start()

func initialize_opponent_card(payload):
	if(payload.player == Global.user_id):
		return
		
	var card = payload.card
	var opp_card = CardBase.instance()
	opp_card.init(card.id, card.name, card.power_top, card.power_right, card.power_bottom, card.power_left)
	opp_card.rect_position = $OpponentDeck.rect_position - CARD_SIZE / 2
	opp_card.set_state(CardState.OpponentDrawing)
	opp_card.rect_rotation = 180
	
	$OpponentHand.add_child(opp_card)
	var oppHandCount = $OpponentHand.get_child_count()
	
	$TweenDraw.interpolate_property(opp_card, "rect_position", 
		$OpponentDeck.rect_position - CARD_SIZE / 2, Vector2(oppHandCount * CARD_SIZE.x, 20), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TweenDraw.start()
	
func handle_place_card(payload):
	if payload.controlled_by == Global.user_id:
		return
		
	for card in $OpponentHand.get_children():
		if card.CardId == payload.card_id:
			selected_card = card
			break;
	
	var coordinate = "%d,%d" % [payload.x, payload.y]
	match coordinate:
		"1,1":
			selected_slot = $GridContainer/CardSlot0
		"1,2":
			selected_slot = $GridContainer/CardSlot1
		"1,3":
			selected_slot = $GridContainer/CardSlot2
		"2,1":
			selected_slot = $GridContainer/CardSlot3
		"2,2":
			selected_slot = $GridContainer/CardSlot4
		"2,3":
			selected_slot = $GridContainer/CardSlot5
		"3,1":
			selected_slot = $GridContainer/CardSlot6
		"3,2":
			selected_slot = $GridContainer/CardSlot7
		"3,3":
			selected_slot = $GridContainer/CardSlot8
	
	$TweenOpponentPlay.interpolate_property(selected_card, "rect_position", 
		selected_card.rect_position, selected_slot.rect_global_position, .5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TweenOpponentPlay.start()
	
func handle_player_rejoined(payload):

	active_player = payload["active"]
	payload.erase("active")
	payload.erase("game_id")

	for key in payload.keys():		
		if(key == Global.user_id):
			sync_player(payload[key])
		else:
			sync_opponent(payload[key])

func sync_player(player):
	for card in player.hand:
		var new_card = CardBase.instance()
		new_card.init(card.id, card.name, card.power_top, card.power_right, card.power_bottom, card.power_left)
		new_card.rect_position = $Deck.rect_position - CARD_SIZE / 2
		new_card.State = CardState.InHand
		new_card.get_node("CardBack").visible = false
		new_card.connect("card_selected", self, "_on_card_selected")
	
		$Hand.add_child(new_card)
		var handCount = $Hand.get_child_count()	
		new_card.rect_position = Vector2(handCount * CARD_SIZE.x, 760)
	
	for card in player.graveyard:
		pass

func sync_opponent(opponent):
	for card in opponent.hand:		
		var opp_card = CardBase.instance()
		opp_card.init(card.id, card.name, card.power_top, card.power_right, card.power_bottom, card.power_left)
		opp_card.rect_position = $OpponentDeck.rect_position - CARD_SIZE / 2
		opp_card.set_state(CardState.OpponentDrawing)
		opp_card.rect_rotation = 180
		
		$OpponentHand.add_child(opp_card)
		var oppHandCount = $OpponentHand.get_child_count()
		opp_card.rect_position = Vector2(oppHandCount * CARD_SIZE.x, 20)
	
	for card in opponent.graveyard:
		pass

func _on_tween_draw_completed(object, node_path):
	match object.State:
		CardState.OpponentDrawing:
			object.set_state(CardState.OpponentInHand)
		CardState.Drawing:
			object.set_state(CardState.InHand)

func _on_tween_play_started(object, node_path):
	selected_card.set_state(CardState.InPlay)
	selected_card.disconnect("card_selected", self, "_on_card_selected")

func _on_tween_play_completed(object, node_path):
	$Hand.remove_child(selected_card)	
	selected_slot.add_child(selected_card)
	
	game_channel.push("place_card", {"x": selected_slot.x, "y": selected_slot.y, "card_id": selected_card.id})
	
	selected_card = null
	selected_slot = null
	pass
	
func _on_tween_opponent_play_started(object, node_path):
	selected_card.set_state(CardState.OpponentInPlay)	

func _on_tween_opponent_play_completed(object, node_path):
	pass
	
func _on_TextureButton0_pressed():
	card_slot_selected($GridContainer/CardSlot0)
	pass # Replace with function body.

func _on_TextureButton1_pressed():
	card_slot_selected($GridContainer/CardSlot1)
	pass # Replace with function body.

func _on_TextureButton2_pressed():
	card_slot_selected($GridContainer/CardSlot2)
	pass # Replace with function body.

func _on_TextureButton3_pressed():
	card_slot_selected($GridContainer/CardSlot3)
	pass # Replace with function body.

func _on_TextureButton4_pressed():
	card_slot_selected($GridContainer/CardSlot4)
	pass # Replace with function body.

func _on_TextureButton5_pressed():
	card_slot_selected($GridContainer/CardSlot5)
	pass # Replace with function body.

func _on_TextureButton6_pressed():
	card_slot_selected($GridContainer/CardSlot6)
	pass # Replace with function body.

func _on_TextureButton7_pressed():
	card_slot_selected($GridContainer/CardSlot7)
	pass # Replace with function body.

func _on_TextureButton8_pressed():
	card_slot_selected($GridContainer/CardSlot8)
	pass # Replace with function body.
