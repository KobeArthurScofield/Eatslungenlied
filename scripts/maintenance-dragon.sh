#!/usr/bin/bash

BASE_DIR="/opt/eatslungenlied/"

REBOOT_TIME="20:00"

echo "Maintenance Dragon is starting up..."

check_if_running_as_root() {
  if [[ "$EUID" -ne '0' ]]; then
    echo "error: You must run this script as root!"
    exit 1
  fi
}

os_identify() {
  if [[ "$(uname)" != 'Linux' ]]; then
    echo "error: This operating system is not supported."
    exit 1
  fi
  if [[ ! -f '/etc/os-release' ]]; then
    echo "error: Don't use outdated Linux distributions."
    exit 1
  fi
  if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
    true
  elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
    true
  else
    echo "error: Only Linux distributions using systemd are supported."
    exit 1
  fi
  if [[ "$(type -P apt)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE='apt -y full-upgrade'
    PACKAGE_MANAGEMENT_LISTUPDATE='apt list --upgradable'
    PACKAGE_MANAGEMENT_UPDATE='apt update'
    package_provide_tput='ncurses-bin'
  elif [[ "$(type -P dnf)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE=''
    PACKAGE_MANAGEMENT_LISTUPDATE=''
    PACKAGE_MANAGEMENT_UPDATE=''
    package_provide_tput='ncurses'
  elif [[ "$(type -P yum)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE=''
    PACKAGE_MANAGEMENT_LISTUPDATE=''
    PACKAGE_MANAGEMENT_UPDATE=''
    package_provide_tput='ncurses'
  elif [[ "$(type -P zypper)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE=''
    PACKAGE_MANAGEMENT_LISTUPDATE=''
    PACKAGE_MANAGEMENT_UPDATE=''
    package_provide_tput='ncurses-utils'
  elif [[ "$(type -P pacman)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE=''
    PACKAGE_MANAGEMENT_LISTUPDATE=''
    PACKAGE_MANAGEMENT_UPDATE=''
    package_provide_tput='ncurses'
  elif [[ "$(type -P emerge)" ]]; then
    PACKAGE_MANAGEMENT_UPGRADE=''
    PACKAGE_MANAGEMENT_LISTUPDATE=''
    PACKAGE_MANAGEMENT_UPDATE=''
    package_provide_tput='ncurses'
  else
    echo "error: The script does not support the package manager in this operating system."
    exit 1
  fi
}

systemd_cat_config() {
  if systemd-analyze --help | grep -qw 'cat-config'; then
    systemd-analyze --no-pager cat-config "$@"
    echo
  else
    echo "${aoi}~~~~~~~~~~~~~~~~"
    cat "$@" "$1".d/*
    echo "${aoi}~~~~~~~~~~~~~~~~"
    echo "${red}warning: ${green}The systemd version on the current operating system is too low."
    echo "${red}warning: ${green}Please consider to upgrade the systemd or the operating system.${reset}"
    echo
  fi
}

check_if_running_as_root
os_identify
systemd_cat_config

# Pre-maintanence script here
echo -e "====Preparing...===="
for SCRIPT in "${BASE_DIR}/pre-maintenance-dragon"/*
do
  case ${SCRIPT} in
    *.sh)
      ${SCRIPT}
      ;;
  esac
done

# Maintenanace

echo -e "====Checking packages updates==="
${PACKAGE_MANAGEMENT_UPDATE}
echo -e "====Update result===="
${PACKAGE_MANAGEMENT_LISTUPDATE}
echo -e "====Install updates===="
${PACKAGE_MANAGEMENT_UPGRADE}

# Pre-maintanence script here
echo -e "====More jobs...===="
for SCRIPT in "${BASE_DIR}/post-maintenance-dragon"/*
do
  case ${SCRIPT} in
    *.sh)
      ${SCRIPT}
      ;;
  esac
done

echo -e "====\nSetting machine auto restart\n===="
shutdown --reboot ${REBOOT_TIME} "Preparing reboot procedure"
echo -e "====\nCompleted\n===="
