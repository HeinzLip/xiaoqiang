class_name AttributeBuff extends Resource


## buff的定时器
var _buff_timer: Timer = Timer.new()
## buff的时间
var _buff_time: float = 0.0
## buff是否生效
var _buff_is_live: bool = false;

var _buff_value: float = 0.0

var _buff_ratio_value: float = 0.0

var _buff_release_callback: Callable


func _init(buff_time: float, buff_value: float, buff_ratio_value: float) -> void:
    _buff_time = buff_time
    _buff_value = buff_value
    _buff_ratio_value = buff_ratio_value

    _buff_timer.wait_time = buff_time
    _buff_timer.one_shot = true
    _buff_timer.timeout.connect(_time_out)


func start() -> void:
    _buff_is_live = true
    _buff_timer.start()

func _time_out() -> void:
    _buff_is_live = false
    _buff_release_callback.call(self)
    pass

func set_release_callback(_on_release: Callable) -> void:
    _buff_release_callback = _on_release
