extends Node
class_name GamePool

var _templete: PackedScene
var _pool := []
var _acitve := {}

func init(templete: PackedScene, size : = 2)->void:
	_templete = templete;
	for i in size:
		_pool.append(_create_instance())

func _create_instance():
	var inst = _templete.instantiate()
	add_child(inst)
	inst.set_physics_process(false)
	inst.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
