class_name BalanceConfig
## ============================================================
## 全局数值统一规划 —— 单一数据源 (BalanceConfig)
## ------------------------------------------------------------
## 原则: 所有平衡数值只在这里定义, 消费方从这里读取, 改数值 = 改这一个文件。
## 锚点: 用"击杀时间 TTK"反推敌人血量, 用"统一伤害管道"规整所有伤害来源。
## 分阶段: Phase1 建本文件+迁移无行为变化的消费方(已完成) / Phase2 武器脚本迁移到
##         管道公式 / Phase3 敌人血量校准(需 HP 走向决策) / Phase4 经济对齐 / Phase5 实机验收
## ============================================================

## ---------- 一、TTK 锚点 (击杀时间, 秒) ----------
const TTK := {
	"normal": 3.0,    # 普通怪
	"elite": 10.0,    # 精英
	"boss": 75.0,     # Boss
}

## ---------- 二、玩家基准 DPS (中期标准构建: 5 槽满 + 轻度强化) ----------
const PLAYER_MID_DPS := 10.0

## ---------- 三、敌人血量 (由 TTK x PLAYER_MID_DPS 推导) ----------
## 普通怪 HP: 各关依次略增 (Phase 3 校准目标; 迁移前 LevelProgress 仍用旧值 28~192)
const ENEMY_HP_BY_LEVEL := [30.0, 40.0, 55.0]
const ELITE_HP_MULTIPLIER := 5.0
## Boss HP (TTK 75s, 逐关递增)
const BOSS_HP_BY_LEVEL := [750.0, 1050.0, 1400.0]

## ---------- 四、统一伤害管道 (乘法顺序固定, 所有武器遵守) ----------
## 最终伤害 = base x (1 + 火力 x PERM_DAMAGE_PER_LEVEL) x (1 + 通用伤害 x UNIVERSAL_DAMAGE_PER_LEVEL)
##            x (1 + Σ 武器专属比例)
const PERM_DAMAGE_PER_LEVEL := 0.12   # 永久升级: 火力
const UNIVERSAL_DAMAGE_PER_LEVEL := 0.10  # 通用强化: 伤害
const UNIVERSAL_RATE_PER_LEVEL := 0.10    # 通用强化: 攻击频率

## ---------- 五、角色成长 (每级数值) ----------
const BASE_MAX_HEALTH := 100.0
const HEALTH_PER_UPGRADE := 20.0
const BASE_MOVE_SPEED := 500.0
const SPEED_PER_UPGRADE := 30.0

## ---------- 六、升级经验曲线 ----------
const XP_BASE := 60.0            # 1 级所需经验
const XP_STEP := 18.0            # 每级增量
const XP_PER_ENEMY := 12.0       # 普通怪经验 (目标: 15~20s/级 ≈ 每级 4~5 杀)

## ---------- 七、永久升级成本 (base + level x step) ----------
const UPGRADE_COST := {
	"health": {"base": 45, "step": 30},
	"speed": {"base": 40, "step": 28},
	"damage": {"base": 60, "step": 40},
}

## ---------- 八、经济目标 (每局) ----------
## 目标: 每局 1~2 次永久升级 → 期望局收入 150~250 金币
const ECONOMY_TARGET_RUN_GOLD := 200

## ---------- 九、武器基础伤害 (当前刻度, Phase 2 迁移目标) ----------
## 迁移前各武器脚本内仍保留各自 base 常量, 迁移后统一从本表读取
const WEAPON_BASE := {
	"missile_damage": 1.5,        # 子弹单发
	"dart_damage": 0.8,           # 飞镖旋转 (飞行 = x0.625)
	"dart_explosion_damage": 2.0, # 飞镖爆炸
	"arc_damage": 1.0,            # 电弧
	"sound_wave_damage": 0.8,     # 声波
	"ice_spike_damage": 0.5,      # 冰刺
	"lightning_damage": 1.0,      # 落雷
}

## ---------- 十、敌人原型 (archetype) ----------
## 波次配置通过 "archetype" 字段指定, 数值修正乘在波次基础值上:
##   fast   移速快但血量低 (脆皮冲脸)
##   tank   移速慢但血量厚 (肉盾推进)
##   ranged 远程攻击、血量更低 (远程威胁, 优先击杀)
const ENEMY_ARCHETYPE := {
	"fast":   {"health": 0.5, "move_speed": 1.5, "attack_damage": 0.8},
	"tank":   {"health": 3.0, "move_speed": 0.6, "attack_damage": 1.2},
	"ranged": {"health": 0.5, "move_speed": 0.9, "attack_damage": 0.7},
}

## 远程敌人攻击参数
const RANGED_ATTACK_RANGE := 380.0     # 进入该距离后停步开火
const RANGED_ATTACK_INTERVAL := 1.8    # 射击间隔 (秒)
const RANGED_PROJECTILE_SPEED := 260.0 # 弹体飞行速度
const RANGED_PROJECTILE_LIFETIME := 3.0

