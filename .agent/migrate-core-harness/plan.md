# Plan: migrate core harness features

## Goal

Migrate reusable core harness features from `/data1/v1/SQLEngine/agent-harness` into this Agency repo without importing SQLEngine/TDSQL-specific project knowledge.

## Success Criteria

- [x] The repo includes the newer main/collaborator role split for Claude and Codex.
- [x] Cross-model collaboration can be installed for either Claude-main or Codex-main mode.
- [x] Generic newer skills and agents are present; TDSQL/HBase/YCSB/domain skills are not imported.
- [x] `install.sh` supports forward sync, reverse sync, `--main`, and `--single`.
- [x] README architecture and quick start match the migrated harness layout.
- [x] Shell syntax and skill/agent frontmatter validate.

## Steps

1. [x] Inventory newer harness deltas and classify generic vs SQLEngine-specific.
2. [x] Create migration task artifacts.
3. [x] Migrate reusable role files, cross-model instructions, generic skills, and perf agents.
4. [x] Update sync/install scripts and README architecture.
5. [x] Validate shell syntax, YAML/frontmatter, and git diff.
