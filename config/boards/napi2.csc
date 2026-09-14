# Rockchip RK3568 quad core 1-8GB SoC 2x1GbE eMMC USB3 PCIe/NVMe HDMI LVDS CAN RS485

BOARD_NAME="NAPI2"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER=""

BOOTCONFIG="napi2-rk3568_defconfig"
BOOT_FDT_FILE="rockchip/rk3568-napi2.dtb"

# edge (7.1) не заявлен: DTS есть только в rockchip64-6.18 (current), в 7.1 его нет.
KERNEL_TARGET="current"
KERNEL_TEST_TARGET="current"

BOOT_SCENARIO="spl-blobs"
IMAGE_PARTITION_TABLE="gpt"
BOOT_LOGO="no"
FULL_DESKTOP="no"

DEFAULT_CONSOLE="serial"

VENDOR="Armbian-napilab"
KEEP_ORIGINAL_OS_RELEASE="yes"
ROOTPWD="napilinux"
NAPI_EXTRAARGS="cma=256M console=tty1"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config"

PACKAGE_LIST_DESKTOP_BOARD="libgbm1 mesa-vulkan-drivers x11vnc mpv celluloid ffmpeg libavcodec-extra"

DESKTOP_APPGROUPS_SELECTED="${DESKTOP_APPGROUPS_SELECTED-}"

