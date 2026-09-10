# AGENTS.md

Godot 4.6 开发的双摇杆俯视角 Roguelite 生存射击游戏（2D，1920×1080，Forward+）。

## 常用命令

- **启动编辑器**：`godot4 -e`（当前机器未装 CLI，通常直接打开 Godot 编辑器导入项目）
- **无测试框架**：项目无自动化测试、无 lint/typecheck 命令。验证改动 = 编辑器运行 + 手动 Play
- **程序化生成美术**（Python3 + Pillow）：见 `tools/`，运行时用 `python3 tools/<script>.py`
- **技能表**：`docs/skills.md` 汇总全部技能与专属强化（数值/机制/属性key），**新增或修改技能后必须同步更新**

## 技术栈

- Godot 4.6，GDScript，`config_version=5`
- 主场景：`res://UI/LevelSelect.tscn`（标题/关卡选择），进入 `res://scenes/main/main.tscn`（战斗场景）
- 大量 Autoload 单例（见 project.godot `[autoload]`），全局状态大多挂在单例上而非场景节点

## 目录结构

```
project.godot       引擎配置 + Autoload 注册 + WASD 输入映射
README.md           面向 GitHub/Gitee 的项目介绍、功能模块、主要系统/类与提交记录
skill_list.csv      技能/强化数据表（weapon_name, skill_name, skill_name_zh,
					attribute_name, attribute_value, attribute_type, description）
export_presets.cfg  Web 导出预设

data/               数据层
  csv_load.gd       读取 skill_list.csv -> Dictionary[String, Array[SkillListItem]]
  file_manager.gd   Autoload FileManager，暴露 skill_map
  bean/skill_list_item.gd  CSV 行数据类
  GlobalData.gd     地图移动边界等基础数据

scripts/            逻辑层（多为 Autoload / class_name）
  config/           weapon_type.gd（5种武器字符串常量）、attribute_enum.gd（属性key）、
					attribute_type.gd、group_config.gd（'enemy'分组）、index.gd（枚举）
  Attribute/        属性系统：Attribute（base/add/ratio/current + buff）、AttributeSet、
					AttributeModifier、AttributeBuff
  Skill/            技能/奖励系统（见下）
  manager/          weapon_manager.gd（Autoload：武器解锁与实例化）
  weaponsystem/     WeaponSystem.gd（持有并调度所有武器、通用增益）
  pool/             GamePool.gd（对象池模板）
  CurrencyManager.gd   本局金币 + 永久金币/永久升级（保存到 user://player_progress.cfg）
  CountManager.gd      击杀计数
  LevelProgress.gd     3 关 × 3 难度，每关 waves + boss 配置（含精灵表路径），存档解锁进度
  EnemyExperienceManager.gd 经验掉落对象池（EEManager）
  AudioManager.gd      音效 Autoload（预加载 assets/audio/*.wav，池化播放器叠播）

scenes/             场景与实体（带 .tscn）
  main/             main.gd（波次刷怪/精英/Boss 流程）、Global.gd（Autoload 场景桥）、
					level_tile_map.gd、camera_2d.gd、canvas_layer.gd
  player/           player.gd（WASD移动+受击）、player_visual.gd（AnimatedSprite2D 动画）
  enemy/            enemy.gd（核心敌人逻辑，见下）
  Weapon/           Weapon.gd（基类）+ dart/ missile/ arc/ sound_wave/ ice_spike/ lightning_strike 六种武器
  Bullet/           Dart/drat.gd、missile/missile.gd
  Coin/             金币拾取
  Experience/       经验豆（ExperienceBean 池化）、player_experience_system.gd

UI/                 界面（LevelSelect/SkillLab/UpgradePanel/GameOver/LevelComplete/HUD/SkillChoose）
docs/               项目文档：skills.md、milestones.md、submission_checklist.md
assets/             美术资源（enemies 精灵表、models 3D树、player、tiles、effects）、audio（程序化音效）
tools/              Python 程序化生成脚本（见下）
```

## 音效系统

