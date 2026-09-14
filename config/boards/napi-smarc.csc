# Rockchip RK3568J quad core SoC on a SMARC carrier board
# 2x1GbE eMMC SD USB3 PCIe3.0x2 SATA HDMI I2S RTC+EEPROM

BOARD_NAME="NAPI-SMARC"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER=""

# Same RK3568 U-Boot as NAPI2 -- both are RK3568J modules, only the carrier differs.
# NOTE: the patch creating this defconfig is not in this tree yet (neither is NAPI2's);
# it still has to be ported into patch/u-boot/legacy/u-boot-radxa-rk35xx/.
BOOTCONFIG="napi2-rk3568_defconfig"
BOOT_FDT_FILE="rockchip/rk3568-smarc.dtb"

# edge (7.1) не заявлен: DTS платы и оверлеи rk3308 лежат только
# в patch/kernel/archive/rockchip64-6.18 (current). Добавить в 7.1 —
# скопировать туда dt/ и overlay/ и вернуть edge сюда.
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

