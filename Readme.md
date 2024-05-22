# Excerpt from gpu_undervolt.sh
Undervolting can save a lot of energy and can also make a GPU run cooler.
No liability taken for any damages, see license above. However, this script
is pretty short and all actions taken are not a particular rocket science.

For Windows, there are special tools like MSI Afterburner to undervolt. For
Linux however, the situation is trickier. This script might help.

Requirements:
1. Linux with Xorg and LightDM installed (I'm not sure though, tested on a Proxmox 8.2 Host)
2. nvidia-driver-515 (other versions might work, too)
3. heterogenous multi GPU systems (single GPU works too of course)

Currently supported cards: see undervolt_all_gpu below. If your card is not
listed, just look up the clocks at Wikipedia and add them to the list. In

    adjust_gpu $i 1695 200 500

The third argument (here 200) means a clock offset of 200 MHz. The larger,
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
