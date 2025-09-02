extends Node
class_name GamePool

var _templete: PackedScene
var _pool := []
var _acitve := {}

func init(templete: PackedScene, size : = 2)->void:
	_templete = templete;
	for i in size:
		_pool.append(_create_instance())

func _create_instance() -> Node:
	var inst = _templete.instantiate()
	add_child(inst)
	inst.set_physics_process(false)
	inst.visible = false
	return inst

func get_pool_object() -> Node:
	var obj: Node
	if _pool.size() > 0:
		obj = _pool.pop_back()
	else:
		obj = _create_instance()
	_acitve[obj.get_instance_id()] = obj
	obj.set_physics_process(true)
	obj.visible = true
	return obj;
	
func recycle_object(obj: Node):
	if not obj or not _acitve.has(obj.get_instance_id()):
		return
	obj.set_physics_process(false);
	obj.visible = false
	obj.reparent(self)
	_pool.append(obj)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
