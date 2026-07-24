extends ColorRect

@onready var wallet_label: Label = $CenterPanel/Content/WalletLabel
@onready var health_label: Label = $CenterPanel/Content/HealthRow/Content/Info
@onready var speed_label: Label = $CenterPanel/Content/SpeedRow/Content/Info
@onready var damage_label: Label = $CenterPanel/Content/DamageRow/Content/Info
@onready var health_button: Button = $CenterPanel/Content/HealthRow/Content/UpgradeButton
@onready var speed_button: Button = $CenterPanel/Content/SpeedRow/Content/UpgradeButton
@onready var damage_button: Button = $CenterPanel/Content/DamageRow/Content/UpgradeButton
@onready var close_button: Button = $CenterPanel/Content/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	health_button.pressed.connect(_purchase_upgrade.bind("health"))
	speed_button.pressed.connect(_purchase_upgrade.bind("speed"))
	damage_button.pressed.connect(_purchase_upgrade.bind("damage"))
	close_button.pressed.connect(hide)
	CurrencyManager.banked_gold_changed.connect(_on_banked_gold_changed)
	_refresh()

func _purchase_upgrade(upgrade_key: String) -> void:
	CurrencyManager.purchase_upgrade(upgrade_key)
	_refresh()

func _on_banked_gold_changed(_amount: int) -> void:
	_refresh()

func _refresh() -> void:
	wallet_label.text = "永久金币  %d" % CurrencyManager.banked_gold
	_refresh_upgrade("health", health_label, health_button)
	_refresh_upgrade("speed", speed_label, speed_button)
	_refresh_upgrade("damage", damage_label, damage_button)

func _refresh_upgrade(upgrade_key: String, info_label: Label, upgrade_button: Button) -> void:
	var level := CurrencyManager.get_upgrade_level(upgrade_key)
	var cost := CurrencyManager.get_upgrade_cost(upgrade_key)
	info_label.text = "%s  Lv.%d\n%s" % [
		CurrencyManager.get_upgrade_name(upgrade_key),
		level,
		CurrencyManager.get_upgrade_description(upgrade_key),
	]
	upgrade_button.text = "升级  %d 金币" % cost
	upgrade_button.disabled = CurrencyManager.banked_gold < cost
