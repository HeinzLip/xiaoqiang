class_name Missile extends Area2D

## 子弹移动速度
var _bullet_move_speed: float = 1300.0
## 子弹可以穿透总次数
var _bullet_penetrate_max_number: int = 0
## 子弹穿透次数
var _bullet_penetrate_number: int = 0
## 子弹伤害
var _bullet_damage: float = 10.0
## 子弹属性
var _attributeSet: AttributeSet
## 子弹是否存活
var _bullet_is_live: bool = false
## 子弹发射后的尺寸
var _bullet_scale: float = 1.0
## 子弹生命周期
var _bullet_life_time: float = 1.5

var missile_pool: GamePool
var _bullet_life_timer: Timer = Timer.new()


func _ready() -> void:
	area_entered.connect(_on_bullet_enter)
	pass

func _init_attr() -> void:
	var bullet_scale: Attribute
	if _attributeSet.attrs.has(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_SCALE)):
		bullet_scale = _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_SCALE))
		_bullet_scale = bullet_scale.get_current_value()
	else:
		bullet_scale = Attribute.new(AttributeEnum.MissileAttribute.BULLET_SCALE)
		bullet_scale.add_base_value(_bullet_scale)
	bullet_scale.register_value_changed(_on_bullet_scale)

	var bullet_damage: Attribute
	if _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_DAMAGE)):
		bullet_damage = _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_DAMAGE))
		_bullet_damage = bullet_damage.get_current_value()
	else:
		bullet_damage = Attribute.new(AttributeEnum.MissileAttribute.BULLET_DAMAGE)
		bullet_damage.add_base_value(_bullet_damage)
	bullet_damage.register_value_changed(_on_bullet_damage)

	var bullet_life_time: Attribute
	if _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_LIFE_TIME)):
		bullet_life_time = _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_LIFE_TIME))
		_bullet_life_time = bullet_life_time.get_current_value()
	else:
		bullet_life_time = Attribute.new(AttributeEnum.MissileAttribute.BULLET_LIFE_TIME)
		bullet_life_time.add_base_value(_bullet_life_time)
	bullet_life_time.register_value_changed(_on_bullet_life_time)

	var bullet_move_speed: Attribute
	if _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_MOVE_SPEED)):
		bullet_move_speed = _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_MOVE_SPEED))
		_bullet_move_speed = bullet_move_speed.get_current_value()
	else:
		bullet_move_speed = Attribute.new(AttributeEnum.MissileAttribute.BULLET_MOVE_SPEED)
		bullet_move_speed.add_base_value(_bullet_move_speed)
	bullet_move_speed.register_value_changed(_on_bullet_move_speed)

	var bullet_penetrate_max_number: Attribute
	if _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_PENETRATE_MAX_NUMBER)):    
		bullet_penetrate_max_number = _attributeSet.attrs.get(AttributeEnum.get_missile_attribute_name(AttributeEnum.MissileAttribute.BULLET_PENETRATE_MAX_NUMBER))
		_bullet_penetrate_max_number = int(bullet_penetrate_max_number.get_current_value())
	else:
		bullet_penetrate_max_number = Attribute.new(AttributeEnum.MissileAttribute.BULLET_PENETRATE_MAX_NUMBER)
		bullet_penetrate_max_number.add_base_value(_bullet_penetrate_max_number)
	_bullet_penetrate_number = _bullet_penetrate_max_number
	bullet_penetrate_max_number.register_value_changed(_on_bullet_penetrate_max_number)

	

func _physics_process(delta: float) -> void:
	if _bullet_is_live:
		prints("Missile _physics_process -> ", transform.x)
		## 子弹存活，需要更新子弹的位置
		position += _bullet_move_speed * delta * transform.x
		pass
	pass

## 判断子弹是否有碰撞
func _on_bullet_enter(area: Area2D):
	if area.is_in_group(GroupConfig.get_instance().Enemy_Group):
		## 子弹击中敌人
		area.apply_damage(_bullet_damage)
		_bullet_penetrate_number -= 1
		try_recycle()
		pass
	pass

## 子弹生命周期结束时，调用此方法
func _on_bullet_life_timer_timeout():
	recycle()
	_bullet_life_timer.timeout.disconnect(_on_bullet_life_timer_timeout)
	pass

func _on_bullet_scale(value: float):
	_bullet_scale = value
	scale = Vector2(_bullet_scale, _bullet_scale)
	pass

func _on_bullet_damage(value: float):
	_bullet_damage = value
	pass

func _on_bullet_life_time(value: float):
	_bullet_life_time = value
	pass

func _on_bullet_move_speed(value: float):
	_bullet_move_speed = value
	pass

func _on_bullet_penetrate_max_number(value: int):
	var diff = value - _bullet_penetrate_max_number
	_bullet_penetrate_max_number = value
	_bullet_penetrate_number += diff
	pass

## 子弹初始化时，调用此方法，更新子弹的属性
func init(attr: AttributeSet, pool: GamePool) -> void:
	_bullet_is_live = true
	missile_pool = pool
	_attributeSet = attr
	_init_attr()
	_bullet_life_timer.wait_time = _bullet_life_time
	_bullet_life_timer.start()
	_bullet_life_timer.timeout.connect(_on_bullet_life_timer_timeout)
	pass

func try_recycle() -> void:
	if _bullet_penetrate_number > 0:
		return
	else:
		recycle()

## 回收子弹
func recycle() -> void:
	_bullet_is_live = false
	_attributeSet = null
	_bullet_life_timer.stop()
	_bullet_life_timer.timeout.disconnect(_on_bullet_life_timer_timeout)
	missile_pool.recycle_object(self)
	missile_pool = null
	pass
