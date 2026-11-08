# Rockchip RK3568 quad core 1-4GB SoC 2x1GbE eMMC USB3 HDMI LVDS CAN RS485

BOARD_NAME="NAPI2"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER="QwaSeeK"

BOOTCONFIG="napi2-rk3568_defconfig"
BOOT_FDT_FILE="rockchip/rk3568-napi2.dtb"

KERNEL_TARGET="current,edge"
KERNEL_TEST_TARGET="current"

BOOT_SCENARIO="spl-blobs"
IMAGE_PARTITION_TABLE="gpt"
BOOT_LOGO="no"

DEFAULT_CONSOLE="serial"

ROOTPWD="napilinux"
NAPI_EXTRAARGS="cma=256M console=tty1"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="can-utils i2c-tools mbpoll memtester minicom python3-pymodbus python3-smbus2"

