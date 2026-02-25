# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

Note: The latest released version is `1.0.1` (2026-02-24). Entries in this
section are pending and may be grouped into the next `1.1.x` / `1.2.x` release
line at release time.

### Added
- CI gate now includes `swift test --parallel`, `swift test -c release`,
  `swift test --sanitize=thread`, and a benchmark smoke test.
- Added release operation documents:
  `MIGRATION.md`, `CONTRIBUTING.md`, and `SECURITY.md`.
- Added legacy API compatibility regression tests for 1.0.x style usage.

### Changed
- `combined` mode dedup path now uses key buckets for improved performance.
- `levenshteinDistance` switched to a 2-row DP implementation to reduce memory usage.

## [1.0.1] - 2026-02-24

### Added
- Additive public API for options and detailed hits:
  `HangulSearchOptions`, `HangulSearchHit`, `HangulMatchKind`,
  `searchItems(input:options:)`, and `searchHits(input:options:)`.

### Changed
- Internal search pipeline refactoring for deterministic sorting and cache reuse.

## [1.0.0] - 2024-09-09

### Added
- Initial stable release of HangulSearch.
