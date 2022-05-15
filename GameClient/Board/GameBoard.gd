extends GridContainer

signal card_slot_selected(slot)

const CardSlot = preload("res://Board/CardSlot.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(rows: int, columns: int):
	self.columns = columns
	var x_size = 0
	var y_size = 0
	for i in range(rows):
		var row = i+1
		for j in range(columns):
			var col = j+1
			var slot = CardSlot.instance()
			slot.init(col, row)
			add_child(slot)
			slot.connect("slot_selected", self, "_on_slot_selected")
			
			x_size = slot.rect_size.x
			y_size = slot.rect_size.y
	
	rect_size = Vector2(x_size * columns, y_size * rows)

	var half_x = rect_size.x / 2
	var half_y = rect_size.y / 2
	
	rect_position = Vector2((get_viewport().size.x / 2) - half_x, (get_viewport().size.y / 2) - half_y)


func get_slot(coordinate: Dictionary):
	var selected_slot = null
	for slot in get_children():
		if(slot.x == coordinate.x && slot.y == coordinate.y):
			selected_slot = slot
			break;
	
	return selected_slot

func _on_slot_selected(slot):
	emit_signal("card_slot_selected", slot)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
