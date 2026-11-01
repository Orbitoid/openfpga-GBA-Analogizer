# GBA for Analogue Pocket

[![Latest Release](https://img.shields.io/github/v/tag/Orbitoid/openfpga-GBA?label=latest)](https://github.com/Orbitoid/openfpga-GBA/releases/latest) [![Downloads](https://img.shields.io/github/downloads/Orbitoid/openfpga-GBA/total)](https://github.com/Orbitoid/openfpga-GBA/releases) [![Platform](https://img.shields.io/badge/platform-Analogue%20Pocket-blue)](https://openfpga-library.github.io/analogue-pocket/)

Analogizer-maintained fork (with some AI assistance), based on [mincer-ray/openfpga-GBA](https://github.com/mincer-ray/openfpga-GBA) which itself is an openFPGA port of: [MiSTer GBA core](https://github.com/MiSTer-devel/GBA_MiSTer).

## Features

- **Filters**
- **Save States**
- **Fast Forward (Bound to Y button)**
- **Button Turbo (Bound to X button)**
- **RTC**
- **Link Cable** - 2/3/4p Multiplayer, GCN link, GBA wireless, Single Pak download
- **Rumble (DS Rumble Pak)** — normal Pocket core only; the Analogizer core uses the cart slot for the adapter.
- **Analogizer Build** — Separate `GBA_Analogizer` core package with cartridge adapter support for Analogizer-FPGA analog video output.
- **SNAC SNES Controller** — Analogizer core only. Play with an original SNES controller through a MiSTer-style SNES SNAC adapter in the Analogizer SNAC port.

## Fast Forward

You can change fast forward behavior with the "Fast Forward Render" setting in the menu. Choices are:

- Fastest: core runs as fast as possible, highest possible fast forward speed but can show tearing/mixed/corrupted frames in some games.
- Stable: wait for full frames. video during fast forward is MUCH more stable, however max fast forward speed is decreased.

## RTC and Save Compatibility

NEW (0.8.0 and above): RTC timestamp is now saved as an external .rtc file next to the .sav. This should increase save compatibility with other cores and emulators since the .sav now presents as correctly sized. Downgrade flow is included so on updating to a version of the core with the new feature, the core should correctly update your saves as well.

LEGACY (0.7.1 and below): When a game uses RTC (either detected automatically or forced on), the core appends RTC data to the end of the save file. This makes the save file larger than a standard GBA save. If you then try to load that save on a GBA core that doesn't support RTC, it will fail with an error because the save file size doesn't match what the core expects. To use the save on a non-RTC core, you would need to trim the extra RTC bytes from the end of the file to restore it to its original size.

>For saves you might be having issues with try the new online self help tool I have added here:
>
>https://www.peterdegenaro.com/pages/rtc-save-tool.html

For save files produced by older releases, the following tools might be able to help, but I have not tested them:
- [mGBA](https://mgba.io/) — The built-in Save Converter tool (Tools → Save Converter) can export saves with RTC data stripped. Requires mGBA v0.10.3 or later.
- [save-file-converter](https://github.com/euan-forrester/save-file-converter) — A web-based tool that can convert and resize save files across many retro formats.

## **FORCE QUIRK**
At the moment there only seems to be 1 romhack that needs this feature. If you are trying to play Unbound keep reading, otherwise PLEASE ignore this feature.

— Manually enables RTC for ROMs that aren't in the database. This is useful for ROM hacks that add RTC support to games that don't normally use it. Make sure to enable this on first load of the hack, ideally as soon as possible during the bios display to avoid any issues with initializing the save. **USE WITH CAUTION:** enabling this on a game that doesn't actually use RTC can cause crashes or glitches.
### **⚠️WARNING: Forced RTC setting persists across games! Remember to turn it off before loading a game that doesn't need it⚠️**
### **⚠️WARNING: Do not enable this setting unless you are playing a romhack that needs it⚠️**

## Accuracy

This core more or less replicates the current accuracy of the MiSTer GBA core master branch. The features that were cut to fit the smaller FPGA were convenience features, not accuracy-related logic. It scores similarly to the MiSTer core in the mGBA test suite. If you encounter an Analogizer-specific issue, please open it on this fork.

Note: MiSTer core has an accuracy branch. A few of those changes have made it into this core but the bulk is still wip on a different branch.

## Installation

The Analogizer core should be available from this fork's releases, or you can install manually:

1. Download the latest release
2. Copy the 3 folders `Cores/`, `Platforms/`, `Assets/` to your SD card
   - **macOS users:** Finder replaces folders instead of merging them, so copy folder contents carefully.
3. Place your ROMs and `gba_bios.bin` in `/Assets/gba/common/`
4. Launch `GBA_Analogizer` on the Pocket when using the Analogizer-FPGA adapter

## Analogizer Support

This branch also builds a separate core named `GBA_Analogizer` in `Cores/Orbitoid.GBA_Analogizer/`. It enables the Pocket cartridge adapter pins for Analogizer-FPGA and uses a dedicated CRT raster path instead of sending the Pocket scaler output to the adapter.

The Analogizer build currently supports:

- **RGBS**
- **RGsB**
- **Y/C NTSC**
- **Y/C PAL**
- **Pocket OFF** variants for the same video outputs

The `CRT Scale` core setting controls how the 240x160 GBA framebuffer is mapped to the 15 kHz Analogizer output:

- **Scaled Full Width** — Default larger mode, 408x204 output clocks with horizontal interpolation and the same 2:1 output shape as the previous larger mode.
- **Aspect / Blend** — 320-wide output with horizontal interpolation.
- **No Scale / Square** — 240-wide output with square source pixels.
- **Small / Stretch** — 320-wide nearest-neighbor output.
- **Wide / Overscan** — 448-wide output for wider CRT fill.
- **Full Screen / Square** — 336x224 nearest-neighbor output that uniformly scales the square-pixel mode, intentionally not matching GBA display aspect.

The Analogizer video path uses `clk_vid` timing at about 15.65 kHz / 59.7 Hz, prefetches each GBA line through a small line buffer, and shares the existing framebuffer read port with the Pocket video adapter. Pocket screen output remains available unless a `Pocket OFF` Analogizer mode is selected.

## SNAC Controller (Analogizer)

The `GBA_Analogizer` core can read an original SNES controller through the Analogizer SNAC port, using a MiSTer-style SNES SNAC adapter (for example the retroremake SNES SNAC adapter) and a USB-A to USB-A cable. Only the first controller port of the adapter is used.

Core settings:

- **SNAC Controller**
  - **None** — SNAC port not polled (default).
  - **SNES + Pocket** — SNES controller and Pocket/dock controls both drive the GBA buttons.
  - **SNES Only** — Pocket/dock controls are ignored while SNAC is active.
- **SNAC Buttons**
  - **A/B, X Turbo, Y FF** — SNES A/B are GBA A/B; X is the Turbo button and Y is Fast Forward, matching the Pocket layout.
  - **B/Y, A Turbo, X FF** — SNES B/Y act as GBA A/B (the diagonal pair, closer to the GBA's button placement); A is Turbo and X is Fast Forward.
  - **A/B Only** / **B/Y Only** — Same face-button layouts with Turbo and Fast Forward disabled on the SNES controller.

L/R, Start, Select and the D-pad always map directly. Turbo and Fast Forward behaviour still follows the `Button Turbo` and `Fast Forward Mode` settings. If the controller is unplugged, the core reports no buttons pressed.

Rumble cartridges are not available on the Analogizer core because the adapter occupies the cartridge slot.

## Known Issues

- **Fast forward speed varies by game** — Games that make heavy use of the GBA's slower external RAM will not fast-forward as quickly as games that primarily use internal RAM. This is most noticeable with the Classic NES Series titles.
- **Analogizer support is a separate core** — Use `GBA_Analogizer`, not the normal `GBA` core, when using the Analogizer adapter.
- **Analogizer output depends on CRT/display tolerance** — The CRT path targets about 15.65 kHz / 59.7 Hz. Some displays or scalers may need a different scale mode or video output type.
- **Fast forward creates visible screen tearing** — Nothing i can do about this for the time being. Would need a frame buffer.
- **64MB Video carts do not work** you cant watch shrek, shrek 2, or shark tale =(

## Building from Source

The Analogizer build is self-contained in this repo. A fresh clone plus Docker is enough to build the Quartus bitstream and generate a ready-to-copy SD card package.

Note for contributors and LLM agents: check `scripts/` before invoking tools directly. The build scripts provide the expected Quartus access, Docker environment, bitstream reversal, package generation, and timing-summary steps for this repo.

### Prerequisites

- Docker
- `raetro/quartus:21.1` Docker image
- Python 3 on the host, used after Quartus to reverse the generated bitstream
- `zip` is optional; when present, the build script also creates a local SD card package archive

### Build Analogizer

```bash
docker pull raetro/quartus:21.1
./scripts/build_analogizer.sh
```

The script runs Quartus inside Docker, reverses the generated `.rbf`, writes the Pocket bitstream to `pkg/Cores/Orbitoid.GBA_Analogizer/bitstream.rbf_r`, and prints the timing summary. If `zip` is installed, it also creates `build_output/Orbitoid.GBA_Analogizer-dev.zip` with the same SD card layout used by releases.

### Install A Local Build

After a successful build, either unzip `build_output/Orbitoid.GBA_Analogizer-dev.zip` to the root of your Pocket SD card, or manually copy these folders from `pkg/` to the SD card root:

```bash
Cores/
Platforms/
Assets/
```

Place ROMs and `gba_bios.bin` in `/Assets/gba/common/` on the SD card. Use the `GBA_Analogizer` core, not the normal `GBA` core, when connecting the Analogizer-FPGA adapter.

### Build Normal Pocket Core

The original non-Analogizer Pocket build is still available for comparison:

```bash
./scripts/build.sh
```

### Background Build

To run Quartus in the background:

```bash
./scripts/quartus-build-bg.sh start
./scripts/quartus-build-bg.sh status
./scripts/quartus-build-bg.sh wait
```

For the Analogizer build:

```bash
./scripts/quartus-build-bg.sh --analogizer start
./scripts/quartus-build-bg.sh --analogizer status
./scripts/quartus-build-bg.sh --analogizer wait
```


## Credits

- **[MiSTer GBA core](https://github.com/MiSTer-devel/GBA_MiSTer)** — original FPGA GBA implementation
- **[mincer-ray/openfpga-GBA](https://github.com/mincer-ray/openfpga-GBA)** — original Analogue Pocket port this Analogizer fork is based on
- **[Analogue openFPGA](https://www.analogue.co/developer)** — platform framework and core template
- **[budude2/openfpga-GBC](https://github.com/budude2/openfpga-GBC)** — reference for MiSTer-to-Pocket porting patterns
- **[agg23](https://github.com/agg23)** — analogue-pocket-utils and reference SNES/NES Pocket cores
- **[RndMnkIII Analogizer](https://github.com/RndMnkIII/Analogizer)** — Analogizer-FPGA adapter and openFPGA interface modules

## License

GPL-2.0 — see [GBA_MiSTer LICENSE](https://github.com/MiSTer-devel/GBA_MiSTer/blob/master/LICENSE) for details.
