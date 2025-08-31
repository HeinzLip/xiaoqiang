extends Area2D

## 子弹移动速度
var _bullet_move_speed: float
## 子弹可以穿透总次数
var _bullet_penetrate_max: float
## 子弹穿透次数
var _bullet_penetrate_number: float
## 子弹属性
var _attributeSet: AttributeSet
## 子弹是否存活
var _bullet_is_live: bool = false

func _ready() -> void:
    area_entered.connect(_on_bullet_enter)
    pass

func _physics_process(delta: float) -> void:
    if _bullet_is_live:
        ## 子弹存活，需要更新子弹的位置
        pass
    pass

## 判断子弹是否有碰撞
func _on_bullet_enter():
    pass

## 子弹初始化时，调用此方法，更新子弹的属性
func init() -> void:
    _bullet_is_live = true
    pass

## 回收子弹
func recycle() -> void:
    _bullet_is_live = false
    pass 