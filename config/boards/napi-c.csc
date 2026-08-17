# Rockchip RK3308 quad core 256-512MB SoC 100MbE WiFi/BT USB2 mPCIe-modem-slot
# NAPI-C / NAPI-P / NAPI-Slot

BOARD_NAME="NAPI-C"
BOARD_VENDOR="napilab"
BOARDFAMILY="rockchip64"
BOARD_MAINTAINER=""

BOOTCONFIG="napi-c-rk3308_defconfig"
BOOT_FDT_FILE="rockchip/rk3308-napi-c.dtb"

KERNEL_TARGET="current,edge"
KERNEL_TEST_TARGET="current"

DEFAULT_CONSOLE="serial"
SERIALCON="ttyS0"
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

VENDOR="Armbian-napilab"
KEEP_ORIGINAL_OS_RELEASE="yes"
ROOTPWD="napilinux"

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config"

function post_family_config__napi_c_boot_and_defaults() {
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTSCRIPT="boot-rockchip64-ttyS0.cmd:boot.cmd"

	declare -g TZDATA="Europe/Moscow"

	# Was INSTALL_HEADERS=yes on the old run-mynapi.sh command line; it is a genuine
	# board property here (out-of-tree modules are the point of the board). Precedent:
	# config/boards/orangepi5pro.csc:61. Still overridable from the CLI.
	declare -g INSTALL_HEADERS="${INSTALL_HEADERS:-yes}"

	# Overrides rockchip64_common.inc's family_tweaks_bsp, which ships rk3399 mali/vpu
	# udev rules that are meaningless on RK3308. Same trick as config/boards/rockpi-s.conf.
	function family_tweaks_bsp() {
		# udev helper deriving fixed, unique MAC addresses for interfaces that would
		# otherwise get random ones -- like the on-board WiFi.
		install -m 755 "${SRC}/packages/bsp/rockpis/lib/udev/fixEtherAddr" \
			"${destination}/lib/udev"
		install -m 644 "${SRC}/packages/bsp/rockpis/etc/udev/rules.d/05-fixMACaddress.rules" \
			"${destination}/etc/udev/rules.d"
	}
}

function post_family_tweaks_bsp__napi_bsp_cli_files_c() {
	[[ ! -d "${SRC}/packages/bsp/napi" ]] && return 0
	display_alert "${BOARD}" "adding NapiLab BSP files to armbian-bsp-cli" "info"
	run_host_command_logged cp -a "${SRC}/packages/bsp/napi/." "${destination}/"
	return 0
}

function post_family_tweaks__napi_firstrun_preset_c() {
	display_alert "${BOARD}" "presetting armbian-firstlogin (root + user 'napi')" "info"
	cat <<- 'NAPI_PRESET' > "${SDCARD}"/root/.not_logged_in_yet
		PRESET_USER_SHELL=bash
		PRESET_CONNECT_WIRELESS=n
		SET_LANG_BASED_ON_LOCATION=n
		PRESET_LOCALE=en_US.UTF-8
		PRESET_TIMEZONE=Europe/Moscow
		PRESET_ROOT_PASSWORD=napilinux
		PRESET_USER_NAME=napi
		PRESET_USER_PASSWORD=napilinux
		PRESET_DEFAULT_REALNAME=NAPI
	NAPI_PRESET
	chmod 600 "${SDCARD}"/root/.not_logged_in_yet
	return 0
}

function post_family_tweaks__napi_motd_no_wan_lookup_c() {
	declare motd="${SDCARD}/etc/update-motd.d/10-armbian-header"
	[[ ! -f "${motd}" ]] && return 0
	if ! grep -q '^wan_ip_address=' "${motd}"; then
		display_alert "${BOARD}" "10-armbian-header changed upstream, WAN lookup not disabled" "wrn"
		return 0
	fi
	display_alert "${BOARD}" "disabling WAN IP lookup in MOTD" "info"
	sed -i -e 's|^wan_ip_address=.*|wan_ip_address=""|' \
		-e 's|^wan_ip6_address=.*|wan_ip6_address=""|' \
		-e 's|^if \[\[ "${ipv4s}" == \*${wan_ip_address}\* \]\]; then|if [[ -n "${wan_ip_address}" \&\& "${ipv4s}" == *${wan_ip_address}* ]]; then|' \
		"${motd}"
	return 0
}

function post_repo_customize_image__napi_napilab_packages_c() {
	[[ ! -f "${SDCARD}/usr/share/keyrings/napilab.gpg" ]] && return 0
	display_alert "${BOARD}" "installing napilab packages: mbusd gpiod" "info"
	# No `apt-get purge libgpiod2 libgpiod-dev gpiod` any more: the Pin-Priority 1001
	# entry in packages/bsp/napi/etc/apt/preferences.d/napilab lets apt replace (and even
	# downgrade) the distro packages with the napilab ones on its own.
	chroot_sdcard_apt_get_install mbusd gpiod
	return 0
}

function image_specific_armbian_env_ready__napi_c_extraargs() {
	declare env_file="${SDCARD}/boot/armbianEnv.txt"
	declare extraargs="cma=16M earlycon loglevel=7"
	display_alert "${BOARD}" "set CMA size to 16MB due to small DRAM size" "info"
	if grep -q '^extraargs=' "${env_file}"; then
		sed -i "s|^extraargs=.*|extraargs=${extraargs}|" "${env_file}"
	else
		echo "extraargs=${extraargs}" >> "${env_file}"
	fi
	return 0
}

