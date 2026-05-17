# GooseJanitor — 8-Day Milestone

10-day jam. 8 days planned, 2-day buffer (days 9–10) for emergencies.

**Team:**
- **First** — code (GDScript)
- **Krit** — art / animation _(overview only — manages own art track)_
- **Pat** — game design / flex code

---

## Day 1 ✅ — Foundation

**Code (First + Pat)**
- Stain System autoload (`StainSystem.gd`) — spawn, register, filth %
- Stain object — Clean Action support (advance/reset)
- Player Janitor Mode — horizontal movement
- Enemy spawns stain on lunge

**Art (Krit)**
- Placeholder sprites for player + bacteria

---

## Day 2 ✅ — Playable Prototype

**Code (First + Pat)**
- Bacteria Tier 1 AI — IDLE / CHASE / ATTACK / LUNGE / DODGE states
- Spit projectile — arc trajectory, spawns stain on impact, splash VFX
- Boss Stage — Defend Phase → Clean Phase → Respawn loop
- Filth-to-tier scaling (3 tiers via `TIER_STATS`)
- Filth Gauge UI (basic label)

**Art (Krit)**
- Basic character sprites in place

---

## Day 3 — Moveset Design + Phase 2 Trigger

_Design first, implement same day. Boss Transformation wired but not polished._

**Design (Pat)**
- [ ] Goose Moveset Doc — 2 moves minimum per mode (Janitor Mode + Goose Boss Mode); punch is placeholder only
- [ ] Bacteria New Moveset Doc — 1 additional move beyond current AI states (TBD)
- [ ] Both docs reviewed by First (implementation feasibility) and Krit (animation feasibility) before EOD

**Code (First + Pat)**
- [ ] Implement Goose moveset from doc — both Janitor Mode and Goose Boss Mode
- [ ] Boss Transformation: Filth Gauge 100% → permanently switch to Goose Boss Mode (remove debug toggle key)

**Art (Krit)**
- Phase 2 Goose concept + sprite sheet start
- Review Bacteria new moveset doc for animation scope

---

## Day 4 — Game Flow Completion

_The game can now be started, played, and finished._

**Code (First + Pat)**
- [ ] Double jump + glide (Goose Boss Mode)
- [ ] Respawn Window: after Bacteria defeated in Phase 2, same tier respawns at death position after 5–6s
- [ ] Win condition: Bacteria defeated + Filth 0% → trigger win
- [ ] Main menu scene — title + Start button
- [ ] Win screen scene — minimal, shows win state
- [ ] Game restart flow (win screen → back to main menu)
- [ ] Filth Gauge: upgrade from label to proper UI meter (ProgressBar or custom)
- [ ] Contact damage — decide and implement what happens when Bacteria touches The Goose

**Art (Krit)**
- Title screen art
- UI elements (Filth Gauge bar art, icons)

---

## Day 5 — Integration + Balance

_Full loop playable. Wire end mechanic. Find what feels broken._

**Code (First + Pat)**
- [ ] Wire Goose Boss Mode clean-via-moveset: attack moves can clean Stains they contact
- [ ] Bacteria new moveset implementation (from Day 3 doc, pending Krit sprite delivery)
- [ ] Bacteria HP values tuned per tier
- [ ] Tier escalation thresholds finalized (currently placeholder: <20% T1, <30% T2)
- [ ] Bug fixes from playtesting session
- [ ] Pat: design doc — Transformation Cutscene beats (what plays, how long, what signals it)

**Art (Krit)**
- Bacteria new moveset sprites delivered
- Transformation Cutscene asset list locked
- Bacteria Tier 2 / 3 sprites (if not done)

---

## Day 6 — Feel: Sound + Hit Reaction + AI Polish

**Code (First + Pat)**
- [ ] Basic SFX: punch, spit launch, stain spawn, stain clean, phase transition tone
- [ ] Screen shake on hit
- [ ] Hit reaction: flash or knockback on Bacteria when damaged
- [ ] Wire audio bus — placeholder sounds acceptable, silence is not
- [ ] Dodge polish: only trigger dodge when Goose is within attack range
- [ ] Dodge polish: Bacteria can dodge left or right, not just backward

**Art (Krit)**
- Transformation Cutscene assets delivered to First
- Lighting reference / mood boards

---

## Day 7 — Feel: Cutscene + Lighting

**Code (First + Pat)**
- [ ] Transformation Cutscene — implement using assets from Krit; plays when Filth hits 100%
- [ ] Lighting — `PointLight2D` or `CanvasModulate` pass; room should feel dirtier as Filth rises
- [ ] Phase transition visual cue (flash / pause / sound at moment of Boss Transformation)
- [ ] Final bug sweep

**Art (Krit)**
- All remaining assets delivered and integrated

---

## Day 8 — Submission

**All**
- [ ] Full playtest session — play from main menu to win screen, multiple runs
- [ ] Fix any blocking bugs
- [ ] Export builds: Windows + Web (HTML5) for itch.io
- [ ] Write itch.io page: description, controls, credits
- [ ] Submit before deadline

---

## Days 9–10 — Buffer

Reserved. Do not plan work here. Use only if a member is unavailable on a planned day or a blocking bug appears in Day 8 playtesting.

---

## Cut List (if time runs short, in order)

1. Dialog
2. Parallax background
3. Reflective floor after clean
4. Lighting _(moved to buffer if Day 7 overruns)_
