#!/bin/bash
# Sync Agency to ~/.claude and ~/.codex
# Usage:
#   ./install.sh [--main claude|codex] [--single]
#   ./install.sh --reverse [--main claude|codex]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_SRC="$SCRIPT_DIR/shared"
CLAUDE_SRC="$SCRIPT_DIR/claude"
CODEX_SRC="$SCRIPT_DIR/codex"
CLAUDE_MAIN_SRC="$CLAUDE_SRC/CLAUDE-main.md"
CLAUDE_COLLABORATOR_SRC="$CLAUDE_SRC/CLAUDE-collaborator.md"
CLAUDE_CROSS_MODEL_SRC="$CLAUDE_SRC/cross-model-codex.md"
CODEX_MAIN_SRC="$CODEX_SRC/AGENTS-main.md"
CODEX_COLLABORATOR_SRC="$CODEX_SRC/AGENTS-collaborator.md"
CODEX_CROSS_MODEL_SRC="$CODEX_SRC/cross-model-claude.md"

# Optional: drop a project-specific context file at shared/PROJECT.md
# (code structure, build commands, internal services). It will be appended to
# the installed CLAUDE.md / AGENTS.md at sync time. Skipped if not present.
PROJECT_SRC="$SHARED_SRC/PROJECT.md"

# --- Arg parsing ---
MODE="forward"
MAIN_AGENT="claude"
SINGLE_MODE=0

usage() {
    local out="${1:-/dev/stderr}"
    cat > "$out" <<USAGE
Usage:
  $(basename "$0") [--main claude|codex] [--single]
  $(basename "$0") --reverse [--main claude|codex]
  $(basename "$0") -h|--help

Options:
  --main claude|codex  Select the primary agent to install. Default: claude.
  --single             Install only the selected main agent; do not install peer/cross-model behavior.
  --reverse, -r        Pull live skills/rules back into this repo. Root instruction files are never reverse-synced.
  --help, -h           Show this help.

Examples:
  $(basename "$0") --main claude
  $(basename "$0") --main codex
  $(basename "$0") --main codex --single
  $(basename "$0") --reverse --main claude
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage /dev/stdout
            exit 0
            ;;
        --reverse|-r)
            MODE="reverse"
            shift
            ;;
        --main)
            if [[ $# -lt 2 ]]; then
                usage
                exit 1
            fi
            MAIN_AGENT="$2"
            shift 2
            ;;
        --single)
            SINGLE_MODE=1
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ "$MAIN_AGENT" != "claude" && "$MAIN_AGENT" != "codex" ]]; then
    usage
    exit 1
fi

if [[ "$MODE" == "reverse" && "$SINGLE_MODE" -eq 1 ]]; then
    echo "--single is only valid for forward sync" >&2
    usage
    exit 1
fi

# --- Reverse sync: live config → Agency shared assets ---
# Additive (no --delete): deletions in live config do not propagate back.
# Root instruction files are generated from role-specific templates and are never
# reverse-synced.
if [[ "$MODE" == "reverse" ]]; then
    echo "=== Reverse syncing shared assets for main=$MAIN_AGENT ==="

    if [[ "$MAIN_AGENT" == "claude" ]]; then
        for dir in rules skills agents; do
            if [ -d ~/.claude/$dir ]; then
                mkdir -p "$SHARED_SRC/$dir"
                rsync -a ~/.claude/$dir/ "$SHARED_SRC/$dir/"
            fi
        done
        echo "  Pulled from ~/.claude into shared/: $(ls ~/.claude/rules/ 2>/dev/null | wc -l) rules, $(ls ~/.claude/skills/ 2>/dev/null | wc -l) skills, $(ls ~/.claude/agents/ 2>/dev/null | wc -l) agents"
    else
        if [ -d ~/.codex/skills ]; then
            mkdir -p "$SHARED_SRC/skills"
            rsync -a ~/.codex/skills/ "$SHARED_SRC/skills/"
        fi
        echo "  Pulled from ~/.codex into shared/: $(ls ~/.codex/skills/ 2>/dev/null | wc -l) skills"
        echo "  Codex has no Claude-style Markdown rules directory; root AGENTS.md is not reverse-synced."
    fi

    echo "  Root instruction files are not reverse-synced"
    echo "  Review changes: cd $SCRIPT_DIR && git status"
    echo "=== Done ==="
    exit 0
