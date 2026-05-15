# GooseJanitor

A Godot 4 boss battle game jam entry. You play as a goose janitor defending your room from bacteria. The room's cleanliness is the health system.

## Language

**The Goose**:
The player character. A powerful goose who is the boss of the room. Fights Bacteria and cleans Stains to defend the room.
_Avoid_: goose janitor, goose boss, the player, protagonist



**Room**:
The single arena where all gameplay takes place. The Goose defends it from Bacteria. Its cleanliness is tracked by the Filth Gauge.
_Avoid_: level, stage, arena, map

**Stain**:
A static green puddle left on the floor or wall by bacteria. The physical object in the game world.
_Avoid_: filth, dirt, puddle, pollution

**Filth Gauge**:
The UI meter showing `active_stains / MAX_STAINS * 100`. Represents how dirty the room is. Drives enemy scaling.
_Avoid_: stain gauge, health bar, dirt meter

**Bacteria**:
The enemy. A ground-dwelling microorganism that chases the player, attacks, and spawns Stains. Always fought 1v1. Has its own HP separate from the Filth Gauge.
_Avoid_: enemy, monster, boss, bacterium

**Bacteria Tier**:
An evolution of the Bacteria. Each tier is a separate Godot scene with higher stats and new moves. Spawns when the previous tier is defeated and the room is not fully clean. Prototype has 2 tiers; final game targets a maximum of 3.
_Avoid_: evolution, form, stage, variant

**Defend Phase**:
The combat phase. The player fights one Bacteria while it spreads Stains. Ends when the Bacteria is defeated.
_Avoid_: fight phase, battle phase, boss phase

**Clean Phase**:
The time-limited window (5–10s, random) after a Bacteria is defeated. The Goose can clean Stains. Ends on timer expiry OR when Filth Gauge hits 0% (win condition). By design, the window is intentionally too short to fully clean the Room as Bacteria tiers escalate — the Filth Gauge trends upward over time.
_Avoid_: cleaning mode, janitor phase, mop phase

**Janitor Mode**:
The Goose's Phase 1 movement state. Grounded, horizontal movement only. Fight and clean are separate actions. Active until the Filth Gauge hits 100%.
_Avoid_: Phase 1, restricted mode, walk mode
_Status_: EXPERIMENTAL — restrictions subject to change after prototype testing

**Goose Boss Mode**:
The Goose's Phase 2 movement state. Unlocked permanently when the Filth Gauge hits 100%. Full movement: run, double jump, glide. Can clean and attack simultaneously. The Goose's true form. Cannot revert to Janitor Mode.
_Avoid_: Phase 2, flight mode, boss mode

**Boss Transformation**:
The moment the Filth Gauge hits 100% and The Goose transitions from Janitor Mode to Goose Boss Mode. The designed climax of Phase 1 — not a failure state, but the intended path to victory.
_Avoid_: phase transition, power-up, unlock

**Respawn Window**:
A Goose Boss Mode-only mechanic. After The Goose defeats the Bacteria in Phase 2, the same Bacteria tier respawns at its death position after 5–6 seconds. The Goose must simultaneously fight and clean to reach 0% Filth Gauge before the Bacteria revives. Does not occur in Janitor Mode.
_Avoid_: death timer, revival, grace period

**Stain System**:
The autoload singleton (`StainSystem.gd`) that tracks all active Stains, enforces the cap, and exposes the Filth Gauge value.
_Avoid_: dirt system, filth system, cleaning system

**Clean Action**:
The player input during Clean Phase: stand on a Stain → hold E → alternate A/D to fill the per-Stain gauge → Stain removed.
_Avoid_: mop action, scrub, wipe

## Relationships

- A **Stain** is spawned by a **Bacteria** (via projectile, vomit, or floor contact)
- The **Filth Gauge** reads from the **Stain System**
- The **Filth Gauge** value directly scales **Bacteria** strength (speed, dodge chance, moveset unlocks)
**Phase 1 loop (Janitor Mode):**
- A **Defend Phase** ends when the **Bacteria** is defeated
- A **Clean Phase** follows every **Defend Phase**
- A new, higher **Bacteria Tier** spawns after each **Clean Phase** if Filth Gauge > 0%

**Phase 2 loop (Goose Boss Mode — triggered at 100% Filth Gauge):**
- The Goose fights whichever **Bacteria Tier** was active at the moment of Boss Transformation — no tier jump occurs
- The Goose fights the current **Bacteria** tier while simultaneously cleaning **Stains**
- Defeating the **Bacteria** opens a **Respawn Window** (5–6s) — same tier respawns at death position
- **Win condition**: defeat the Bacteria AND reach 0% Filth Gauge
- **Lose condition**: none — the game cannot be lost, only won or abandoned
- The **Clean Action** removes one **Stain** completely (no partial saves across phases)
- **Filth Gauge = 100%** triggers the **Boss Transformation** — The Goose enters **Goose Boss Mode**
- **Win condition**: defeat the Bacteria AND clean the Room to 0% Filth Gauge
- **The game is designed so Phase 1 cannot sustain 0% filth** — Boss Transformation is inevitable

## Example dialogue

> **Dev:** "After the player defeats the Bacteria, does the Filth Gauge drop?"
> **Domain expert:** "No — the Filth Gauge only drops when the player removes a Stain during the Clean Phase. Defeating the Bacteria just opens the Clean Phase window."

> **Dev:** "Can the player clean Stains during the Defend Phase?"
> **Domain expert:** "No — the Clean Action is only available during the Clean Phase."

## Open questions

- **Bacteria Tier escalation**: Threshold-based (Filth Gauge must exceed X% before next tier spawns). Thresholds TBD — design deferred post-prototype.


- **Bacteria HP values**: Specific HP per tier. TBD — combat mechanics undesigned.
- **Goose Boss Mode unlock**: Confirmed as Filth Gauge = 100%. Mechanism for returning to Janitor Mode (if ever) is TBD.
- **Contact damage**: What happens when Bacteria touches The Goose. Currently no effect — TBD post-prototype.

## Flagged ambiguities

- "Stain gauge" and "Filth Gauge" were used interchangeably — resolved: **Stain** is the physical puddle, **Filth Gauge** is the UI meter. They are distinct concepts.
- "Phase 1 / Phase 2" were used as names — resolved: canonical names are **Janitor Mode** and **Goose Boss Mode**.