- `AudioManager`（Autoload）：预加载 `assets/audio/*.wav`，用 8 个池化 `AudioStreamPlayer` 叠播同类音效（不打断已播音效）；各 `play_*` 便捷函数均可传入可选的 `volume_db`
- 武器音效由 `tools/generate_weapon_sfx.py` 程序化合成（numpy 生成 WAV）：missile_fire/hit、dart_fire/hit、arc、sound_wave、ice_spike、lightning
- 接入点：武器发射函数（`_fire*`）+ 子弹命中（`_try_hit_enemy`/`_deal_arc_damage`）。电弧音效有 0.25s 节流避免爆响
- 新增音效：生成 WAV 后加 `_load_stream` + 便捷方法，再在触发点调用；PNG/WAV 需 Godot 重新导入

## 核心系统

### 地图系统（scenes/main/level_tile_map.gd + assets/tiles/）
- **瓦片地图已下掉（暂用）**：`level_tile_map._ready` 与 `main.gd` 中 `configure`/`_place_trees` 调用均已停用，地图不生成瓦片与树
- 瓦片地图（TileMapLayer）：96px 瓦片。**source 0 = `demo1-atlas.png`**（13×13 瓦片：草地 + 水域，水域在右侧列/中部少数格），**source 1 = `cartoon_terrain_atlas.png`**（64px 瓦片：行1 col3-5 高山、col6-7 岩石）
- `level_tile_map.gd` 用 value noise 程序化布局：高山在边缘成环带（`_border_strength`）、湖泊内部成簇、岩石散点；`_pick_terrain` 判定地形；**玩家出生区（中心 ±1/±2 格）强制草地**
- **碰撞**：tile_set 加 physics layer（layer 1，与玩家默认层匹配），湖泊/高山/岩石瓦片设碰撞多边形阻挡玩家；敌人是 Area2D 会穿透
- **树木**：`main.gd` 的 `_place_trees()` 在地图草地格上程序化放置 2D 松树（`assets/tiles/tree_sprites.png`，`tools/generate_tree_sprites.py` 生成，4 棵像素松树，hframes=4），每棵树 = StaticBody2D（collision_layer 1）+ Sprite2D + CircleShape2D 碰撞（半径 30px），阻挡玩家；树位置由 `level_tile_map.get_tree_placements()` 提供（避开出生区、只放草地格）
- **地图范围**：x∈[-10,10] y∈[-20,20]（96px → 世界 ±960/±1920px），与玩家边界（±1000/±2000）匹配
- 地形 atlas：`demo1-atlas.png` 为素材（草/水），`cartoon_terrain_atlas.png` 由 `tools/generate_terrain_atlas.py` 生成（山/岩）

### 技能/奖励系统（scripts/Skill/）
- `SkillDefinition`：不可变定义（Resource）。`Kind`：WEAPON_UNLOCK / ATTRIBUTE_UPGRADE / UNIVERSAL_UPGRADE / GOLD；`AttributeOperation`：BASE_VALUE / CURRENT_VALUE / BASE_SURPLUS_RATIO / BASE_RATIO / CURRENT_RATIO
- `SkillCatalog`（Autoload）：启动时从 CSV 构建全部定义 + 武器解锁/数量/通用/金币奖励
- `SkillService`（Autoload）：`can_offer` 判定可选项、`apply_definition` 应用选择、`build_state`（RunBuildState）记录运行等级/已解锁武器
- `RunBuildState`：单次运行的可变状态（纯 Resource，不碰场景节点）
- `RewardOption`：临时 UI 卡片（引用 definition + 当前等级）
- `skill_pool.gd`（Autoload SkillPool）：奖励生成——升级三选一、精英战利品、金币混合
- `SkillLab.tscn`：从关卡选择页的“技能体验场”进入；一次仅装备一种基础武器，提供无限血量、零攻击、缓慢移动的练习靶，便于观察范围、动画、伤害频率与减速。右侧"专属强化"面板会列出当前武器的全部专属强化（含数量卡），点击即可叠加应用（`SkillService.apply_definition`），可反复点到满级，配"重置强化"按钮（重新装配武器清空等级）。切武器时调用 `SkillService.register_starter_weapon` 解锁武器，否则强化无法应用。
- `EnemyTrial.tscn`（怪物试炼场）：从关卡选择页"怪物试炼场"进入（`UI/enemy_trial.gd`，UI 程序化构建）。玩家**无敌**（`health_changed` 信号先于死亡判定 emit，处理器回满血量即可拦截死亡）+ 默认子弹武器可击杀观察受击/死亡动画。左侧面板选**怪物类型**（骷髅/僵尸/虫/外星/Boss，5 种精灵表）× **原型**（默认/tank/fast/ranged），批量生成 6 只围圈观察移速/血量/远程攻击差异；试炼怪 `experience_reward=0`（击杀不触发升级技能选择，避免无 UIPanel 场景下暂停卡死）。血量基值 `TRIAL_BASE_HP = ENEMY_HP_BY_LEVEL[1]`(40) 直观对比原型乘数（fast=20/tank=120/ranged=20）。

