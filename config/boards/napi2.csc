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
BOOT_LOGO="yes"

DEFAULT_CONSOLE="serial"

ROOTPWD="napilinux"
NAPI_EXTRAARGS="cma=256M systemd.show_status=1 plymouth.nolog"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="can-utils i2c-tools mbpoll memtester minicom python3-pymodbus python3-smbus2"

function post_family_tweaks__napi2_desktop() {
	[[ "${BUILD_DESKTOP}" == yes ]] || return 0
	declare desktop_dm
	case "${DESKTOP_ENVIRONMENT}" in
		mate)
			desktop_dm=lightdm
			install -d -m 0755 "${SDCARD}/etc/lightdm/lightdm.conf.d"
			cat > "${SDCARD}/etc/lightdm/lightdm.conf.d/50-napi-mate.conf" <<- EOF
				[Seat:*]
				user-session=mate
			EOF
			;;
		gnome)
			desktop_dm=gdm3
			;;
		*) return 0 ;;
	esac
	if [[ "${desktop_dm}" == gdm3 ]]; then
		chroot_sdcard "ln -sf /lib/systemd/system/gdm3.service /etc/systemd/system/display-manager.service"
	else
		chroot_sdcard "systemctl --no-reload enable ${desktop_dm}.service"
	fi
	chroot_sdcard "systemctl --no-reload set-default graphical.target"
}
