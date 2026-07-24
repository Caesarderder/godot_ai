---
name: game-design
description: Turn an accepted product direction into a lightweight, implementable gameplay contract for Godot. Use only when the user explicitly invokes $game-design or selects a skill book containing it; do not infer it from an ordinary implementation request. Extend an existing product-design document when one exists; do not require an enterprise GDD suite or implement the game.
---

# Game Design

Make the chosen game precise enough to build and test without burying a small project under studio
paperwork. Extend the existing product-design Markdown in place when one exists; otherwise create the
smallest contract requested by the user. Preserve accepted choices, deferred dreams, and any existing
conceptual Godot appendix.

Activation is explicit-only: run this workflow only for `$game-design` or a selected skill book that
contains it. Ordinary build, fix, or implementation requests stay on Codex's native path.

This skill owns gameplay rules and the implementation contract. It does not own visual layout,
engine code, scene construction, or production scheduling.

Read [references/playable-contract.md](references/playable-contract.md) before editing the document. When adopting a partially implemented design or changing scope, also read [references/design-integrity-review.md](references/design-integrity-review.md).

## Preflight

1. Find the accepted contract in the user's request or an existing product-design document and read
   it completely.
2. Inspect the current project only to identify confirmed mechanics, constraints, and reusable content.
3. Extract the chosen first playable, design pillars, signature moment, non-goals, fun hypotheses, and
   unresolved decisions.
4. Report contradictions between those elements before adding detail.
5. For a new or empty project, do not turn this workflow into a mandatory interview; choose the
   smallest reversible assumption and record it. For an accepted brownfield design, ask
   one focused question only when an irreversible creative decision would materially change the game.
   Resolve technical facts from the repository or relevant installed skills.

If no accepted product direction exists, derive only the smallest reversible contract supported by
the developer's explicit request. Do not manufacture a generic design from a genre label.

## Build the playable contract

Work in this order and omit sections that do not affect the selected first playable.

### 1. Promise and proof

Write one sentence for the player promise and one observable moment that would prove it is present.
Every included system must support this promise or a required recovery path.

### 2. Player verbs and loops

Define:

- the actions the player can intentionally perform;
- the 5–30 second interaction loop;
- the session loop only if the first playable reaches it;
- the reason to repeat after success or failure.

Express each material mechanic as:

`input or trigger → precondition → choice or cost → world response → feedback → new state`

### 3. Rules and state transitions

Specify initial state, allowed transitions, invalid actions, success, failure, recovery, and restart.
Name the owner of each mutable value. Resolve edge cases that can block or corrupt the loop; do not
catalog impossible hypotheticals.

### 4. Numbers and tuning

Introduce a number only when implementation or playtest needs it. For each number, state:

- unit and starting value or bounded range;
- formula or relationship;
- intended player effect;
- safe tuning direction;
- observation that would justify changing it.

Label untested values as hypotheses. Avoid fake precision and do not balance from arithmetic alone.

### 5. Content slice

List the minimum reusable content that demonstrates variation without hiding the mechanic:
encounters, levels, enemies, cards, items, puzzles, dialogue beats, or equivalent. Give each item a
purpose in the learning or mastery curve. Keep the rest under deferred scope.

### 6. Feedback contract

For each critical event, specify the minimum visual, audio, motion, UI, and timing cue required for the
player to understand what happened. Route detailed composition to `$game-visual-design`; do not decide
screen layout here.

### 7. Acceptance and playtest evidence

Write behavior checks that can be observed without reading implementation details. Cover:

- input and world response;
- success, failure, and restart;
- one edge case that threatens the core loop;
- the signature feedback moment;
- the fun hypothesis and what a real player would do or say if it holds.

Separate deterministic checks from human observations.

### 8. Implementation boundary

Update the existing conceptual Godot appendix only enough to name scene ownership, data ownership,
important signals or calls, and Web-specific validation questions. Reuse `$godot-architecture` for
architecture choices and avoid speculative global services.

## Write discipline

- Modify the existing product-design Markdown when one exists; otherwise update only the compact
  gameplay contract unless the developer explicitly requests another artifact.
- Prefer tables and state diagrams only when they make rules materially clearer.
- Mark developer decisions, confirmed project facts, accepted proposals, and open hypotheses distinctly.
- Do not require epics, stories, sprints, departments, sign-offs, or a fixed number of design documents.
- Do not broaden the first playable to make every section look complete.
- Keep prose useful to both the developer and the implementation agent.

## Readiness review

Before handing the result back to the user's task, test the document against these
questions:

- Can someone describe the first 30 seconds without inventing a rule?
- Does every player input have a visible or audible consequence?
- Are success, failure, recovery, and restart unambiguous?
- Does each system support the player promise or a required loop boundary?
- Are mutable values owned and tunable?
- Is the content slice sufficient to test learning and repetition?
- Can deterministic checks and human fun evidence be distinguished?
- Are deferred dreams protected from accidental implementation?

If any answer is no, revise the smallest relevant section. If all are yes, summarize the first
playable contract and return it to the user's task. The normal next step
is `$game-technical-design`, followed by `$game-prototype`; do not bypass the technical-design boundary.
