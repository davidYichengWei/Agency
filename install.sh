#!/bin/bash
# Install Agency to ~/.claude and ~/.codex
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$SCRIPT_DIR/claude"
CODEX_SRC="$SCRIPT_DIR/codex"

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

    cat > "$toml_file" <<TOML_EOF
name = "$name"
description = "$(echo "$description" | sed 's/"/\\"/g')"
sandbox_mode = "$sandbox_mode"
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
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

# === Claude: straight copy ===
echo "=== Syncing to ~/.claude ==="
mkdir -p ~/.claude

cp "$CLAUDE_SRC/CLAUDE.md" ~/.claude/

for dir in rules skills agents; do
    if [ -d "$CLAUDE_SRC/$dir" ]; then
        mkdir -p ~/.claude/$dir
        rsync -a "$CLAUDE_SRC/$dir/" ~/.claude/$dir/
    fi
done

echo "  CLAUDE.md, $(ls ~/.claude/rules/ 2>/dev/null | wc -l) rules, $(ls ~/.claude/skills/ 2>/dev/null | wc -l) skills, $(ls ~/.claude/agents/ 2>/dev/null | wc -l) agents"

# === Codex: unified dual-role AGENTS.md + rules inlined + shared skills + converted agents ===
echo "=== Syncing to ~/.codex ==="
mkdir -p ~/.codex/agents ~/.codex/skills

# Build AGENTS.md: codex/AGENTS.md + rules appended
{
    cat "$CODEX_SRC/AGENTS.md"
    echo ""
    echo "---"
    echo ""
    echo "## Rules"
    echo ""
    for rule_file in "$CLAUDE_SRC/rules/"*.md; do
        [ -f "$rule_file" ] || continue
        echo ""
        extract_rule_body "$rule_file"
        echo ""
    done
} > ~/.codex/AGENTS.md

# Copy all skills from Claude to Codex
rsync -a "$CLAUDE_SRC/skills/" ~/.codex/skills/

# Convert all agents from both sources to .toml
agent_count=0
for md_file in "$CLAUDE_SRC/agents/"*.md "$CODEX_SRC/agents/"*.md; do
    [ -f "$md_file" ] || continue
    basename="$(basename "$md_file" .md)"
    convert_agent_md_to_toml "$md_file" ~/.codex/agents/"$basename".toml
    agent_count=$((agent_count + 1))
done

echo "  AGENTS.md (dual-role + $(ls "$CLAUDE_SRC/rules/"*.md 2>/dev/null | wc -l) rules inlined), $(ls ~/.codex/skills/ 2>/dev/null | wc -l) skills, $agent_count agents"
echo "  Workspace-write agents: ${WORKSPACE_WRITE_AGENTS[*]}"

echo "=== Done ==="
