# Analogizer Timing Closure

How the `ap_core_analogizer` revision is closed against upstream's `ap_core`,
and what to redo after an RTL change.

## Baseline

The bar is the upstream mincer-ray release core built unchanged with its
committed settings (v1.0.1, `ap_core`, SEED 4):

| Metric                      | Upstream v1.0.1 | Analogizer (SEED 75) |
|-----------------------------|-----------------|----------------------|
| Worst setup slack           | +0.004 ns       | +0.119 ns            |
| Worst hold slack            | +0.095 ns       | +0.120 ns            |
| TNS                         | 0               | 0                    |
| SDRAM read                  | +0.643          | +0.647               |
| SDRAM write                 | +2.820          | +2.814               |
| CRAM0 output setup / hold   | +0.494 / +5.707 | +0.494 / +5.707      |
| CRAM0 input setup / hold    | +3.044 / +0.870 | +3.048 / +1.108      |
| clk_74a / bridge_spiclk setup | +2.988 / +10.226 | +2.571 / +9.928   |
| ALMs                        | 17,762 (96%)    | 18,031 (98%)         |

SEED 75 came out of a sweep of about 130 seeds. No seed beat upstream on every
row. SDRAM write is 6 ps lower because of the clock network delay described
below. The clk_74a and bridge_spiclk rows are bridge-side paths with multiple
nanoseconds of margin in both builds.

Upstream has no Analogizer build, so this is the only baseline available. Our
Analogizer core is a larger design (about 97% of ALMs), so closing it takes the
setup below on top of a seed choice.

## What is pinned in `ap_core_analogizer.qsf`

- **sys_pll output counters** (`PLLOUTPUTCOUNTER_*`) at upstream's locations.
  Left free, the fit chose different counters and the SDRAM read capture lost
  about 1.2 ns of clock skew.
- **Global clock buffers** (`CLKCTRL_G*`) for every clock, at upstream's
  assignment. Left free, SDRAM write and CRAM0 slack came in below upstream on
  every seed.
- **SDRAM output delay chains** (`D5_DELAY` / `D5_OE_DELAY`) copied per pin
  from upstream's fit.

## Fitter-only margin (`src/fpga/core/analogizer_fit_margin.sdc`)

These constraints apply only while `quartus_fit` runs. Signoff in `quartus_sta`
uses `core_constraints.sdc` alone, so reported slack is measured against the
real limits.

- +0.1 ns hold uncertainty inside `clk_sys` and inside `clk_74a`. The
  hold-critical paths are register to M10K inputs (OAM, BIOS and cache RAMs).
- CRAM0 read data budget 0.35 ns tighter than one `clk_sys` period.

Two things tried and dropped: hold margin on all clocks padded the SDRAM
output delay chains and cost write setup, and a setup margin made placement
worse at this utilization.

## Remaining variation

A few picoseconds of global clock network delay into the SDRAM and CRAM0 I/O
registers depends on the clock's regional load, so it moves from seed to seed
and no assignment controls it. This shows up as SDRAM write slack of
2.814 to 2.820 ns, and as CRAM0 output setup and hold moving by ±2 ps in
opposite directions.

## After an RTL change

1. Build once with `./scripts/build_analogizer.sh` and compare against the
   table above.
2. If it misses, sweep seeds. The fit is chaotic at this utilization, and only
   a few percent of seeds pass both setup and hold.
3. Keep the pins and the margin SDC unless the clocking or I/O changes. If
   upstream's clocking changes, re-derive the pins from a fresh upstream build
   (the "Global & Other Fast Signals" and "Delay Chain Summary" tables in
   `ap_core.fit.rpt`).
