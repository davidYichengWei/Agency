# Task: migrate core harness features
Started: 2026-04-26 18:41:27 +0800
Status: completed

## Activity

### [2026-04-26 18:41:27 +0800] — Decision
**Decision**: Migrate reusable harness features from `/data1/v1/SQLEngine/agent-harness` while excluding SQLEngine/TDSQL-specific domain content.
**Rationale**: The source tree mixes generic harness improvements with local project skills and rules. This repo is a public generic Agency harness, so importing domain-specific context would make the default install less portable.

### [2026-04-26 18:48:00 +0800] — Decision
**Decision**: Keep `submit-mr`, TDSQL/HBase/YCSB skills, output-language rules, and Claude settings out of the public repo.
**Rationale**: Those files are project- or host-specific. Core migration should remain portable and avoid installing local permission or Tencent workflow assumptions.

### [2026-04-26 18:56:00 +0800] — Error: generated TOML parse failure
**Error**: Generated `implementer.toml` failed TOML parsing in validation.
**Root cause**: The Markdown heading `What you DON'T do` triggered the local TOML parser when embedded in a triple-quoted TOML string.
**Fix**: Renamed the heading to `What you do not do` and reran TOML validation successfully.

### [2026-04-26 18:58:00 +0800] — Gate: validation
**Status**: N/A
**User feedback**: Validation was local and deterministic; no human decision required.

### [2026-04-26 19:05:00 +0800] — Decision
**Decision**: Removed `sysperf-analysis`, the six `perf-*-analyst` agents, and repo-level `claude/CLAUDE.md` / `codex/AGENTS.md` snapshots.
**Rationale**: User explicitly did not want the sysperf feature. The root files are generated install targets, not source-of-truth files, now that role-specific templates exist.

### [2026-04-26 19:08:00 +0800] — Decision
**Decision**: Folded `sync.sh` into `install.sh` and removed `sync.sh`.
**Rationale**: The public repo should expose a single install/sync command. The role templates remain the source of truth; `install.sh` now performs both forward and reverse sync.
