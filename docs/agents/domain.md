# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`planning/CONTEXT.md`** — primary domain context for this repo (note: not at repo root)
- **`docs/adr/`** — read ADRs that touch the area you're about to work in (directory doesn't exist yet; create lazily when decisions are resolved)

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront.

## File structure

Single-context repo:

```
/
├── planning/
│   └── CONTEXT.md        ← domain context lives here (non-standard path)
├── docs/
│   ├── agents/           ← skill configuration
│   ├── adr/              ← architectural decision records (create as needed)
│   ├── STAIN_SPIKE.md
│   └── AI_SPIKE.md
└── scenes/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `planning/CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

Key domain terms for this project:
- **Stain** — a green puddle left by bacteria on the floor; not "dirt", "filth", or "pollution"
- **Filth gauge** — the `active_stains / MAX_STAINS * 100` percentage; not "health bar" or "dirt meter"
- **Clean Phase** — the time-limited window (5–10s) where the player can clean stains; not "cleaning mode"
- **Defend Phase** — the 1v1 combat phase against bacteria; not "fight phase" or "battle mode"
- **Bacteria** — the enemy type; individual instances are "bacteria" not "bacterium" or "enemy"

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0001 (stain gauge = health) — but worth reopening because…_
