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

The menu follows RndMnkIII's SNES Analogizer core: same entry names, same
bit layout, but only the options that make sense for a one-player core with
the SNES reader.

`analogizer_settings` at bridge address `0xA0000000`. The register is
readable and the three entries that share it are not `writeonly`, so the
Pocket can merge their masked writes (the SNES core does the same at
`0xF7000000`).

| Bits      | Meaning                                              | Menu entry                 |
|-----------|------------------------------------------------------|----------------------------|
| `[4:0]`   | SNAC adapter: 0x00 None, 0x03 SNES, 0x0B SNES A,B<->X,Y | SNAC Adapter            |
| `[9:6]`   | Assignment: 0 SNAC -> P1, 1 SNAC + Pocket -> P1      | SNAC Controller Assignment |
| `[13:10]` | Analog video type                                    | Analogizer Video Out       |

Menu option values: SNAC Adapter None = 0, SNES = 3, SNES A,B<->X,Y = 11.
SNAC Controller Assignment SNAC -> P1 = 0, SNAC + Pocket -> P1 = 64.

- SNAC -> P1 replaces the Pocket/dock controls, as in the SNES core. With a
  SNES adapter selected and no pad plugged in, the Pocket controls do nothing.
- SNAC + Pocket -> P1 ORs both together. The SNES core has no such option;
  its value 0x40 there means "SNAC -> P2", which has no use in a GBA core.
- SNES buttons map by name: A, B, L, R, Start, Select, X = Turbo button,
  Y = Fast Forward button.
- SNES A,B<->X,Y uses the SNES core's swap: SNES B = GBA A, SNES Y = GBA B,
  SNES A = X (Turbo), SNES X = Y (Fast Forward).

## Hardware test checklist

Run on a real Pocket with the Analogizer and a SNES SNAC adapter:

- [ ] Menu shows SNAC Adapter, SNAC Controller Assignment and Analogizer
      Video Out, in that order.
- [ ] SNAC Adapter = None: Pocket controls work, SNES pad does nothing.
- [ ] SNES, SNAC -> P1: every SNES button registers (D-pad, A, B, L, R,
      Start, Select); Pocket face buttons and D-pad are ignored.
- [ ] SNES, SNAC + Pocket -> P1: SNES pad and Pocket controls both work.
- [ ] Y triggers Fast Forward (per Fast Forward Mode), X triggers Turbo when
      Button Turbo is enabled.
- [ ] SNES A,B<->X,Y: SNES B = GBA A, SNES Y = GBA B, A = Turbo, X = FF.
- [ ] Unplug the SNES controller mid-game: no stuck buttons. Plug it back in:
      input resumes.
- [ ] Unplug the SNAC adapter entirely with SNES selected: no stuck buttons.
- [ ] All video modes (RGBS, RGsB, Y/C NTSC/PAL, Pocket OFF variants) still
      look correct with SNES selected and with None selected.
- [ ] Changing a SNAC entry does not change the video mode, and vice versa
      (all three share `0xA0000000` via masks). Check again after a power
      cycle, since the persisted values are written back on core load.
