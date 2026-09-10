class_name EnemyProjectile extends Area2D
## 远程敌人弹体: 朝发射时锁定的玩家位置直线飞行, 碰到玩家受击区造成伤害, 超时自毁。
## 碰撞: layer 4 / mask 1 —— 只与玩家 Attacked_Area (layer 1, mask 5 含 layer 4) 交互,
##       不与其他敌方弹体/子弹/经验豆互扰 (依赖各对象 layer/mask 组合)。
## 视觉: 复用 assets/effects/spark.png 柔边圆点, 红色染色。

const SPARK_TEXTURE := preload("res://assets/effects/spark.png")

var _damage := 5.0
var _direction := Vector2.ZERO
var _life := 0.0

func configure(from_position: Vector2, target_position: Vector2, damage: float) -> void:
	global_position = from_position
	_direction = from_position.direction_to(target_position)
	_damage = maxf(damage, 0.0)

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	area_entered.connect(_on_area_entered)
	var sprite := Sprite2D.new()
	sprite.texture = SPARK_TEXTURE
	sprite.scale = Vector2.ONE * 7.0
	sprite.modulate = Color(1.0, 0.32, 0.42, 0.95)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= BalanceConfig.RANGED_PROJECTILE_LIFETIME:
		queue_free()
		return
	global_position += _direction * BalanceConfig.RANGED_PROJECTILE_SPEED * delta

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(GroupConfig.get_instance().Player_Attack_Area_Group):
		return
	if is_instance_valid(Global.player):
		Global.player.apply_damage(-_damage)
	queue_free()
