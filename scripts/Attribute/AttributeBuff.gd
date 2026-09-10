class_name AttributeBuff extends Resource

## Buff 的计时器必须加入 SceneTree 才会触发 timeout。
var _buff_timer := Timer.new()
var _buff_time := 0.0
var _buff_is_live := false
var _buff_value := 0.0
var _buff_ratio_value := 0.0
var _buff_release_callback: Callable

func _init(buff_time: float, buff_value: float, buff_ratio_value: float) -> void:
    _buff_time = maxf(buff_time, 0.0)
    _buff_value = buff_value
    _buff_ratio_value = buff_ratio_value
    _buff_timer.wait_time = _buff_time
    _buff_timer.one_shot = true
    # 技能三选一和结算页会暂停游戏；战斗 Buff 在暂停期间不应消耗时间。
    _buff_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
    _buff_timer.timeout.connect(_time_out)

func start() -> void:
    if _buff_is_live:
        return
    _buff_is_live = true
    if _buff_time <= 0.0:
        _time_out.call_deferred()
        return
    var scene_tree := Engine.get_main_loop() as SceneTree
    if scene_tree == null or not is_instance_valid(scene_tree.root):
        push_warning("AttributeBuff: 无法取得 SceneTree，Buff 不会自动过期")
        return
    if _buff_timer.get_parent() == null:
        scene_tree.root.add_child(_buff_timer)
    _buff_timer.start()

func _time_out() -> void:
    if not _buff_is_live:
        return
    _buff_is_live = false
    if _buff_timer.get_parent() != null:
        _buff_timer.get_parent().remove_child(_buff_timer)
    if _buff_release_callback.is_valid():
        _buff_release_callback.call(self)

func set_release_callback(_on_release: Callable) -> void:
    _buff_release_callback = _on_release

func is_live() -> bool:
    return _buff_is_live
