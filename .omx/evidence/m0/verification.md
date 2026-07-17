# M0 verification evidence

Date: 2026-07-17

- Godot: `4.7.1.stable.official.a13da4feb`
- GUT: `v9.7.1`, 10/10 tests, 34 assertions
- Headless editor import: PASS
- Mobile renderer game boot: PASS
- Compatibility renderer game boot: PASS
- Protected `godot_ai` addon: 245 staged `R100` renames, 0 non-rename entries, 0 unstaged content diffs
- GUT vendor: 259 files
- GUT manifest SHA-256: `991cd4266de3e6928d0084f23d2f5acb388887c57134daa127b9ee1acf8a87b1`
- Post-M0 baseline summary SHA-256: `882dbfa2325e9a7243a222c0bd55a643cae5d4f70cf65251d69d36aa18a7b68e`

Evidence exception: the first pre-M0 capture omitted per-file hashes for most
untracked files. The limitation and recoverable evidence are documented in
`pre-m0-observed.md`; the enhanced post-M0 baseline is the frozen reference for
future milestones.

Verification command:

```bash
GODOT_BIN=/opt/homebrew/bin/godot project-a/tools/verify_m0.sh
```
