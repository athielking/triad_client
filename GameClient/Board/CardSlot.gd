extends CenterContainer

signal slot_selected(slot)

var x := 0
var y := 0

func _ready():
	$TextureButton.connect("pressed", self, "_on_texture_button_pressed")
	pass # Replace with function body.

func init(x, y):
	self.x = x
	self.y = y

func place_card(card):
	$Cards.add_child(card)

func get_card():
	return $Cards.get_child(0)

func coordinate_equals(coordinate: Dictionary) -> bool:
	
	if not coordinate.has_all(["x", "y"]):
		return false;
	
	var x_1 = coordinate["x"]
	var y_1 = coordinate["y"]
	
	return x == x_1 && y == y_1

func _on_texture_button_pressed():
	emit_signal("slot_selected", self)
