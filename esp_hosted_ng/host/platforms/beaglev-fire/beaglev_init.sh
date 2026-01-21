#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2015-2021 Espressif Systems (Shanghai) PTE LTD
#
# This is modified version of rpi_init.sh for BeagleV-Fire (RISC-V)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Platform-specific settings for BeagleV-Fire
resetpin=512                # BeagleV GPIO for ESP32 reset (was 6 for RPi)

# WLAN/BT initialization
wlan_init() {
    echo "WLAN init"
    
    cd "$SCRIPT_DIR" || exit 1
    
    # Build for RISC-V architecture (not ARM)
    make target=$IF_TYPE \
    ARCH=riscv \
    KERNEL=/lib/modules/$(uname -r)/build
    
    if [ $? -ne 0 ]; then
        echo "Failed to build driver"
        exit 1
    fi
    
    # Insert module
    sudo insmod esp32_spi.ko
    
    if [ $? -ne 0 ]; then
        echo "Failed to insert module"
        exit 1
    fi
    
    sleep 2
    echo "esp32_spi module loaded"
}

bt_init() {
    echo "Bluetooth init"
    
    # Note: raspi-gpio commands removed (BeagleV doesn't have this utility)
    # GPIO configuration is handled by device tree
    
    echo "Bluetooth initialization skipped (requires kernel support)"
}

# Main execution
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <spi|sdio>"
    exit 1
fi

IF_TYPE=$1

if [ "$IF_TYPE" != "spi" ] && [ "$IF_TYPE" != "sdio" ]; then
    echo "Error: Interface type must be 'spi' or 'sdio'"
    exit 1
fi

echo "Interface type: $IF_TYPE"

# Note: spidev_disabler not needed on BeagleV-Fire
# SPI device configuration is handled by custom device tree overlay

# Reset ESP32
if [ -d /sys/class/gpio/gpio$resetpin ]; then
    echo "GPIO $resetpin already exported"
else
    echo $resetpin > /sys/class/gpio/export
fi

echo out > /sys/class/gpio/gpio$resetpin/direction
echo "Resetting ESP32 using GPIO $resetpin"
echo 0 > /sys/class/gpio/gpio$resetpin/value
sleep 1
echo 1 > /sys/class/gpio/gpio$resetpin/value
sleep 2

# Load kernel modules
if [ $(lsmod | grep bluetooth | wc -l) = "0" ]; then
    echo "Attempting to load bluetooth module..."
    sudo modprobe bluetooth 2>/dev/null || echo "Bluetooth not available, skipping"
fi

if [ $(lsmod | grep cfg80211 | wc -l) = "0" ]; then
    echo "Attempting to load cfg80211 module..."
    sudo modprobe cfg80211 2>/dev/null || echo "cfg80211 not available, will try to build anyway"
fi

# Initialize WLAN (always attempt, even if bluetooth failed)
wlan_init

echo "Setup complete!"
echo "Check dmesg for ESP32 initialization messages:"
echo "  dmesg | grep -i esp"
echo ""
echo "If successful, wlan0 interface should be available:"
echo "  ip link show wlan0"
