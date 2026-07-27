---
name: game-balance
description: Design, analyze, or tune evidence-grounded balance for a Builda game. Use only when the user explicitly invokes $game-balance or selects a skill book containing it; do not infer it from an ordinary implementation request. Cover combat, resources, progression, rewards, loot, difficulty, and controlled tuning without manufacturing precision or player evidence.
---

# Game Balance

Turn balance questions into explicit models, measurable hypotheses, and controlled changes. Own numerical relationships and tuning evidence; leave mechanic identity to `$game-design`, implementation to the relevant delivery skill, and human feel validation to `$game-playtest`.

This is an explicit-only design workflow. Ordinary build, fix, or implementation requests stay on Codex's native path.

Read [references/balance-model.md](references/balance-model.md) before analyzing or changing values.

## Evidence contract

- Current data/config and runtime code outrank design-document targets.
- A design target explains intent; it does not prove the implemented values meet it.
- Arithmetic can reveal outliers and impossible relationships, but cannot prove fun, fairness, or perceived value.
- A passing automated test proves deterministic rules, not difficulty or player choice.
- Never invent telemetry, player populations, acquisition rates, device results, or confidence intervals.
- Label every recommendation as `derived`, `measured`, `playtest hypothesis`, or `unknown`.

## Preflight

1. Read repository instructions, the accepted gameplay contract, relevant data files, formulas, runtime code, tests, and current playtest/telemetry evidence.
2. Identify the domain: combat, economy, progression, loot/rewards, encounter difficulty, or a coupled subset.
3. Record the source of each input value and its unit. Separate implemented values from proposed targets.
4. Define the player behavior the balance is meant to create and the failure symptom under investigation.
5. Ask one focused question only when multiple product goals would lead to materially different balance targets.

## Analysis workflow

### 1. Reconstruct the model

Map inputs, formulas, caps, gates, state transitions, random variables, sources, sinks, and feedback loops. Use names and units from the project. If the real formula cannot be located, report the gap rather than replacing it with a genre convention.

### 2. Establish comparison surfaces

Choose only relevant surfaces:

- effective output and time-to-outcome for combat options;
- survivability, recovery, crowd control, positional or opportunity costs;
- resource sources, sinks, stockpiles, caps, conversion paths, and infinite loops;
- progression cost, power gain, unlock cadence, dead zones, and spikes;
- reward probability, expected attempts, guarantee ceilings, duplicate value, and inventory pressure;
- encounter demand against the capabilities available when the player reaches it.

Normalize by cost, availability, risk, execution difficulty, and downtime. Raw damage or reward size alone is rarely a fair comparison.

### 3. Find structural failures

Check for strictly dominant or never-rational options, unreachable or mandatory content, runaway feedback loops, resource imbalance, unjustified progression discontinuities, random streaks outside the intended experience, coupled tuning knobs, and displayed values that disagree with runtime behavior.

### 4. Test sensitivity

Vary one independent input at a time over a bounded, stated range. Show which conclusions are stable and which flip after a small change. Use a script or table when it improves repeatability; do not create a simulation that assumes the player behavior it is supposed to test.

### 5. Recommend the smallest experiment

For each high-value finding, provide the observed or derived problem, evidence and confidence, one proposed change, likely side effects, deterministic checks, and the playtest or telemetry observation needed to judge the result. Do not tune several independent variables in one experiment unless the relationship itself is under test.

## Output

Return a concise report containing scope and data sources, model and assumptions, findings ranked by player impact and confidence, relevant comparison tables, recommended experiments rather than unexplained replacement numbers, and the deterministic/human evidence still required.

Write a persistent balance note only when requested or when the repository already has a canonical balance document. Prefer updating the existing source of truth over creating parallel values.

## Change and verification boundary

When the developer asks to apply a tuning change:

1. change the authoritative data/formula, not a copied report value;
2. update dependent design text only when the contract changed;
3. run focused deterministic tests and an engine/runtime check;
4. compare before/after results using the same scenario;
5. route subjective difficulty, comprehension, and desirability to `$game-playtest`.

Finish with exact changed values, unchanged coupled values, evidence obtained, and the next smallest balance experiment. Never report `BALANCED` without representative player or telemetry evidence appropriate to the claim.

## Attribution

This skill adapts selected methods from the MIT-licensed Donchitos/Claude-Code-Game-Studios `balance-check` workflow at reviewed commit `984023ddac0d5e27624f2baacde6105e45de375f`. It removes Claude-specific runtime and approval assumptions. See [references/upstream-license.txt](references/upstream-license.txt).
