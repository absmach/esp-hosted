# BeagleV-Fire Platform Support

ESP-Hosted support for BeagleV-Fire (Microchip PolarFire SoC RISC-V platform).

## Hardware

- **Board**: BeagleV-Fire
- **SoC**: Microchip PolarFire SoC (RISC-V)
- **Interface**: SPI0
- **ESP32**: Any ESP32 module (ESP32-WROOM-32, DevKitC, etc.)

## Pin Connections

| Function       | ESP32 GPIO | ESP32 Physical Pin | BeagleV-Fire Pin | BeagleV GPIO | Description     |
| -------------- | ---------- | ------------------ | ---------------- | ------------ | --------------- |
| **SPI MOSI**   | GPIO 13    | D13                | P9_18            | SPI0_MOSI    | SPI Master Out  |
| **SPI MISO**   | GPIO 12    | D12                | P9_21            | SPI0_MISO    | SPI Master In   |
| **SPI CLK**    | GPIO 14    | D14                | P9_22            | SPI0_CLK     | SPI Clock       |
| **SPI CS**     | GPIO 15    | D15                | P9_17            | SPI0_CS0     | SPI Chip Select |
| **Handshake**  | GPIO 26    | D26                | P8_03            | 512          | MSS GPIO_2[0]   |
| **Data Ready** | GPIO 25    | D25                | P8_04            | 513          | MSS GPIO_2[1]   |
| **Reset**      | EN         | EN                 | P8_05            | 514          | MSS GPIO_2[2]   |
| **Ground**     | GND        | GND                | P9_1 or P9_2     | GND          | Common Ground   |

## Configuration Details

### Hardware Configuration

- **SPI Interface**: SPI0 on BeagleV-Fire
- **GPIO Chip**: MSS GPIO_2 (base 512)
- **Reset Pin**: GPIO 514 (configured in `beaglev_init.sh`)
- **Handshake Pin**: GPIO 512 (configured in `spi/esp_spi.h`)
- **Data Ready Pin**: GPIO 513 (configured in `spi/esp_spi.h`)

## Files in This Directory

- **beaglev_init.sh** - Modified initialization script for BeagleV-Fire
- **beaglev-esp-hosted.dts** - Device tree overlay for SPI configuration
- **patches/esp_spi.h.patch** - GPIO pin modifications

## Quick Setup

### 1. Apply Device Tree Overlay

```bash
# Compile overlay
dtc -O dtb -o beaglev-esp-hosted.dtbo -b 0 -@ beaglev-esp-hosted.dts

# Copy to firmware directory
sudo cp beaglev-esp-hosted.dtbo /lib/firmware/

# Apply overlay
sudo mkdir -p /sys/kernel/config/device-tree/overlays/esp-hosted
echo beaglev-esp-hosted.dtbo | sudo tee /sys/kernel/config/device-tree/overlays/esp-hosted/path

# Verify
cat /sys/kernel/config/device-tree/overlays/esp-hosted/status  # Should show "applied"
ls /dev/spidev0.0  # Should exist
```

### 2. Apply GPIO Pin Patch

If not already applied in your fork:

```bash
cd ~/esp-hosted
patch -p1 < esp_hosted_ng/host/platforms/beaglev-fire/patches/esp_spi.h.patch
```

Or manually edit `esp_hosted_ng/host/linux/host_driver/esp32/spi/esp_spi.h`:

```c
#define HANDSHAKE_PIN 513        // Changed from 22
#define SPI_DATA_READY_PIN 514   // Changed from 27
```

### 3. Copy Init Script

```bash
cp esp_hosted_ng/host/platforms/beaglev-fire/beaglev_init.sh \
   esp_hosted_ng/host/beaglev_init.sh
chmod +x esp_hosted_ng/host/beaglev_init.sh
```

### 4. Build and Load Driver

```bash
cd esp_hosted_ng/host
sudo ./beaglev_init.sh spi
```

### 5. Verify

```bash
# Check module loaded
lsmod | grep esp32_spi

# Check interface
ip link show wlan0

# Test WiFi
sudo iw dev wlan0 scan
```

## Troubleshooting

**No /dev/spidev0.0**:

```bash
# Load SPI modules
sudo modprobe spidev
sudo modprobe spi-microchip-core
sudo modprobe spi-microchip-core-qspi

# Reboot if needed
sudo reboot
```

**Module won't load**:

```bash
# Check kernel headers
ls /lib/modules/$(uname -r)/build/include/linux/module.h

# If missing, rebuild kernel headers
```

**No wlan0 interface**:

```bash
# Check ESP32 is powered and connected
# Check kernel logs
dmesg | grep -i esp

# Look for "ESP peripheral capabilities"
```

## Notes

- Bluetooth requires `bluetooth` kernel module (not in default BeagleV kernel)
- WiFi works independently of Bluetooth
- SPI speed can be increased to 20 MHz for better performance (experimental)
