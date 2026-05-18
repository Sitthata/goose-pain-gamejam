class_name BacteriaStats

## Typed stat container for a bacteria tier.
## Use BacteriaStats.for_filth(filth_percent) to get stats — single source of truth.
## Raw _init is available for one-off overrides only.

var tier: int
var scene_tier: int   # 1=small blob, 2=medium glob, 3=humanoid — which scene to load
var max_health: int
var lunge: bool
var spit_cd: float
var death_spits: int
var lunge_cd: float
var lunge_dur: float
var lunge_stains: int
var dodge: float
var jump_enabled: bool
var jump_cd: float
var slam_enabled: bool
var slam_cd: float

func _init(
	p_tier: int,
	p_scene_tier: int,
	p_max_health: int,
	p_lunge: bool,
	p_spit_cd: float,
	p_death_spits: int,
	p_lunge_cd: float,
	p_lunge_dur: float,
	p_lunge_stains: int,
	p_dodge: float,
	p_jump_enabled: bool,
	p_jump_cd: float,
	p_slam_enabled: bool,
	p_slam_cd: float
) -> void:
	tier         = p_tier
	scene_tier   = p_scene_tier
	max_health   = p_max_health
	lunge        = p_lunge
	spit_cd      = p_spit_cd
	death_spits  = p_death_spits
	lunge_cd     = p_lunge_cd
	lunge_dur    = p_lunge_dur
	lunge_stains = p_lunge_stains
	dodge        = p_dodge
	jump_enabled = p_jump_enabled
	jump_cd      = p_jump_cd
	slam_enabled = p_slam_enabled
	slam_cd      = p_slam_cd


## Single source of truth for all 10 stat brackets.
## Tiers map evenly to filth: tier 1 = 0-10%, tier 2 = 10-20%, ..., tier 10 = 90%+
## Moveset unlocks: lunge@tier3, dodge@tier5, jump@tier7, slam@tier9
## Scene changes:   tiers 1-3 = scene 1, tiers 4-6 = scene 2, tiers 7-10 = scene 3
##
## Columns: tier, scene_tier, max_health, lunge, spit_cd, death_spits,
##          lunge_cd, lunge_dur, lunge_stains, dodge, jump, jump_cd, slam, slam_cd
static func for_filth(filth: float) -> BacteriaStats:
	if filth < 10.0: return BacteriaStats.new(1,  1,  80, false, 4.0, 3, 8.0, 0.20, 2, 0.00, false, 3.0, false, 14.0)
	if filth < 20.0: return BacteriaStats.new(2,  1,  90, false, 3.5, 3, 8.0, 0.20, 2, 0.00, false, 3.0, false, 14.0)
	if filth < 30.0: return BacteriaStats.new(3,  1, 100,  true, 3.2, 8, 7.0, 0.25, 2, 0.00, false, 3.0, false, 14.0)
	if filth < 40.0: return BacteriaStats.new(4,  2, 115,  true, 3.0, 7, 7.0, 0.30, 3, 0.00, false, 3.0, false, 13.0)
	if filth < 50.0: return BacteriaStats.new(5,  2, 130,  true, 2.8, 7, 6.0, 0.30, 3, 0.10, false, 3.0, false, 13.0)
	if filth < 60.0: return BacteriaStats.new(6,  2, 145,  true, 2.5, 6, 6.0, 0.35, 3, 0.20, false, 3.0, false, 12.0)
	if filth < 70.0: return BacteriaStats.new(7,  3, 160,  true, 2.3, 6, 6.0, 0.35, 3, 0.20,  true, 12.0, false, 12.0)
	if filth < 80.0: return BacteriaStats.new(8,  3, 175,  true, 2.0, 6, 6.0, 0.40, 3, 0.20,  true, 11.0, true, 12.0)
	if filth < 90.0: return BacteriaStats.new(9,  3, 190,  true, 1.8, 5, 6.0, 0.40, 4, 0.25,  true, 10.0,  true, 10.0)
	return             		BacteriaStats.new(10, 3, 200,  true, 1.5, 5, 6.0, 0.40, 4, 0.25,  true, 10.0,  true, 10.0)
