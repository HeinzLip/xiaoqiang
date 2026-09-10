class_name GroupConfig

static var sInstance: GroupConfig

static func get_instance() -> GroupConfig:
    if sInstance == null:
        sInstance = GroupConfig.new()
    return sInstance

var Enemy_Group = 'enemy'
## 玩家"受击判定区"分组: 敌人 Area2D 用它判断是否与玩家近战接触
var Player_Attack_Area_Group = 'player_attack_area'
## 玩家"拾取判定区"分组: 经验豆/金币 Area2D 用它判断是否进入拾取范围
var Player_Experience_Area_Group = 'player_experience_area'