extends Node
class_name GamePool

var _templete: PackedScene
var _pool := []
var _acitve := {}

func init(templete: PackedScene, size: int = 2) -> void:
	_templete = templete
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
	return obj
	
func recycle_object(obj: Node):
	if not obj or not _acitve.has(obj.get_instance_id()):
		return
	_acitve.erase(obj.get_instance_id())
	obj.set_physics_process(false);
	obj.visible = false
	if obj.get_parent() != self:
		obj.reparent(self)
	_pool.append(obj)

func get_active_objects() -> Array[Node]:
	var active_objects: Array[Node] = []
	for object in _acitve.values():
		active_objects.append(object as Node)
	return active_objects

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
