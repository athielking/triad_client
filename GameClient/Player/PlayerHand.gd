extends Node2D

const CardBase = preload("res://Cards/CardBase.tscn")
const CardState = preload("res://Cards/CardState.gd")
const Playspace = preload("res://Playspace.gd")

const CARD_SPREAD = .12

onready var _center_card_oval = get_viewport().size * Vector2(0.5, 1.25)
onready var _horizontal_radius = get_viewport().size.x *0.45
onready var _vertical_radius = get_viewport().size.y*0.4

var selected_card = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func add_card_to_hand(new_card):
	var cardsInHand = $Cards.get_children().size()
	var angle = PI/2 + CARD_SPREAD * (float(cardsInHand)/2 - cardsInHand)
	var ovalVector = Vector2(_horizontal_radius * cos(angle), -_vertical_radius * sin(angle))
	
	#Set target position in hand
	new_card.target_position = _center_card_oval + ovalVector - Playspace.CARD_SIZE
	new_card.target_rotation = (90 - rad2deg(angle)) / 4
	new_card.State = CardState.Drawing
	new_card.connect("card_selected", self, "_on_card_selected")

	var card_num = 0
	for card in $Cards.get_children(): # reorganise hand
		angle = PI/2 + CARD_SPREAD*(float(cardsInHand)/2 - card_num)
		ovalVector = Vector2(_horizontal_radius * cos(angle), -_vertical_radius * sin(angle))

		card.target_position = _center_card_oval + ovalVector - Playspace.CARD_SIZE
		card.start_rotation = card.rect_rotation
		card.target_rotation = (90 - rad2deg(angle))/4
		card.draw_order = card_num
		
		card_num += 1

		if card.State == CardState.InHand:
			card.State = CardState.ReOrganize
			card.start_position = card.rect_position
		elif card.State == CardState.Drawing:
			card.start_position = card.target_position - ((card.target_position - card.rect_position)/(1-card.t))

	$Cards.add_child(new_card)

func put_selected_card_in_play(slot):
	
	if(selected_card == null):
		return
	
	$Cards.remove_child(selected_card)
	
#	var cardsInHand = $Cards.get_children().size()
#	var angle = PI/2 + CARD_SPREAD * (float(cardsInHand)/2 - cardsInHand)
#	var ovalVector = Vector2(_horizontal_radius * cos(angle), -_vertical_radius * sin(angle))
#	var card_num = 0
#	for card in $Cards.get_children(): # reorganise hand
#		angle = PI/2 + CARD_SPREAD*(float(cardsInHand)/2 - card_num)
#		ovalVector = Vector2(_horizontal_radius * cos(angle), -_vertical_radius * sin(angle))
#
#		card.target_position = _center_card_oval + ovalVector - Playspace.CARD_SIZE
#		card.start_rotation = card.rect_rotation
#		card.target_rotation = (90 - rad2deg(angle))/4
#		card.draw_order = card_num
#
#		card_num += 1
#
#		if card.State == CardState.InHand:
#			card.State = CardState.ReOrganize
#			card.start_position = card.rect_position
#		elif card.State == CardState.Drawing:
#			card.start_position = card.target_position - ((card.target_position - card.rect_position)/(1-card.t))
	
	selected_card.disconnect("card_selected", self, "_on_card_selected")
	selected_card.State = CardState.InPlay
	
#	var new_card = CardBase.instance()
#	new_card.State = CardState.InPlay
#	new_card.get_node("CardBack").visible = false
#
	slot.add_child(selected_card)
	#slot.add_child(new_card)
	#selected_card.queue_free()
	selected_card = null
	

func _on_card_selected(card):
	if(selected_card != null):
		selected_card.deselect()
		
	selected_card = card
		
#	if(selected_card != null):
#		$Cards.move_child(selected_card, $Cards.get_children().size() - 1)