fi

# --- Helper: copy Claude-mode assets ---
sync_claude_home() {
    local home_dir="$1"
    local instruction_file="$2"
    local extra_file="${3:-}"

    mkdir -p "$home_dir"
    {
        cat "$instruction_file"
        if [[ -n "$extra_file" ]]; then
            echo ""
            cat "$extra_file"
        fi
        if [[ -f "$PROJECT_SRC" ]]; then
            echo ""
            cat "$PROJECT_SRC"
        fi
    } > "$home_dir/CLAUDE.md"

    for dir in rules skills agents; do
        if [ -d "$SHARED_SRC/$dir" ]; then
            mkdir -p "$home_dir/$dir"
            rsync -a "$SHARED_SRC/$dir/" "$home_dir/$dir/"
        fi
    done

    local project_note=""
    [[ -f "$PROJECT_SRC" ]] && project_note=" + PROJECT.md"
    echo "  CLAUDE.md$project_note, $(ls "$home_dir/rules/" 2>/dev/null | wc -l) rules, $(ls "$home_dir/skills/" 2>/dev/null | wc -l) skills, $(ls "$home_dir/agents/" 2>/dev/null | wc -l) agents"
}

# --- Helper: build Codex AGENTS.md from selected role template + shared rules ---
build_codex_agents_md() {
    local instruction_file="$1"
    local extra_file="$2"
    local output_file="$3"

    {
        cat "$instruction_file"
        if [[ -n "$extra_file" ]]; then
            echo ""
            cat "$extra_file"
        fi
        if [[ -f "$PROJECT_SRC" ]]; then
            echo ""
            cat "$PROJECT_SRC"
        fi
        echo ""
        echo "---"
        echo ""
        echo "## Rules"
        echo ""
        for rule_file in "$SHARED_SRC/rules/"*.md; do
            [ -f "$rule_file" ] || continue
            echo ""
            extract_rule_body "$rule_file"
            echo ""
        done
    } > "$output_file"
}

# --- Codex sandbox overrides ---
# Agents listed here get "workspace-write" instead of the default "read-only".
# Add agent names (without .md extension) to extend this list.
WORKSPACE_WRITE_AGENTS=(
    "implementer"
)

# --- Helper: check if agent needs workspace-write ---
get_sandbox_mode() {
    local agent_name="$1"
    for writable in "${WORKSPACE_WRITE_AGENTS[@]}"; do
        if [[ "$agent_name" == "$writable" ]]; then
            echo "workspace-write"
            return
        fi
    done
    echo "read-only"
}

# --- Helper: convert .md agent to .toml agent ---
convert_agent_md_to_toml() {
    local md_file="$1"
    local toml_file="$2"

    local name="" description="" body=""
    local in_frontmatter=0 frontmatter_done=0

    while IFS= read -r line; do
        if [[ "$frontmatter_done" -eq 0 ]]; then
            if [[ "$line" == "---" ]]; then
                if [[ "$in_frontmatter" -eq 0 ]]; then
                    in_frontmatter=1
                    continue
                else
                    frontmatter_done=1
                    continue
                fi
            fi
            if [[ "$in_frontmatter" -eq 1 ]]; then
                if [[ "$line" =~ ^name:\ *(.*) ]]; then
                    name="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^description:\ *(.*) ]]; then
                    description="${BASH_REMATCH[1]}"
                fi
            fi
        else
            body+="$line"$'\n'
        fi
    done < "$md_file"

    body="$(echo "$body" | sed -e 's/^[[:space:]]*//' -e '/^$/N;/^\n$/d' | sed -e '1{/^$/d}')"

    local sandbox_mode
    sandbox_mode="$(get_sandbox_mode "$name")"

    # Escape backslashes for TOML multi-line strings (e.g., \| in markdown tables)
    local escaped_body
    escaped_body="$(echo "$body" | sed 's/\\/\\\\/g')"

    # Omit model/model_reasoning_effort so Codex subagents inherit the caller.
    cat > "$toml_file" <<TOML_EOF
name = "$name"
description = "$(echo "$description" | sed 's/"/\\"/g')"
sandbox_mode = "$sandbox_mode"
developer_instructions = """
$escaped_body
"""
TOML_EOF
}

