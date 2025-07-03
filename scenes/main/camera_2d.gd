extends Camera2D

var player: Player

var gap_side = 100

func _ready() -> void:
	player = get_tree().current_scene.get_node("Player")
	#prints("camera has player ->", player)
	
func _process(delta: float) -> void:
	var game_width = Global.move_max_width
	var game_height = Global.move_max_height
	var player_position = player.global_position
	var camera_global_position = player_position
	var camera_size = Global.camera_size
	var negX = camera_size[0] / 2 - game_width
	var x = game_width - camera_size[0] / 2
	var negY = camera_size[1] / 2 - game_height
	var y = game_height - camera_size[1] / 2
	if camera_global_position.x < negX:
		camera_global_position.x = negX
	elif camera_global_position.x > x:
		camera_global_position.x = x
	if camera_global_position.y < negY:
		camera_global_position.y = negY
	elif camera_global_position.y > y:
		camera_global_position.y = y
		
	global_position = camera_global_position
		
		
	
