#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		stretch)
			# your code here
			# InstallOpenMediaVault # uncomment to get an OMV 4 image
			;;
		buster)
			# your code here
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;
		noble)
			InstallExtraAll
			;;
	esac
} # Main

InstallOpenMediaVault() {
	# use this routine to create a Debian based fully functional OpenMediaVault
	# image (OMV 3 on Jessie, OMV 4 with Stretch). Use of mainline kernel highly
	# recommended!
	#
	# Please note that this variant changes Armbian default security 
	# policies since you end up with root password 'openmediavault' which
	# you have to change yourself later. SSH login as root has to be enabled
	# through OMV web UI first
	#
	# This routine is based on idea/code courtesy Benny Stark. For fixes,
	# discussion and feature requests please refer to
	# https://forum.armbian.com/index.php?/topic/2644-openmediavault-3x-customize-imagesh/

	echo root:openmediavault | chpasswd
	rm /root/.not_logged_in_yet
	. /etc/default/cpufrequtils
	export LANG=C LC_ALL="en_US.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	case ${RELEASE} in
		jessie)
			OMV_Name="erasmus"
			OMV_EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all3.deb"
			;;
		stretch)
			OMV_Name="arrakis"
			OMV_EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all4.deb"
			;;
	esac

	# Add OMV source.list and Update System
	cat > /etc/apt/sources.list.d/openmediavault.list <<- EOF
	deb https://openmediavault.github.io/packages/ ${OMV_Name} main
	## Uncomment the following line to add software from the proposed repository.
	deb https://openmediavault.github.io/packages/ ${OMV_Name}-proposed main
	
	## This software is not part of OpenMediaVault, but is offered by third-party
	## developers as a service to OpenMediaVault users.
	# deb https://openmediavault.github.io/packages/ ${OMV_Name} partner
	EOF

	# Add OMV and OMV Plugin developer keys, add Cloudshell 2 repo for XU4
	if [ "${BOARD}" = "odroidxu4" ]; then
		add-apt-repository -y ppa:kyle1117/ppa
		sed -i 's/jessie/xenial/' /etc/apt/sources.list.d/kyle1117-ppa-jessie.list
	fi
	mount --bind /dev/null /proc/mdstat
	apt-get update
	apt-get --yes --force-yes --allow-unauthenticated install openmediavault-keyring
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7AA630A1EDEE7D73
	apt-get update

	# install debconf-utils, postfix and OMV
	HOSTNAME="${BOARD}"
	debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
	apt-get --yes --force-yes --allow-unauthenticated  --fix-missing --no-install-recommends \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install \
		debconf-utils postfix
	# move newaliases temporarely out of the way (see Ubuntu bug 1531299)
	cp -p /usr/bin/newaliases /usr/bin/newaliases.bak && ln -sf /bin/true /usr/bin/newaliases
	sed -i -e "s/^::1         localhost.*/::1         ${HOSTNAME} localhost ip6-localhost ip6-loopback/" \
		-e "s/^127.0.0.1   localhost.*/127.0.0.1   ${HOSTNAME} localhost/" /etc/hosts
	sed -i -e "s/^mydestination =.*/mydestination = ${HOSTNAME}, localhost.localdomain, localhost/" \
		-e "s/^myhostname =.*/myhostname = ${HOSTNAME}/" /etc/postfix/main.cf
	apt-get --yes --force-yes --allow-unauthenticated  --fix-missing --no-install-recommends \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install \
		openmediavault

	# install OMV extras, enable folder2ram and tweak some settings
	FILE=$(mktemp)
	curl "$OMV_EXTRAS_URL" -fLso "$FILE" && dpkg -i "$FILE"
	
	/usr/sbin/omv-update
	# Install flashmemory plugin and netatalk by default, use nice logo for the latter,
	# tweak some OMV settings
	. /usr/share/openmediavault/scripts/helper-functions
	apt-get -y -q install openmediavault-netatalk openmediavault-flashmemory
	AFP_Options="mimic model = Macmini"
	SMB_Options="min receivefile size = 16384\nwrite cache size = 524288\ngetwd cache = yes\nsocket options = TCP_NODELAY IPTOS_LOWDELAY"
	xmlstarlet ed -L -u "/config/services/afp/extraoptions" -v "$(echo -e "${AFP_Options}")" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/smb/extraoptions" -v "$(echo -e "${SMB_Options}")" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/flashmemory/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/ssh/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/ssh/permitrootlogin" -v "0" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/time/ntp/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/time/timezone" -v "UTC" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/network/dns/hostname" -v "${HOSTNAME}" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/monitoring/perfstats/enable" -v "0" /etc/openmediavault/config.xml
	echo -e "OMV_CPUFREQUTILS_GOVERNOR=${GOVERNOR}" >>/etc/default/openmediavault
	echo -e "OMV_CPUFREQUTILS_MINSPEED=${MIN_SPEED}" >>/etc/default/openmediavault
	echo -e "OMV_CPUFREQUTILS_MAXSPEED=${MAX_SPEED}" >>/etc/default/openmediavault
	for i in netatalk samba flashmemory ssh ntp timezone interfaces cpufrequtils monit collectd rrdcached ; do
		/usr/sbin/omv-mkconf $i
	done
	/sbin/folder2ram -enablesystemd || true
	sed -i 's|-j /var/lib/rrdcached/journal/ ||' /etc/init.d/rrdcached

	# Fix multiple sources entry on ARM with OMV4
	sed -i '/stretch-backports/d' /etc/apt/sources.list

	# rootfs resize to 7.3G max and adding omv-initsystem to firstrun -- q&d but shouldn't matter
	echo 15500000s >/root/.rootfs_resize
	sed -i '/systemctl\ disable\ armbian-firstrun/i \
	mv /usr/bin/newaliases.bak /usr/bin/newaliases \
	export DEBIAN_FRONTEND=noninteractive \
	sleep 3 \
	apt-get install -f -qq python-pip python-setuptools || exit 0 \
	pip install -U tzupdate \
	tzupdate \
	read TZ </etc/timezone \
	/usr/sbin/omv-initsystem \
	xmlstarlet ed -L -u "/config/system/time/timezone" -v "${TZ}" /etc/openmediavault/config.xml \
	/usr/sbin/omv-mkconf timezone \
	lsusb | egrep -q "0b95:1790|0b95:178a|0df6:0072" || sed -i "/ax88179_178a/d" /etc/modules' /usr/lib/armbian/armbian-firstrun
	sed -i '/systemctl\ disable\ armbian-firstrun/a \
	sleep 30 && sync && reboot' /usr/lib/armbian/armbian-firstrun

	# add USB3 Gigabit Ethernet support
	echo -e "r8152\nax88179_178a" >>/etc/modules

	# Special treatment for ODROID-XU4 (and later Amlogic S912, RK3399 and other big.LITTLE
	# based devices). Move all NAS daemons to the big cores. With ODROID-XU4 a lot
	# more tweaks are needed. CS2 repo added, CS1 workaround added, coherent_pool=1M
	# set: https://forum.odroid.com/viewtopic.php?f=146&t=26016&start=200#p197729
	# (latter not necessary any more since we fixed it upstream in Armbian)
	case ${BOARD} in
		odroidxu4)
			HMP_Fix='; taskset -c -p 4-7 $i '
			# Cloudshell stuff (fan, lcd, missing serials on 1st CS2 batch)
			echo "H4sIAKdXHVkCA7WQXWuDMBiFr+eveOe6FcbSrEIH3WihWx0rtVbUFQqCqAkYGhJn
			tF1x/vep+7oebDfh5DmHwJOzUxwzgeNIpRp9zWRegDPznya4VDlWTXXbpS58XJtD
			i7ICmFBFxDmgI6AXSLgsiUop54gnBC40rkoVA9rDG0SHHaBHPQx16GN3Zs/XqxBD
			leVMFNAz6n6zSWlEAIlhEw8p4xTyFtwBkdoJTVIJ+sz3Xa9iZEMFkXk9mQT6cGSQ
			QL+Cr8rJJSmTouuuRzfDtluarm1aLVHksgWmvanm5sbfOmY3JEztWu5tV9bCXn4S
			HB8RIzjoUbGvFvPw/tmr0UMr6bWSBupVrulY2xp9T1bruWnVga7DdAqYFgkuCd3j
			vORUDQgej9HPJxmDDv+3WxblBSuYFH8oiNpHz8XvPIkU9B3JVCJ/awIAAA==" \
			| tr -d '[:blank:]' | base64 --decode | gunzip -c >/usr/local/sbin/cloudshell2-support.sh
			chmod 755 /usr/local/sbin/cloudshell2-support.sh
			apt install -y i2c-tools odroid-cloudshell cloudshell2-fan
			sed -i '/systemctl\ disable\ armbian-firstrun/i \
			lsusb | grep -q -i "05e3:0735" && sed -i "/exit\ 0/i echo 20 > /sys/class/block/sda/queue/max_sectors_kb" /etc/rc.local \
			/usr/sbin/i2cdetect -y 1 | grep -q "60: 60" && /usr/local/sbin/cloudshell2-support.sh' /usr/lib/armbian/armbian-firstrun
			;;
		bananapim3)
			HMP_Fix='; taskset -c -p 4-7 $i '
			;;
		edge*|ficus|firefly-rk3399|nanopct4|nanopim4|nanopineo4|renegade-elite|roc-rk3399-pc|rockpro64|station-p1)
			HMP_Fix='; taskset -c -p 4-5 $i '
			;;
	esac
	echo "* * * * * root for i in \`pgrep \"ftpd|nfsiod|smbd|afpd|cnid\"\` ; do ionice -c1 -p \$i ${HMP_Fix}; done >/dev/null 2>&1" \
		>/etc/cron.d/make_nas_processes_faster
	chmod 600 /etc/cron.d/make_nas_processes_faster

	# add SATA port multiplier hint if appropriate
	[ "${LINUXFAMILY}" = "sunxi" ] && \
		echo -e "#\n# If you want to use a SATA PM add \"ahci_sunxi.enable_pmp=1\" to bootargs above" \
		>>/boot/boot.cmd

	# Filter out some log messages
	echo ':msg, contains, "do ionice -c1" ~' >/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "action " ~' >>/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "netsnmp_assert" ~' >>/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "Failed to initiate sched scan" ~' >>/etc/rsyslog.d/omv-armbian.conf

	# Fix little python bug upstream Debian 9 obviously ignores
	if [ -f /usr/lib/python3.5/weakref.py ]; then
		GITREF="9cd7e17640a49635d1c1f8c2989578a8fc2c1de6"
		curl -fLo /usr/lib/python3.5/weakref.py \
			"https://raw.githubusercontent.com/python/cpython/${GITREF}/Lib/weakref.py"
	fi

	# clean up and force password change on first boot
	umount /proc/mdstat
	chage -d 0 root
} # InstallOpenMediaVault

