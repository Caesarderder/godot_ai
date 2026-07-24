> ← Back to [SKILL.md](../SKILL.md)

# CSV Plural and Context Support (Godot 4.6)

Godot 4.6 extends CSV translations with a `?plural` header column, a special `?pluralrule` row, and an optional `?context` header column.

## New CSV Columns

| Column header | Purpose |
|---------------|---------|
| `?context` | Disambiguates keys with the same string but different meanings (e.g. "file" as a noun vs. "to file" as a verb) |
| `?plural` | Provides the plural form of the string (for the source locale) |
| `?pluralrule` | A special value in the first column of a row; that row stores each locale's gettext-style `nplurals=...; plural=...;` rule |

## Example CSV with Context and Plural

```csv
keys,?plural,?context,en,fr
?pluralrule,,,nplurals=2; plural=(n != 1);,nplurals=2; plural=(n > 1);
ITEM_FILE,,noun,File,Fichier
ITEM_FILE,,verb,File,Classer
ENEMY_COUNT_ONE,ENEMY_COUNT_OTHER,,%d enemy,Il y a %d pomme
,,,%d enemies,Il y a %d pommes
```

The `?pluralrule` marker belongs in the first column, not in the header. Each additional plural form uses another row with empty key/plural/context cells; do not join forms with `/` inside one cell.

## Using Context in Code

```gdscript
# Translate with context to disambiguate identical keys
var file_noun: String = tr("ITEM_FILE", "noun")    # "File" (object)
var file_verb: String = tr("ITEM_FILE", "verb")    # "File" (action)

# Without context — returns the first match for the key
var file_default: String = tr("ITEM_FILE")
```


## Using Plural in Code

```gdscript
# Pluralize with tr_n() — works with CSV plural columns in 4.6+
var enemy_count := 3
var msg: String = tr_n("ENEMY_COUNT_ONE", "ENEMY_COUNT_OTHER", enemy_count)
# Godot substitutes the correct plural form based on the current locale's rules
```


> **When to use PO vs CSV:** CSV can represent multiple plural forms by adding rows, but PO often remains easier to audit for languages such as Russian, Polish, or Arabic. Choose one format deliberately; do not collapse several forms into one CSV cell.
