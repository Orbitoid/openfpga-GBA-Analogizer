# Agent Notes

## Tooling

- Check `scripts/` before invoking build or FPGA tools directly.
- Quartus access for this repo is wrapped by the scripts, usually through Docker with the expected project paths and post-build steps.
- Use `./scripts/build_analogizer.sh` for the Analogizer core and `./scripts/build.sh` for the normal Pocket core.
- For long Quartus jobs, use `./scripts/quartus-build-bg.sh` or `./scripts/quartus-build-bg.sh --analogizer` so status, logs, bitstream reversal, and timing summaries are handled consistently.
- Do not assume host-installed Quartus is the correct path for this project unless a script or user instruction explicitly says so.