UnattendedStorageBenchmark() {
	# Function to create Armbian images ready for unattended storage performance testing.
	# Useful to use the same OS image with a bunch of different SD cards or eMMC modules
	# to test for performance differences without wasting too much time.

	rm /root/.not_logged_in_yet

	apt-get -qq install time

	curl -fLso /usr/local/bin/sd-card-bench.sh "https://raw.githubusercontent.com/ThomasKaiser/sbc-bench/master/sd-card-bench.sh"
	chmod 755 /usr/local/bin/sd-card-bench.sh

	sed -i '/^exit\ 0$/i \
	/usr/local/bin/sd-card-bench.sh &' /etc/rc.local
} # UnattendedStorageBenchmark

InstallAdvancedDesktop()
{
	apt-get install -yy transmission libreoffice libreoffice-style-tango meld remmina thunderbird kazam avahi-daemon
	[[ -f /usr/share/doc/avahi-daemon/examples/sftp-ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/
	[[ -f /usr/share/doc/avahi-daemon/examples/ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/
	apt clean

} # InstallAdvancedDesktop

InstallExtraAll()
{

#### Disable first login wizard, set locale, set timezone ###############

echo "[CUSTOM] -> Set default pass, add default user napi"

ROOT_PASS="napilinux"
USERNAME="napi"
PASSWORD_HASH='$6$aKSitqfHesC39mSa$VyraNR1ZZsvYCTZEeDJC3XR9/375qc5VTpK8eKxMJ3zKC1GGTeW7cKZFzYUIUNM3uEeFCeRiCAWsaj0mcvGPJ/'

# root пароль
echo "root:${ROOT_PASS}" | chpasswd

echo `date` > /root/info.txt
echo "#start vnc server"  > /root/good-scripts.txt
echo "x11vnc -display :0 -nopw -listen 0.0.0.0 -forever &" >> /root/good-scripts.txt

useradd -d "/home/$USERNAME" -s /bin/bash \
    -G sudo,video,render,audio,input,netdev,dialout \
    "$USERNAME"

# задать пароль пользователю (hash)
usermod -p "$PASSWORD_HASH" "$USERNAME"

#systemctl enable create-home.service

echo "[CUSTOM] -> Disable first login script"
# отключить мастер первого запуска Armbian
rm -f /root/.not_logged_in_yet || true
systemctl mask armbian-firstlogin.service 2>/dev/null || true

##########################################################################

####### LOCALES #########################################################
  echo "[CUSTOM] -> Install Moscow localtime, LANG=en"

  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  echo "Europe/Moscow" > /etc/timezone

  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8

#########################################################################

##### Apply overlays from userpathes/overlay/etc/sysctl.da #############

echo "[CUSTOM] -> Install extra services sysctl.d/* for all"
cp /tmp/overlay/etc/sysctl.d/* /etc/sysctl.d/

#########################################################################

#### ONLY for desktop install gpu\mesa packets and graph ###########################

  if [ "${BUILD_DESKTOP}" = "yes" ]; then
        echo "[CUSTOM] -> Install extra-packages for desktop"
	apt-get update
	apt-get install -y --no-install-recommends libgbm1 mesa-utils libgl1-mesa-dri mesa-vulkan-drivers \
                                                   x11vnc mpv celluloid ffmpeg libavcodec-extra

	echo "x11vnc -auth guess -display :0 -nopw -listen 0.0.0.0 -forever &" >/root/x11srv.sh
  fi      

#########################################################################


#### ADD SErvice to make /home/napi on first start ######################

#cat > /etc/systemd/system/create-home.service << 'EOF'
#[Unit]
#Description=Create home directory for napi
#After=local-fs.target
#ConditionPathExists=!/home/napi

#[Service]
#Type=oneshot
#ExecStart=/bin/bash -c "mkdir -p /home/napi && cp -r /etc/skel/. /home/napi/ && chown -R napi:napi /home/napi"
#RemainAfterExit=yes

#[Install]
#WantedBy=multi-user.target
#EOF

#mkdir -p /etc/systemd/system/multi-user.target.wants/
#ln -sf /etc/systemd/system/create-home.service \
#    /etc/systemd/system/multi-user.target.wants/create-home.service

echo "[CUSTOM] -> Create create-home service"

cp /tmp/overlay/services/create-home.service /etc/systemd/system/create-home.service
ln -sf /etc/systemd/system/create-home.service \
    /etc/systemd/system/multi-user.target.wants/create-home.service

##############################################################################


############## Compile OVERLAYS ##############################################
echo "[CUSTOM] -> Compile overlays DTS - DTBO "

mkdir -p /root/dts/
mkdir -p /boot/overlay-user/

apt-get update
apt-get install -y cpp

if [ "${BOARD}" = "napic" ]; then
        echo "[CUSTOM] -> Compile overlaysi for Napi based on 3308"

mkdir -p /tmp/overlays-work/dt-bindings/gpio
mkdir -p /tmp/overlays-work/dt-bindings/pinctrl
mkdir -p /tmp/overlays-work/dt-bindings/interrupt-controller/
cp /tmp/overlay/overlays-rk3308/*.dts /tmp/overlays-work/
cp /tmp/overlay/dt-bindings/interrupt-controller/arm-gic.h /tmp/overlays-work/
cp /tmp/overlay/dt-bindings/interrupt-controller/arm-gic.h /tmp/overlays-work/dt-bindings/interrupt-controller/arm-gic.h
cp /tmp/overlay/dt-bindings/interrupt-controller/irq.h /tmp/overlays-work/dt-bindings/interrupt-controller/
cp /tmp/overlay/dt-bindings/gpio/gpio.h /tmp/overlays-work/dt-bindings/gpio/
cp /tmp/overlay/dt-bindings/pinctrl/rockchip.h /tmp/overlays-work/dt-bindings/pinctrl/

# компилируем
for dts in /tmp/overlays-work/*.dts; do
    name=$(basename ${dts%.dts})
    cpp -nostdinc -I /tmp/overlays-work -I /tmp/overlays-work/dt-bindings -undef -x assembler-with-cpp "$dts" | \
    dtc -@ -I dts -O dtb -o "/boot/dtb/rockchip/overlay/${name}.dtbo" - \
    && echo "[ ok ] compiled: ${name}" \
    || echo "[ FAIL ] failed: ${name}"
    cp "$dts" /root/dts/
done

# убираем
rm -rf /tmp/overlays-work


	ENV_FILE="${SDCARD}/boot/armbianEnv.txt"
	echo "overlays=uart1 uart2-m0 uart3-m0 i2c1-ds1338 i2c3-m0 usb20-host" >> "$ENV_FILE"
fi

#compile vendor dts

if [ "${BOARD}" = "napi2" ]; then
	BRANCH=$(cat /tmp/overlay/napi-branch.txt 2>/dev/null)
	if [ "${BRANCH}" = "vendor" ]; then
        	echo "[CUSTOM] -> copy bindings for vendor"
        	mkdir -p /tmp/overlays-work/dt-bindings/gpio
        	mkdir -p /tmp/overlays-work/dt-bindings/pinctrl
        	mkdir -p /tmp/overlays-work/dt-bindings/interrupt-controller
        	mkdir -p /tmp/overlays-work/dt-bindings/display
        	mkdir -p /tmp/overlays-work/uapi/linux
        	
		cp /tmp/overlay/overlays-rk3568-vendor/*.dts /tmp/overlays-work/
        
		cp /tmp/overlay/includes-rk35xx-vendor/dt-bindings/interrupt-controller/arm-gic.h /tmp/overlays-work/dt-bindings/interrupt-controller/
        	cp /tmp/overlay/includes-rk35xx-vendor/dt-bindings/interrupt-controller/irq.h /tmp/overlays-work/dt-bindings/interrupt-controller/
        	cp /tmp/overlay/includes-rk35xx-vendor/dt-bindings/gpio/gpio.h /tmp/overlays-work/dt-bindings/gpio/
        	cp /tmp/overlay/includes-rk35xx-vendor/dt-bindings/pinctrl/rockchip.h /tmp/overlays-work/dt-bindings/pinctrl/
        	cp /tmp/overlay/includes-rk35xx-vendor/dt-bindings/display/media-bus-format.h /tmp/overlays-work/dt-bindings/display/
        	cp /tmp/overlay/includes-rk35xx-vendor/uapi/linux/media-bus-format.h /tmp/overlays-work/uapi/linux/
	fi
	
        if [ "${BRANCH}" = "current" ]; then
        	echo "[CUSTOM] -> copy bindings for current"
        	mkdir -p /tmp/overlays-work/dt-bindings/gpio
        	mkdir -p /tmp/overlays-work/dt-bindings/pinctrl
        	mkdir -p /tmp/overlays-work/dt-bindings/interrupt-controller
        	mkdir -p /tmp/overlays-work/dt-bindings/display
        	mkdir -p /tmp/overlays-work/uapi/linux
		cp /tmp/overlay/overlays-rk3568-current/*.dts /tmp/overlays-work/
	fi

        echo "[CUSTOM] -> Compile overlays for Napi2"
        for dts in /tmp/overlays-work/*.dts; do
                name=$(basename "${dts%.dts}")
                cpp -nostdinc -I /tmp/overlays-work -I /tmp/overlays-work/dt-bindings -undef -x assembler-with-cpp "$dts" | \
                dtc -@ -I dts -O dtb -o "/boot/dtb/rockchip/overlay/${name}.dtbo" - \
                && echo "[CUSTOM] -> [ OK ] compiled: ${name}" \
                || echo "[CUSTOM] -> [ FAIL ] failed: ${name}"
                cp "$dts" /root/dts/
        done
# убираем
	rm -rf /tmp/overlays-work
	cp /tmp/overlay/overlays-rk3568/* /root/dts/
        
        ENV_FILE="${SDCARD}/boot/armbianEnv.txt"
        echo "overlays=" >> "$ENV_FILE"
        echo "user_overlays=" >> "$ENV_FILE"
fi

##############################################################################


echo "[CUSTOM] -> Repair mod scripts on login"
##########   MOTD: скрипты должны быть исполняемыми #########################
if [ -d /etc/update-motd.d ]; then
  chmod 0755 /etc/update-motd.d/* 2>/dev/null || true
fi
##############################################################################

echo "[CUSTOM] -> Install extra packages for all"
apt-get update  
apt-get install -y --no-install-recommends \
                vim net-tools can-utils mbpoll minicom \
                tcpdump screen memtester xxd tree util-linux-extra \
		mosquitto mosquitto-clients i2c-tools \
                python3-pymodbus python3-pip python3-smbus2 git tmux

#################### NO Autologin ##############################

cp /tmp/overlay/services/serial-getty-override.conf \
   /etc/systemd/system/serial-getty@.service.d/override.conf

cp /tmp/overlay/services/serial-getty-override.conf \
   /etc/systemd/system/getty@.service.d/override.conf

################################################################


echo "[CUSTOM] -> Repair lightdm start"
########### enabe autostart graphics #########################
if [ "${BOARD}" = "napi2" ] && [ "${BUILD_DESKTOP}" = "yes" ]; then
    ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
    systemctl daemon-reload
fi
##############################################################

#####################################################################################
## Personal tweaks (bacground, firefox from repo (not snapd) )
## ALL do for root, service create-home will copy to /home/napi/.config/ on first boot
##

# copy background 

echo "[CUSTOM] -> Install napi backgound"



# Install browsers 

if [ "${BOARD}" = "napi2" ] && [ "${BUILD_DESKTOP}" = "yes" ]; then

echo "[CUSTOM] -> Browsers part"

#forbid snap for firefox anfd chrome

  cat > /etc/apt/preferences.d/browsers-no-snap << 'EOF'
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1

Package: chromium*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF

# install firefox

echo "[CUSTOM] -> Install Firefox"
add-apt-repository -y ppa:mozillateam/ppa
apt-get update
apt-get install -y firefox 

#install crome (ucomment) will download about 300Mb
#	echo "[CUSTOM] -> Install Chromium"
#    apt install chromium


# tweak for chromium window
echo "[CUSTOM] -> Tweak chromium"
mkdir -p /root/cf/chrome-configs/
cp /tmp/overlay/chromium-configs/chrome-window-repair-.config-chromium-Default-Preferences /root/cf/chrome-configs/chrome-window-repair-.config-chromium-Default-Preferences
mkdir -p /etc/chromium/
cp /tmp/overlay/chromium-configs/chrome-window-repair-.config-chromium-Default-Preferences  /etc/chromium/master_preferences

fi
#############################################################


########### FIX Display init windows ###################

echo "[CUSTOM] -> XFCE teaks"

if [ "${BOARD}" = "napi2" ] && [ "${BUILD_DESKTOP}" = "yes" ]; then
    mkdir -p /usr/share/backgrounds/
    cp /tmp/overlay/backgrounds/napi-wallpaper.jpg /usr/share/backgrounds/napi-wallpaper.jpg
    cp /tmp/overlay/backgrounds/napi-wallpaper.jpg /usr/share/backgrounds/armbian/napi-wallpaper.jpg
    cp /tmp/overlay/backgrounds/napi-wallpaper.jpg /usr/share/backgrounds/xfce/napi-wallpaper.jpg
    chmod 644 /usr/share/backgrounds/napi-wallpaper.jpg
    chmod 644 /usr/share/backgrounds/armbian/napi-wallpaper.jpg
    chmod 644 /usr/share/backgrounds/xfce/napi-wallpaper.jpg
     
    mkdir -p /root/cf/xfce-configs/
    cp /tmp/overlay/lightdm/* /root/cf/xfce-configs/
    #mkdir -p /etc/lightdm/slick-greeter.conf.d
    cp /tmp/overlay/lightdm/slick-greeter.conf /etc/lightdm/slick-greeter.conf
    
    #mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    #cp /tmp/overlay/xfce-configs/* /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    
    cp /tmp/overlay/xfce-configs/* /root/cf/xfce-configs/

    cp /tmp/overlay/xfce-configs/napi-wallpaper.desktop /etc/xdg/autostart/napi-wallpaper.desktop
    cp /tmp/overlay/xfce-configs/napi-set-wallpaper.sh /usr/local/bin/napi-set-wallpaper.sh

    # disable popup display window
#    cp /tmp/overlay/xfce-configs/xfce4-display-settings-autostart.desktop /etc/xdg/autostart/xfce4-display-settings-autostart.desktop
     cp /tmp/overlay/xfce-configs/displays.xml /root/cf/xfce-configs/

     cp /tmp/overlay/xfce-configs/displays.xml \
       /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml
    
    chmod +x /usr/local/bin/napi-set-wallpaper.sh
fi
#### Fix WAN (remove) ###################################
echo "[CUSTOM] -> Remove WAN in initial motd "
sed -i '/^get_wan_address/s/.*/get_wan_address()  { true; }/' /etc/update-motd.d/20-ip-info
sed -i '/^get_wan6_address/s/.*/get_wan6_address() { true; }/' /etc/update-motd.d/20-ip-info
#########################################################

###### FIX log to momitor and console ###############
echo "[CUSTOM] -> kernel log  to monitor and console "
sed -i 's/^console=.*/console=serial/' /boot/armbianEnv.txt
sed -i 's/^extraargs=.*/extraargs=cma=256M console=tty1 earlycon loglevel=7/' /boot/armbianEnv.txt
######################################################

########### Add headers, make, glibc  ############################
echo "[CUSTOM] -> Install make and Ko"
apt-get update
apt-get install -y make cmake gcc build-essential flex bison libssl-dev pkg-config
#echo "[CUSTOM] -> install headers "

#### Headers added fom parameter compile.sh ########

#apt-get install -y linux-headers-rockchip64

#if [ "${BRANCH}" = "vendor" ]; then
#	apt-get install -y linux-headers-vendor-rk35xx
#fi

#if [ "${BRANCH}" = "current" ]; then
#	apt-get install -y linux-headers-current-rockchip64
#fi

#apt-get install -y linux-headers-${BRANCH}-${LINUXFAMILY}

#cat /etc/apt/sources.list.d/*.list 2>/dev/null
#apt-cache search linux-headers | head -20
#dpkg -i /tmp/debs/linux-headers-*-rockchip64_*.deb 
#dpkg -i /tmp/debs/linux-libc-dev-*-rockchip64_*.deb
#apt-get update
#apt-get install -y linux-headers-rockchip64
####################################################

########## Install make and Ko ##############################
#apt-get install -y make gcc build-essential
############################################################


### Set russian mirror 
#echo "[CUSTOM] -> set rumirror"
#if [ -f /etc/apt/sources.list.d/armbian.sources ]; then
#    sed -i 's|http://apt.armbian.com|http://stpete-mirror.armbian.com|g' \
#        /etc/apt/sources.list.d/armbian.sources
#fi
##############

#echo "[CUSTOM] -> set rumirror"
#SOURCES_FILE="/etc/apt/sources.list.d/armbian.sources"
#if [ -f "$SOURCES_FILE" ]; then
#    echo "[CUSTOM] -> file found, replacing..."
#    sed -i 's|http://apt.armbian.com|http://stpete-mirror.armbian.com|g' "$SOURCES_FILE"
#    echo "[CUSTOM] -> result:"
#    cat "$SOURCES_FILE"
#else
#    echo "[CUSTOM] -> file NOT found at $SOURCES_FILE"
#fi

########## Compile mbusd ####################
#echo "[CUSTOM] -> compile mbusd"
#cd /tmp
#git clone https://github.com/3cky/mbusd.git
#cd mbusd
#cmake .
#make
#make install
#############################################

########## Set russian mirror ###############

#echo "[CUSTOM] -> set rumirror"
#if [ -f /etc/apt/sources.list.d/armbian.sources ]; then
#    sed -i 's|http://apt.armbian.com|http://stpete-mirror.armbian.com|g' \
#        /etc/apt/sources.list.d/armbian.sources
#    echo "[CUSTOM] -> mirror set OK"
#else
#    echo "[CUSTOM] -> armbian.sources not found, skipping (SKIP_ARMBIAN_REPO mode?)"
#fi

echo "[CUSTOM] -> add napilab repo, install mbusd"
# NapiLab repo + mbusd for Armbian build
curl -fsSL https://repo.napilab.ru/napilab.gpg | gpg --dearmor | tee /usr/share/keyrings/napilab.gpg > /dev/null
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/napilab.gpg] https://repo.napilab.ru stable main" > /etc/apt/sources.list.d/napilab.list
apt-get update || true
apt-get purge -y libgpiod2 libgpiod-dev gpiod || true
apt-get install -y mbusd gpiod



### ONLY FOR RTK ##########
#### INSTALL DEBS ########
if [ -f /tmp/overlay/napi-client.txt ]; then
    echo "[CUSTOM] -> Add RTK VIDEO  Server"
    CLIENT=$(cat /tmp/overlay/napi-client.txt)
    echo "[CUSTOM] -> Add RTK: DEBS OK "
    if [ -d /tmp/overlay/${CLIENT}-debs ]; then
        mkdir -p /root/${CLIENT}-debs
        cp /tmp/overlay/${CLIENT}-debs/*.deb /root/${CLIENT}-debs/

        # depenedeces
        apt-get install -y libjson-perl libllvm17t64 libpq5 libxslt1.1 \
            postgresql postgresql-16 postgresql-client-16 \
            postgresql-client-common postgresql-common ssl-cert \
            2>&1 || true

        # Теперь клиентские пакеты
        dpkg -i /root/${CLIENT}-debs/*.deb 2>&1 || true
        find /etc/apt/sources.list.d/ -name '*rt*' -exec mv {} {}.disabled \; 2>/dev/null || true
    fi
fi
############################

}

Main "$@"
