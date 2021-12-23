#!/usr/bin/env sh


## This file should be run from inside the cloned repository
## Setup tor directories, user, packages needed for OnionJuggler.

repo="https://github.com/nyxnor/onionjuggler.git"

## colors
nocolor="\033[0m"
#bold="\033[1m"
#underline="\033[4m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"

error_msg(){ printf %s"${red}ERROR: ${1}${nocolor}\n"; exit 1; }

if [ ! -f onionjuggler-cli ]||[ ! -f onionjuggler-tui ]||[ ! -f etc/onionjuggler/sample.conf ]||[ ! -f docs/onionjuggler-cli.1.md ] \
  ||[ ! -f docs/onionjuggler.conf.5.md ]||[ ! -f man/man1/onionjuggler-cli.1 ]||[ ! -f man/man5/onionjuggler.conf.5 ]; then
  error_msg "This script must be run from inside the onionjuggler repository!"
fi

usage(){
  printf "Configure the environment for OnionJuggler
\nUsage: configure.sh command [option <ARG>]
\nOptions:
  -i, --install                               setup environment copying files to path
  -d, --uninstall [-P, --purge]               remove onionjuggler scripts and manual pages from path
  -h, --help                                  show this help message
\nAdvanced options:
  -i, --install [-b <DIR>|-c <DIR>|-m <DIR>]  setup environment with specified paths
  -C, --config <ONIONJUGGLER_CONF>            specify alternative onionjuggler configuration file to be read
  -B, --bin-dir <DIR>                         script directory that is on path (Default: /usr/local/bin)
  -F, --conf-dir <DIR>                        configuration directory (Default: /etc)
  -M, --man-dir <DIR>                         manual directory (Default: /usr/local/man/man1)
  -k, --check                                 run pre-defined shellcheck
  -m, --man                                   build manual pages
  -r, --release                               prepare for commiting
  -u, --update                                development updating by pulling from upstream
"
  exit 1
}

get_arg(){
  case "${2}" in
    ""|-*) error_msg "Option '${1}' requires an argument.";;
  esac
}

while :; do
  case "${1}" in
    -*=*) arg="${1#*=}"; shift_n=1;;
    *) arg="${2}"; shift_n=2;;
  esac
  case "${1}" in
    -i|--install|-u|--update|-d|--uninstall|-r|--release|-k|--check|-m|--man) command="${1}"; shift;;
    -P|--purge) action="${1}"; shift;;
    -C|--config|-C=*|--confg=*) ONIONJUGGLER_CONF="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -B|--bin-dir|-b=*|--bin-dir=*) bin_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -F|--conf-dir|-c=*|--confi-dir=*) conf_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -M|--man-dir|-m=*|--man-dir=*) man_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -h|--help) usage;;
    "") break;;
    *) error_msg "Invalid option: ${1}";;
  esac
done

[ -d "${bin_dir:="/usr/local/bin"}" ] || error_msg "Your system does not seems to support bin_dir=${bin_dir}"
[ -d "${conf_dir:="/etc"}" ] || error_msg "Your system does not seems to support conf_dir=${conf_dir}"
[ -d "${man_dir:="/usr/local/man"}" ] || error_msg "Your system does not seems to support man_dir=${man_dir}"

bin_dir="${bin_dir%*/}"
conf_dir="${conf_dir%*/}/onionjuggler"
man_dir="${man_dir%*/}"

###################
#### FUNCTIONS ####

install_package(){
  for package in "${@}"; do
    install_pkg=0
    case "${package}" in
      python-stem|python3-stem|security/py-stem|py-stem|py3-stem|py37-stem|stem)
        ## https://stem.torproject.org/download.html
        while :; do
          command -v python3 >/dev/null && python_path="$(command -v python3)" && break
          command -v python >/dev/null && python_path="$(command -v python)" && break
          printf %s"${red}Python is not installed and it is needed for Vanguards, skipping...\n${nocolor}" && break
        done
        [ -n "${python_path}" ] && ! "${python_path}" -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader('stem') else 1)" && install_pkg=1
      ;;
      openssl)
        if [ "${openssl_cmd}" != "openssl" ]; then
          ! command -v "${openssl_cmd}" >/dev/null && package="openssl" && install_pkg=1
        else
          ! command -v openssl >/dev/null && package="openssl" && install_pkg=1
        fi
      ;;
      nginx|apache2) if ! command -v "${package}" >/dev/null; then ! ${su_cmd} "${package}" -v >/dev/null 2>&1 && install_pkg=1; fi;;
      openbsd-httpd) :;;
      libqrencode|qrencode) ! command -v qrencode >/dev/null && install_pkg=1;;
      *) ! command -v "${package}" >/dev/null && install_pkg=1;;
    esac

    if [ "${install_pkg}" = 1 ]; then
      printf %s"${nocolor}# Installing ${package}\n"
      # shellcheck disable=SC2086
      "${su_cmd}" ${pkg_mngr_install} "${package}"
    fi
  done
}


