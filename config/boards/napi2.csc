# Rockchip RK3568 quad core 1-4GB SoC 2x1GbE eMMC USB3 HDMI LVDS CAN RS485

BOARD_NAME="NAPI2"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER="QwaSeeK"

BOOTCONFIG="napi2-rk3568_defconfig"
BOOT_FDT_FILE="rockchip/rk3568-napi2.dtb"
BOOTBRANCH_BOARD="tag:v2026.04"
BOOTPATCHDIR="v2026.04"
BOOTDIR="u-boot-napi2"

KERNEL_TARGET="current,edge"
KERNEL_TEST_TARGET="current"

BOOT_SCENARIO="binman"
IMAGE_PARTITION_TABLE="gpt"
INCLUDE_HOME_DIR="yes"
BOOT_LOGO="no"

DEFAULT_CONSOLE="serial"

ROOTPWD="napilinux"
NAPI_EXTRAARGS="cma=256M"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="can-utils i2c-tools mbpoll memtester minicom python3-pymodbus python3-smbus2"

function post_family_tweaks__napi2_desktop() {
	[[ "${BUILD_DESKTOP}" == yes ]] || return 0
	declare desktop_dm
	case "${DESKTOP_ENVIRONMENT}" in
		xfce) desktop_dm=lightdm ;;
		kde-plasma) desktop_dm=sddm ;;
		*) return 0 ;;
	esac
	chroot_sdcard "systemctl --no-reload enable ${desktop_dm}.service"
	chroot_sdcard "systemctl --no-reload set-default graphical.target"
}
