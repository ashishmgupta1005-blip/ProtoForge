# ProtoForge

**An idea → showable hardware product pipeline, as an interactive Claude Code skill.**

![ProtoForge demo — ESP32 GPS Tracker PCBA assembly](assets/demo_gps_tracker.webp)

> *Example output — a PCBA assembly animation ProtoForge produced for an ESP32 GPS tracker.*

ProtoForge takes an electronics idea through four phases — each with a hard exit
criterion — by orchestrating KiCad, FreeCAD and Blender from Claude Code:

| Phase | Tooling | Exit criterion |
|-------|---------|----------------|
| 1. Schematic | KiCad (text-authored, labels-on-pins) | **ERC-clean** |
| 2. PCB + autoroute | `pcbnew` + Freerouting + GND-pour finish | **DRC 0/0/0** (`--schematic-parity`) |
| 3. Enclosure | FreeCAD (MCP), mold-ready 2-part case fitted to the board | **STEP + STL** exported |
| 4. Animation | KiCad colored GLB → Blender cinematic assembly | **MP4** rendered |

It runs as a **guided wizard**: it interviews you, proposes a plan, then executes
phase-by-phase and stops for your approval at each phase boundary.

## What you get
- `skills/protoforge/SKILL.md` — the skill itself (portable; no hard-coded paths)
- `SETUP.md` — full setup: prerequisites, MCP servers, config, install, verify
- `config/protoforge.config.example` — where you put your local tool paths
- `mcp/claude_mcp_config.example.json` — example Claude Code MCP server entries
- `install.ps1` / `install.sh` — copy the skill into your `~/.claude/skills/`

## Quick start
1. Read **[SETUP.md](SETUP.md)** and install the toolchain + MCP servers.
2. Copy `config/protoforge.config.example` → `~/.claude/protoforge.config` and fill in your paths.
3. Run the installer (`install.ps1` on Windows, `install.sh` on macOS/Linux) to drop the
   skill into `~/.claude/skills/protoforge/`.
4. Open Claude Code and type `/protoforge`.

## Heads-up
ProtoForge is a **playbook**, not a standalone app. It only works on top of the local
toolchain in SETUP.md plus a Claude Code subscription/API. KiCad, FreeCAD, Blender and
Freerouting are third-party software under their own (mostly GPL/LGPL) licenses — see
[NOTICE.md](NOTICE.md). The skill text in this repo is under [LICENSE](LICENSE).