make_shellcheck(){
  printf %s"${yellow}# Checking shell syntax"
  ## Customize severity with -S [error|warning|info|style]
  if ! shellcheck configure.sh etc/onionjuggler/*.conf onionjuggler-cli onionjuggler-tui; then
    error_msg "Please fix the shellcheck warnings above before pushing!"
  else
    printf " - 100%%\n${nocolor}"
  fi
}

make_man(){
  printf %s"${magenta}# Creating manual pages"
  pandoc -s -f markdown-smart -t man docs/onionjuggler-cli.1.md -o man/man1/onionjuggler-cli.1
  pandoc -s -f markdown-smart -t man docs/onionjuggler-tui.1.md -o man/man1/onionjuggler-tui.1
  pandoc -s -f markdown-smart -t man docs/onionjuggler.conf.5.md -o man/man5/onionjuggler.conf.5
  printf %s" - Made!\n${nocolor}"
}

get_os(){
  ## Source: pfetch -> https://github.com/dylanaraps/pfetch/blob/master/pfetch
  os="$(uname -s)"
  kernel="$(uname -r)"

  case ${os} in
    Linux*)
      if command -v lsb_release >/dev/null; then
        distro=$(lsb_release -sd)
      elif [ -f /etc/os-release ]; then
        while IFS='=' read -r key val; do
          case $key in (PRETTY_NAME) distro=${val};; esac
        done < /etc/os-release
      else
        command -v crux >/dev/null && distro=$(crux)
        command -v guix >/dev/null && distro='Guix System'
      fi
      distro=${distro##[\"\']}
      distro=${distro%%[\"\']}
      case ${PATH} in (*/bedrock/cross/*) distro='Bedrock Linux' ;; esac
      if [ "${WSLENV}" ]; then
        distro="${distro}${WSLENV+ on Windows 10 [WSL2]}"
      elif [ -z "${kernel%%*-Microsoft}" ]; then
        distro="${distro} on Windows 10 [WSL1]"
      fi
    ;;
    Haiku) distro=$(uname -sv);;
    Minix|DragonFly) distro="${os} ${kernel}";;
    SunOS) IFS='(' read -r distro _ < /etc/release;;
    OpenBSD*) distro="$(uname -sr)";;
    FreeBSD) distro="${os} $(freebsd-version)";;
    *) distro="${os} ${kernel}";;
  esac
}

###################
#### VARIABLES ####

## 1. source default configuration file first
## 2. source local (user made) configuration files to override the default values
## 3. source the ONIONJUGGLER_CONF specified by the cli argument and if it empty, use the environment variable
if [ ! -f /etc/onionjuggler/onionjuggler.conf ]; then
  get_os
  case "${os}" in
    Linux*)
      case "${distro}" in
        "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Tails"*|"Linux Mint"*|"LinuxMint"*|"mint"*) . etc/onionjuggler/debian.conf;;
        "Arch"*|"Artix"*|"ArcoLinux"*) . etc/onionjuggler/arch.conf;;
        "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat") . etc/onionjuggler/fedora.conf;;
      esac
    ;;
    "OpenBSD"*) . etc/onionjuggler/openbsd.conf;;
    "NetBSD"*) . etc/onionjuggler/netbsd.conf;;
    "FreeBSD"*|"HardenedBSD"*|"DragonFly"*) . etc/onionjuggler/freebsd.conf;;
  esac
else
  [ -r /etc/onionjuggler/onionjuggler.conf ] && . /etc/onionjuggler/onionjuggler.conf
fi
for file in /etc/onionjuggler/conf.d/*.conf; do [ -f "${file}" ] && . "${file}"; done
[ -r "${ONIONJUGGLER_CONF}" ] && . "${ONIONJUGGLER_CONF}"

## if any of the configurations are empty, use default ones
: "${su_cmd:="sudo"}"
: "${tor_user:="debian-tor"}"
: "${pkg_mngr_install:="apt install -y"}"
: "${dialog_box:="dialog"}"
: "${webserver:="nginx"}"
: "${requirements:="tor grep sed tar openssl basez git python3-stem qrencode ${dialog_box} ${webserver}"}"
: "${tor_data_dir:="/var/lib/tor"}"; tor_data_dir="${tor_data_dir%*/}"
: "${tor_data_dir_services:="${tor_data_dir}/services"}"; tor_data_dir_services="${tor_data_dir_services%*/}"
: "${tor_data_dir_auth:="${tor_data_dir}/onion_auth"}"; tor_data_dir_auth="${tor_data_dir_auth%*/}"
: "${openssl_cmd:="openssl"}"

## sanity check
printf %d "${tor_control_port:=9050}" >/dev/null 2>&1 || error_msg "tor_control_port must be an integer, not ${tor_control_port}"

range_variable(){
  name="${1}"
  eval var='$'"${1}"
  shift
  if [ -n "${var:-}" ]; then
    success=0
    for tests in "${@}"; do
      [ "${var}" = "${tests}" ] && success=1
    done
    [ ${success} -ne 1 ] && error_msg "${name} has an incorrect value of : ${var}! Check onionjuggler.conf for more details."
  fi
}

range_variable su_cmd sudo doas
range_variable webserver nginx apache2 openbsd-httpd
range_variable dialog_box dialog whiptail

