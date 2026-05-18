# Analogizer CRT Scaling Calibration Checklist

Use this checklist with the GBA 240p Test Suite ROM. The GBA framebuffer is 240x160, even if the test ROM filename says 240p.

The goal is to confirm that each Analogizer CRT scale mode does what it claims on a real CRT, using visible edges, centering, and physical measurements from the grid pattern.

## Current Mode Rules

These are the current mode rules in `src/fpga/core/gba_analogizer_video.sv` and `pkg/Cores/Orbitoid.GBA_Analogizer/interact.json`.

| Menu name | Value | Current output size | Current behavior |
| --- | ---: | ---: | --- |
| No Scale / Square | 0 | 240x160 | Source pixels are output 1:1 horizontally and vertically. |
| Small / Stretch | 1 | 320x160 | No vertical scaling; horizontal nearest-neighbor stretch. |
| Wide / Overscan | 2 | 448x160 | No vertical scaling; wider horizontal nearest-neighbor stretch. |
| Aspect / Blend | 3 | 320x160 | No vertical scaling; horizontal stretch with interpolation. |
| Scaled Full Width | 4 | 408x204 | Large horizontally centered mode with horizontal interpolation, a small CRT-tuned downward offset, and the same 2:1 output shape as the previous larger mode. |
| Full Screen / Square | 5 | 336x224 | Uniform nearest-neighbor scale of the square-pixel mode that intentionally does not match GBA display aspect. |

## Intended Final Modes

These are the practical user-facing targets to calibrate toward.

| Target mode | Goal |
| --- | --- |
| No Scale / Square | Small 1:1 source-pixel image. No scaling. Grid cells should look too narrow compared with real GBA aspect, but source pixels should be clean and unscaled. |
| Small / Stretch | Same 160-line height as no-scale, but horizontally stretched to the correct GBA screen aspect. Grid cells should measure square on the CRT. |
| Wide / Overscan | Same 160-line height as no-scale, but much wider. This is a horizontal overscan option, not the vertical-fill option. |
| Vertical Fill / Overscan | Future mode idea: vertically fills the usable CRT screen height while preserving correct GBA aspect, so the left and right sides intentionally run off the CRT edges. |
| Scaled Full Width | Horizontally fills most of the usable CRT screen width without touching porch timing. It uses horizontal interpolation and keeps the same 2:1 output shape as the previous larger mode. |
| Full Screen / Square | Scales the square-source-pixel presentation up until it fills almost all of the CRT screen. This intentionally breaks GBA display aspect and should look too tall, but it is useful as a user option. |

## Test Setup

- [ ] Use the same CRT geometry settings for the whole test pass.
- [ ] Disable any CRT service-menu overscan adjustments made only for one mode.
- [ ] Use the same Analogizer video output type for the whole pass, such as RGBS or Y/C NTSC.
- [ ] Let the CRT warm up for at least 10 minutes before measuring.
- [ ] Load the GBA 240p Test Suite ROM.
- [ ] Open the grid pattern.
- [ ] Use calipers or a ruler directly on the CRT glass for width and height measurements.
- [ ] Record measurements from the center of the screen, not the curved corners.
- [ ] Treat small CRT geometry errors near the corners as CRT behavior unless the center measurements are also wrong.

## Global Questions For Every Mode

- [ ] Is the image horizontally centered within that mode's intended visible area?
- [ ] Is the image vertically centered within that mode's intended visible area?
- [ ] Is the top edge stable, without vertical rolling, foldover, or tearing?
- [ ] Are the left and right edges stable, without horizontal jitter or sync instability?
- [ ] Are the black borders black, not showing repeated edge pixels or garbage pixels?
- [ ] Does the image start and end cleanly, without a one-pixel colored line before or after the game image?
- [ ] On the grid, are straight vertical lines visibly straight through the center of the screen?
- [ ] On the grid, are straight horizontal lines visibly straight through the center of the screen?
- [ ] Does switching away from the mode and back preserve the same position and size?
- [ ] Does cold booting directly into the mode preserve the same position and size?

## Measuring Aspect Ratio

Use the grid pattern for physical measurements.

- [ ] Pick one grid cell near the center of the screen.
- [ ] Measure the visible width of that cell.
- [ ] Measure the visible height of that cell.
- [ ] For modes intended to match GBA screen aspect, confirm the cell width and height are approximately equal.
- [ ] Repeat the measurement on a second center-area cell to catch local CRT distortion.
- [ ] Do not use corner cells for pass/fail aspect decisions unless the center already passes.

## No Scale / Square

Purpose: verify the unscaled source-pixel baseline.

Expected behavior: 240x160 output clocks. The whole GBA image should be visible with black borders around it. Grid cells are expected to look horizontally compressed compared with correct GBA display aspect.