### 经验/升级流程（player_experience_system.gd）
- 吃经验豆升级 -> 队列 `_pending_rewards` -> 暂停游戏弹出技能选择（SkillChoose）-> 玩家三选一 -> 恢复
- 击杀精英 -> `request_elite_reward()` 精英战利品（优先给新武器）
- 升级经验曲线：`60 + (level-1)*18`

### 敌人系统（scenes/enemy/enemy.gd）
- `Area2D`，`setup(wave_config, difficulty_multiplier, elite, boss)` 从波次配置读取数值与精灵表
- **精灵表**：10列×4行 PNG，每格 256×256。row0=idle(6帧)/row1=walk(10帧)/row2=hit(5帧)/row3=death(10帧)。普通怪 scale 0.25、精英 0.47、Boss 0.70
- **方向约定**：`enemy.gd` 的 flip 逻辑 `flip_h = 玩家在左` **假设素材默认面朝右**。素材面朝左的必须翻转（`rebuild_enemy_standard_sheets.py` 的 `flip` 字段控制）。判定朝向用"头相对身体重心偏移"（walk 多帧平均）或眼睛/脸部特征位置，单帧检测不可靠（正面角色、行走摆动会干扰）
- 精英怪数值：血×5、伤×1.75、速×0.75；Boss 有专属金币爆落
- 敌人配置集中在 `LevelProgress.gd` 的 `waves`/`boss`，`resource` 指向精灵表路径
- **敌人原型（archetype）**：波次配置 `"archetype"` 字段指定，数值修正见 `BalanceConfig.ENEMY_ARCHETYPE`——`fast` 快而脆（HP×0.5/速×1.5/伤×0.8）、`tank` 慢而厚（HP×3/速×0.6/伤×1.2）、`ranged` 远程更脆（HP×0.5/速×0.9/伤×0.7）。**远程敌人**：距玩家 ≤`RANGED_ATTACK_RANGE`(380px) 停步开火、射程外追击；弹体 `scenes/enemy/enemy_projectile.gd`（layer 4/mask 1 只与玩家受击区交互，spark.png 红染色，伤害=当前 attack_damage 含难度/原型修正），间隔 `RANGED_ATTACK_INTERVAL`(1.8s)。精英/难度倍率在原型修正之上叠加。**远程开火动画**：`_fire_ranged_projectile()` 会触发一次攻击行动画（`_attack_animation_remaining`，一次性播放、期间站定），仅对含 attack 行的 5 行动画敌人（如骷髅 kulou）生效——目前 L1 第 3 波与 L3 第 3 波为骷髅·ranged（动画可见），外星 alien_creature（4 行无 attack 行）远程开火无动画，如需统一需为其精灵表补 attack 行（后续美术任务）。
- 各怪 flip 现状：rotten_zombie=False(clean_walk 朝右)、kulou=False、evil_bug=True、alien_creature=True、sci_fi_monster=False
- **骷髅敌人**：`assets/enemies/kulou_standard_sheet.png` 由 `tools/rebuild_kulou_sheet.py` 生成——源素材 `kulou_sprite.png` 是 1254×1254 深蓝背景完整图画，**行布局：行1 行走(walk 7帧)、行2 近战攻击(attack 6帧)、行3 受击(hit 7帧)、行4 死亡(death)**。脚本色键抠除背景(18,22,32)+去噪，生成 **5 行标准表 (2560×1280)**：idle/walk/attack/hit/death。**朝向**：源图 walk/hit 朝左需翻转朝右；attack 行大部分帧源图朝右（第6帧 attack5 朝左），逐帧 flip 列表 `[F,F,F,F,F,T,F]` 控制，保证与 walk 一致朝右。骷髅配置 `animation_rows=5`。用于第一关第一波初级敌人
- **敌人 5 行动画支持**：`enemy.gd` 增加 `_has_attack_animation()`（rows>=5 判定）与 `_hit_row()/_death_row()` 动态行索引——有 attack 行时 hit=3/death=4，否则 hit=2/death=3。敌人接触玩家（`is_attack_player`）时播放 attack 行（`ATTACK_FRAME_COUNT=6`）
- **玩家光环区域识别用分组（约定）**：禁止用 `area.name == "player_attacked_area"` 这类字符串匹配（改节点名即静默失效）。Player 的 `Attacked_Area`/`Experience_Area` 在 `player.gd _ready` 里 `add_to_group`（分组名见 `GroupConfig`：`Player_Attack_Area_Group`/`Player_Experience_Area_Group`），敌人/经验豆/金币用 `area.is_in_group(...)` 判断。不要移除 `player.gd` 的加组逻辑

