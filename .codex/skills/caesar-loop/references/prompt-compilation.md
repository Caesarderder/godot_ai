# Prompt compilation

Generate the final prompt from the user's intent in this order.

1. **Outcome:** State what a target player does, understands, chooses, and feels in one short play window. Replace feature inventories with this outcome.
2. **Bar:** Select a real, inspectable comparison. For visuals, name a matching camera/view and gameplay situation; for performance, name a target device/settings and percentile/hitch budget; for core play, name an observable player task. A reference may guide evaluation but may never be copied into the shipped game.
3. **Freedom:** State the engine/platform and hard constraints, then let the lead choose architecture, task decomposition, and number of loops.
4. **Gauntlet:** Require independent builders and critics; critics inspect real running output and select the largest gap. Require blind A/B when a paired comparison exists.
5. **Evidence:** Require repeatable captures, a gameplay/performance path, a live progress artifact, integration after parallel waves, and target-player evidence for fun/readability. State that the host orchestrator—not the game repository—owns agent scheduling and persistence.
6. **Coupling:** Require the lead to distinguish independently judgeable units from shared/coupled concerns; only the former may run in parallel.

## Reject before publishing

- No concrete bar or no way to inspect it.
- “AAA,” “perfect,” or “fun” standing alone as acceptance criteria.
- A long implementation recipe, agent roster, or fixed number of rounds.
- A critic that sees the builder's explanation instead of the artifact.
- A visual-only loop for a game whose requested quality includes feel or fun.
- A prompt that implies a repository contains a self-running LLM, critic, or memory system without evidence.
- Parallel work on lighting/exposure, camera/input feel, shared runtime contracts, or other coupled concerns without a tested integration protocol.
- A claim that a reference's protected assets can be reused.

## Prompt quality checklist

- [ ] Is it 80–180 words and in the user's language?
- [ ] Does it name an outcome and a concrete bar?
- [ ] Does it require a lead to choose decomposition by change coupling?
- [ ] Does it separate builders from fresh critics and require real-artifact inspection?
- [ ] Does it loop on one largest evidence-backed gap?
- [ ] Does it call for live progress, integration, and appropriate validation?
- [ ] Does it name the external orchestration boundary and restrict parallelism to independent units?
- [ ] Does it leave implementation decisions to the executing lead?
