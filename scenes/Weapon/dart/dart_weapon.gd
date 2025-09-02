class_name DartWeapon extends Weapon

## 飞镖的数量
var dart_number: int = 5
## 飞镖射出的间隔
var dart_fire_delay: float = 1.0


# 发射器
var fire_timer: Timer

var darts: Array[Dart]

func _ready() -> void:
	prints("AttrTools ->", AttributeEnum, SkillPool)
	## 初始化属性
	var fire_delay_attr = Attribute.new(AttributeEnum.DartAttribute.DART_FIRE_DELAY)
	fire_delay_attr.add_base_value(dart_fire_delay);
	attr_set.attrs.set(AttributeEnum.get_dart_attribute_name(AttributeEnum.DartAttribute.DART_FIRE_DELAY), fire_delay_attr)
	var dart_number_attr = Attribute.new(AttributeEnum.DartAttribute.DART_NUMBER)
	dart_number_attr.add_base_value(dart_number);
	attr_set.attrs.set(AttributeEnum.get_dart_attribute_name(AttributeEnum.DartAttribute.DART_NUMBER), dart_number_attr)
	var max_fly_distance_attr = Attribute.new(AttributeEnum.DartAttribute.MAX_FLY_DISTANCE)
	max_fly_distance_attr.add_base_value(100);
	attr_set.attrs.set(AttributeEnum.get_dart_attribute_name(AttributeEnum.DartAttribute.MAX_FLY_DISTANCE), max_fly_distance_attr)
	var move_speed_attr = Attribute.new(AttributeEnum.DartAttribute.MOVE_SPEED)
	move_speed_attr.add_base_value(200);
	attr_set.attrs.set(AttributeEnum.get_dart_attribute_name(AttributeEnum.DartAttribute.MOVE_SPEED), move_speed_attr)
	
	dart_fire_delay = fire_delay_attr.get_current_value() 
	dart_number_attr.register_value_changed(_dart_number_change)
	fire_delay_attr.register_value_changed(_dart_fire_delay_change)
	print("飞镖已经装载 dart_number ->", dart_number)
	
	_init_bullet()
	
	## test code 
	#max_fly_distance_attr.add_current_value(50)
	#dart_fire_delay_attr.add_base_ratio(-0.5)
	#dart_number_attr.add_current_value(10)
	#move_speed_attr.add_base_ratio(2.0)
	
		
func _init_bullet() -> void:
	for index in range(dart_number):
		var dart_bullet_class = preload("res://scenes/Bullet/Dart/Dart.tscn")
		var dart_bullet_obj = dart_bullet_class.instantiate()
		dart_bullet_obj.set_attribute(attr_set)
		darts.append(dart_bullet_obj)
	
	## 调整飞镖的发射逻辑
	fire_timer = Timer.new()
	fire_timer.wait_time = dart_fire_delay
	fire_timer.one_shot = true
	add_child(fire_timer)
	fire_timer.start()
	fire_timer.timeout.connect(_fire)
	
func _fire() -> void:
	## 获取当前节点的forward，通过forward方向平分掉360度
	var rollRadin = PI * 2 / dart_number
	#prints("飞镖创建的数量 ->", dart_number, darts.size())
	for index in range(darts.size()):
		var dart = darts[index]
		dart.position = Vector2.ZERO
		var direction = Vector2.UP.rotated(rollRadin * index)
		dart.rotation = direction.angle()
		if dart.get_parent() != self:
			add_child(dart)
		dart.fire()

func _dart_fire_delay_change(change_value: float) -> void:
	dart_fire_delay = max(0, change_value)
	prints("fire delay change 1->", dart_fire_delay, change_value)
	if is_instance_valid(dart_fire_delay):
		prints("fire delay change 2->", change_value)
		fire_timer.wait_time = dart_fire_delay
	
func _dart_number_change(change_value: float) -> void:
	_update_bullet_obj(change_value - dart_number)
	dart_number = clamp(change_value, 0, change_value)
	

func _update_bullet_obj(_update_number: float) -> void:
	var current_bullet_size = darts.size()
	var calc_bullet_size = current_bullet_size + _update_number
	if calc_bullet_size <=0 :
		## TODO 清掉所有节点
		pass
	elif calc_bullet_size <= current_bullet_size:
		## TODO 减少节点
		var delete_size = current_bullet_size - calc_bullet_size
		
	else:
		var add_size = calc_bullet_size - current_bullet_size
		for index in range(add_size):
			var new_dart: Dart
			if darts.size() > 0:
				new_dart = darts[0].duplicate()
				new_dart.set_attribute(attr_set)
			else:
				var dart_bullet_class = preload("res://scenes/Bullet/Dart/Dart.tscn")
				new_dart = dart_bullet_class.instantiate()
				new_dart.set_attribute(attr_set)
			
			darts.append(new_dart)
			#print("飞镖数量增加", _update_number, darts.size())
	

func fire() -> void:
	#print("再次发射飞镖")
	fire_timer.start()
	
func _exit_tree() -> void:
	prints("dart_waepon exit")