### 武器系统
- 6 种武器：子弹(missile，默认初始，内部类名/文件沿用"导弹")/飞镖(dart)/电弧(arc)/声波(sound_wave)/冰刺(ice_spike)/落雷(lightning)
- `WeaponSystem` 持有所有武器，应用通用增益（伤害/攻速倍率）；各武器通过 `Attribute` 响应属性变化（数量/射速/伤害等）
- `WeaponSystem.clear_weapons()` 仅供技能体验场切换独立武器使用：释放现有武器并重置通用倍率；正常关卡仍随场景释放而清理。
- **子弹/弹幕生命周期**：子弹发射后必须 `reparent(get_tree().current_scene)` 挂到场景根，使世界坐标独立，不随 `WeaponSystem`/玩家移动（`WeaponSystem._process` 每帧把自身移到玩家位置，电弧等环绕武器需要，但子弹不能跟着走）。
- **飞镖复用约定（踩坑）**：飞镖回旋结束 `_complete()` **禁止 `queue_free()`**。飞镖已挂到场景根、不再由武器管理释放，若回旋时释放，`dart_weapon.darts` 数组会持有 freed 引用，下次发射/应用通用强化时报 "null instance" 错误，飞镖武器直接失效。正确做法：`_complete()` 里 `visible=false` + `set_deferred("monitoring", false)` 隐藏停用，等待下次 `fire()` 复用；`dart_weapon` 提供 `_prune_darts()` 防御性清理无效引用，并在 `_exit_tree()` 显式 `queue_free()` 清理仍挂场景根的飞镖。
- **飞镖机制（drat.gd，飞出→旋转→爆炸）**：`dart_weapon._fire()` 把飞镖摆到角色当前位置环形发射；**飞出阶段**沿发射角度匀速前进 1 秒（`FLY_TIME` 固定，覆盖距离成长走 `MOVE_SPEED` 速度卡），每帧用 `_hit_enemies_in_path` 射线判伤——对沿途敌人造成一次**飞行伤害 = `_dart_damage × FLY_DAMAGE_RATIO(0.625)`**（即 0.5，`_hit_enemy_ids` 保证每敌每轮一次）；**旋转阶段**原地旋转（`SPIN_ROTATE_SPEED`）`spin_time`（基础 0.5 秒），每 `SPIN_TICK_INTERVAL`（0.2 秒）用 `get_overlapping_areas()` 对接触敌人造成**0.8** 伤害（依赖 layer/mask：敌人 layer 2 在飞镖 mask 2 内）；**爆炸阶段**瞬发——对**动态半径**内敌人造成 `dart_explosion_damage`（基础 2），随后 `isRunning=false` 触发复用。**爆炸半径动态公式**：`1.2 × 碰撞体实际尺寸(24 × dart_scale 体积) × 爆炸半径卡倍率`，**判伤用"圆 vs 敌人碰撞体 AABB 相交"（与落雷一致）而非中心点**。**没有回旋/归航**。**动效**：飞行 sprite 自旋 + 尾迹、旋转快速自旋 + 圆弧残影、爆炸生成 `DartBurst`（闪光环 + 放射尖刺 + **CPUParticles2D 粒子迸溅**，蓝→金→透明渐变，粒子贴图 `assets/effects/spark.png`）。专属属性（`attribute_enum.gd` + CSV）：`dart_damage`(+10%)、`move_speed` 飞行速度(+10%)、`dart_spin_time`(+20%)、`dart_explosion_damage`(+50%)、`dart_explosion_radius`(+15% 倍率)、`dart_scale`(+10% 体积，同时放大爆炸半径)、数量卡 `dart_number`(+1)。伤害均为正数存储、应用时取负；基础值含永久加成，通用倍率在应用时相乘。**注意：武器伤害刻度(子弹 1.5/飞镖 0.5·0.8·2/电弧 1/声波 0.8/冰刺 0.5/落雷 1)与敌人血量已通过 BalanceConfig 对齐（见"数值平衡框架"章节），剩余经济对齐(Phase4)与实机验收(Phase5)未实施。**
- **飞镖轮次门控与均匀角度（dart_weapon，踩坑）**：`fire_timer` 是 **0.1s 轮询**而非固定发射间隔——只有所有飞镖 `isRunning=false`（上一轮完整播放完旋转+爆炸）才发射下一轮，**禁止**在固定间隔 < 一轮周期（1.5s）时强行重新发射（会把旋转中的飞镖拽回玩家、爆炸永远打不出，且增加数量时角度看起来混乱）。每轮按当前 `darts.size()` 均匀平分角度（`step = TAU / size`，`Vector2.UP.rotated(step*index)`）环形发射——数量卡增加后下一轮自动重排均匀。**通用攻击频率对飞镖无效**（受一轮周期限制，勿在 `set_universal_modifiers` 里用它缩放计时）。**坑：`dart.fire()` 内禁止重置 `rotation`**——发射角度由 `dart_weapon._fire()` 在调用 `fire()` 前通过 `global_rotation` 设置，若 fire() 里 `rotation = 0.0` 会把所有飞镖角度清零，全部朝右发射且重叠成一枚。
- **子弹反弹（专属强化 bullet_reflex_number，展示名"子弹"内部类名仍 Missile/missile）**：反弹=**相机可视区边缘反弹**——下一帧位置超出可视矩形（`_get_visible_world_rect()`：相机中心 ± 视口半尺寸，无相机时退回 `GlobalData` 世界边界）即反射方向（竖边 `global_rotation = PI - rotation`、横边 `global_rotation = -rotation`），每次反弹消耗 1 次；**无反弹次数时子弹离开屏幕即回收销毁**（避免飞出后空转）。反弹属性已在 `missile_bullet.gd._init_attr` 注册并由 `missile.gd._bind_attributes` 绑定。展示名约定：UI/文案用"子弹"，**内部类名/文件名/`WeaponType`/CSV weapon_name 一律不改**（避免 uid 连锁）。
- **电弧伤害记录清理**：`arc_weapon._last_damage_times` 按敌人 instance_id 记录冷却，`_deal_arc_damage` 每次结算时必须顺带清理已不在电弧范围内的记录，防止整局无限增长。
- **运行状态重置**：`main.gd _ready` 需先 `WeaponManager.reset_run()`，保证直接从编辑器运行 main.tscn（不经 LevelSelect）时 Autoload 无上一局残留状态、初始武器注册正常。
- 声波（SoundWave）用 `_lock_origin` 锁定发射原点，挂场景根后完全独立
- 落雷（LightningStrike）从天上随机劈下闪电，**落点在随机敌人的位置附近随机偏移（60px）**（无敌人时回退到玩家周围）；命中半径内敌人并造成伤害（基础半径 15px=初始范围扩大 3 倍、伤害 1、频率 1 秒）。**判伤用"落雷圆 vs 敌人碰撞体 AABB 相交"（考虑 scale），而非敌人中心点距离**，避免敌人渲染部分在范围内却不受伤。**感电用 `enemy.apply_shock(duration)`**：短暂减速 + 敌人身上**挂着大小不一的小电球（5 个，固定布局）+ 电球间闪电连线（中心→电球串联链，中点随时间抖动产生电流蠕动感）**。感电美术为程序化生成的精灵表 `assets/effects/shock_balls.png`（`tools/generate_shock_balls.py`，4 帧×128px，电球+连线动画），由 Enemy 的 `ShockSprite`（Sprite2D，hframes=4，z_index=1 在身体上方）播放：`apply_shock` 显示、`_process` 按帧率切帧、`_shock_remaining` 归零隐藏、死亡时隐藏。ShockSprite 在 `_ready` 抵消父节点 scale（约 110px 世界尺寸）。感电机制：命中后按概率（基础 30%）施加感电（基础持续 1 秒），感电中的敌人再次被落雷击中伤害 +50%（`enemy.is_shocked()` 判断）。专属强化（CSV + 数量卡）：频率+25%（间隔 -0.2 比例）、范围+10%、感电时间+50%（BASE_RATIO 0.5）、感电后伤害+10%（CURRENT_VALUE 0.1）、感电概率+2%（CURRENT_VALUE 0.02）、每次多一道雷
- 冰刺（IceSpike）锁定发射时角色位置，朝最近敌人方向逐刺破土生成持续地面冰晶路径；基础长度 210px、基础宽度 40px、默认持续 1 秒、每 0.2 秒造成 0.5 伤害。横向贴图会按约 52px 一节拆成独立 Sprite2D，每节每 0.055 秒弹出并用 0.12 秒完成向上缩放；伤害判定也只覆盖已长出的长度。不要恢复原先的淡蓝色范围底板，它会在冰刺下方形成明显背影。专属属性：距离（+30px = 0.5米）、宽度（+50%）、持续时间（+50%）、伤害间隔（-0.04秒 = 频率+20%）、减速（+5%）；数量卡会生成扇形多条路径。
- 冰刺（IceSpike）方向实现要点：节点**不旋转不镜像**（`rotation=0`、`scale=1`），保存 `_direction` 方向向量；piece 沿 `_direction * piece_start` 排列实现任意方向（含斜向）延伸，尖刺靠贴图锚点固定朝上；伤害判定用 `offset.dot(_direction)` 投影距离 + 横向偏移宽度。切勿用 `rotation` 旋转节点（向左会刺朝下）或 `scale.x` 镜像（只能左右、斜向失效）

