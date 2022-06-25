#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021- https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021- https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Instructions: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Download options: https://downloads.openwrt.org/releases
# Command: ./imagebuilder.sh <branch>
#          ./imagebuilder.sh 21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# custom_packages         : Add custom packages
# custom_files            : Add custom files
# adjust_settings         : Adjust related file settings
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
imagebuilder_path="${make_path}/openwrt"
custom_files_path="${make_path}/router-config/openwrt-imagebuilder/files"
# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    echo -e "${STEPS} Start downloading OpenWrt files..."
    # Downloading imagebuilder files
    # Download example: https://downloads.openwrt.org/releases/21.02.3/targets/armvirt/64/openwrt-imagebuilder-21.02.3-armvirt-64.Linux-x86_64.tar.xz
    download_file="https://downloads.openwrt.org/releases/${rebuild_branch}/targets/armvirt/64/openwrt-imagebuilder-${rebuild_branch}-armvirt-64.Linux-x86_64.tar.xz"
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf openwrt-imagebuilder-* && sync && rm -f openwrt-imagebuilder-*.tar.xz
    mv -f openwrt-imagebuilder-* openwrt

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start adding custom packages..."
    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-amlogic
    amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
    #
    amlogic_file="luci-app-amlogic"
    amlogic_file_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_name}.*.ipk" | head -n 1)"
    wget -q ${amlogic_file_down} -O packages/${amlogic_file_down##*/}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${amlogic_file} ] is downloaded successfully."
    #
    amlogic_i18n="luci-i18n-amlogic"
    amlogic_i18n_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_i18n}.*.ipk" | head -n 1)"
    wget -q ${amlogic_i18n_down} -O packages/${amlogic_i18n_down##*/}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${amlogic_i18n} ] is downloaded successfully."

    # Download other luci-app-xxx
    # ......

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}

    [[ -d "${custom_files_path}" ]] && {
        echo -e "${STEPS} Start adding custom files..."
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    }
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}

    # For .config file
    [[ -s ".config" ]] && {
        echo -e "${STEPS} Start adjusting .config file settings..."
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    }

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start building OpenWrt with Image Builder..."
    # Selecting packages, lib, theme, app and i18n
    my_packages="\
        cgi-io libiwinfo libiwinfo-data libiwinfo-lua liblua liblucihttp liblucihttp-lua \
        libubus-lua lua luci luci-app-firewall luci-app-opkg luci-base luci-lib-base \
        luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network \
        luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-ssl \
        luci-theme-bootstrap px5g-wolfssl rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci \
        rpcd-mod-rrdns uhttpd uhttpd-mod-ubus luci-compat \
        ath9k-htc-firmware btrfs-progs hostapd hostapd-utils kmod-ath kmod-ath9k kmod-ath9k-common \
        kmod-ath9k-htc kmod-cfg80211 kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash \
        kmod-fs-btrfs kmod-mac80211 wireless-tools wpa-cli wpa-supplicant \
        libc php8 php8-cgi php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv php8-mod-mbstring \
        zoneinfo-core zoneinfo-asia nano htop unzip wget wget-ssl libmbedtls tar bash luci-app-mwan3 luci-theme-material \
        git git-http jq openssh-client openssl-util luci-app-ttyd ttyd zram-swap curl ca-certificates \
        netdata httping coreutils-timeout perl fdisk \
        kmod-usb-net-rndis kmod-usb-net-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset \
        kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb2 kmod-usb-net-ipheth usbmuxd libimobiledevice \
        kmod-usb-net-huawei-cdc-ncm kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan block-mount usb-modeswitch usbutils \
        kmod-usb-net-asix kmod-usb-net-asix-ax88179 kmod-usb-net-dm9601-ether kmod-usb-net-rtl8152 \
        \
        luci-app-amlogic iptables-mod-tproxy iptables-mod-extra libcap-bin ip6tables-mod-nat ruby ruby-yaml libnetfilter-conntrack3 \
        rrsync lighttpd-mod-access perl-http-date perlbase-getopt perlbase-time perlbase-unicode perlbase-utf8 \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}" FILES="files"

    sync && sleep 3
    echo -e "${INFO} [ openwrt/bin/targets/armvirt/64 ] directory status: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} 21.02.3 ]"
rebuild_branch="${1}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild branch: [ ${rebuild_branch} ]"
#
# Perform related operations
download_imagebuilder
custom_packages
custom_files
adjust_settings
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
