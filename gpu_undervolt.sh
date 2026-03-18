#!/bin/sh
#
# MIT License
#
# Copyright (c) 2022 Michael Siebert
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
################################################################################
#
# Undervolting can save a lot of energy and can also make a GPU run cooler.
# No liability taken for any damages, see license above. However, this script
# is pretty short and all actions taken are not a particular rocket science.
#
# For Windows, there are special tools like MSI Afterburner to undervolt. For
# Linux however, the situation is trickier. This script might help.
#
# Requirements:
# 1. Ubuntu Desktop Linux 22.04 (Ubuntu Server won't work)
# 2. nvidia-driver-515 (other versions might work, too)
# 3. heterogenous multi GPU systems (single GPU works too of course)
#
# Currently supported cards: see undervolt_all_gpu below. If your card is not
# listed, just look up the clocks at Wikipedia and add them to the list. In
#
#     adjust_gpu $i 1695 200
#
# the third argument (here 200) means a clock offset of 200 Mhz. The larger,
# the more intense the undervolting. Too much undervolting destabilizes the
# system and can make it crash. Therefore, this value can be tuned and an
# actual setting can be verfied with a benchmark, e.g. some deep learning
# training or your favorite GPU intense game.
#
################################################################################

if [ $(id -u) -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "error: nvidia-smi not found"
    exit 1
fi

types=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | sed -e 's/ /_/g')
nvidia_tuner_bin=${NVIDIA_TUNER_BIN:-nvidia-tuner}
nvidia_tuner_warned=false
nvidia_tuner_version=0.5.0
nvidia_tuner_url="https://github.com/WickedLukas/nvidia-tuner/releases/download/${nvidia_tuner_version}/nvidia-tuner"
nvidia_tuner_sha256=cd8921adf65300f76a3099f21f6522411e89e5df0767cc754fe2c2ba07ee1bec
nvidia_tuner_install_path=/usr/local/sbin/nvidia-tuner

warn_missing_nvidia_tuner() {
    if [ "$nvidia_tuner_warned" = false ]; then
        echo "warning: ${nvidia_tuner_bin} not found, applying nvidia-smi settings only" >&2
        echo "warning: install nvidia-tuner or set NVIDIA_TUNER_BIN to enable clock offsets" >&2
        nvidia_tuner_warned=true
    fi
}

have_nvidia_tuner() {
    command -v "$nvidia_tuner_bin" >/dev/null 2>&1
}

run_nvidia_tuner() {
    "$nvidia_tuner_bin" "$@"
}

download_file() {
    url=$1
    output=$2

    if command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
    else
        echo "error: neither curl nor wget is installed"
        return 1
    fi
}

check_sha256() {
    file=$1

    if command -v sha256sum >/dev/null 2>&1; then
        actual_sha256=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual_sha256=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        echo "error: neither sha256sum nor shasum is installed"
        return 1
    fi

    if [ "$actual_sha256" != "$nvidia_tuner_sha256" ]; then
        echo "error: checksum mismatch for downloaded nvidia-tuner"
        echo "expected: $nvidia_tuner_sha256"
        echo "actual:   $actual_sha256"
        return 1
    fi
}

install_nvidia_tuner() {
    if have_nvidia_tuner; then
        echo "nvidia-tuner already available at $(command -v "$nvidia_tuner_bin")"
        return 0
    fi

    tmp_file=$(mktemp /tmp/nvidia-tuner.XXXXXX) || exit 1
    trap 'rm -f "$tmp_file"' EXIT INT TERM

    echo "downloading nvidia-tuner ${nvidia_tuner_version}..."
    download_file "$nvidia_tuner_url" "$tmp_file" || exit 1

    echo "verifying checksum..."
    check_sha256 "$tmp_file" || exit 1

    install -m 0755 "$tmp_file" "$nvidia_tuner_install_path" || exit 1
    rm -f "$tmp_file"
    trap - EXIT INT TERM

    echo "installed nvidia-tuner to $nvidia_tuner_install_path"
}

reset_gpu_offsets() {
    gpu=$1

    if have_nvidia_tuner; then
        run_nvidia_tuner --index "$gpu" --core-clock-offset 0 --memory-clock-offset 0
    else
        warn_missing_nvidia_tuner
    fi
}

if [ $# -eq 1 ] && [ $1 = 'disable' ]; then
    echo disabling...
    nvidia-smi -pm 0
    nvidia-smi -rgc

    i=0
    for type in $types; do
        reset_gpu_offsets "$i"
        i=$((i + 1))
    done

    exit 0
fi

if [ $# -eq 1 ] && [ $1 = 'init' ]; then
    install_nvidia_tuner
    exit 0
fi

adjust_gpu() {

    gpu=$1
    gpu_high=$2 # e.g. 1770 (RTX 2070 Super)
    clock_offset=$3
    memory_offset=${4:-"0"}

    nvidia-smi -i $gpu -pm 1
    nvidia-smi -i $gpu -lgc 0,$gpu_high

    if [ "$clock_offset" -ne 0 ] || [ "$memory_offset" -ne 0 ]; then
        if have_nvidia_tuner; then
            run_nvidia_tuner \
                --index "$gpu" \
                --core-clock-offset "$clock_offset" \
                --memory-clock-offset "$memory_offset"
        else
            warn_missing_nvidia_tuner
        fi
    fi
}

undervolt_all_gpu() {
    i=0

    for type in $types; do
        if [ "$type" = "NVIDIA_GeForce_GTX_1080_Ti" ]; then
            adjust_gpu $i 1582 100
        elif [ "$type" = "NVIDIA_GeForce_GTX_1070" ]; then
            adjust_gpu $i 1683 100
        elif [ "$type" = "NVIDIA_GeForce_GTX_1650_with_Max-Q_Design" ]; then
            # discussion see https://github.com/xor2k/gpu_undervolt/issues/3
            adjust_gpu $i 1595 220
        elif [ "$type" = "NVIDIA_GeForce_RTX_2060_SUPER" ]; then
            adjust_gpu $i 1650 150 325
        elif [ "$type" = "NVIDIA_GeForce_RTX_2070_SUPER" ]; then
            adjust_gpu $i 1770 100
        elif [ "$type" = "NVIDIA_GeForce_RTX_3090" ]; then
            adjust_gpu $i 1695 200
        elif [ "$type" = "NVIDIA_GeForce_RTX_4060_Ti" ]; then
            adjust_gpu $i 2535 180 1000
        else
            echo unknown type: $type
            exit 1
        fi
        i=$((i + 1))
    done

    exit 0

}

undervolt_all_gpu
