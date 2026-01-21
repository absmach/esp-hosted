# this assumes ${scriptaddr} is already set!!

# Boot with separate Image and DTB
setenv fdt_high 0xffffffffffffffff
setenv initrd_high 0xffffffffffffffff

# Load kernel
load mmc 0:${distro_bootpart} ${kernel_addr_r} Image

# Load modified DTB
load mmc 0:${distro_bootpart} ${fdt_addr_r} modified.dtb

# Set bootargs
setenv bootargs "root=/dev/mmcblk0p3 ro rootfstype=ext4 rootwait console=ttyS0,115200 crashkernel=256M earlycon uio_pdrv_genirq.of_id=generic-uio net.ifnames=0"

# Set MAC addresses
fdt addr ${fdt_addr_r}
fdt set /soc/ethernet@20112000 mac-address ${icicle_mac_addr0}
fdt set /soc/ethernet@20110000 mac-address ${icicle_mac_addr1}

# Run overlays
run design_overlays

# Boot
booti ${kernel_addr_r} - ${fdt_addr_r}