### 敌人死亡
- 敌人 `_dead()` 时立即禁用碰撞（`collision_layer=0` + `monitoring=false`），死亡动画期间子弹可穿透死亡敌人继续前进

### 货币/成长
- 本局金币（局内拾取）+ 永久金币（结算入银行）双轨；永久升级：体魄/迅捷/火力（`CurrencyManager.UPGRADE_INFO`）
- 保存文件：`user://player_progress.cfg`（金币+升级）、`user://level_progress.cfg`（关卡解锁）

### 数值平衡框架（BalanceConfig，单一数据源）
- **`data/balance.gd`（class_name BalanceConfig）是全部平衡数值的唯一入口**：TTK 锚点、敌人血量推导表、统一伤害管道常量、升级/经济曲线、武器基础伤害表。改数值 = 改这一个文件；**新数值一律写进 BalanceConfig，禁止在业务脚本里再散落魔数**。
- **TTK 锚点**：普通怪 3s / 精英 10s / Boss 75s；`PLAYER_MID_DPS = 10`（5 槽满 + 轻度强化）；敌人 HP = TTK × DPS 推导（`ENEMY_HP_BY_LEVEL=[30,40,55]`、`BOSS_HP_BY_LEVEL=[750,1050,1400]`、精英 ×5）。**敌人原型** `ENEMY_ARCHETYPE`（fast/tank/ranged 数值修正）与远程攻击参数（`RANGED_ATTACK_*`）也在本文件。
- **统一伤害管道**：`最终伤害 = base × (1+火力×0.12) × (1+通用伤害×0.10) × (1+Σ专属比例)`——所有武器伤害计算遵守同一乘法顺序。
- **分阶段路线图（当前状态）**：Phase1 ✅ 建 BalanceConfig + 迁移无行为变化的消费方（CurrencyManager 成本/每级值、XP 曲线、player 基础属性）；Phase2 ✅ 六武器基础伤害迁入 `WEAPON_BASE` 表（`dart_weapon`/`drat`/`missile_bullet`/`missile`/`arc_weapon`/`sound_wave_weapon`/`ice_spike_weapon`/`lightning_strike_weapon`），武器侧常量统一读 BalanceConfig；Phase3 ✅ 敌人血量校准（**方案 A 保持量级**）——`LevelProgress` 各关普通怪统一 `ENEMY_HP_BY_LEVEL[30,40,55]`、Boss `BOSS_HP_BY_LEVEL[750,1050,1400]`（精英自动 ×5），波次内血量差异改为靠密度/敌人类型体现；Phase4 ⏳ 经济对齐（目标每局 1~2 次永久升级）；Phase5 ⏳ 实机 TTK 验收。

