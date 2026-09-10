# project1

Godot 4.6 开发的 2D 双摇杆俯视角 Roguelite 生存射击游戏。玩家在波次刷怪的战斗场景中移动、拾取经验和金币、升级选择技能，逐步解锁多种自动攻击武器，对抗普通怪、精英怪与 Boss。

## 项目概览

- 引擎：Godot 4.6
- 语言：GDScript
- 渲染：Forward+
- 分辨率：1920 x 1080
- 主入口：`res://UI/LevelSelect.tscn`
- 战斗场景：`res://scenes/main/main.tscn`
- 数据来源：`skill_list.csv`、`data/balance.gd`、`scripts/LevelProgress.gd`

## 核心玩法

- WASD 控制角色移动。
- 武器自动瞄准、自动攻击，玩家主要负责走位、生存和成长选择。
- 击杀敌人掉落经验豆，拾取后升级并弹出三选一奖励。
- 精英敌人提供更高价值的战利品，Boss 用于关卡阶段验收。
- 本局金币和永久金币分离，永久金币可用于局外成长升级。
- 关卡包含 3 个关卡、3 个难度，并通过存档记录解锁进度。

## 已实现功能

- 关卡选择、技能体验场、怪物试炼场、战斗 HUD、技能选择、结算与失败界面。
- 普通怪、精英怪、Boss、远程敌人和不同敌人原型：`fast`、`tank`、`ranged`。
- 经验系统、金币系统、永久成长系统和关卡解锁系统。
- 武器解锁、专属强化、数量卡、通用伤害/频率强化、金币奖励。
- 对象池：经验豆等可复用对象减少频繁创建释放。
- 程序化音效系统：武器发射、命中、电弧、声波、冰刺、落雷等。
- 每局战斗会播放独立的循环背景音乐，通关、失败或离开正式战斗场景时淡出停止。
- 数值平衡集中管理：`BalanceConfig` 作为 TTK、血量、经济、武器基础伤害的单一入口。

## 武器系统

当前包含 6 种武器：

| 武器 | 内部名称 | 说明 |
| --- | --- | --- |
| 子弹 | `missile` | 默认初始武器，扇形发射直线子弹，支持穿透和屏幕边缘反弹 |
| 飞镖 | `dart` | 环形均匀发射，飞出后原地旋转并爆炸，节点复用 |
| 电弧 | `arc` | 围绕玩家的持续环形伤害区域 |
| 声波 | `sound_wave` | 从发射点扩散的圆形波，命中可减速并支持回弹 |
| 冰刺 | `ice_spike` | 朝最近敌人方向逐段破土生成冰刺路径 |
| 落雷 | `lightning` | 随机锁定敌人附近落雷，支持感电和二次增伤 |

详细数值和专属强化见：

- `docs/skills.md`
- `skill_list.csv`
- `data/balance.gd`

## 主要目录

```text
project.godot       Godot 项目配置、Autoload、输入映射
skill_list.csv      技能与专属强化数据表
docs/skills.md      技能、武器和强化说明
data/               数据读取、全局数据、数值平衡
scripts/            Autoload、属性系统、技能系统、武器管理、对象池等
scenes/             战斗主场景、玩家、敌人、武器、子弹、金币、经验
UI/                 关卡选择、HUD、技能选择、结算、试炼场等界面
assets/             角色、敌人、特效、地图、音频等资源
tools/              程序化生成美术和音效的 Python 脚本
```

## 主要系统与类

### 全局单例

| 单例 | 文件 | 职责 |
| --- | --- | --- |
| `FileManager` | `data/file_manager.gd` | 读取技能 CSV 并暴露技能映射 |
| `SkillCatalog` | `scripts/Skill/SkillCatalog.gd` | 构建全部技能定义、武器解锁、通用奖励和金币奖励 |
| `SkillService` | `scripts/Skill/SkillService.gd` | 判断奖励是否可选、应用技能、维护单局构筑状态 |
| `SkillPool` | `scripts/Skill/skill_pool.gd` | 生成升级奖励、精英奖励、金币混合奖励 |
| `Global` | `scenes/main/Global.gd` | 场景桥接和运行时全局状态 |
| `EEManager` | `scripts/EnemyExperienceManager.gd` | 经验豆对象池管理 |
| `PlayerExperienceSystem` | `scenes/Experience/player_experience_system.gd` | 经验、升级、奖励队列和暂停弹窗流程 |
| `CountManager` | `scripts/CountManager.gd` | 击杀计数 |
| `WeaponManager` | `scripts/manager/weapon_manager.gd` | 武器解锁、实例化和单局重置 |
| `LevelProgress` | `scripts/LevelProgress.gd` | 关卡、难度、波次、Boss 与解锁存档 |
| `CurrencyManager` | `scripts/CurrencyManager.gd` | 本局金币、永久金币和永久升级 |
| `AudioManager` | `scripts/AudioManager.gd` | 音效预加载和池化播放 |

