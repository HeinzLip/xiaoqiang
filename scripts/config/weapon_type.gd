class_name WeaponType

static var sInstance: WeaponType

static func get_instance() -> WeaponType:
    if sInstance == null:
        sInstance = WeaponType.new()
    return sInstance

var Missile_Weapon = 'missile'
var Dart_Weapon = 'dart'
