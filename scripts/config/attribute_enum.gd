extends Node

enum AttributeEnum {
    
}
## 飞镖属性
enum DartAttribute {
    ## 飞镖射出的间隔
    DART_FIRE_DELAY,
    ## 飞镖的数量
    DART_NUMBER,
    ## 飞镖的最大飞行距离
    MAX_FLY_DISTANCE,
    ## 飞镖的移动速度
    MOVE_SPEED
}

var dart_attribute_name = {
    DartAttribute.DART_FIRE_DELAY: "dart_fire_delay",
    DartAttribute.DART_NUMBER: "dart_number",
    DartAttribute.MAX_FLY_DISTANCE: "max_fly_distance",
    DartAttribute.MOVE_SPEED: "move_speed",
}

func get_dart_attribute_name(attr: DartAttribute) -> String:
    return dart_attribute_name[attr]

enum MissileAttribute {
    ## 子弹射出的间隔
    BULLET_FIRE_DELAY,
    ## 子弹射出的数量
    BULLET_FIRE_NUMBER,
    ## 子弹发射后的尺寸
    BULLET_SCALE,
    ## 子弹发射后的伤害
    BULLET_DAMAGE,
    ## 子弹发射时的角度
    BULLER_FIRE_ANGLE,
    ## 子弹移动速度
    BULLET_MOVE_SPEED,
    ## 子弹可以穿透的最大次数
    BULLET_PENETRATE_MAX_NUMBER,
    ## 子弹生命周期
    BULLET_LIFE_TIME,
}

var missile_attribute_name = {
    MissileAttribute.BULLET_FIRE_DELAY: "bullet_fire_delay",
    MissileAttribute.BULLET_FIRE_NUMBER: "bullet_fire_number",
    MissileAttribute.BULLET_SCALE: "bullet_scale",
    MissileAttribute.BULLET_DAMAGE: "bullet_damage",
    MissileAttribute.BULLER_FIRE_ANGLE: "buller_fire_angle",
    MissileAttribute.BULLET_MOVE_SPEED: "bullet_move_speed",
    MissileAttribute.BULLET_PENETRATE_MAX_NUMBER: "bullet_penetrate_max_number",
    MissileAttribute.BULLET_LIFE_TIME: "bullet_life_time",
}

func get_missile_attribute_name(attr: MissileAttribute) -> String:
    return missile_attribute_name[attr]


