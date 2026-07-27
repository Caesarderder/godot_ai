---
name: game-economy
description: Use when implementing Godot 4.6 GDScript wallets, currencies, shops, prices, loot grants, harvesting, crafting transactions, offline progress boundaries, and economic ledgers
---

# Game Economy for Godot 4.6 Web

Own value transactions and their audit trail. Reuse **game-balance** for source/sink tuning, **inventory-system** for item capacity and ownership, **save-load** for durable serialization, **resource-pattern** for definitions, and **godot-ui** for storefront presentation.

## Transaction contract

Represent every mutation as a stable transaction:

`request ID -> validate -> reserve -> commit ledger mutation -> emit result`

Use integer minor units for currencies. Never use localized display strings or floating-point equality as economic truth. A request ID must be idempotent across retries. Validate currency/item IDs, amounts, caps, prerequisites, stock, and inventory capacity before commit.

For purchases, wallet debit and inventory grant are one application-level transaction. If the current storage cannot commit atomically, use an explicit reservation and recovery record; never silently debit without delivery.

## Sources, sinks, and recipes

Every source and sink has a named reason code. Loot resolves from deterministic inputs when replayability matters, then records the accepted grant. Crafting validates all ingredients and output capacity before consuming anything. Harvest nodes own depletion and respawn state, not the wallet.

Offline progress is a product and security boundary. Cap elapsed time, use a trusted or explicitly best-effort clock policy, store the last accepted timestamp, reject negative/implausible jumps, and never claim anti-cheat guarantees from client-only Web storage.

## Verification

Test duplicate requests, insufficient funds, capacity failure, zero/negative values, integer overflow bounds, partial recovery, stale definitions, save/load, clock rollback, and refresh during commit. Reconcile ledger deltas against wallet and inventory totals.