## 美术资源规范

- **统一画风与清晰度（强制）**：当前项目目标为平滑、干净的 2D 漫画风，主角、怪物、武器特效与地图必须保持一致。默认禁止引入像素风、抖动颗粒（dithering）、胶片颗粒、噪点纹理、密集网点、脏污划痕、细碎高光和 AI 生成的随机小斑点；这些细节在缩小和移动时会变成明显的噪点/闪烁。若确实要使用像素风，必须先单独确认，并将整套资源切换为整数倍缩放与最近邻采样，不能与当前漫画资源混用。
- **按实际显示尺寸验收**：生成源图清晰不等于游戏内清晰。敌人单帧虽为 256×256，但普通怪以 `0.25` 缩放（约 64px 显示）、精英 `0.47`、Boss `0.70`；主角约 `0.38`。新资源必须先模拟/预览到对应运行时尺寸，再判断轮廓、五官、武器和动作是否仍清楚；小尺寸下不清晰时，应简化细节、加粗色块与描边，而不是增加纹理。
- **生成提示词与构图要求**：美术提示词必须包含“clean flat cartoon game art / smooth solid color blocks / thick clean outlines / no grain, no noise, no dithering, no pixel-art texture, no speckles”；主体应占有效画布的大部分，留出有限透明边距。64px 级显示目标下，轮廓应至少保留约 2–3 像素，避免单像素装饰线、细密阴影和随机颗粒。
- **透明边缘与导入检查**：透明 PNG 不得含色键残留、半透明杂点或主体之外的孤立像素（特效粒子除外且须有明确设计意图）。色键转透明后需要检查边缘去色、孤立像素与透明区域；导入 Godot 后还要在技能体验场/关卡实机尺寸下观察静止和移动时是否有锯齿、闪烁或脏边。
- **缩放与采样原则**：非像素漫画资源在缩小显示时应使用平滑采样；对于长期明显缩小的贴图应评估 mipmap，降低移动时的细节混叠。不要仅靠运行时把高细节大图强缩来获得小图；优先导出细节已简化、适合目标尺寸的版本。
- **敌人标准精灵表**：2560×1024，10列×4行，布局见 `assets/enemies/standard_sheet_layout.md`。未用格子保持透明
- 程序化生成/修复脚本（`tools/`）：
  - `generate_elite_enemy.py` 精英怪精灵表（超采样抗锯齿）
  - `rebuild_enemy_standard_sheets.py` 基于原始素材重建普通怪标准表（修复串帧/裁剪/方向/风格）
  - `generate_weapon_sfx.py` 程序化合成武器音效（numpy → WAV）
  - `generate_dart_sprite.py` 飞镖精灵图（4刃手里剑：3钢蓝刃 + 1金刃用于旋转可辨，扁平卡通）→ `assets/effects/dart_shuriken.png`（128px，Dart.tscn Sprite2D scale=0.2 约25px显示）。**抗锯齿要点（v2）**：刃型用二次贝塞尔曲线（消除长斜边阶梯感）、刃尖圆角、8x 超采样 + LANCZOS、均匀 2px 描边；且该贴图 **.import 已开启 mipmaps/generate=true**（长期缩小显示，避免采样闪烁）——新缩小显示的贴图都应开启 mipmap
  - `generate_spark_texture.py` 柔边圆点粒子贴图（CPUParticles2D 用，径向渐变抗锯齿）→ `assets/effects/spark.png`（16px，运行时由 color_ramp 染色）
  - `generate_japanese_cloud_pine.py` / `generate_realistic_pine.py` 3D 树模型（Blender Python）
