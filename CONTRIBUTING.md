# Contributing

Thank you for contributing to HangulSearch.

## Prerequisites

- Swift toolchain compatible with this repository (`swift --version`)
- macOS environment for parity with CI (`macos-14` runners)

## Development setup

```bash
git clone https://github.com/Juhwa-Lee1023/HangulSearch.git
cd HangulSearch
swift test --parallel
```

## Branch and commit conventions

- Keep one logical change per PR.
- Prefer additive changes in 1.x. Do not introduce breaking API changes.
- Use concise commit titles with a clear prefix, for example:
  - `Feat/...`
  - `Fix/...`
  - `Perf/...`
  - `Test/...`
  - `Docs/...`

## Local checks before opening a PR

Run all required checks locally:

```bash
swift test --parallel
swift test -c release
swift test --sanitize=thread
swift test -c release --filter HangulSearchBenchmarkSmokeTests/testCombinedModeP95SmokeSynthetic10k
```

## PR checklist

1. Include a clear motivation and behavior impact summary.
2. Confirm 1.x compatibility (no removed public API, no default behavior break).
3. Add or update tests for changed behavior.
4. Update docs when public behavior/contracts changed.
5. Ensure CI is green.

## Code style notes

- Keep behavior deterministic.
- Preserve stable tie-break behavior in sorting paths.
- Prefer reusable internal helpers over duplicated logic.
- Keep comments focused on non-obvious decisions.
