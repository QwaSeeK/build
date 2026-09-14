# Rockchip RK3308 quad core 256-512MB SoC 100MbE WiFi/BT USB2 mPCIe-modem-slot
# NAPI-C / NAPI-P / NAPI-Slot

BOARD_NAME="NAPI-C"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER=""

BOOTCONFIG="napi-c-rk3308_defconfig"
BOOT_FDT_FILE="rockchip/rk3308-napi-c.dtb"

KERNEL_TARGET="current"
KERNEL_TEST_TARGET="current"

DEFAULT_CONSOLE="serial"
MODULES_BLACKLIST="rockchipdrm analogix_dp dw_mipi_dsi dw_hdmi gpu_sched lima hantro_vpu panfrost"
HAS_VIDEO_OUTPUT="no"

BOOTBRANCH_BOARD="tag:v2024.10"
BOOTPATCHDIR="v2024.10"
BOOT_SCENARIO="binman"
DDR_BLOB="rk33/rk3308_ddr_589MHz_uart0_m0_v2.07.bin"
BL31_BLOB="rk33/rk3308_bl31_v2.26.elf"
FORCE_UBOOT_UPDATE="yes"

OVERLAY_PREFIX="rk3308"
DEFAULT_OVERLAYS="uart1 uart2-m0 uart3-m0 i2c1-ds1338 i2c3-m0 otg-host"

VENDOR="ArmbianNapi"
HOST="napic"
KEEP_ORIGINAL_OS_RELEASE="yes"
ROOTPWD="napilinux"
NAPI_EXTRAARGS="cma=16M"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config"

function post_family_config__napi_c_family_tweaks() {
	function family_tweaks_bsp() {
		install -m 755 "${SRC}/packages/bsp/rockpis/lib/udev/fixEtherAddr" \
			"${destination}/lib/udev"
		install -m 644 "${SRC}/packages/bsp/rockpis/etc/udev/rules.d/05-fixMACaddress.rules" \
			"${destination}/etc/udev/rules.d"
	}
}

