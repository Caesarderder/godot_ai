# Save Architecture Boundary

The Save service is a persistence boundary, not a scene-tree crawler. It accepts and returns detached,
validated data. Feature/session owners decide which runtime state participates and when to capture or
apply it.

```text
FeatureRoot / SessionController
├── RunState.capture_snapshot()
├── InventoryState.capture_snapshot()
└── ObjectiveState.capture_snapshot()
           |
           v
    SaveSnapshot (detached typed/value data)
           |
           v
 SaveService.save_slot(slot_id, snapshot)
```

Loading reverses the flow only after full validation:

```text
SaveService.load_slot(slot_id)
    -> read primary/backup
    -> parse + migrate + validate
    -> SaveLoadResult(snapshot or error)
    -> FeatureRoot.apply_snapshot(snapshot)
```

## Ownership rules

- The feature/session composition root knows its participating runtime models and calls them
  explicitly. Do not use `get_nodes_in_group("saveable")` as an application-wide discovery mechanism.
- SaveService owns slot IDs, schema/migration, byte and collection bounds, temporary publication,
  backup recovery, and load results.
- Runtime models own semantic capture/apply logic and validate their domain ranges again.
- SaveService never stores live Nodes, scene paths, Callables bound to scene Nodes, or a registry that
  can outlive a route.
- Snapshots use stable content IDs. They do not grant authority to arbitrary `res://` paths.
- Loading returns a detached result and leaves the current runtime untouched on every failure.

For a large session, the feature root may delegate capture to explicitly owned subsystem state models.
That remains direct composition, not global tree scanning.

## Transition coordination

Save-before-route is an application workflow:

```text
App/FlowCoordinator
    -> capture detached snapshot
    -> await/check SaveService result
    -> SceneRouter.navigate(route_id)
```

SaveService must not call SceneRouter, and SceneRouter must not trigger hidden saves. The coordinator
defines whether a failed save blocks, warns, or allows the route according to product requirements.

## Verification

- corrupt, oversized, future-version, and missing saves leave runtime state unchanged;
- backup recovery is observable and applies exactly one validated snapshot;
- repeated route entry does not accumulate save participants or stale Callables;
- snapshot capture is deterministic for the same authoritative state;
- browser-origin reload and storage-loss behavior are tested separately.
