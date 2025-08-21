extends Weapon

## 子弹发射时间
var _bullet_fire_delay: float = 1.0
## 子弹每次发射的数量
var _bullet_fire_number: int = 1
## 子弹发射后移动速度
var _bullet_fire_speed: float = 1.0
## 子弹发射后的尺寸
var _bullet_scale: float = 1.0
## 子弹发射后的伤害
var _bullet_damage: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
