# Minimal project contract template

Use the files under [templates/docs](templates/docs/) only when the project has no equivalent
canonical documentation. Copy the two-file structure; do not generate a large document suite.

Before filling it:

1. preserve any existing product or design document;
2. add it to `docs/index.md` as the canonical source instead of copying its rules;
3. create only the smallest items needed for the current milestone;
4. leave unavailable implementation or evidence fields as `—`;
5. validate from the project root:

```bash
node path/to/game-project-contract/scripts/validate-contract.mjs .
```

The template starts with one proposed player-promise item. Add accepted rule, implementation, and
verification items only as evidence becomes available.
