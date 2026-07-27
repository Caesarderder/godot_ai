---
name: game-playtest
description: Plan, run, analyze, or review playtests for a playable Builda Godot game. Use only when the user explicitly invokes $game-playtest or selects a skill book containing it; do not infer it from an ordinary implementation request. Do not infer fun from automated tests or invent player feedback.
---

# Game Playtest

Turn a playable build into observed player evidence and a small, ranked iteration plan. This skill owns gameplay validation; `godot-testing` owns code and scene correctness.

Activation is explicit-only: ordinary build, fix, or implementation requests stay on Codex's native
path unless the user selects this workflow by name or through a skill book.

## Evidence contract

- A passing build proves only that the game runs.
- The developer playing their own game is useful iteration evidence but not new-player evidence.
- A simulated review can find clarity risks, but cannot prove enjoyment or comprehension.
- Never fabricate sessions, quotes, measurements, retention, or player behavior.
- Record the exact build/version, test environment, hypothesis, participant context, observations, and limitations.

Read [references/session-protocol.md](references/session-protocol.md) before preparing or observing a session. Read [references/playtest-report.md](references/playtest-report.md) when recording results.

## 1. Establish the question

Inspect the current product design, playable build, recent changes, and previous playtests. Select one primary hypothesis, for example:

```text
If a new player sees the first enemy telegraph, they will evade without instruction;
evidence is the action they attempt, not whether they later say the attack was clear.
```

Define:

- who should play and why that audience is informative;
- which build and target browser/device they will use;
- the entry state and timebox;
- observable success, confusion, and stop conditions;
- what this session cannot establish.

Do not test the entire game with one vague question such as “is it fun?”

## 2. Choose the smallest useful session

- **First-use comprehension**: start without instructions; observe the first meaningful action, hesitation, and recovery.
- **Core-loop desire**: observe whether the player voluntarily repeats the loop and what decision changes on the next attempt.
- **Difficulty and pacing**: record failure location, cause, recovery, downtime, and whether challenge changes behavior.
- **Controls and accessibility**: test the actual keyboard, pointer, touch, or gamepad path plus focus, pause, readable feedback, and settings.
- **Content or balance comparison**: compare controlled variants without changing several independent variables at once.

Use representative humans whenever the claim concerns human understanding or enjoyment. If nobody is available, prepare the session, improve instrumentation, and report the evidence as pending.

## 3. Observe without coaching

Give only the context a real player would receive. Do not explain controls, goals, or intended strategy unless the build itself does. Record behavior before interpretation:

- first action and time to meaningful control;
- where attention moves;
- repeated mistakes, pauses, retries, abandonment, and recovery;
- success/failure path and whether the player understands why;
- spontaneous repetition, experimentation, or avoidance;
- browser/input/audio/storage problems that contaminate the session.

Ask neutral follow-ups after observation: what the player thought the goal was, what caused a decision, what felt confusing, and what they wanted to do next. Avoid praise-seeking questions.

## 4. Separate findings

Classify each finding:

1. observed behavior;
2. participant interpretation;
3. analyst inference;
4. product decision.

Then rank it by impact on the core promise, frequency across sessions, confidence, and cost of another test. One loud opinion is not automatically a design requirement; repeated behavior is not automatically caused by the first explanation that comes to mind.

## 5. Produce an iteration

Choose the smallest change that can challenge the most important finding. Route work by cause:

- unclear rules or degenerate strategy -> `game-design`;
- unreadable priorities or weak feedback -> `game-visual-design`, `audio-system`, or relevant feedback skill;
- control or lifecycle failure -> `input-handling`, `godot-debugging`;
- measurable frame/load issue -> `godot-optimization`;
- implementation slice -> the user's native implementation task and relevant specialty skills;
- broad quality regression -> the project's existing test and runtime verification route.

For each accepted change, write the next falsifiable hypothesis and the evidence needed to close it. Re-test the affected moment; do not declare a whole game improved from a code diff.

## Handoff

When the user requests a durable report, store a concise result under `docs/game/playtests/`. Do not
advance a milestone on document presence alone.

## Completion

Report:

- build and environment tested;
- participants/session count and its limits;
- primary hypothesis and verdict: supported, contradicted, mixed, or not tested;
- observed findings, separated from inference;
- highest-value next iteration;
- remaining human, browser, device, or content evidence.

“Fun proven” is not a valid verdict. State what behavior was observed and what remains uncertain.
