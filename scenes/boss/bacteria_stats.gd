class_name BacteriaStats

## Typed stat container for a bacteria tier.
## Created by boss_stage and consumed by BacteriaTier1.apply_stats().

var tier: int
var lunge: bool
var spit_cd: float
var death_spits: int
var lunge_cd: float
var lunge_dur: float
var lunge_stains: int
var dodge: float
var jump_enabled: bool
var slam_enabled: bool
var slam_cd: float

func _init(
	p_tier: int,
	p_lunge: bool,
	p_spit_cd: float,
	p_death_spits: int,
	p_lunge_cd: float,
	p_lunge_dur: float,
	p_lunge_stains: int,
	p_dodge: float,
	p_jump_enabled: bool,
	p_slam_enabled: bool,
	p_slam_cd: float
) -> void:
	tier         = p_tier
	lunge        = p_lunge
	spit_cd      = p_spit_cd
	death_spits  = p_death_spits
	lunge_cd     = p_lunge_cd
	lunge_dur    = p_lunge_dur
	lunge_stains = p_lunge_stains
	dodge        = p_dodge
	jump_enabled = p_jump_enabled
	slam_enabled = p_slam_enabled
	slam_cd      = p_slam_cd
