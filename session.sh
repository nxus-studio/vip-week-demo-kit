#!/usr/bin/env bash
# Opens Claude Code in a clone of vip-week-demo with one of the kit's prompts already sent.
#   ./session.sh <demo-dir> <prompt>      prompts: act1-juan act1-ana stale-ana correct-ana correct-juan sap-juan sap-ana
# What it sets for the session (nothing is written into the demo):
#   TZ=UTC                         the time-zone bug only shows when the process is not on Mexico City time
#   auto-memory off                so what the agent recalls comes from Lemma, not from Claude Code's own notes
#   Lemma's MCP                    the global `lemma` when installed (connected from the first turn, no background
#                                  proxy, as in the measured runs), else the
#                                  repo's .mcp.json (npx); approved, and its tools allowed without asking
#   edits accepted; git, jest, tsc and reading files allowed without asking; anything else still asks
#   ~/finanzas added as a readable directory when it exists (the SAP act, Juan's side only)
# Leave the session with /exit.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 2 ] && [ -f "$KIT/prompts/$2.txt" ] || { sed -n '2,3p' "$0"; ls "$KIT/prompts" | sed 's/\.txt$//; s/^/    /'; exit 1; }
cd "$1"
extra=()
[ -d "$HOME/finanzas" ] && extra+=(--add-dir "$HOME/finanzas")
if command -v lemma >/dev/null; then
  extra+=(--strict-mcp-config --mcp-config '{"mcpServers":{"lemma":{"command":"lemma","args":["mcp"],"env":{"LEMMA_MCP_NO_PROXY":"1"}}}}')
else
  extra+=(--settings '{"enableAllProjectMcpServers":true}')
fi
export TZ=UTC CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
exec claude ${extra[@]+"${extra[@]}"} \
  --permission-mode acceptEdits \
  --allowedTools 'mcp__lemma' 'Bash(git log:*)' 'Bash(git show:*)' 'Bash(git diff:*)' 'Bash(git status:*)' \
    'Bash(git blame:*)' 'Bash(git cat-file:*)' 'Bash(git rev-parse:*)' 'Bash(npx jest:*)' 'Bash(npm test:*)' \
    'Bash(npx tsc:*)' 'Bash(cat:*)' 'Bash(ls:*)' 'Bash(grep:*)' 'Bash(head:*)' 'Bash(wc:*)' 'Read' 'Grep' 'Glob' \
  -- "$(cat "$KIT/prompts/$2.txt")"
