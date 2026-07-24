class_name AttributeEnum

static var _sInstance: AttributeEnum

static var instance: AttributeEnum:
    get:
        if _sInstance == null:
            _sInstance = AttributeEnum.new()
        return _sInstance

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

enum BulletAttrbute {
    ## 飞镖射出的间隔   
    DART_FIRE_DELAY,
    ## 飞镖的数量
    DART_NUMBER,
    ## 飞镖的最大飞行距离
    MAX_FLY_DISTANCE,
    ## 飞镖的移动速度
    MOVE_SPEED,
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
    ## 子弹反射的次数
    BULLET_REFLEX_NUMBER,
    ## 子弹生命周期
    BULLET_LIFE_TIME,
}

## 飞镖射出的间隔
var DART_FIRE_DELAY = "dart_fire_delay"
## 飞镖的数量
var DART_NUMBER = "dart_number"
## 飞镖的最大飞行距离
var MAX_FLY_DISTANCE = "max_fly_distance"
## 飞镖的移动速度
var MOVE_SPEED = "move_speed"

## 子弹射出的间隔
var BULLET_FIRE_DELAY = "bullet_fire_delay"
## 子弹射出的数量
var BULLET_FIRE_NUMBER = "bullet_fire_number"
## 子弹发射后的尺寸
var BULLET_SCALE = "bullet_scale"
## 子弹发射后的伤害
var BULLET_DAMAGE = "bullet_damage"
## 子弹发射时的角度
var BULLER_FIRE_ANGLE = "buller_fire_angle"
## 子弹移动速度
var BULLET_MOVE_SPEED = "bullet_move_speed"
## 子弹可以穿透的最大次数
var BULLET_PENETRATE_MAX_NUMBER = "bullet_penetrate_max_number"
## 子弹反射的次数
var BULLET_REFLEX_NUMBER = "bullet_reflex_number"
## 子弹生命周期
var BULLET_LIFE_TIME = "bullet_life_time"

## 电弧属性
var ARC_RADIUS = "arc_radius"
var ARC_DAMAGE_INTERVAL = "arc_damage_interval"
var ARC_DAMAGE = "arc_damage"
var ARC_THICKNESS = "arc_thickness"

## 声波属性
var SOUND_WAVE_EXPAND_SPEED = "sound_wave_expand_speed"
var SOUND_WAVE_COUNT = "sound_wave_count"
var SOUND_WAVE_SLOW = "sound_wave_slow"
var SOUND_WAVE_PLAYER_SPEED = "sound_wave_player_speed"
var SOUND_WAVE_REBOUND = "sound_wave_rebound"