- [ ] Can you see the full top edge of the grid?
- [ ] Can you see the full bottom edge of the grid?
- [ ] Can you see the full left edge of the grid?
- [ ] Can you see the full right edge of the grid?
- [ ] Is there no intentional crop on any side?
- [ ] Is the image smaller than all other scaled modes?
- [ ] Does one source-pixel-wide grid detail look as sharp as this CRT/video output can show?
- [ ] Are vertical grid lines clean, with no interpolation softness?
- [ ] Are horizontal grid lines clean, with no vertical interpolation softness?
- [ ] Do measured grid cells look narrower than they are tall? This should pass for this mode because it is square source pixels, not corrected GBA display aspect.
- [ ] Record visible image width: ____ mm.
- [ ] Record visible image height: ____ mm.
- [ ] Pass/fail notes: ____.

## Small / Stretch

Purpose: no vertical scaling, horizontally stretched to correct GBA screen aspect.

Expected behavior: same 160-line height as `No Scale / Square`, but wider. The full image should be visible. Grid cells should measure square near the center of the CRT.

- [ ] Is the visible image height the same as `No Scale / Square`?
- [ ] Is the visible image horizontally wider than `No Scale / Square`?
- [ ] Can you see the full top edge of the grid?
- [ ] Can you see the full bottom edge of the grid?
- [ ] Can you see the full left edge of the grid?
- [ ] Can you see the full right edge of the grid?
- [ ] Is there no intentional crop on any side?
- [ ] Does a center grid cell measure approximately square?
- [ ] Does a second center-area grid cell also measure approximately square?
- [ ] If the grid cells are wider than tall, note that horizontal scale is too large.
- [ ] If the grid cells are taller than wide, note that horizontal scale is too small.
- [ ] Record center grid cell width: ____ mm.
- [ ] Record center grid cell height: ____ mm.
- [ ] Record visible image width: ____ mm.
- [ ] Record visible image height: ____ mm.
- [ ] Pass/fail notes: ____.

## Wide / Overscan

Purpose: provide a wider 160-line horizontal overscan option.

Expected behavior: same 160-line height as `No Scale / Square` and `Small / Stretch`, but much wider. Left and right edges may be off-screen depending on CRT geometry. This mode is not expected to fill the CRT vertically.

- [ ] Is the visible image height the same as `No Scale / Square` and `Small / Stretch`?
- [ ] Is the visible image horizontally wider than `Small / Stretch`?
- [ ] Are the top and bottom grid edges fully visible?
- [ ] Are the left and right grid edges cropped by the CRT, or very close to the CRT edges?
- [ ] Is the horizontal crop roughly symmetrical, with similar loss on the left and right sides?
- [ ] Is the important center of the image still centered on the CRT?
- [ ] Does a center grid cell measure approximately square?
- [ ] Does the mode feel clearly distinct from `Small / Stretch`?
- [ ] If the grid cells are wider than tall, note that horizontal scale is too large for aspect-correct wide mode.
- [ ] If the grid cells are taller than wide, note that horizontal scale is too small for aspect-correct wide mode.
- [ ] Record center grid cell width: ____ mm.
- [ ] Record center grid cell height: ____ mm.
- [ ] Record approximate left crop: ____ grid columns or ____ mm.
- [ ] Record approximate right crop: ____ grid columns or ____ mm.
- [ ] Pass/fail notes: ____.

## Vertical Fill / Overscan

Purpose: future mode target that fills the CRT vertically while preserving GBA screen aspect, accepting larger horizontal overscan.

Current candidate: not currently implemented as a distinct mode.

Expected behavior: vertical game area fills the usable CRT height. Left and right edges are expected to be off-screen. Center grid cells should measure square if enough of the grid is visible to measure.

- [ ] Does the game image fill the usable CRT height from top to bottom?
- [ ] Is the top grid edge at or just beyond the top visible CRT boundary?
- [ ] Is the bottom grid edge at or just beyond the bottom visible CRT boundary?
- [ ] Are the left and right grid edges intentionally cropped by the CRT?
- [ ] Is the horizontal crop roughly symmetrical, with similar loss on the left and right sides?
- [ ] Is the important center of the image still centered on the CRT?
- [ ] Does a center grid cell measure approximately square?
- [ ] Does the vertical fill look like a real overscan mode rather than a small centered image?
- [ ] Is there no black bar above the image, except normal CRT edge behavior?
- [ ] Is there no black bar below the image, except normal CRT edge behavior?
- [ ] If the grid cells are wider than tall, note that horizontal scale is too large or vertical scale is too small.
- [ ] If the grid cells are taller than wide, note that horizontal scale is too small or vertical scale is too large.
- [ ] Record center grid cell width: ____ mm.
- [ ] Record center grid cell height: ____ mm.
- [ ] Record approximate left crop: ____ grid columns or ____ mm.
- [ ] Record approximate right crop: ____ grid columns or ____ mm.
- [ ] Pass/fail notes: ____.