# --- Helper: extract rule body (strip YAML frontmatter) ---
extract_rule_body() {
    local md_file="$1"
    local in_frontmatter=0 frontmatter_done=0

    while IFS= read -r line; do
        if [[ "$frontmatter_done" -eq 0 ]]; then
            if [[ "$line" == "---" ]]; then
                if [[ "$in_frontmatter" -eq 0 ]]; then
                    in_frontmatter=1
                    continue
                else
                    frontmatter_done=1
                    continue
                fi
            fi
        else
            echo "$line"
        fi
    done < "$md_file"
}

if [[ "$MAIN_AGENT" == "claude" ]]; then
    CLAUDE_INSTALL_SRC="$CLAUDE_MAIN_SRC"
    CODEX_INSTALL_SRC="$CODEX_COLLABORATOR_SRC"
    CLAUDE_EXTRA_SRC="$CLAUDE_CROSS_MODEL_SRC"
    CODEX_EXTRA_SRC=""
else
    CLAUDE_INSTALL_SRC="$CLAUDE_COLLABORATOR_SRC"
    CODEX_INSTALL_SRC="$CODEX_MAIN_SRC"
    CLAUDE_EXTRA_SRC=""
    CODEX_EXTRA_SRC="$CODEX_CROSS_MODEL_SRC"
fi

if [[ "$SINGLE_MODE" -eq 1 ]]; then
    CLAUDE_EXTRA_SRC=""
    CODEX_EXTRA_SRC=""
fi

if [[ "$SINGLE_MODE" -eq 1 ]]; then
    echo "=== Sync mode: main=$MAIN_AGENT single=true ==="
else
    echo "=== Sync mode: main=$MAIN_AGENT single=false ==="
fi

if [[ "$SINGLE_MODE" -eq 0 || "$MAIN_AGENT" == "claude" ]]; then
    # === Claude: selected role copy ===
    echo "=== Syncing to ~/.claude ==="
    sync_claude_home "$HOME/.claude" "$CLAUDE_INSTALL_SRC" "$CLAUDE_EXTRA_SRC"
else
    echo "=== Skipping Claude home in single Codex mode ==="
fi

if [[ "$SINGLE_MODE" -eq 0 || "$MAIN_AGENT" == "codex" ]]; then
    # === Codex: selected role AGENTS.md + rules inlined + shared skills + converted agents ===
    echo "=== Syncing to ~/.codex ==="
    mkdir -p ~/.codex/agents ~/.codex/skills

    # Build AGENTS.md: selected Codex role template + rules appended
    build_codex_agents_md "$CODEX_INSTALL_SRC" "$CODEX_EXTRA_SRC" ~/.codex/AGENTS.md

    # Copy all skills from shared/ to Codex
    rsync -a "$SHARED_SRC/skills/" ~/.codex/skills/

    # Convert all agents to .toml
    agent_count=0
    for md_file in "$SHARED_SRC/agents/"*.md; do
        [ -f "$md_file" ] || continue
        basename="$(basename "$md_file" .md)"
        convert_agent_md_to_toml "$md_file" ~/.codex/agents/"$basename".toml
        agent_count=$((agent_count + 1))
    done

    project_note=""
    [[ -f "$PROJECT_SRC" ]] && project_note=" + PROJECT.md"
    echo "  AGENTS.md ($(basename "$CODEX_INSTALL_SRC")$project_note + $(ls "$SHARED_SRC/rules/"*.md 2>/dev/null | wc -l) rules inlined), $(ls ~/.codex/skills/ 2>/dev/null | wc -l) skills, $agent_count agents"
    echo "  Workspace-write agents: ${WORKSPACE_WRITE_AGENTS[*]}"
else
    echo "=== Skipping Codex home in single Claude mode ==="
fi

echo "=== Done ==="
