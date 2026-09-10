---
feature: survival-loop
status: delivered
updated: 2026-09-11
branch: feature/survival-loop
commits: pending
---

# 生存闭环（被囚者牢房可玩）

## Report

**What was built** — Godot 4.7.2 本地离线 2D 像素动作 Rogue《Cells of Ruin / 残骸细胞》。含中文主菜单、被囚者牢房 4×4 程序化关卡、玩家移动/跳跃/翻滚无敌帧/近战三连/木盾招架/弓箭/冰冻手雷、四种敌人 AI、细胞金币经济、收藏家蓝图解锁与永久升级、三槽位 JSON 存档、火炬 PointLight2D 与粒子打击反馈。`start.bat` 一键启动；冒烟测试与运行截图见 `docs/screenshots/`。

**Verification** — `godot --headless --script tools/smoke_test.gd` → SMOKE_PASS（菜单加载、关卡生成、24 敌人、玩家存在、存档读写）。`tools/capture.gd` 实机渲染截图成功（1280×720）。全部源文件 UTF-8 校验通过。

**Journey log**
1. winget 安装 Godot 4.7.2；空仓库未用 worktree（沙箱限制），直接在 `feature/survival-loop` 分支开发。
2. `level.tscn` 曾被 PowerShell 截断中文 UTF-8 导致解析失败——整文件重写修复。
3. GDScript 禁止 `var exit`、嵌套 `for x` 与外层同名、`path[-1]` 与未标注类型推断——改为显式命名与 `path.size()-1`。
4. `--script` 的 SceneTree 早期无法用全局 autoload 标识符，冒烟测试改 `root.get_node("GameState")`。
5. 像素生成越界 `y=40`（height=40）——钳制坐标后通过。

## [S1] Problem
玩家需要一款可本地离线一键启动的 2D 像素动作 Rogue 游戏，首期交付《死亡细胞》式核心生存闭环：进入牢房、战斗收集、通过关卡、收藏家升级、退出重载后继续。禁止空壳菜单与假按钮。

## [S2] Design

### 技术与启动
- 引擎：Godot 4.7.2（winget）
- 主场景：`res://scenes/ui/main_menu.tscn`
- 一键启动：`start.bat` / `start.sh`
- 中文 UI 硬编码；基准 1920×1080

### 架构
autoload：EventBus / GameState / SaveManager  
scenes：main_menu、level、player  
scripts：player / combat / enemies / level / items / ui

### 玩家
移动、跳跃、翻滚无敌帧、J 近战、K 副武器（盾/弓，Q 切换）、U 冰雷、E 交互

### 敌人
僵尸 / 蝙蝠 / 掷弹兵 / 自杀蝙蝠；攻击前摇 `!` 预警

### 关卡
4×4 网格通路生成，种子可查看，火炬动态光源

### 经济
细胞→收藏家解锁蓝图与金币上限；死亡清零局内资源；三槽 JSON 存档

## [S3] Out of Scope
多群系、BOSS、变异、符文、BSC、音频、完整法线管线 — 详见 `缺项清单.md`

## Tasks
- [x] T1: Godot 项目骨架 project.godot + start.bat — acceptance: start.bat 能启动游戏
- [x] T2: 玩家移动跳跃翻滚攻击受击死亡 — acceptance: 可操作并有 hitstop/无敌帧
- [x] T3: 生锈之剑+木盾招架+弓+冰雷 — acceptance: 武器与技能可用
- [x] T4: 敌人 AI 四种 — acceptance: 可被击杀且有预警
- [x] T5: 4×4 程序化牢房 — acceptance: 种子不同布局不同
- [x] T6: 细胞金币与收藏家解锁 — acceptance: 解锁写入存档
- [x] T7: 存档读档多槽 — acceptance: 退出重载恢复进度
- [x] T8: 中文主菜单/HUD/暂停/死亡 — acceptance: 无假按钮
- [x] T9: 火炬光照粒子 — acceptance: 运行可见动态光源
- [x] T10: 验证截图与缺项清单 — acceptance: 文档列出真实缺项
