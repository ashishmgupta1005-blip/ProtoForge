---
name: protoforge
description: >-
  ProtoForge — end-to-end hardware product pipeline that takes an electronics
  idea to a showable product through four phases: KiCad schematic → PCB layout +
  autoroute → FreeCAD injection-mold-ready enclosure → Blender cinematic PCBA
  assembly animation. Use when the user wants to design a board, design/print a
  case for an existing board, produce a PCBA showcase/assembly animation, or run
  the whole "board to box" flow. Also triggers on: "protoforge", "board2box",
  "make a case for this PCB", "PCBA assembly animation".
argument-hint: "[project name or path] [optional: phase = schematic|pcb|case|animation]"
---

# ProtoForge

A repeatable **idea → showable hardware product** pipeline. Four phases, each with a
hard exit criterion. Run the whole thing or jump to one phase.

## Inputs & scope
- **Project**: a name or path. Default layout: `<root>\PCB\`, `<root>\Case design\`, `<root>\Animation\`.
- **Phase** (optional): `schematic` | `pcb` | `case` | `animation`. If omitted and the project
  already has artifacts, **ask which phase** (don't redo finished, clean phases).
- Before any destructive regen, check what already exists. **NEVER regenerate a board whose
  3D the user has hand-edited** (see Phase-2 rule). Confirm outward/irreversible steps.

## Configuration (tool paths — keeps this portable)
ProtoForge calls some CLIs directly. Resolve each tool in this order:
1. The user config file `~/.claude/protoforge.config` (KEY=VALUE) — keys
   `KICAD_CLI`, `BLENDER`, `JAVA`, `FREEROUTING_JAR`, optional `KICAD_FOOTPRINTS`.
2. Otherwise discover on `PATH` (`kicad-cli`, `blender`, `java`).
3. If still not found, **ask the user for the path and offer to save it** to the config.
Refer to them below as `<KICAD_CLI>`, `<BLENDER>`, `<JAVA>`, `<FREEROUTING_JAR>`. Never assume
another machine's paths — different OS/username/install locations.

## Interactive wizard — DEFAULT mode (run ProtoForge as a guided agent)
ProtoForge runs as a **conversational wizard**: interview → plan → execute phase-by-phase with
an approval gate after each phase. Drive it with `AskUserQuestion` (batch related questions,
≤4 per call, recommended option first). Do NOT silently run the whole pipeline.

**Step 0 — Intake interview.** Establish (free-text "Other" always allowed):
  - Project: **new or existing?** name/path. If existing, scan the three subfolders and report
    what's already done (and clean) — don't redo finished phases.
  - **Scope** (multiSelect): which phases — schematic / pcb / case / animation.
  - If schematic or pcb: **MCU/module**, **peripherals**, **power input**, **connectors**,
    **layer count** (capture into `PCB/DESIGN.md` net/pin map).
  - If case: **style** (screwed 2-part / snap-fit), **look/colour**, **board retention**
    (posts vs ledge), any **windows/labels**.
  - If animation: **clean vs cinematic**, **length**, **resolution**.

**Step 1 — Plan & approve.** Summarise the plan (phases, key choices, deliverables, folder
layout) and ask for explicit **approve / revise / cancel**. Create a task list (one per phase).

**Step 2 — Execute with phase gates.** For each phase, in order:
  1. Mark the task in progress.
  2. Do the work (per the phase sections below).
  3. **Verify the exit criterion with actual tool output** (ERC 0 / DRC 0/0/0 / case STEP+STL /
     MP4) — render a check still/frame where useful and show it.
  4. **STOP at the phase boundary**: present a checkpoint (what was produced, exit-criterion
     result, file paths, a preview) and ask **approve & continue / revise / stop**. Only advance
     on approval; mark the task done.

**Step 3 — Forks & safety.** Use `AskUserQuestion` for any genuine decision (connector
placement, enclosure trade-offs, animation style, a board-3D-edit conflict). Surface constraints
instead of guessing. Honour the never-regenerate-hand-edited-board rule; confirm irreversible steps.

**Step 4 — Wrap-up.** Record project status + any new gotcha (in the repo or your notes), list
deliverables, and offer tunables (animation pacing/DOF/dust/1080p; case ribs/fillets; re-route).

> If the user says "just run it" / "don't ask", downgrade to autonomous: defaults + stop only on
> real forks or failures. Otherwise stay in wizard mode.

## Toolchain
- **KiCad 10** + **KiPilot MCP** (PCB only — no schematic API) and `<KICAD_CLI>` for ERC/DRC/GLB.
  IPC quirk: some builds crash on Update-PCB (F8) while IPC is on — disable for F8, re-enable.
- **Freerouting** via `<JAVA> -jar <FREEROUTING_JAR>` for autoroute.
- **FreeCAD MCP** (`mcp__freecad__execute_code`, live RPC) for the enclosure.
- **Blender** (`<BLENDER>`) + **Blender MCP** for scene building; **render headless** in a
  separate process.

---

## Phase 1 — Schematic  →  exit: ERC-clean
- KiCad has **no schematic scripting API** and KiPilot is PCB-only, so **author the
  `.kicad_sch` as text** via a re-runnable Python generator (`PCB/gen_sch.py`).
- Connectivity by **labels placed exactly on pin tips, NO wires**. Symbol libs are Y-up
  (pin at lib (lx,ly) → instance (Ox+lx, Oy−ly)); snap origins to the 2.54 mm grid (else
  `endpoint_off_grid`). Embed installed std symbol defs verbatim (rename leading id, e.g.
  `Device:R`) to avoid `lib_symbol_mismatch`. One `PWR_FLAG` on GND.
- Validate headless: `<KICAD_CLI> sch erc`. Keep `PCB/DESIGN.md` as the net/pin source of truth.

## Phase 2 — PCB layout + autoroute  →  exit: DRC 0/0/0 (`--schematic-parity`)
- Two re-runnable scripts in `PCB/`: `build_pcb.py` (pcbnew: parse netlist, load footprints,
  assign pad nets, place per floorplan, draw Edge.Cuts) and `finish_pcb.py` (import SES, zones,
  stitching vias, fill, link 3D models).
- Route via **DSN → Freerouting → SES**. **GND trick** (dense 2-layer): do NOT strip GND from
  the DSN — let Freerouting route GND as tracks (no zones at export), then pour; avoids
  isolated-pour islands.
- Gotchas: mounting-hole NPTH footprints break `ExportSpecctraDSN` → add holes AFTER routing;
  board nets are `/`-prefixed (`FindNet("/GND")`); PinHeader/RJ45/SOIC footprint origins are at
  pad 1 not centre; via drill ≥ board min (0.3 mm). Final: `<KICAD_CLI> pcb drc --schematic-parity`.
- **Hand-edited 3D rule**: once the user tweaks the board's 3D (adds/moves models, offsets,
  rotations), DO NOT re-run build/finish (they wipe `Models()`). Edit the saved `.kicad_pcb`
  **surgically** (LoadBoard → move footprints → `RemoveNative` tracks/zones → re-route →
  re-pour → Save, never touching `Models()`).

## Phase 3 — Enclosure  →  exit: 2-part case fitted to the board, STEP+STL exported
- FreeCAD MCP. Import the board STEP; **case frame = board STEP frame** (KiCad Y already negated
  on export → identity transform).
- Build **molding-ready** 2-part screwed case: drafted walls (~1.5° via `makeLoft`, wider at the
  z parting line), ~2.2 mm walls, board-rest ledge, 4 corner **screw bosses** (external
  drafted-cone lugs clear of dense areas) with M2.5 self-tap pilots + countersunk lid holes.
- **Measure features off the board** by intersecting thin slab boxes (`board.common(box)`) and
  reading `BoundBox` — locate connectors, the display/active face, tallest part. Cut connector
  openings; **connectors straddle the parting line → cut in BOTH base and lid**. Optional
  engraved label via `Draft.make_shapestring`.
- Export `Case_Base/Case_Lid.{step,stl}` + an assembly STEP; mesh via
  `MeshPart.meshFromShape(LinearDeflection=0.1..0.15, AngularDeflection=0.35)`.
- Iterate by cutting/fusing into the EXISTING `.Shape` (preserve windows/engraving).

## Phase 4 — Showcase animation  →  exit: rendered MP4 in `Animation/`
- **Colors come from KiCad, not a single mesh.** Export a colored GLB (reads the saved board —
  does NOT regenerate): `<KICAD_CLI> pcb export glb -o board_color.glb --subst-models
  --include-tracks --include-zones --include-silkscreen --include-soldermask --force <pcb>`.
  Case base/lid stay FreeCAD STL.
- **House style:** **opaque matte off-white case** (~0.84, rough 0.5) + **rich saturated green**
  soldermask (scan Principled nodes for green-dominant base → ~(0.01,0.16,0.04)). NOT translucent.
- **Blender assembly:** import GLB **without joining** (keeps every part separate; components get
  ref-designator names C/R/D/U/J, but the bare-board layers get junk object names → **detect
  board layers by `o.data.name`** containing soldermask/copper/silkscreen/via/_pcb). Hierarchy
  `Pivot(turntable) → Asm(holds the ×10 align scale+translate) → all meshes`. Align `Asm` by
  matching the **full all-meshes world bbox** to the FreeCAD board bbox ×0.01.
- **Cinematic choreography**: bare board drops onto a glossy table (impact + bounce) → **dust
  burst** (PARTICLE_SYSTEM, low gravity + up normal, instanced tiny mote,
  `show_instancer_for_render=False`) → components **fade-fall** (per-comp `material.copy()`,
  `surface_render_method='DITHERED'`, keyframe Principled **Alpha 0→1**) → base rises in → lid
  seals → slow turntable. Moody dark world + warm key/cool rim, DOF (focus_object=Pivot),
  `render.use_motion_blur`, animated camera (low→rising→hero, TRACK_TO Pivot).
- **Rigging traps (heed them):** (1) STL `import(global_scale=0.01)` sets OBJECT scale, not mesh
  — never reset `matrix_world=Identity` (balloons to mm). (2) Repeated `matrix_world=W` round-trips
  shear a scaled object → if a transform gets corrupted, **re-import the GLB fresh**. (3) Parent
  ALL siblings to the pivot with the SAME `matrix_parent_inverse=pivot.world.inverted()` at rot 0,
  or parts fly off during the spin. (4) `animation_data_clear()` freezes at the current frame —
  capture baselines first. (5) Don't iterate a saved object list after `object.join()`.
- **Render headless, never through the MCP socket:** `bpy.ops.render.render(animation=True)` over
  MCP blocks Blender's main thread → socket drops, 0-byte file. Bake render+ffmpeg+frame settings
  into the `.blend`, save, then `<BLENDER> -b file.blend -a` in a background process; FFMPEG H264
  output appends `0001-NNNN` — rename to a clean name when done.

---

## Execution notes
- Work phase-by-phase; report each exit criterion with the actual tool output before moving on.
- Keep everything re-runnable (scripts in `PCB/`, the `.blend` + `parts/*.glb` in `Animation/`).
- Offer the obvious tunables at the end (animation pacing, DOF, dust, 1080p; case ribs/fillets).
