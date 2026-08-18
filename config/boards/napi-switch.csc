# Rockchip RK3308 quad core 256-512MB SoC, KSZ9567S 5-port GbE switch, LAN7850 USB GbE
# NAPI-Switch

BOARD_NAME="NAPI-Switch"
BOARD_VENDOR="napilab"
BOARDFAMILY="rockchip64"
BOARD_MAINTAINER=""

# Own U-Boot: patch/u-boot/v2024.10/board_napi-switch. Same RK3308 blobs and boot
# scenario as NAPI-C, but its own device tree -- no WiFi/BT, no external Ethernet PHY,
# and an eMMC node fixed up to 8-bit HS200 with a vqmmc supply.
BOOTCONFIG="napi-switch-rk3308_defconfig"
BOOT_FDT_FILE="rockchip/rk3308-napi-switch.dtb"

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
# Deliberately no DEFAULT_OVERLAYS. NAPI-C's set cannot be reused here:
#   uart1     disables &spi2 and takes GPIO1_D1/D0 -- those are the KSZ9567S chip
#             select and clock, so it kills the switch outright.
#   uart3-m0  takes GPIO3_B5/B4, wired to the switch SYSCLKO and LED1.
#   otg-host  redundant: the board DTS already pins dr_mode = "host", the LAN7850
#             is soldered to the OTG port and there is nothing to negotiate.
# i2c2 must stay disabled as well: GPIO2_A3/A2 carry RST_PHY_N and PME_N.

VENDOR="Armbian-napilab"
KEEP_ORIGINAL_OS_RELEASE="yes"
ROOTPWD="napilinux"

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config \
	ethtool bridge-utils"

function post_family_config__napi_switch_boot_and_defaults() {
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTSCRIPT="boot-rockchip64-ttyS0.cmd:boot.cmd"

	declare -g TZDATA="Europe/Moscow"
	declare -g INSTALL_HEADERS="${INSTALL_HEADERS:-yes}"

	# Overrides rockchip64_common.inc's family_tweaks_bsp, which ships rk3399 mali/vpu
	# udev rules that are meaningless on RK3308. Unlike NAPI-C this board has no WiFi,
	# so the rockpis fixEtherAddr helper is not installed either -- every interface here
	# gets its MAC from hardware (KSZ9567S ports) or from the LAN7850 EEPROM.
	function family_tweaks_bsp() {
		return 0
	}
}

function post_family_tweaks_bsp__napi_bsp_cli_files_switch() {
	[[ ! -d "${SRC}/packages/bsp/napi" ]] && return 0
	display_alert "${BOARD}" "adding NapiLab BSP files to armbian-bsp-cli" "info"
	run_host_command_logged cp -a "${SRC}/packages/bsp/napi/." "${destination}/"
	return 0
}

function post_family_tweaks__napi_firstrun_preset_switch() {
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

function post_family_tweaks__napi_motd_no_wan_lookup_switch() {
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

function post_repo_customize_image__napi_napilab_packages_switch() {
	[[ ! -f "${SDCARD}/usr/share/keyrings/napilab.gpg" ]] && return 0
	display_alert "${BOARD}" "installing napilab packages: mbusd gpiod" "info"
	chroot_sdcard_apt_get_install mbusd gpiod
	return 0
}

function image_specific_armbian_env_ready__napi_switch_extraargs() {
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
