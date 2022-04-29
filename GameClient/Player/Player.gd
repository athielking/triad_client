extends Node

const CardState = preload("res://Cards/CardState.gd")
const Playspace = preload("res://Playspace.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	$PlayerDeck.connect("card_drawn", self, "_on_Player_card_drawn")

func _on_Player_card_drawn(card):
	$PlayerHand.add_card_to_hand(card)

func card_slot_selected(slot):
	if $PlayerHand.selected_card == null:
		return
	
	$PlayerHand.put_selected_card_in_play(slot)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
