# Excerpt from gpu_undervolt.sh
Undervolting can save a lot of energy and can also make a GPU run cooler.
No liability taken for any damages, see license above. However, this script
is pretty short and all actions taken are not a particular rocket science.

For Windows, there are special tools like MSI Afterburner to undervolt. For
Linux however, the situation is trickier. This script might help.

Requirements:
1. Linux with the proprietary NVIDIA driver installed
2. `nvidia-smi`
3. [`nvidia-tuner`](https://github.com/WickedLukas/nvidia-tuner) is strongly suggested for full behavior, because `nvidia-smi` does not handle graphics and memory clock offsets
4. root privileges
5. heterogenous multi GPU systems (single GPU works too of course)

This version is headless-friendly. It no longer depends on Xorg, LightDM,
`nvidia-settings`, `Coolbits`, or `XAUTHORITY`.

Currently supported cards: see undervolt_all_gpu below. If your card is not
listed, just look up the clocks at Wikipedia and add them to the list. In

    adjust_gpu $i 1695 200 500

The second argument (here 1695) is the locked graphics clock applied with
`nvidia-smi -lgc`.

The third argument (here 200) means a graphics clock offset of 200 MHz. The larger,
the more intense the undervolting. Too much undervolting destabilizes the
system and can make it crash. Therefore, this value can be tuned and an
actual setting can be verfied with a benchmark, e.g. some deep learning
training or your favorite GPU intense game.

The fourth argument (here 500) means a memory offset of 500 MHz.
This is usually useful for memory-intensive processes such as LLM inference.
This setting can compensate for performance loss due to the undervolting process,
allowing you to achieve power usage savings with minimal overall performance loss.
However, tuning this setting can be tricky since the same GPU chip can be equipped
with memory from different brands, especially if you have some GPUs with different brands.
This also means it will be a bit difficult to generalize this setting.
For stability, I usually choose the lowest memory offset value among the cards.

By default the script uses `nvidia-smi` for persistence mode and locked clocks,
and then uses `nvidia-tuner` for graphics and memory offsets.
If `nvidia-tuner` is missing, the `nvidia-smi` settings are still applied and the
script prints a warning that offsets were skipped.

`init` can be used to install the pinned `nvidia-tuner` release `0.5.0`
from GitHub Releases into `/usr/local/sbin/nvidia-tuner`, with SHA-256
verification before installation.

Commands:
- `sudo sh gpu_undervolt.sh`
  Applies the configured presets.
- `sudo sh gpu_undervolt.sh disable`
  Resets locked clocks with `nvidia-smi` and resets offsets to zero when `nvidia-tuner` is installed.
- `sudo sh gpu_undervolt.sh init`
  Downloads and installs the pinned `nvidia-tuner` release if it is not already available.
