# ProtoForge — Setup

ProtoForge orchestrates external tools from Claude Code via MCP. You need all of the
following installed and working **before** the skill can run.

## 1. Prerequisites

| Tool | Why | Notes |
|------|-----|-------|
| **Claude Code** | Runs the skill | With a Claude subscription or API key |
| **KiCad 10** | Schematic + PCB + `kicad-cli` (ERC/DRC/GLB export) | https://www.kicad.org |
| **KiPilot MCP** | Lets Claude drive KiCad's PCB editor | PCB-only (KiCad has no schematic API) |
| **FreeCAD** (≥1.0) | Enclosure modeling | https://www.freecad.org |
| **freecad-mcp** | Lets Claude drive FreeCAD over RPC | neka-nat/freecad-mcp (addon + uvx server) |
| **Blender** (4.x) | PCBA assembly animation | https://www.blender.org |
| **blender-mcp** | Lets Claude build the Blender scene | ahujasid/blender-mcp (addon + server) |
| **Java 21+** + **Freerouting** | PCB autoroute (DSN→SES) | https://github.com/freerouting/freerouting (jar) |

> macOS/Linux work too, but paths differ — put the right paths in your config (step 3).

## 2. Install the MCP servers

ProtoForge expects three MCP servers registered in Claude Code: **kipilot**, **freecad**,
**blender**. See `mcp/claude_mcp_config.example.json` for the shape of the entries; adapt the
commands/paths to your install, then add them to your Claude Code MCP config.

Per-server setup:
- **KiPilot (KiCad):** install the KiPilot MCP server; enable KiCad's IPC API
  (Preferences → Plugins → enable IPC), then restart KiCad so the socket is live.
  *Known quirk:* some KiCad builds crash on **Update-PCB-from-Schematic (F8)** while the IPC
  API is enabled — disable IPC for that one action, then re-enable.
- **FreeCAD:** drop the `freecad-mcp` addon into FreeCAD's `Mod` directory, run the MCP server
  (e.g. via `uvx`), and **start the RPC server from inside FreeCAD** before use.
- **Blender:** install the `blender-mcp` addon, enable it, and start its server from the addon
  panel. Keep Blender open while ProtoForge runs the animation phase.

Verify in Claude Code that all three servers connect.

## 3. Configure your tool paths

ProtoForge calls some CLIs directly (kicad-cli, blender, java, the freerouting jar). Copy the
example config and fill in **your** paths:

```
cp config/protoforge.config.example ~/.claude/protoforge.config   # macOS/Linux
copy config\protoforge.config.example %USERPROFILE%\.claude\protoforge.config   :: Windows
```

If a path is left blank, ProtoForge will try to find the tool on your `PATH`, and if it still
can't, it will ask you for the location on first run (and offer to save it).

## 4. Install the skill

Run the installer for your OS (it copies `skills/protoforge/` into `~/.claude/skills/`):

```
# Windows (PowerShell)
./install.ps1

# macOS / Linux
bash install.sh
```

Or manually: copy the `skills/protoforge` folder into `~/.claude/skills/` (so you end up with
`~/.claude/skills/protoforge/SKILL.md`).

## 5. Run it

Open Claude Code and type:

```
/protoforge
```

It will interview you, propose a plan, and walk the phases with an approval gate after each.

## Troubleshooting
- `/protoforge` doesn't appear → check the skill is at `~/.claude/skills/protoforge/SKILL.md` and restart Claude Code.
- A phase can't find a tool → fill its path in `~/.claude/protoforge.config`.
- MCP server "not connected" → re-check the server is running and registered; for FreeCAD/Blender, confirm the in-app RPC/server is started.
- Autoroute fails → confirm Java runs the Freerouting jar from the configured paths.