###################
###### MAIN #######


case "${command}" in

  -u|--update)
    printf %s"${magenta}# Pulling, hold back\n${nocolor}"
    git pull "${repo}"
  ;;

  -i|--install)
    printf %s"${magenta}# Checking requirements\n${nocolor}"
    # shellcheck disable=SC2086
    install_package ${requirements}
    ## see https://github.com/nyxnor/onionjuggler/issues/15 about using complete path to binary
    ## see https://github.com/nyxnor/onionjuggler/issues/29 about usermod not appending with -a
    #printf %s"${cyan}# Appending ${USER} to the ${tor_user} group\n${nocolor}"
    #"${su_cmd}" /usr/sbin/usermod -G "${tor_user}" "${USER}"
    printf %s"${yellow}# Creating tor directories\n${nocolor}"
    [ ! -d "${tor_data_dir_services}" ] && "${su_cmd}" mkdir -p "${tor_data_dir_services}"
    [ ! -d "${tor_data_dir_auth}" ] && "${su_cmd}" mkdir -p "${tor_data_dir_auth}"
    "${su_cmd}" chown -R "${tor_user}":"${tor_user}" "${tor_data_dir}"
    printf %s"${green}# Copying files to path\n${nocolor}"
    [ ! -d "${man_dir}/man1" ] && "${su_cmd}" mkdir -p "${man_dir}/man1"
    [ ! -d "${man_dir}/man1" ] && "${su_cmd}" mkdir -p "${man_dir}/man5"
    "${su_cmd}" cp man/man1/onionjuggler-cli.1 man/man1/onionjuggler-tui.1 "${man_dir}/man1"
    "${su_cmd}" cp man/man5/onionjuggler.conf.5 "${man_dir}/man5"
    "${su_cmd}" cp onionjuggler-cli onionjuggler-tui "${bin_dir}"
    [ ! -d "${conf_dir}/onionjuggler" ] && "${su_cmd}" mkdir -p "${conf_dir}/conf.d"
    "${su_cmd}" cp etc/onionjuggler/dialogrc "${conf_dir}"
    get_os
    ## Source of distro names: neofetch -> https://github.com/dylanaraps/neofetch/blob/master/neofetch
    case "${os}" in
      Linux*)
        case "${distro}" in
          "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Tails"*|"Linux Mint"*|"LinuxMint"*|"mint"*) "${su_cmd}" cp etc/onionjuggler/debian.conf "${conf_dir}/onionjuggler.conf";;
          "Arch"*|"Artix"*|"ArcoLinux"*) "${su_cmd}" cp etc/onionjuggler/arch.conf "${conf_dir}/onionjuggler.conf";;
          "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat") "${su_cmd}" cp etc/onionjuggler/fedora.conf "${conf_dir}/onionjuggler.conf";;
        esac
      ;;
      "OpenBSD"*) "${su_cmd}" cp etc/onionjuggler/openbsd.conf "${conf_dir}/onionjuggler.conf";;
      "NetBSD"*) "${su_cmd}" cp etc/onionjuggler/netbsd.conf "${conf_dir}/onionjuggler.conf";;
      "FreeBSD"*|"HardenedBSD"*|"DragonFly"*) "${su_cmd}" cp etc/onionjuggler/freebsd.conf "${conf_dir}/onionjuggler.conf";;
    esac
    printf %s"${blue}# OnionJuggler enviroment is ready\n${nocolor}"
  ;;

  -d|--uninstall)
    printf %s"${red}# Removing OnionJuggler scripts from your system.${nocolor}\n"
    "${su_cmd}" rm -f "${man_dir}/man1/onionjuggler-cli.1" "${man_dir}/man1/onionjuggler-tui.1"
    "${su_cmd}" rm -f "${man_dir}/man5/onionjuggler.conf.5"
    "${su_cmd}" rm -f "${bin_dir}/onionjuggler-cli" "${bin_dir}/onionjuggler-tui"
    printf %s"${green}# Done!${nocolor}"
    if [ "${action}" = "-P" ] || [ "${action}" = "--purge" ]; then
      printf %s"${red}# Purging OnionJuggler configuration from your system.${nocolor}\n"
      "${su_cmd}" rm -f "${conf_dir}/onionjuggler"
    fi
  ;;

  -r|--release)
    printf %s"${blue}# Preparing release\n${nocolor}"
    install_package shellcheck pandoc git
    make_man
    make_shellcheck
    printf %s"${cyan}# Checking git status"
    find . -type f -exec sed -i'' "s/set \-\x//g;s/set \-\v//g;s/set \+\x//g;s/set \+\v//g" {} \; ## should not delete, could destroy lines, just leave empty lines
    if [ -n "$(git status -s)" ]; then
      printf %s" - Uncommited changes!\n${nocolor}"
      git status
      error_msg "Please record the changes to the file(s) above with a commit before pushing!"
    else
      printf " - Working tree clean\n"
    fi
    printf %s"${green}# Done!\n${nocolor}"
  ;;

  -k|--check) make_shellcheck;;

  -m|--man) make_man;;

  *) usage;;

esac