### 战斗实体

- `scenes/player/player.gd`：玩家移动、受击、血量和关键碰撞区域分组。
- `scenes/player/player_visual.gd`：玩家动画表现。
- `scenes/enemy/enemy.gd`：敌人移动、受击、死亡、精英/Boss 数值、远程攻击、感电表现。
- `scenes/enemy/enemy_projectile.gd`：远程敌人弹体。
- `scenes/main/main.gd`：战斗主流程、波次刷怪、精英、Boss、结算。
- `scenes/main/camera_2d.gd`：相机跟随。

### 技能与属性

- `SkillDefinition`：技能定义资源，区分武器解锁、属性强化、通用强化和金币奖励。
- `RunBuildState`：单局构筑状态，记录已解锁武器和各强化等级。
- `RewardOption`：UI 奖励卡片临时数据。
- `Attribute` / `AttributeSet` / `AttributeModifier` / `AttributeBuff`：基础值、加值、倍率、当前值和 Buff 管线。

### 武器与弹体

- `scenes/Weapon/Weapon.gd`：武器基类。
- `scripts/weaponsystem/WeaponSystem.gd`：持有并调度所有武器，应用通用增益。
- `scenes/Weapon/missile/`：子弹武器与子弹行为。
- `scenes/Weapon/dart/`、`scenes/Bullet/Dart/`：飞镖武器、飞镖弹体和爆炸特效。
- `scenes/Weapon/arc/`：电弧武器。
- `scenes/Weapon/sound_wave/`：声波武器与声波实体。
- `scenes/Weapon/ice_spike/`：冰刺武器与冰刺路径。
- `scenes/Weapon/lightning_strike/`：落雷武器与落雷实体。

## 数据与存档

- 技能数据：`skill_list.csv`
- 技能说明：`docs/skills.md`
- 数值平衡：`data/balance.gd`
- 永久金币和永久升级存档：`user://player_progress.cfg`
- 关卡解锁进度存档：`user://level_progress.cfg`

## 运行方式

本机如果安装了 Godot CLI，可以在项目根目录运行：

```bash
godot4 -e
```

当前项目通常直接通过 Godot 编辑器导入项目并运行：

1. 打开 Godot 4.6。
2. 导入本项目根目录。
3. 运行主场景 `res://UI/LevelSelect.tscn`。
4. 从关卡选择页进入正式关卡、技能体验场或怪物试炼场。

## 开发约定

- 项目暂无自动化测试、lint 或 typecheck 命令，改动后主要通过 Godot 编辑器手动 Play 验证。
- 新增或修改技能、武器强化时，必须同步更新 `docs/skills.md`。
- 新武器需要同步更新武器类型、武器管理器、技能目录、属性 key、CSV、技能体验场入口和音效生成脚本。
- 新 PNG/WAV 资源需要让 Godot 编辑器重新导入生成对应 `.import` 文件。
- 平衡数值优先放入 `data/balance.gd`，避免在业务脚本中分散魔数。

## 作业提交资料

- Milestone 划分建议：`docs/milestones.md`
- 提交前检查清单：`docs/submission_checklist.md`
- 技能与强化说明：`docs/skills.md`

## 提交记录

| 提交 | 日期 | 说明 |
| --- | --- | --- |
| `47f3125` | 2025-07-03 | 首次提交，建立项目基础结构 |
| `bf08227` | 2025-07-03 | 调整文件和格式 |
| `e569126` | 2025-07-03 | 调整全局单例初始化逻辑 |
| `12e2c24` | 2025-07-07 | 调整游戏重置逻辑 |
| `bc33d50` | 2025-07-08 | 继续调整游戏重置逻辑 |
| `d351e32` | 2025-08-16 | 增加 UI 选择技能点逻辑 |
| `6cf493d` | 2025-08-21 | 增加新武器 |
| `706f87a` | 2025-08-29 | 增加对象池 |
| `2599dbf` | 2025-08-31 | 增加新子弹 |
| `5d836d1` | 2025-09-02 | 增加新的子弹能力 |
| `241e6fe` | 2025-09-04 | 调整技能列表 |
| `2ec60cf` | 2025-09-05 | 调整武器系统 |
| `c3ff73f` | 2026-07-24 | 完善游戏内容 |
| `a28b724` | 2026-09-10 | 更新游戏逻辑 |

## Git 远程仓库建议

项目可以同时保留 GitHub 和 Gitee 两个远程仓库。例如：

```bash
git remote rename origin gitee
git remote add origin git@github.com:<your-name>/<repo-name>.git
```

之后分别推送：

```bash
git push origin develop:develop
git push gitee develop:develop
```
