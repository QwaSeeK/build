# Rockchip RK3308 quad core 256-512MB SoC, KSZ9567S 5-port GbE switch, LAN7850 USB GbE
# NAPI-Switch

BOARD_NAME="NAPI-Switch"
BOARD_VENDOR="napilab"
BOARDFAMILY="rockchip64"
BOARD_MAINTAINER=""

BOOTCONFIG="napi-switch-rk3308_defconfig"
BOOT_FDT_FILE="rockchip/rk3308-napi-switch.dtb"


KERNEL_TARGET="current"
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
VENDOR="Armbian-napilab"
KEEP_ORIGINAL_OS_RELEASE="yes"
ROOTPWD="napilinux"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config \
	ethtool bridge-utils"

function post_family_config__napi_switch_boot_and_defaults() {
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTSCRIPT="boot-rockchip64-ttyS0.cmd:boot.cmd"

	declare -g TZDATA="Europe/Moscow"
	declare -g INSTALL_HEADERS="${INSTALL_HEADERS:-yes}"

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

function post_family_tweaks_bsp__napi_switch_bsp_cli_files() {
	[[ ! -d "${SRC}/packages/bsp/napi-switch" ]] && return 0
	display_alert "${BOARD}" "adding NAPI-Switch BSP files to armbian-bsp-cli" "info"
	run_host_command_logged cp -a "${SRC}/packages/bsp/napi-switch/." "${destination}/"
	# git does not carry the mode; netplan complains about world-readable files.
	run_host_command_logged chmod 600 "${destination}/etc/netplan/60-switch.yaml"
	return 0
}

function post_post_debootstrap_tweaks__napi_switch_netplan_release_lan_ports() {
	declare yaml="${SDCARD}/etc/netplan/10-dhcp-all-interfaces.yaml"
	[[ ! -f "${yaml}" ]] && return 0
	if ! grep -q '^    all-lan-interfaces:' "${yaml}"; then
		display_alert "${BOARD}" "10-dhcp-all-interfaces.yaml changed upstream, lanN ports not released" "wrn"
		return 0
	fi
	display_alert "${BOARD}" "releasing lanN ports from per-interface DHCP, they belong to br0" "info"
	sed -i '/^    all-lan-interfaces:/,/^      ipv6-privacy:/d' "${yaml}"
	return 0
}

function post_family_tweaks__napi_switch_provision_accounts() {
	declare user_name="napi"
	declare user_pass="napilinux"
	declare group

	display_alert "${BOARD}" "creating user '${user_name}' at build time" "info"
	chroot_sdcard "useradd --create-home --shell /bin/bash --comment 'NAPI' '${user_name}'"
	chroot_sdcard "echo '${user_name}:${user_pass}' | chpasswd"

	for group in sudo netdev audio video disk tty users games dialout plugdev input \
		bluetooth systemd-journal ssh render docker; do
		chroot_sdcard "usermod -aG '${group}' '${user_name}' 2>/dev/null || true"
	done

	display_alert "${BOARD}" "disabling the first-login wizard, booting to a login prompt" "info"
	run_host_command_logged rm -fv "${SDCARD}/root/.not_logged_in_yet"
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

function post_repo_customize_image__napi_switch_mstpd() {
	declare mstpd_version="0.2.0-2"
	declare mstpd_sha256="d985d09b47c03812bbe465cb12e749442a6fa09bd044362c7fbefa59939b6baa"
	declare mstpd_deb="mstpd_${mstpd_version}_arm64.deb"
	declare mstpd_cache="${SRC}/cache/mstpd"
	declare mstpd_url="https://deb.debian.org/debian/pool/main/m/mstpd/${mstpd_deb}"

	if [[ "${ARCH}" != "arm64" ]]; then
		display_alert "${BOARD}" "mstpd is pinned for arm64, skipped on ${ARCH}" "wrn"
		return 0
	fi

	run_host_command_logged mkdir -pv "${mstpd_cache}"
	if ! echo "${mstpd_sha256}  ${mstpd_cache}/${mstpd_deb}" | sha256sum --check --status; then
		display_alert "${BOARD}" "downloading ${mstpd_deb}" "info"
		run_host_command_logged curl -fSL --retry 3 --connect-timeout 20 \
			-o "${mstpd_cache}/${mstpd_deb}" "${mstpd_url}"
		echo "${mstpd_sha256}  ${mstpd_cache}/${mstpd_deb}" | sha256sum --check --status ||
			exit_with_error "mstpd ${mstpd_version} checksum mismatch, superseded in the Debian pool?"
	fi

	display_alert "${BOARD}" "installing mstpd ${mstpd_version} (RSTP daemon)" "info"
	run_host_command_logged cp -v "${mstpd_cache}/${mstpd_deb}" "${SDCARD}/tmp/${mstpd_deb}"
	chroot_sdcard_apt_get_install "/tmp/${mstpd_deb}"
	run_host_command_logged rm -f "${SDCARD}/tmp/${mstpd_deb}"
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
