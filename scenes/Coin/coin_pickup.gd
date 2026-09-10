class_name CoinPickup extends Area2D

var coin_value := 1
var move_speed := 900.0
var player: Player

func configure(value: int, auto_attract: bool = false) -> void:
	coin_value = maxi(value, 1)
	if auto_attract:
		player = Global.player
		move_speed = 2200.0

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < 18.0:
		CurrencyManager.add_run_gold(coin_value)
		queue_free()
		return
	global_position = global_position.move_toward(player.global_position, move_speed * delta)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(GroupConfig.get_instance().Player_Experience_Area_Group):
		player = area.get_parent() as Player
