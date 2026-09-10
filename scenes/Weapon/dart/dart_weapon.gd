class_name DartWeapon extends Weapon

## 飞镖机制: 环形均匀发射 -> 飞出 1 秒(飞行伤害=旋转x0.625) -> 原地旋转 spin_time 秒造成伤害 -> 爆炸(动态半径) -> 复用。
## 轮次门控: 上一轮飞镖全部完成(全部 isRunning=false)后才发射下一轮, 避免打断旋转/爆炸;
## 每轮按当前飞镖数量均匀平分角度发射 (step = TAU / size), 数量卡增加后自动重排为均匀分布。
## 注意: 飞镖受一轮完整周期限制, 通用攻击频率对其无加速效果。

const VOLLEY_POLL_INTERVAL := 0.1    # 轮询间隔: 上一轮完成后 ≤0.1s 发射下一轮
const DART_BASE_DAMAGE := BalanceConfig.WEAPON_BASE["dart_damage"]            # 旋转阶段伤害 (飞行 = x0.625)
const DART_BASE_FLY_SPEED := 420.0   # 飞行速度 (飞行速度卡 +10%/级)
const DART_BASE_SPIN_TIME := 0.5     # 旋转时间
const DART_BASE_EXPLOSION_DAMAGE := BalanceConfig.WEAPON_BASE["dart_explosion_damage"] # 爆炸伤害
const DART_BASE_EXPLOSION_RADIUS := 1.0 # 爆炸半径倍率 (实际 = 1.2 x 碰撞体尺寸 x 体积 x 此倍率)
const DART_BASE_SCALE := 1.0

var dart_number := 3
var fire_timer: Timer
var darts: Array[Dart] = []
var _universal_damage_multiplier := 1.0

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_add_attribute(AttributeEnum.instance.DART_NUMBER, dart_number, _dart_number_change)
	# 以下属性由飞镖子弹直接绑定消费, 武器侧只负责注册基准值
	_add_attribute(AttributeEnum.instance.DART_DAMAGE, DART_BASE_DAMAGE * CurrencyManager.get_damage_multiplier(), func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.MOVE_SPEED, DART_BASE_FLY_SPEED, func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.DART_SPIN_TIME, DART_BASE_SPIN_TIME, func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.DART_EXPLOSION_DAMAGE, DART_BASE_EXPLOSION_DAMAGE * CurrencyManager.get_damage_multiplier(), func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.DART_EXPLOSION_RADIUS, DART_BASE_EXPLOSION_RADIUS, func(_value: float): pass)
	_add_attribute(AttributeEnum.instance.DART_SCALE, DART_BASE_SCALE, func(_value: float): pass)
	_update_dart_count()
	fire_timer = Timer.new()
	add_child(fire_timer)
	fire_timer.timeout.connect(_fire)
	fire_timer.wait_time = VOLLEY_POLL_INTERVAL
	fire_timer.start()

func _add_attribute(key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[key] = attribute

func _fire() -> void:
	_prune_darts()
	if darts.is_empty():
		return
	# 轮次门控: 仍有飞镖在运行(上一轮未结束)时跳过, 不打断其旋转/爆炸
	for dart in darts:
		if is_instance_valid(dart) and dart.isRunning:
			return
	# 全部空闲: 按当前飞镖数量均匀平分角度环形发射
	var step := TAU / float(darts.size())
	for index in range(darts.size()):
		var dart := darts[index]
		if not is_instance_valid(dart):
			continue
		# 发射时挂到场景根, 使飞镖世界坐标独立, 不随 WeaponSystem/玩家移动
		var dart_parent := get_tree().current_scene
		if dart.get_parent() != dart_parent:
			dart.reparent(dart_parent)
		dart.global_position = Global.player.global_position
		dart.global_rotation = Vector2.UP.rotated(step * index).angle()
		dart.fire()
	AudioManager.play_dart_fire(-8.0)

func _dart_number_change(value: float) -> void:
	dart_number = maxi(roundi(value), 1)
	_update_dart_count()

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	# 飞镖受一轮完整周期限制, 通用攻击频率(attack_rate_multiplier)无加速效果
	_update_dart_count()
	for dart in darts:
		if is_instance_valid(dart):
			dart.set_universal_damage_multiplier(_universal_damage_multiplier)

func _update_dart_count() -> void:
	_prune_darts()
	_update_bullet_obj(maxi(dart_number, 1) - darts.size())

## 移除数组中已释放/无效的飞镖引用 (防御性清理, 防止持有 freed 实例)
func _prune_darts() -> void:
	for index in range(darts.size() - 1, -1, -1):
		if not is_instance_valid(darts[index]):
			darts.remove_at(index)

## 飞镖在发射后挂到场景根, 不再由自身释放; 武器释放时必须显式清理它们
func _exit_tree() -> void:
	for dart in darts:
		if is_instance_valid(dart):
			dart.queue_free()
	darts.clear()

func _update_bullet_obj(add_count: int) -> void:
	if add_count <= 0:
		return
	var dart_scene := preload("res://scenes/Bullet/Dart/Dart.tscn")
	for index in range(add_count):
		var dart := dart_scene.instantiate() as Dart
		dart.set_attribute(attr_set)
		dart.set_universal_damage_multiplier(_universal_damage_multiplier)
		add_child(dart)
		darts.append(dart)
