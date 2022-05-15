extends MarginContainer

signal card_selected(card)

const CardState = preload("res://Cards/CardState.gd")
const Selected_Highlight = preload("res://assets/images/greenhighlight.png")
const Card_Highlight = preload("res://assets/images/cardhighlight.png")
const ZOOM_SCALE = 1.6
const FLIP_TIME = 0.4

onready var _top_label = $Card/ColorRect/PowerContainer/Top/PowerTop
onready var _right_label = $Card/ColorRect/PowerContainer/Middle/PowerRight
onready var _left_label = $Card/ColorRect/PowerContainer/Middle/PowerLeft
onready var _bottom_label = $Card/ColorRect/PowerContainer/Bottom/PowerBottom
onready var _name_label = $Card/ColorRect2/Name

onready var _orig_scale = rect_scale;

# Declare member variables here. Examples:
var card_id = 109
var owner_id := ""
var controller_id := ""
var power_top := 0
var power_right := 0
var power_bottom := 0
var power_left := 0
var card_name := ""

var State = CardState.InHand

var focused: = false
var _orig_parent_index: = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_loadImage()
	_setStats()

func _loadImage():
	var path = str("res://assets/images/109.png")
	$Card.texture = load(path)
	$CardBack.texture = load("res://assets/images/CardBack.png")
	# $CardBack.scale = rect_size / $CardBack.texture.get_size();	

func _setStats():
	_top_label.text = str(power_top)
	_right_label.text = str(power_right)
	_bottom_label.text = str(power_bottom)
	_left_label.text = str(power_left)
	_name_label.text = card_name

func init(id, card_nm, top, right, bottom, left, player_id):
	card_id = id
	power_top = top
	power_right = right
	power_bottom = bottom
	power_left = left
	card_name = card_nm
	owner_id = player_id
	controller_id = player_id
	
	if(controller_id == Global.user_id):
		$Card/ColorRect.color = Color(1, 1, 1, 1)
	else:
		$Card/ColorRect.color = Color(1, 0, 0, 1)

func flip(player_id):
	controller_id = player_id
	
	$FlipStartTween.interpolate_property(self, "rect_scale", rect_scale, Vector2(.01, 1), FLIP_TIME/2, Tween.TRANS_LINEAR, Tween.EASE_OUT )
	$FlipStartTween.connect("tween_completed", self, "_on_flip_start_completed")
	$FlipStartTween.start()
	
func _on_flip_start_completed(object, path):
	$FlipEndTween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1, 1), FLIP_TIME/2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$FlipEndTween.connect("tween_completed", self, "_on_flip_end_completed")
	$FlipEndTween.start()
	
func _on_flip_end_completed(object, path):
	if(controller_id == Global.user_id):
		$Card/ColorRect.color = Color(1, 1, 1, 1)
	else:
		$Card/ColorRect.color = Color(1, 0, 0, 1)
	
func set_state(desired_state):
	var prevState = State;
	State = desired_state
	
	match State:
		CardState.OpponentInHand:
			$Focus.disabled = true
			$CardBack.visible = true
			
		CardState.OpponentDrawing:
			$Focus.disabled = true
			$CardBack.visible = true
			
		CardState.OpponentInPlay:
			$Focus.disabled = true
			$CardBack.visible = false
			$RotateTween.interpolate_property(self, "rect_rotation", rect_rotation, 0, .4, Tween.TRANS_LINEAR, Tween.EASE_OUT )
			$RotateTween.start()
			
		CardState.Drawing:
			$Focus.texture_normal = null
			$Focus.texture_hover = null
			
		CardState.SelectedInHand:
			$Focus.texture_normal = Selected_Highlight
			emit_signal("card_selected", self)
			
			_orig_parent_index = get_index()
			get_parent().move_child(self, get_parent().get_child_count()-1)
			$ZoomTween.interpolate_property(self, "rect_scale", rect_scale, rect_scale * ZOOM_SCALE, .4, Tween.TRANS_LINEAR, Tween.EASE_OUT )
			$ZoomTween.connect("tween_completed", self, "_on_zoom_in_completed")
			$ZoomTween.start()
			
		CardState.InHand:
			$Focus.texture_normal = null
			if prevState == CardState.SelectedInHand:
				emit_signal("card_selected", null)
				$ZoomTween.interpolate_property(self, "rect_scale", rect_scale, _orig_scale, .4, Tween.TRANS_LINEAR, Tween.EASE_OUT )
				$ZoomTween.connect("tween_completed", self, "_on_zoom_out_completed")
				$ZoomTween.start()
				
		CardState.InPlay:
			$Focus.texture_normal = null
			$Focus.texture_hover = Card_Highlight
			$ZoomTween.interpolate_property(self, "rect_scale", rect_scale, _orig_scale, .4, Tween.TRANS_LINEAR, Tween.EASE_OUT )			
			$ZoomTween.start()

func _input(event):
	if event.is_action_released("mouse_left"):
		if focused && State == CardState.InHand:
			set_state(CardState.SelectedInHand)
			return
		if focused && State == CardState.SelectedInHand:
			set_state(CardState.InHand)

func _on_zoom_in_completed(object, path):	
	$ZoomTween.disconnect("tween_completed", self, "_on_zoom_in_completed")
	pass
	
func _on_zoom_out_completed(object, path):
	get_parent().move_child(self, _orig_parent_index)
	$ZoomTween.disconnect("tween_completed", self, "_on_zoom_out_completed")
	pass

func _on_Focus_mouse_entered():
	focused = true
	
func _on_Focus_mouse_exited():
	focused = false
