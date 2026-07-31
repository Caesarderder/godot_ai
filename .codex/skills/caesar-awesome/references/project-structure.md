# Project structure for a Gauntlet Loop

This is a coordination structure, not a framework mandate. Its purpose is to let
builders work within explicit ownership boundaries while critics and integrators
can reproduce and judge the complete player experience. Adapt names to the engine;
do not create an empty directory merely because it appears here.

```text
project/
├── app/ or bootstrap/             # thin composition root: startup, registration, lifecycle
├── core/ or runtime/              # engine loop, time/RNG, configuration, registry, shared primitives
├── features/ or systems/          # one owned domain per directory
│   ├── player/
│   ├── combat/
│   ├── world/
│   ├── presentation/              # rendering, VFX, audio, UI; split further only when ownership is clear
│   └── ...
├── contracts/                     # stable public events, interfaces, schemas, surface/category vocabulary
├── content/ or assets/            # source/generated content under explicit licensing and generation rules
├── dev/                           # named debug poses, deterministic scenes, scenario setup and inspection APIs
├── tools/                         # build/run drivers, capture, diff, profile, functional checks, report readers
├── tests/                         # deterministic domain, integration, and smoke tests where the stack supports them
├── docs/                          # player outcome, ownership map, accepted decisions, progress and known risks
└── [engine-native folders]        # scenes, prefabs, shaders, project settings, plugins, etc.
```

## Responsibilities

| Surface | Owns | Must not own |
|---|---|---|
| Composition root | lifecycle wiring, registration, scene/level transition, top-level configuration | feature rules, combat math, rendering policy, or UI behavior |
| Core/runtime | clock, deterministic RNG where needed, scheduling, registry, shared primitives | feature-specific content or player-facing rules |
| Feature/subsystem | one coherent player-facing or domain concern, its internal state and tests | another feature's private state |
| Contracts | minimum stable vocabulary for feature collaboration | an all-purpose service locator or a dumping ground for internals |
| Dev scenarios | reproducible setup, debug state, capture/playtest hooks; may drive shipping systems | shipping runtime logic or the production control path |
| Tools/tests | evidence production and automated checks | hidden gameplay logic required by shipping runtime |
| Docs/progress | current ownership, quality bar, evidence, accepted/rejected decisions, known gaps | unverifiable completion claims |

## Rules that make parallel work safe

1. **One owner per feature directory.** A builder changes its owned surface only;
   shared contracts and composition-root changes are lead/integrator work.
2. **Public APIs, not private coupling.** Cross-feature dependencies use a declared
   public module, interface, event, schema, adapter, or engine-native equivalent.
   A consumer must not reach into another feature's private state.
3. **One lifecycle authority.** The composition root registers systems/scenes;
   lifecycle ordering and disposal are explicit. Features do not start competing
   global loops or keep unowned global state.
4. **Determinism is a shared runtime concern.** If images or gameplay are compared
   frame-for-frame, put time, randomness, and scenario state behind a controllable
   runtime surface rather than scattered wall-clock calls.
5. **Dev evidence is first-class but isolated.** Named scenarios, capture APIs,
   and debug staging may expose game state for evaluation, but they must be
   clearly development-only and must not become the production control path.
6. **Tools are contracts too.** A capture/profile/test tool must name its scenario,
   environment, inputs, outputs, and failure condition so a fresh critic can run it
   without the builder's explanation.
7. **Author scenarios before changing features.** A work unit cannot enter a
   maker–critic loop until its reusable Test Scenario establishes the decisive
   state, drives shipping systems, defines observations, resets cleanly, and
   exposes both fast-review and strict-regression routes.

## Minimum ownership-map record

Create this before parallel work and update it when interfaces move:

| Owner | Directory/module | Public contract | Named scenario | Acceptance evidence | Coupling / handoff |
|---|---|---|---|---|---|
| [owner] | [owned surface] | [events/interfaces] | [repeatable setup] | [command/artifact] | [independent or sequential owner] |

If a project is too small for feature directories, retain the same boundaries as
modules. If a project is large, split only when a new directory has a distinct
owner, lifecycle, public contract, and validation route.
