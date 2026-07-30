# Project C — player outcome contract

**Target player/platform:** PC keyboard-and-mouse player; Godot 4.7.1 at 1280×720.

**45-second fantasy:** As a signal runner, move with WASD, aim with the mouse, use Q to clear a wave or pressure the rival, use E to evade a telegraphed return shot, then choose to advance with friendly minions toward the enemy relay or retreat before the timer. The immediate outcome is a relay takedown or a clean retry prompt.

**Inspectable bar:** In `tools/capture_moba_review.gd`, a fixed top-down lane must make the player, rival, friendly/enemy wave, towers, incoming fire, health, Q/E readiness, timer, and objective distinguishable without copied art. This validates moment-to-moment readability only—not competitive balance, networking, content breadth, or parity with League of Legends.

**Constraints:** Original vector-authored presentation only; no copied League of Legends names, characters, map, assets, audio, or UI. Baseline is GL Compatibility on this Mac; performance claims require a separate real-play profile. Colour is not the only channel: labels, position, bars, and text state convey meaning.

**Required evidence:** boot check; deterministic functional script; action capture; real-play frame-time profile; at least three independent target-player observations for controls/combat feel.
