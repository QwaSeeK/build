# Rockchip RK3562 quad core 2GB LPDDR3 eMMC GbE 100MbE USB3

BOARD_NAME="NAPI-M"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER=""

BOOT_SOC="rk3562"
BOOTCONFIG="napi-m-rk3562_defconfig"
BOOT_FDT_FILE="rockchip/rk3562-napi-m.dtb"
BOOT_SCENARIO="spl-blobs"

KERNEL_TARGET="vendor,vendor-next"
IMAGE_PARTITION_TABLE="gpt"
BOOT_LOGO="no"
FULL_DESKTOP="no"
DEFAULT_CONSOLE="serial"

ROOTPWD="napilinux"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="vim net-tools minicom tcpdump screen memtester xxd tree i2c-tools"

function post_family_config__napi_m_vendor() {
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTDELAY=2
}

function custom_kernel_config__napi_m_soc() {
	opts_y+=("CPU_RK3562" "CLK_RK3562" "ROCKCHIP_CSU")
}