- **重要**：新 PNG 需 Godot 编辑器重新导入（自动生成 .import）
- 冰刺视觉资源：`assets/effects/ice_spike_single.png`（`tools/generate_ice_spike_single.py` 生成），单根独立尖刺、根部在画布垂直中心（`centered=true` 锚点即根部）；每根刺一个 Sprite2D 沿 `_direction` 排列，`scale.y` 从 0 生长实现每根单独破土刺出。不要用连续的 `ice_spike_barrage.png` 横向贴图切片（那是连续冰条、每段不是独立刺，动画无法单根弹出）

### 敌人精灵表素材选择要点（历史踩坑记录）

- **风格统一**：idle/walk/hit/death 四行动画必须来自同一套素材，避免混用不同风格的 PNG。判定风格看主色调（如僵尸 idle [58,65,46] 与 walk [86,108,75] 是不同风格；与 idle 匹配的 walk 是 `*_walk_aligned.png`，不匹配的是 `cartoon_*`/`clean_*`）
- **僵尸特例**：用户认可的移动风格是 `clean_walk`（亮绿色，86,108,75），因此僵尸 idle 取 `clean_walk_aligned.png` 的 f1 帧（`idle_frame: 1`），walk/hit/death 全部从 clean_walk 派生
- **walk 动画**：用原始帧往返循环（0,1,2,1,...）保留明显换腿；不要用插值补间（会稀释脚步变化、看起来没动画）
- **hit/death 派生**：无原始 hit/death 素材时从 idle 派生——hit 做白色渐显渐隐（正弦包络 0.9*sin(t*π)，先白后恢复）+ 短促后仰；death 做粉碎效果（切成 4×3 碎片向外飞散+旋转+淡出，前 80% 扩散后 20% 淡出，铺满 10 帧）
- **帧数约束**：idle 6 帧 / walk 10 帧 / hit 5 帧 / death 10 帧，多余格子保持透明；death 必须铺满 10 帧（至少 8 帧可见），否则 `enemy.gd` 的死亡动画提前结束

