# Migration Guide

This guide explains how to migrate between HangulSearch minor versions in 1.x.

## 1.0.x -> 1.1.x

No breaking API change is required.

Existing 1.0.x code keeps working:

```swift
let results = engine.searchItems(input: query)
engine.changeItems(items: newItems)
engine.changeSearchMode(mode: .combined)
engine.changeSortMode(mode: .matchPosition)
```

### Optional adoption in 1.1.x

You can adopt additive APIs when needed:

```swift
let options = HangulSearchOptions(
    mode: .combined,
    sortMode: .editDistance,
    limit: 20,
    offset: 0,
    normalizeToNFC: true
)
let items = engine.searchItems(input: query, options: options)
let hits = engine.searchHits(input: query, options: options)
```

### Behavior notes

- Default empty query behavior remains unchanged:
  `searchItems(input: "")` returns `[]`.
- `searchItems(input:options:)` also returns `[]` by default.
  To return all, use `emptyQueryBehavior: .returnAll`.
- `normalizeToNFC` is opt-in (`false` by default) to preserve legacy behavior.
- Sort tie-break for `matchPosition` and `editDistance` remains deterministic
  using original result order.

## 1.1.x -> 1.2.x

No breaking API change is planned.

This line focuses on performance and operational hardening:

- internal dedup optimization for combined mode
- memory optimization for edit-distance calculation
- stronger CI/release process docs and gates

## Upgrade checklist

1. Update package dependency to the target 1.x version.
2. Run local checks:
   - `swift test --parallel`
   - `swift test -c release`
3. If you use concurrent mutation/search patterns, also run:
   - `swift test --sanitize=thread`
