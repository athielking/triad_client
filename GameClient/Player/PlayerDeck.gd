extends TextureButton

const CardBase = preload("res://Cards/CardBase.tscn")
const Playspace = preload("res://Playspace.gd")

signal card_drawn(card)

# Called when the node enters the scene tree for the first time.
func _ready():
	rect_position = Vector2(get_viewport().size.x - Playspace.CARD_SIZE.x - 10, 10)
	rect_size = Playspace.CARD_SIZE
	texture_normal = load("res://assets/images/CardBack.png");
	texture_pressed = load("res://assets/images/CardBack.png");
	texture_pressed = load("res://assets/images/CardBack.png");
	rect_scale = Playspace.CARD_SIZE / texture_normal.get_size()


func _on_PlayerDeck_button_up():
		
	var new_card = CardBase.instance()
#	new_card.card_size = Playspace.CARD_SIZE
#	new_card.rect_scale = Playspace.CARD_SIZE / new_card.rect_size
	new_card.start_position = rect_position - Playspace.CARD_SIZE/2
	new_card.start_rotation = 0
	emit_signal("card_drawn", new_card)
