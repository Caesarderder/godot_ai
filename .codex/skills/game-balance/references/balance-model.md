# Balance model

Use only the sections relevant to the current game.

## Common comparison model

For every option or stage, record:

| Field | Meaning |
|---|---|
| Availability | when and how the player can access it |
| Cost | resource, time, risk, position, cooldown, or opportunity given up |
| Output | immediate and delayed state change |
| Reliability | conditions, accuracy, variance, and failure modes |
| Feedback | whether the player can understand the result |
| Follow-up | choices enabled or removed by the outcome |

An option is suspiciously dominant when it is no worse across all material fields and strictly better in at least one. Confirm that hidden execution or opportunity costs are not missing before making the claim.

## Combat

- Compare effective output over a representative action window, not only single-hit numbers.
- Include downtime, range, accuracy, area coverage, control, safety, resource cost, and target conditions.
- Compare time-to-outcome at the actual player/enemy tiers under review.
- Check defense and recovery for unkillable or unrecoverable states.
- Treat animation timing, collision, input latency, and readability as runtime evidence, not spreadsheet constants unless measured.

## Economy

Map every resource as `source -> stockpile/cap -> conversion or decision -> sink -> player-facing result`. Check source/sink cadence per meaningful session unit, circular conversions, hoarding incentives, mandatory purchases, useless purchases, overflow behavior, and what happens when the player reaches zero. Do not assume a live-service monetization model.

## Progression

Compare cost and new capability across the curve. Flag long stretches without a new decision, sudden power jumps, gates reached before the expected capability exists, dominant grind/skip paths, and growth that increases numbers without changing choices.

## Rewards and loot

For random rewards, distinguish probability per attempt, expected attempts, median experience, worst-case ceiling, duplicate handling, and guarantee/pity behavior. Expected value alone hides bad streaks. Validate probability weights and conditions.

## Experiment quality

A useful tuning experiment states one hypothesis, one primary changed variable, unchanged controls, deterministic expected effect, player behavior that would support or challenge it, and a rollback value or condition.

Avoid universal targets such as a fixed ideal time-to-outcome or source/sink ratio. Derive targets from the game's promise, session shape, and observed players.
