# Agent Notes

GBA core for the Analogue Pocket (openFPGA), with a second Analogizer build that drives a CRT raster path through the cartridge adapter. Two Quartus revisions share one project: `ap_core` (normal Pocket) and `ap_core_analogizer`. The Analogizer core is the one that gets released.

## Layout

- `src/fpga/core/` — core RTL. `core_top.sv` holds the top level and the Analogizer raster timing. `gba_analogizer_video.sv` handles CRT scale modes.
- `src/fpga/analogizer/` — Analogizer adapter glue and the Y/C encoder (`yc_out.sv`).
- `src/fpga/build/` — Quartus project (`gba_pocket.qpf`, `ap_core*.qsf`). `output_files/`, `db/` and `incremental_db/` are generated.
- `pkg/Cores/Orbitoid.GBA_Analogizer/` — Analogizer core package (JSON definitions; `interact.json` is the menu).
- `pkg/Cores/mincer_ray.GBA/` — normal Pocket core package.
- `docs/` — design notes and hardware test checklists.

## Building

Always go through `scripts/`. They run Quartus 21.1 in Docker (`raetro/quartus:21.1`), reverse the bitstream, and print timing. Do not use a host-installed Quartus.

- `./scripts/build_analogizer.sh` — Analogizer core, plus `build_output/Orbitoid.GBA_Analogizer-dev.zip` (SD card layout).
- `./scripts/build.sh` — normal Pocket core.
- `./scripts/quartus-build-bg.sh [--analogizer] start|status|wait|log|stop` — the same builds run detached, with state in `build_output/background-build*/`.
- `./scripts/seed_sweep.sh [start] [end]` — fitter seed sweep for the normal core. It rewrites `SEED` in `ap_core.qsf`.
- `./scripts/watch-build.sh` — follows the CI build for the current branch and downloads its artifacts.

A full compile takes several minutes. Don't start one unless the user asks, or unless an RTL change needs to be verified. Run only one build at a time, since both revisions write to `src/fpga/build/output_files/`.

## Verifying changes

- A build counts as passing only if the timing summary reports "Timing met." Check the per-clock setup slack, and the SDRAM paths in `build_output/reports/` when memory timing is involved.
- Video, Y/C and CRT changes can't be fully checked without hardware. Say what needs testing on a real Pocket or CRT. `docs/analogizer-crt-scaling-calibration.md` is the checklist for scale modes.
- When `interact.json` changes, keep its option values in sync with the RTL that decodes them.

## Git and releases

- Commit messages use conventional prefixes (`fix:`, `feat:`). CI (`.github/workflows/build-branch.yml`) builds the Analogizer core on every push to `main`.
- Releases come from the manual `Release` workflow (`build.yml`). It bumps `core.json`, tags the release and publishes the zip. Don't edit the version in `core.json` by hand.
- Never commit bitstreams (`*.rbf_r`) or Quartus outputs; they are gitignored.
