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

check_if_running_as_root
os_identify

# Pre-maintanence script here
echo -e "====Preparing...===="
for SCRIPT in "${BASE_DIR}/pre-maintenance-dragon"/*
do
  case ${SCRIPT} in
    *.sh)
      echo "Running ${SCRIPT}..."
      ${SCRIPT}
      echo "${SCRIPT} completed with $?."
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
      echo "Running ${SCRIPT}..."
      ${SCRIPT}
      echo "${SCRIPT} completed with $?."
      ;;
  esac
done

echo -e "====\nSetting machine auto restart\n===="
shutdown --reboot ${REBOOT_TIME} "Preparing reboot procedure"
echo -e "====\nCompleted\n===="
