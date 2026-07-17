# M0 Pre-change Evidence

Captured before modifying the project-a M0 gameplay shell on 2026-07-17.

```text
godot_version=4.7.1.stable.official.a13da4feb
head=4e57e1101fb43c4e499db9de352c5dab8735ee5b
status_v2_sha256=f253c457de8e65b5a67901347798c06f75e9b6b7bc3cd6ecf226efcb14bf9408
cached_patch_sha256=6cf3d006749604fe5d71bcd4145f0c12b1807a19a61201be2ddcd2e00962a42d
unstaged_patch_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
untracked_list_sha256=847ae5ae09131be5d324ec4ad83d59161529f8059cf9e4530acca69aebc757a1
protected_addon_files=245
protected_addon_manifest_sha256=e58551a9e8f1d506f3c24e0f91003917bb3a0edfd8e22303203e815a8db6898b
project_godot_sha256=a780891e8dafe4dba2135c9f3ae22942bd10af9d7ca8c183f57f28e39d7ac2c8
baseline_headless_editor=PASS
```

## Evidence limitation and reconstruction

The first capture recorded the complete NUL path-list digest, binary patch digests,
the protected addon manifest, and `project.godot`, but it did not create per-file
hash records for every untracked file. That omission was discovered by independent
review and cannot be repaired retroactively.

The following pre-edit bytes are still recoverable from the contemporaneous read
and patch contexts:

| Path | Pre-edit SHA-256 | Basis |
|---|---|---|
| `project-a/project.godot` | `a780891e8dafe4dba2135c9f3ae22942bd10af9d7ca8c183f57f28e39d7ac2c8` | contemporaneous hash |
| `project-a/.gitignore` | `9990beea43a9d1b3f0bb14f1d4a6fe059dcaf717d9440dae4225b6d45f881e82` | exact pre-edit patch context reconstructed |
| `project-a/.editorconfig` | `3b2c749c8a940905a08f727d8be9017c9568a12421c0aee7e37e9543b3751b1b` | exact pre-edit patch context reconstructed |
| `project-a/.gitattributes` | `21b01a606c9f85f18bb9230245f00ab104df7409cbb2fe9423f6751ca72ba754` | unchanged during M0; post-review continuity hash |
| `project-a/icon.svg` | `6c80384360a5b269d1054bfb27241258154e2cc8167c522016fdc1820e84e0f8` | unchanged during M0; post-review continuity hash |
| `project-a/icon.svg.import` | `fe0b9637652b4b30b4759f5b1dcc3e6d80de92ffff0fdc077dd1ec8e153745fe` | unchanged during M0; post-review continuity hash |

The final three rows are continuity assertions, not contemporaneous per-file
pre-M0 hashes. The enhanced capture tool now emits `dirty-untracked-hashes.nul`,
`artifact-hashes.nul`, and explicit `MISSING` records so future milestones do not
repeat this gap.

The full NUL-safe status, path sets, binary patches and addon manifest are generated locally by `project-a/tools/capture_worktree_baseline.sh` under `.omx/evidence/m0/worktree-baseline/`.
