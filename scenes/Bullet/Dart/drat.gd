class_name Dart extends Bullet

var attribute_set: AttributeSet

## 飞镖的速度
var move_speed: float
## 飞镖的飞行距离
var max_fly_distance: float
var fly_direction := 1

var isRunning := false: set = _update_running_state

func set_attribute(attr_set: AttributeSet) -> void:
	self.attribute_set = attr_set
	var move_speed_attr = attr_set.find_attr(AttributeEnum.instance.MOVE_SPEED)
	move_speed_attr.register_value_changed(_move_speed_change)
	move_speed = move_speed_attr.get_current_value()
	#prints("dart bullet move speed ->", move_speed)
	var max_fly_distance_attr = attr_set.find_attr(AttributeEnum.instance.MAX_FLY_DISTANCE)
	max_fly_distance = max_fly_distance_attr.get_current_value()
	max_fly_distance_attr.register_value_changed(_move_max_fly_distance)
	
func _ready() -> void:
	super._ready()
	
func _physics_process(delta: float) -> void:
	if not isRunning:
		return
	position += Vector2.RIGHT.rotated(rotation) * move_speed * delta * fly_direction
	
	var fly_distance = position.length()
	#prints("飞镖飞行距离->", fly_distance, fly_direction, move_speed)
	if fly_distance >= max_fly_distance:
		fly_direction = -1
	elif isRunning && fly_distance <= 1:
		isRunning = false

func fire():
	#prints("发射")
	isRunning = true
	fly_direction = 1

func _update_running_state(val):
	
	if val == false && self.isRunning == true:
		_complete()
	isRunning = val
	pass

func _move_speed_change(_change_value) ->void:
	#print('_move_speed_change ->', _change_value)
	move_speed = _change_value
	pass

func _move_max_fly_distance(_change_value) -> void:
	max_fly_distance = _change_value
	pass

func _complete():
	(get_parent() as DartWeapon).fire()
