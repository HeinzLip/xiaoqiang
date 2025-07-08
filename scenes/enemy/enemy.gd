class_name Enemy extends Area2D

var mPlayer: Player
@export var max_health: float
var current_health: float

var is_attack_player := false


func _ready() -> void:
	current_health = max_health
	mPlayer = Global.player
	#prints("敌人准备完毕")
	
func _process(delta: float) -> void:
	var playerPosition = mPlayer.global_position
	var dis = global_position.distance_to(playerPosition)
	#prints("enemy move is_attack_player ->", )
	if not is_attack_player:
		global_position = position.lerp(playerPosition, 0.1 * delta)
	
func _get_fire_power() -> float:
	return -1

func apply_damage(_damage: float) -> void:
	current_health = clamp(current_health + _damage, 0, max_health)
	#prints("enemy apply damage ->", _damage, "current_health ->", current_health)
	if current_health == 0:
		CountManager.add_destroy_enemy()
		_dead()

func _dead() -> void:
	## 敌人阵亡
	var _bean = EEManager.get_bean()
	_bean.global_position = global_position
	get_tree().current_scene.add_child(_bean)
	queue_free()
	pass

func _on_area_entered(area: Area2D) -> void:
	if area.name == "player_attacked_area":
		## 敌人进入了可以攻击player的攻击范围
		Global.player.apply_damage(_get_fire_power())
		is_attack_player = true
		prints("enemy begin attack player")
	
	if area.name.begins_with("player_bullet"):
		## 敌人进入player的子弹，受到伤害
		apply_damage(area.bullet_damage())
		prints("enemy area enter ->", area.name)


func _on_area_exited(area: Area2D) -> void:
	if area.name == "player_attacked_area":
		is_attack_player = false