## 约定与注意事项

- **每次完成问题后必须更新本 AGENTS.md**：把本次改动的要点（新增文件/系统、踩坑、约定）同步到对应章节，保证上下文始终反映项目最新状态
- `README.md` 是对外展示文档：上传 GitHub/Gitee 前保持项目介绍、核心功能、主要系统/类、运行方式和提交记录与当前项目状态一致。
- 作业平台提交资料放在 `docs/milestones.md` 与 `docs/submission_checklist.md`；提交前确保 Milestone 区间与实际 Git 历史一致，且敏感信息检查结果仍有效。
- **修改/新增技能后必须同步更新 `docs/skills.md`**：含基础数值、专属强化、属性 key；通用与金币奖励变化也需记录
- 代码含较多中文注释与命名（如 `_spwan_enemy` 拼写为历史遗留，勿动）
- 全局状态尽量走 Autoload（Global/WeaponManager/CurrencyManager 等）；场景切换时部分单例存活需手动重置（见 `Global.reset_world`）
- 修改敌人精灵表时，同时确认：尺寸 2560×1024、帧数布局、不触边、默认面朝右、四行动画风格统一
- 改动敌人美术后需重新运行 `python3 tools/rebuild_enemy_standard_sheets.py`（或 `generate_elite_enemy.py`），且 PNG 需 Godot 重新导入
- 新武器需同时更新：`weapon_type.gd`、`weapon_manager.gd` 的 `_weapon_map`、`SkillCatalog.weapon_names`、对应场景/子弹、`attribute_enum.gd`（属性key）、`skill_list.csv`（专属强化）、`skill_lab.gd`（体验场入口）、`generate_weapon_sfx.py`（音效）
- 新武器完成后，应同步在 `UI/skill_lab.gd` 的按钮映射与说明表中加入入口，确保可立即体验基础效果。
- 无自动化验证手段；改动后建议手动在编辑器中运行 LevelSelect -> 选关 走通流程
