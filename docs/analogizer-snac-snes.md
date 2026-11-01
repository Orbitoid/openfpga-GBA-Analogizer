# Analogizer SNAC SNES Controller

Hardware notes and test checklist for the SNES controller on the Analogizer
SNAC port (`GBA_Analogizer` core only).

## Wiring

The core uses the Analogizer SNAC configuration A pin map for SNES, the same
one used by RndMnkIII's `openFPGA_Pocket_Analogizer_SNAC` module, so any
MiSTer-style SNES SNAC adapter should work.

| SNAC (USB3) | Analogizer name | Pocket cart pin      | Direction | SNES signal |
|-------------|-----------------|----------------------|-----------|-------------|
| D-          | OUT1            | `cart_tran_bank1[6]` | out       | CLK         |
| D+          | OUT2            | `cart_tran_bank1[7]` | out       | LATCH       |
| RX-         | IO3             | `cart_tran_bank0[4]` | in        | DATA (P1)   |
| GND_D       | IO5             | `cart_tran_pin30`    | out       | CLK2        |

`bank0` is an input while the core runs (driven high only during reset).
`pin30` drives CLK2 only while SNES is selected, and is an input otherwise.

## Protocol

`src/fpga/analogizer/snac_snes.sv` polls at about 2.8 kHz: a 100 kHz strobe,
LATCH high for about 20 us, then 16 clock pulses with data sampled on each
falling edge. Bits 12-15 (controller ID) must read as "not pressed". If they
don't, the poll is dropped and no buttons are reported, so a missing or
unpowered controller cannot hold buttons down.

## Settings

`analogizer_settings` at bridge address `0xA0000000`:

| Bits    | Meaning                                         | Menu entry            |
|---------|-------------------------------------------------|-----------------------|
| `[4:0]` | SNAC type: 0 = None, 3 = SNES                   | SNAC Controller       |
| `[6]`   | SNAC only (ignore Pocket/dock controls)         | SNAC Controller       |
| `[8]`   | Face buttons: 0 = A/B, 1 = B/Y act as GBA A/B   | SNAC Buttons          |
| `[9]`   | Disable Turbo/Fast Forward on the SNES pad      | SNAC Buttons          |
| `[13:10]` | Analog video type                             | Analogizer Video Out  |

Menu option values: SNAC Controller None = 0, SNES + Pocket = 3,
SNES Only = 67. SNAC Buttons values are 0, 256, 512 and 768.

## Hardware test checklist

Run on a real Pocket with the Analogizer and a SNES SNAC adapter:

- [ ] SNAC Controller = None: Pocket controls work, SNES pad does nothing.
- [ ] SNES + Pocket: every SNES button registers (D-pad, A, B, L, R, Start,
      Select); Pocket controls still work at the same time.
- [ ] SNES Only: Pocket face buttons and D-pad are ignored; SNES pad works.
- [ ] SNAC Buttons = A/B, X Turbo, Y FF: Y triggers Fast Forward (per Fast
      Forward Mode), X triggers Turbo when Button Turbo is enabled.
- [ ] B/Y, A Turbo, X FF: SNES B = GBA A, SNES Y = GBA B.
- [ ] A/B Only and B/Y Only: X/Y (or A/X) do nothing.
- [ ] Unplug the SNES controller mid-game: no stuck buttons. Plug it back in:
      input resumes.
- [ ] Unplug the SNAC adapter entirely with SNES selected: no stuck buttons.
- [ ] All video modes (RGBS, RGsB, Y/C NTSC/PAL, Pocket OFF variants) still
      look correct with SNES selected and with None selected.
- [ ] Changing SNAC settings does not change the selected video mode, and
      vice versa (both share `0xA0000000` via masks).
