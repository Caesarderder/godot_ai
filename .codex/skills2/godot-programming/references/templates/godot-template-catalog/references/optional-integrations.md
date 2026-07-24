# Optional integration evaluation

These projects are references or optional project dependencies. This skill does not install them.
Before adoption, inspect the tenant project's existing addons, pin the exact release, retain the
upstream license and notices, and run project-specific Godot 4.6 Web tests.

| Need | Candidate and pin | Prefer the native recipe when | Reject or defer when |
| --- | --- | --- | --- |
| Programmatic Theme generation and editor preview | [ThemeGen v1.4.0](https://github.com/Inspiaaa/ThemeGen/tree/v1.4.0) | semantic tokens and a runtime-created Theme are enough | the project cannot accept an editor plugin or generated-resource workflow |
| Nested, parallel, guarded, or delayed state semantics | [Godot State Charts v0.22.5](https://github.com/derkork/godot-statecharts/tree/v0.22.5) | an object has only a few exclusive states | a default addon dependency would outweigh the state complexity |
| Rich inventory prototypes, constraints, serialization, and editor support | [GLoot v3.0.2](https://github.com/peter-kish/gloot/tree/v3.0.2) | slots and stacks remain small and project-specific | the project has an incompatible item identity or save contract |
| Framework-backed unit and scene tests | [gdUnit4 v6.1.3](https://github.com/godot-gdunit-labs/gdUnit4/tree/v6.1.3) | the project already uses GUT or only needs a small contract smoke test | the plugin would enter runtime/export content |
| Menus, settings, loading, and accessibility shell examples | [Maaack audited revision](https://github.com/Maaack/Godot-Game-Template/tree/93e66a02b979872b870ccb5ac1452f8d6a31c737) | only one small shell recipe is needed | adoption would make the game inherit the starter project's global architecture |

Never copy demo art merely because adjacent code is permissively licensed. GDQuest and several plugin
demos use assets under different terms than their scripts.
