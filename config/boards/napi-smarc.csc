# Rockchip RK3568J quad core SoC on a SMARC carrier board
# 2x1GbE eMMC SD USB3 PCIe3.0x2 SATA HDMI I2S RTC+EEPROM

BOARD_NAME="NAPI-SMARC"
BOARD_VENDOR="napilab"
BOARDFAMILY="rk35xx"
BOARD_MAINTAINER=""

# Same RK3568 U-Boot as NAPI2 -- both are RK3568J modules, only the carrier differs.
# NOTE: the patch creating this defconfig is not in this tree yet (neither is NAPI2's);
# it still has to be ported into patch/u-boot/legacy/u-boot-radxa-rk35xx/.
BOOTCONFIG="napi2-rk3568_defconfig"
BOOT_FDT_FILE="rockchip/rk3568-smarc.dtb"

# No vendor kernel here: rk3568-smarc.dts exists for mainline only (6.12 / 6.16).
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

PACKAGE_LIST_BOARD="vim net-tools can-utils mbpoll minicom tcpdump screen memtester xxd tree \
	util-linux-extra mosquitto mosquitto-clients i2c-tools python3-pymodbus python3-pip \
	python3-smbus2 git tmux make cmake gcc build-essential flex bison libssl-dev pkg-config"

PACKAGE_LIST_DESKTOP_BOARD="libgbm1 mesa-vulkan-drivers x11vnc mpv celluloid ffmpeg libavcodec-extra"

DESKTOP_APPGROUPS_SELECTED="${DESKTOP_APPGROUPS_SELECTED-}"

function post_family_config__napi_smarc_overlay_prefix_and_defaults() {
	declare -g OVERLAY_PREFIX="rk3568"
	declare -g TZDATA="Europe/Moscow"
	declare -g INSTALL_HEADERS="${INSTALL_HEADERS:-yes}"
}

function post_family_tweaks_bsp__napi_bsp_cli_files_smarc() {
	[[ ! -d "${SRC}/packages/bsp/napi" ]] && return 0
	display_alert "${BOARD}" "adding NapiLab BSP files to armbian-bsp-cli" "info"
	run_host_command_logged cp -a "${SRC}/packages/bsp/napi/." "${destination}/"
	return 0
}

function post_family_tweaks__napi_firstrun_preset_smarc() {
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

function post_family_tweaks__napi_motd_no_wan_lookup_smarc() {
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

function post_family_tweaks__napi_smarc_desktop_assets() {
	[[ "${BUILD_DESKTOP}" != "yes" ]] && return 0
	if [[ -d "${SRC}/packages/bsp/napi-desktop" ]]; then
		display_alert "${BOARD}" "installing NapiLab desktop assets" "info"
		# NOT `cp -a`: the build runs as root, so --preserve=ownership would stamp the
		# *build host user's* uid/gid (typically 1000, i.e. the future "napi" user) onto
		# /etc/apt/sources.list.d, /usr/share/keyrings, /usr/local/bin and /etc/skel --
		# and cp also rewrites the mode of pre-existing destination directories. Unlike
		# the bsp-cli copy above, nothing chowns ${SDCARD} afterwards. tar keeps the
		# symlinks and the 0755 bits without touching ownership or existing directories.
		run_host_command_logged "tar -C '${SRC}/packages/bsp/napi-desktop' -cf - ." "|" \
			"tar -C '${SDCARD}' --no-same-owner --no-overwrite-dir -xf -"
	fi

	declare mozilla_src="${SDCARD}/etc/apt/sources.list.d/napi-mozillateam.sources"
	if [[ -f "${mozilla_src}" ]]; then
		if [[ "${DISTRIBUTION}" == "Ubuntu" ]]; then
			sed -i "s|^Suites:.*|Suites: ${RELEASE}|" "${mozilla_src}"
		else
			display_alert "${BOARD}" "not Ubuntu (${DISTRIBUTION}), dropping mozillateam PPA" "info"
			run_host_command_logged rm -f "${mozilla_src}" \
				"${SDCARD}/etc/apt/preferences.d/napi-browsers-no-snap" \
				"${SDCARD}/usr/share/keyrings/napi-mozillateam.gpg"
		fi
	fi

	declare greeter
	for greeter in "${SDCARD}/etc/lightdm/slick-greeter.conf" \
		"${SDCARD}/etc/armbian/lightdm/slick-greeter.conf"; do
		[[ -f "${greeter}" ]] || continue
		sed -i 's|^background *=.*|background = /usr/share/backgrounds/napi-wallpaper.jpg|' "${greeter}"
	done
	return 0
}

function post_repo_customize_image__napi_extra_repo_packages_smarc() {
	if [[ -f "${SDCARD}/usr/share/keyrings/napilab.gpg" ]]; then
		display_alert "${BOARD}" "installing napilab packages: mbusd gpiod" "info"
		chroot_sdcard_apt_get_install mbusd gpiod
	fi

	if [[ "${BUILD_DESKTOP}" == "yes" ]] && [[ "${DISTRIBUTION}" == "Ubuntu" ]] &&
		compgen -G "${SDCARD}/etc/apt/sources.list.d/"*mozillateam* > /dev/null; then
		display_alert "${BOARD}" "installing browser: firefox (mozillateam PPA)" "info"
		chroot_sdcard_apt_get_install firefox
	fi
	return 0
}

function image_specific_armbian_env_ready__napi_smarc_extraargs() {
	declare env_file="${SDCARD}/boot/armbianEnv.txt"
	declare extraargs="cma=256M console=tty1 earlycon loglevel=7"
	display_alert "${BOARD}" "setting extraargs" "${extraargs}" "info"
	if grep -q '^extraargs=' "${env_file}"; then
		sed -i "s|^extraargs=.*|extraargs=${extraargs}|" "${env_file}"
	else
		echo "extraargs=${extraargs}" >> "${env_file}"
	fi
	return 0
}