## Scaled Full Width

Purpose: fill the CRT horizontally while keeping horizontal scaling clean.

Current candidate: `Scaled Full Width`.

Expected behavior: left and right image edges touch or nearly touch the usable CRT screen width. The full image should remain visible horizontally. Horizontal source pixels are interpolated across 408 output clocks. Vertical source pixels are mapped to 204 output lines, preserving the 2:1 output shape of the previous larger mode. The image is shifted down 10 lines from mathematical raster center to better match CRT-visible centering.

- [ ] Does the left edge of the grid reach the left usable CRT boundary without being cropped?
- [ ] Does the right edge of the grid reach the right usable CRT boundary without being cropped?
- [ ] If the image does not reach both side boundaries, record how much horizontal gap remains.
- [ ] If either side is cropped, record how much crop occurs.
- [ ] Are the left and right gaps or crops symmetrical?
- [ ] Are there visible black bars above and below the image?
- [ ] Are the top and bottom grid edges fully visible?
- [ ] Does a center grid cell measure approximately square?
- [ ] Does a second center-area grid cell also measure approximately square?
- [ ] Is the image vertically centered between the top and bottom black bars?
- [ ] Are vertical grid lines sharp, without horizontal interpolation softness?
- [ ] During vertical scrolling, is the line-repeat cadence less wobbly than the old +12.5% mode?
- [ ] Record center grid cell width: ____ mm.
- [ ] Record center grid cell height: ____ mm.
- [ ] Record left horizontal gap or crop: ____ mm.
- [ ] Record right horizontal gap or crop: ____ mm.
- [ ] Record top black bar: ____ mm.
- [ ] Record bottom black bar: ____ mm.
- [ ] Pass/fail notes: ____.

## Full Screen / Square

Purpose: scale the `No Scale / Square` shape up until it fills the CRT screen, even though this intentionally breaks the GBA screen aspect.

Current candidate: `Full Screen / Square`.

Expected behavior: the square-source-pixel image is enlarged to 336x224 output clocks with the same scale factor horizontally and vertically. It should not match the correct GBA display aspect. This is intentional for this mode.

- [ ] Does the image fill the usable CRT height?
- [ ] Does the mode look like a uniformly enlarged version of `No Scale / Square`?
- [ ] Are colors correct and stable in this mode, matching the other CRT scale modes?
- [ ] Are all four grid edges visible, or is any crop intentional for the selected fill target?
- [ ] Is any crop roughly symmetrical left/right and top/bottom?
- [ ] Does the center of the grid remain centered on the CRT?
- [ ] Do measured grid cells clearly show this is not an aspect-correct GBA mode?
- [ ] Does the image visibly look too tall compared with `Small / Stretch` or `Scaled Full Width`? This should pass for this mode.
- [ ] Are there no black bars unless unavoidable because of CRT geometry?
- [ ] Record center grid cell width: ____ mm.
- [ ] Record center grid cell height: ____ mm.
- [ ] Record visible image width: ____ mm.
- [ ] Record visible image height: ____ mm.
- [ ] Pass/fail notes: ____.

## Cross-Mode Sanity Checks

- [ ] `No Scale / Square` and `Small / Stretch` have the same visible height.
- [ ] `Small / Stretch` is wider than `No Scale / Square`.
- [ ] `Small / Stretch` grid cells measure square, while `No Scale / Square` grid cells do not.
- [ ] `Wide / Overscan` has the same visible height as `Small / Stretch` but more horizontal fill or crop.
- [ ] `Vertical Fill / Overscan`, when implemented, fills more vertical CRT area than `Wide / Overscan`.
- [ ] `Wide / Overscan` crops left and right more than `Scaled Full Width`.
- [ ] `Scaled Full Width` has little to no left/right border on the CRT.
- [ ] `Full Screen / Square` fills more total CRT area than `No Scale / Square` while intentionally breaking GBA display aspect.
- [ ] Mode names in the menu match the behavior observed on the CRT.

## Build Notes To Feed Back Into Code

Use these notes after each CRT pass to decide what to adjust.

- [ ] If a mode is centered but too small, increase that mode's output width, output height, or both.
- [ ] If a mode has correct size but is off-center, adjust the image-left or image-top positioning rule.
- [ ] If aspect-correct modes have grid cells wider than tall, reduce horizontal scale or increase vertical scale.
- [ ] If aspect-correct modes have grid cells taller than wide, increase horizontal scale or reduce vertical scale.
- [ ] If `Scaled Full Width` leaves side gaps, increase cautiously; 480-clock active width was observed to disturb colors and overscan both sides.
- [ ] If `Vertical Fill / Overscan` is added, adjust horizontal scale after vertical size is correct.
- [ ] Verify `Full Screen / Square` is intentionally marked as aspect-broken in the menu or release notes.
