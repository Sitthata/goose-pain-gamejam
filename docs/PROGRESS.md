# GooseJanitor — Progress Tracker

Tracks what is implemented vs. what CONTEXT.md calls for. Cross-referenced against the actual GDScript files.

---

## Done

### Core Systems

| Feature | File(s) | Notes |
|---|---|---|
| **Stain System** (autoload singleton) | `scripts/autoload/StainSystem.gd` | Tracks active Stains, enforces MAX_STAINS cap (20), exposes `get_filth_percent()` |
| **Stain object** | `scenes/systems/stain/stain.gd` | Registers/unregisters with StainSystem; supports `advance_clean`, `reset_clean` |
| **Spit projectile** | `scenes/systems/split/spit.gd` | Arc trajectory (gravity), spawns Stain on impact, plays Splash VFX |
| **Splash VFX** | `scenes/systems/splash/splash.gd` | AnimatedSprite2D one-shot on impact, then frees itself |
| **Filth Gauge UI** | `scenes/ui/filth_gauge/filth_gauge.gd` | Live `%` label reading from StainSystem each frame |

### The Goose (Player)

| Feature | File | Notes |
|---|---|---|
| **Janitor Mode movement** | `scenes/characters/player/player.gd` | Horizontal movement only; no jump in PHASE1 |
| **Goose Boss Mode movement** | same | Run + single jump; faster speed (special_speed) |
| **Clean Action** | same | Hold E → alternate A/D fills per-Stain progress bar → Stain removed |
| **Proximity detection** | same | CleanZone Area2D detects nearby Stains; shows indicator |
| **Punch attack** | same | Punch animation + hit Area2D; deals `punch_damage` to any body with `take_damage()` |
| **Attack telegraphed signal** | same | `attack_telegraphed` signal emitted on punch — Bacteria can react to dodge |

### Bacteria AI

| Feature | File | Notes |
|---|---|---|
| **Tier 1 Bacteria** | `scenes/boss/bacteria_tier1.gd` | Full state machine: IDLE → CHASE → ATTACK → LUNGE → DODGE |
| **Spit attack** | same | Fires arc projectile at player on ATTACK state |
| **Death spit burst** | same | Fires N spits in random upward arc on death |
| **Lunge** | same | Enabled per-tier; deposits trail Stains; duration + cooldown tunable |
| **Dodge** | same | Probability-based; triggered by `attack_telegraphed` signal |
| **`apply_stats()`** | same | Accepts a dict from boss_stage so all tuning lives in one place |

### Game Loop

| Feature | File | Notes |
|---|---|---|
| **Boss Stage orchestrator** | `scenes/stages/boss_stage.gd` | Manages DEFEND / CLEAN phase enum |
| **Defend Phase** | same | Spawns Bacteria, connects `defeated` signal |
| **Clean Phase** | same | Random 5–10s timer; shows countdown; enables Clean Action on player |
| **Filth-to-tier mapping** | same | `_filth_to_tier()`: <20% → T1, <30% → T2, 30%+ → T3 |
| **Difficulty curve (TIER_STATS)** | same | 3 tiers, each with lunge/dodge/spit_cd/death_spits tuned |
| **Respawn after Clean Phase** | same | `_end_clean_phase()` calls `_start_defend_phase()` if filth > 0% |

---

## Not Yet Implemented

| Feature | CONTEXT.md Reference | What's Missing |
|---|---|---|
| **Boss Transformation trigger** | Filth Gauge = 100% → permanent Goose Boss Mode unlock | Mode is currently toggled by a debug key (`switch_mode`), not driven by StainSystem |
| **Goose Boss Mode: simultaneous clean+fight** | Goose Boss Mode only | Phase 2 player is not currently blocked from cleaning during Defend Phase anyway — the phase gating needs to be tightened |
| **Respawn Window** | Goose Boss Mode only — same Bacteria tier respawns 5–6s after defeat at death position | Not implemented; `_win()` is a stub |
| **Win condition** | Filth 0% + Bacteria defeated in Boss Mode | `_win()` in boss_stage.gd is empty |
| **Lose condition** | Explicitly none — game is unloseable | No loss path exists; consistent with design |
| **Contact damage** | TBD | Explicitly deferred post-prototype in CONTEXT.md open questions |
| **Bacteria Tier escalation thresholds** | Threshold-based (TBD) | `_filth_to_tier()` thresholds (20%, 30%) are placeholder values |
| **Double jump / glide** | Goose Boss Mode full moveset | Only single jump implemented |
| **Phase transition animation/effect** | Should Have | No animation or visual cue on mode switch |
| **Sound / audio cues** | Should Have | No audio implementation |
| **Screen shake / hit reaction** | Should Have | No hit feedback |

---

## Partially Implemented / Stubs

| Feature | Status |
|---|---|
| `spit_spawner.gd` | Debug tool (left-click to fire) — not part of game loop |
| Player `phase2_clean` animation | Code path exists; animation may not be authored |
| `_win()` in boss_stage.gd | Stub — no win screen, signal, or state |

---

## Day Milestone Status (from CLAUDE.md)

### Day 1 ✅
- [x] Player horizontal movement
- [x] Stain spawn + clean system
- [x] Player clean action (E + A/D alternation)
- [x] Enemy spawns stain on movement (lunge trail stains)

### Day 2 (Partially Done)
- [x] Simple enemy AI (IDLE/CHASE/ATTACK/LUNGE/DODGE states)
- [x] Boss Stage scene
- [x] Full game loop: Defend → Clean Phase → Respawn Enemy
- [x] Playable prototype
- [ ] Boss Transformation (100% filth triggers Goose Boss Mode)
- [ ] Win condition
- [ ] Respawn Window (Phase 2 mechanic)
