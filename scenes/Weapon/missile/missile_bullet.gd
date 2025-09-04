extends Weapon

## 子弹发射时间
var _bullet_fire_delay: float = 1.0
## 子弹每次发射的数量
var _bullet_fire_number: int = 3
## 发射子弹的角度
var _bullet_fire_angle: float = 5

@onready var game_pool := $MissileBulletPool

var _fire_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var missile_bullet_scene = preload("res://scenes/Bullet/missile/Missile.tscn")
	game_pool.init(missile_bullet_scene, _bullet_fire_number)
	attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_init_attr()

	_create_timer()

func _init_attr() -> void:
	var bullet_fire_angle = Attribute.new(AttributeEnum.BulletAttrbute.BULLER_FIRE_ANGLE)
	bullet_fire_angle.add_base_value(_bullet_fire_angle)
	attr_set.attrs.set(AttributeEnum.instance.BULLER_FIRE_ANGLE, bullet_fire_angle)
	bullet_fire_angle.register_value_changed(_on_bullet_fire_angle)

	var bullet_fire_delay = Attribute.new(AttributeEnum.BulletAttrbute.BULLET_FIRE_DELAY)
	bullet_fire_delay.add_base_value(_bullet_fire_delay)
	attr_set.attrs.set(AttributeEnum.instance.BULLET_FIRE_DELAY, bullet_fire_delay)
	bullet_fire_delay.register_value_changed(_on_bullet_fire_delay)

	var bullet_fire_number = Attribute.new(AttributeEnum.BulletAttrbute.BULLET_FIRE_NUMBER)
	bullet_fire_number.add_base_value(_bullet_fire_number)
	attr_set.attrs.set(AttributeEnum.instance.BULLET_FIRE_NUMBER, bullet_fire_number)
	bullet_fire_number.register_value_changed(_on_bullet_fire_number)

	
func _create_timer():
	_fire_timer = Timer.new();
	_fire_timer.wait_time = _bullet_fire_delay
	add_child(_fire_timer)
	_fire_timer.start()
	_fire_timer.timeout.connect(_fire_missile_bullet)
	
func _fire_missile_bullet():
	var update_angle = _bullet_fire_angle / (_bullet_fire_number - 1)
	var start_angle = -_bullet_fire_angle / 2
	# var bullet_class = preload("res://scenes/Bullet/missile/Missile.tscn")
	# var bullet_obj = bullet_class.instantiate() as Missile
	# bullet_obj.init(attr_set, game_pool)
	# Global.weapont_system.add_child(bullet_obj)
	for index in range(_bullet_fire_number):
		var bullet = game_pool.get_pool_object()
		bullet.init(attr_set, game_pool)
		var new_rotation = rad_to_deg(global_rotation) + start_angle + update_angle * index 
		if _bullet_fire_number == 1:
			new_rotation = 0;
		bullet.global_rotation = deg_to_rad(new_rotation)
		bullet.global_position = Global.player.global_position
		Global.weapont_system.add_child(bullet)

func _on_bullet_fire_angle(change_value: float) -> void:
	_bullet_fire_angle = change_value

func _on_bullet_fire_delay(change_value: float) -> void:
	_bullet_fire_delay = change_value
	_fire_timer.wait_time = _bullet_fire_delay

func _on_bullet_fire_number(change_value: int) -> void:
	_bullet_fire_number = change_value


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
