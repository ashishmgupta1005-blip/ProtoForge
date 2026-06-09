#!/usr/bin/env bash
# ProtoForge installer (macOS / Linux)
# Copies the skill into ~/.claude/skills and seeds the config if missing.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude="${HOME}/.claude"
skills="${claude}/skills/protoforge"

mkdir -p "${skills}"
cp -Rf "${repo}/skills/protoforge/." "${skills}/"
echo "Installed skill -> ${skills}"

cfg="${claude}/protoforge.config"
if [ ! -f "${cfg}" ]; then
  cp "${repo}/config/protoforge.config.example" "${cfg}"
  echo "Seeded config  -> ${cfg}  (edit it with your tool paths)"
else
  echo "Config exists  -> ${cfg}  (left untouched)"
fi
echo
echo "Next: 1) edit ${cfg}   2) register the MCP servers (see SETUP.md)   3) run /protoforge in Claude Code"
