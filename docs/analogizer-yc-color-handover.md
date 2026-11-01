# Analogizer Y/C Color Handover

## Status

The back-porch and colorburst fix described under "Applied Fix" shipped in v0.4.5 (`4d78448`). It still needs confirmation on the tester's Y/C and PAL-M setup. If color is still missing, the next steps are in "Suggested Tester Instructions".

## Problem

A tester using Mike's Y/C adapter reports that the GBA Analogizer core outputs a stable black-and-white image in Y/C modes. Their PAL-M TV normally shows NTSC/PAL inputs as black-and-white, but they use an NTSC-to-PAL-M transcoder. That same transcoder setup produces color with other Analogizer cores when choosing `Y/C NTSC`, but not with this GBA core.

Local RGBS output works. Local Y/C testing through an RGB/OSSC path only appears green, which is expected because Y/C mode repurposes the Analogizer pins and is not valid RGB.

The most likely remaining cause is invalid or misplaced Y/C colorburst timing. Stable monochrome means sync and luma are likely present, while chroma decode/colorburst lock is failing.

## Code State Before v0.4.5

Relevant files:

- `src/fpga/core/core_top.sv`
- `src/fpga/core/gba_analogizer_video.sv`
- `src/fpga/analogizer/openFPGA_Pocket_Analogizer_GBA.v`
- `src/fpga/analogizer/yc_out.sv`

Current GBA Analogizer raster timing in `core_top.sv`:

```verilog
.H_TOTAL         (536),
.H_ACTIVE        (480),
.H_FP            (4),
.H_SYNC          (40),
// H_BP = 536 - 480 - 4 - 40 = 12
```

Current Y/C encoder clock:

```verilog
.MASTER_CLK_FREQ (8_388_608),
.LINE_LENGTH     (536)
.i_clk           (clk_vid)
```

Current `yc_out` burst selection for this clock falls into the first branch because `PHASE_INC[39:32]` is high:

```verilog
cburst_length <= PAL_EN ? 10'd85 : 10'd90;
cburst_start <= 10'd40;
```

At `8.388608 MHz`, this means:

- `cburst_start=40` is about `4.77 us` after sync.
- `cburst_length=90` is about `10.73 us` after sync.
- Current back porch is only `12` clocks, about `1.43 us`.

Therefore the colorburst is almost certainly outside the valid back porch.

## Already Tried

The Y/C encoder HSync input was inverted in `openFPGA_Pocket_Analogizer_GBA.v` so Mike's `yc_out` sees active-high HSync for its internal burst timer:

```verilog
.hsync    (~Hsync),
```

This matches the SNES Analogizer pattern conceptually: SNES feeds active-high `HSync` into `yc_out`, while separately outputting active-low composite sync. This did not fix the tester's black-and-white output.

Also note there is a separate current change in `core_top.sv` for Pocket OFF modes: it sends black video with normal Pocket timing for a short period before disabling Pocket output, so the Pocket/dock does not hold the last frame.

## Comparison Notes

SNES Analogizer:

- `yc_out.hsync` receives active-high `HSync`.
- Composite sync output is generated separately as active-low `SYNC = ~^{HSync, VSync}`.
- Y/C encoder clock is about `42.95 MHz`, so the hardcoded `yc_out` colorburst counters are in a much more reasonable time range.

GBC Analogizer:

- Uses the same Mike Simone `yc_out.sv` implementation.
- Feeds `yc_out` at about `67.108864 MHz`.
- Also has a sync-fix stage before feeding Analogizer signals.

GBA differs because it drives `yc_out` at only `8.388608 MHz`, making the existing `yc_out` burst counters far too late in real time.

## Applied Fix (v0.4.5)

This test build targets the colorburst and back-porch timing directly:

1. Keep `H_TOTAL=536` to preserve the line rate near `15.65 kHz`.
2. Reduce `H_ACTIVE` from `480` to `432`.
3. Reduce `H_SYNC` from `40` to `36`.
4. Keep `H_FP=4`.
5. This yields `H_BP = 536 - 432 - 4 - 36 = 64` clocks, about `7.6 us`.
6. Reduce the widest image mode so it does not run into blanking/colorburst time.
7. Add a low-clock Y/C burst override in `yc_out.sv`, likely for `MASTER_CLK_FREQ == 8_388_608` or by detecting this large `PHASE_INC[39:32]` case.

Image width change in `gba_analogizer_video.sv`:

```verilog
localparam [9:0] IMG_W_WIDE   = 10'd416; // was 448
```

`IMG_W_LARGE=408` can probably stay as-is. Check `H_CENTER_OFFSET=6`; with `H_ACTIVE=432`, `IMG_W_WIDE=416` gives about 8 clocks nominal margin before the offset, and `IMG_W_LARGE=408` gives more margin.

Timing in `core_top.sv`:

```verilog
.H_TOTAL         (536),
.H_ACTIVE        (432),
.H_FP            (4),
.H_SYNC          (36),
// H_BP = 536 - 432 - 4 - 36 = 64
```

Low-clock burst timing in `yc_out.sv`:

```verilog
cburst_start  <= 10'd4;
cburst_length <= 10'd25;
```

At `8.388608 MHz`, this starts burst about `0.48 us` after sync and ends about `2.98 us` after sync, within the new `7.6 us` back porch. Adjust if needed based on scope/capture feedback.

## Design Constraints

- Do not reduce `H_TOTAL` as a first attempt. It changes line rate globally and may worsen compatibility.
- Do not expect local RGBS/OSSC testing to validate Y/C color. A real Y/C adapter plus composite/S-video-capable display/capture is needed.
- If possible, keep the change test-focused and reversible so the tester can compare builds.
- After changing horizontal active width, review all scale modes for overflow or overly clipped output.
- Build with `./scripts/build_analogizer.sh` or `./scripts/quartus-build-bg.sh --analogizer`.

## Suggested Tester Instructions

Ask Jonas to test:

- `Y/C NTSC` through the same NTSC-to-PAL-M transcoder chain that works with other Analogizer cores.
- `Y/C PAL` only as a secondary check; PAL-M compatibility is not the same as 625-line PAL.
- RGBS mode, to confirm no regression in the normal analog path.
- A saturated/colorful scene if possible, because chroma failure is easiest to see there.

If still black-and-white, ask whether the transcoder or capture device indicates NTSC color lock. If they have a scope, ask them to check for a colorburst packet on the back porch after each HSync.
