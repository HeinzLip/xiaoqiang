class_name GameMain extends Node2D

@onready var enemyPath := $Camera2D/Path2D/PathFollow2D
@onready var enemy_timer := $Timer

@onready var weapon_system := $WeaponSystem
@onready var skill_ui: CanvasLayer = $UIPanel

func _ready() -> void:
	#var v1 = Vector3(0.575, -0.1134, -0.81)
	#var v2 = Vector3(0.0005, -0.004141, -0.000743)
	#var v3 = Vector3(0.578, -0.1166, -0.81)
	#var v4 = Vector3(0.0052, -0.00135, -0.0026)
	#var dir = v1.dot(v2.normalized())
	#var dir1 = v3.dot(v4.normalized())
	#prints("dir ->", dir, "dir1 ->", dir1)	

	FileManager.get_csv_data("res://skill_list.csv")
	
	# var dart_weapon_class = preload("res://scenes/Weapon/dart/DartWeapon.tscn")
	# var dart_weapon_obj = dart_weapon_class.instantiate()
	# weapon_system.add_weapon(WeaponType.Dart_Weapon, dart_weapon_obj)
	# var missile_weapon_class = preload("res://scenes/Weapon/missile/MissileBullet.tscn")
	# var missile_weapon_obj = missile_weapon_class.instantiate()
	# weapon_system.add_weapon(WeaponType.Missile_Weapon, missile_weapon_obj)
	#skill_ui.visible = false
	
	#var timer = Timer.new();
	#timer.wait_time = 0.5
	#timer.timeout.connect(_test_skill_ui)
	#add_child(timer)
	#timer.start()
	pass

#func _test_skill_ui() -> void:
	#skill_ui.show_skill_panel()

#func _add_attribute():
	#var dart_weapon = weapon_system.find_weapon("dart_weapon") as DartWeapon
	#var dart_number_attr = dart_weapon.attr_set.find_attr("dart_number")
	#if dart_number_attr:
		#dart_number_attr.add_current_value(1)
	#pass

func _spwan_enemy():
	enemyPath.progress_ratio = randf()
	var enemy_position = enemyPath.global_position
	var enemy_class = preload("res://scenes/enemy/Enemy.tscn")
	var enemy_obj = enemy_class.instantiate()
	enemy_obj.global_position = enemy_position;
	get_tree().current_scene.add_child(enemy_obj)
	#prints("生成一个敌人")


func _on_enemy_spwan() -> void:
	_spwan_enemy()
	
