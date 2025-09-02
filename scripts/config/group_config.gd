class_name GroupConfig

static var sInstance: GroupConfig

static func get_instance() -> GroupConfig:
    if sInstance == null:
        sInstance = GroupConfig.new()
    return sInstance

var Enemy_Group = 'enemy'