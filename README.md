# Cells of Ruin / 残骸细胞

本地离线的 2D 像素动作 Rogue 游戏（死亡细胞风格玩法，**全部素材为原创生成**，不含任何原版资产）。

## 一键启动

### Windows
双击 `start.bat`。脚本会自动寻找 Godot 4.x（WinGet 安装或 `tools/godot/` 目录）并启动。

### Linux / macOS
```bash
chmod +x start.sh
./start.sh
```

### 手动启动
```bash
godot --path .
```

## 环境要求

- Godot Engine **4.7+**（推荐 4.7.2）
  ```bash
  winget install GodotEngine.GodotEngine
  ```
- 无需网络、无需账号

## 操作

| 操作 | 键位 |
|------|------|
| 移动 | A/D 或 ←/→ |
| 跳跃 | 空格 |
| 翻滚（无敌帧） | Shift 或 L |
| 主武器 | J |
| 副武器 | K |
| 切换副武器 | Q |
| 技能 1 | U |
| 技能 2 | I |
| 交互 / 出口 | E |
| 地图 | Tab |
| 暂停 | Esc |

## 玩法循环

1. 主菜单 → 开始游戏 → 选择存档槽
2. 进入**被囚者牢房**（4×4 程序化房间）
3. 战斗收集**细胞**与**金币**
4. 走到出口按 **E** → **收藏家**
5. 用细胞解锁武器蓝图 / 永久金币上限
6. 继续深入或保存回主菜单
7. 死亡后本局金币与细胞清零（已解锁蓝图永久保留）

## 项目结构

```
project.godot
start.bat / start.sh
scenes/          # 主菜单、关卡、玩家
scripts/
  autoload/      # EventBus / GameState / SaveManager
  player/ combat/ enemies/ level/ items/ ui/
docs/compose/spec/
```

## 存档位置

`user://saves/slot_N.json`（Windows 通常在 `%APPDATA%\Godot\app_userdata\Cells of Ruin\saves\`）

## 文档

- 操作与系统说明：`操作说明.md`
- 真实缺项清单：`缺项清单.md`
- 设计规格：`docs/compose/spec/survival-loop.md`
