class_name WeaponDB
## Static weapon/skill definitions. Original values only — not copied from Dead Cells data tables.

const WEAPONS := {
	"rusty_sword": {
		"name": "生锈之剑",
		"type": "melee",
		"damage": 18,
		"combo": [18, 18, 28],
		"cooldown": 0.28,
		"range": Vector2(48, 28),
		"color": Color(0.75, 0.75, 0.78),
		"desc": "可靠的近战三连击。",
		"cost": 0,
	},
	"wooden_shield": {
		"name": "木盾",
		"type": "shield",
		"damage": 0,
		"parry_window": 0.28,
		"cooldown": 0.45,
		"color": Color(0.55, 0.4, 0.22),
		"desc": "招架成功可反弹并短暂眩晕敌人。",
		"cost": 0,
	},
	"beginner_bow": {
		"name": "初学者弓",
		"type": "ranged",
		"damage": 14,
		"cooldown": 0.55,
		"projectile_speed": 720,
		"color": Color(0.7, 0.55, 0.3),
		"desc": "击杀后有概率回收箭矢。",
		"cost": 0,
	},
	"ice_bow": {
		"name": "冰之弓",
		"type": "ranged",
		"damage": 12,
		"cooldown": 0.7,
		"projectile_speed": 640,
		"freeze": true,
		"color": Color(0.55, 0.8, 0.95),
		"desc": "命中时短暂冻结敌人。",
		"cost": 25,
	},
	"double_dagger": {
		"name": "双匕首",
		"type": "melee",
		"damage": 14,
		"combo": [14, 14, 22],
		"cooldown": 0.18,
		"range": Vector2(36, 22),
		"color": Color(0.85, 0.85, 0.9),
		"desc": "极速三连刺。",
		"cost": 30,
	},
	"assassin_dagger": {
		"name": "刺客匕首",
		"type": "melee",
		"damage": 20,
		"combo": [20],
		"cooldown": 0.35,
		"range": Vector2(40, 24),
		"crit_from_behind": true,
		"color": Color(0.4, 0.2, 0.35),
		"desc": "背刺必定暴击。",
		"cost": 40,
	},
}

const SKILLS := {
	"ice_grenade": {
		"name": "冰冻手雷",
		"damage": 20,
		"cooldown": 6.0,
		"radius": 72,
		"color": Color(0.6, 0.85, 1.0),
		"desc": "投掷冰冻弹，冻结范围内敌人。",
	},
	"fire_grenade": {
		"name": "燃烧手雷",
		"damage": 28,
		"cooldown": 7.0,
		"radius": 64,
		"burn": true,
		"color": Color(1.0, 0.45, 0.2),
		"desc": "引燃区域，持续灼烧。",
	},
}

static func weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["rusty_sword"])

static func skill(id: String) -> Dictionary:
	return SKILLS.get(id, {})

static func all_weapon_ids() -> Array:
	return WEAPONS.keys()
