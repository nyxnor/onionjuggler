#!/usr/bin/env sh


## This file should be run from inside the cloned repository
## Setup tor directories, user, packages needed for OnionJuggler.

onionjuggler_repo="${ONIONJUGGLER_GIT_ORIGIN:-"https://github.com/nyxnor/onionjuggler.git"}"

topdir="$(git rev-parse --show-toplevel)"
me="${0##*/}"

onionjuggler_defaults="/usr/share/onionjuggler/defaults.sh"
[ -e "${onionjuggler_defaults}" ] || { printf '%s\n' "${onionjuggler_defaults} does not exist"; exit 1; }
[ -f "${onionjuggler_defaults}" ] || { printf '%s\n' "${onionjuggler_defaults} is not a regular file"; exit 1; }
[ -r "${onionjuggler_defaults}" ] || { printf '%s\n' "${onionjuggler_defaults} can not be read"; exit 1; }
. "${onionjuggler_defaults}"

usage(){
  printf %s"Configure the environment for OnionJuggler
\nUsage: ${me} [--option <ARG>]
\nOptions:
  -i, --install                               setup environment copying files to path
  -d, --uninstall [-P, --purge]               remove onionjuggler scripts and manual pages from path
  -h, --help                                  show this help message
\nAdvanced options:
  -B, --bin-dir <DIR>                         script directory that is on path (Default: /usr/local/bin)
  -F, --conf-dir <DIR>                        configuration directory (Default: /etc)
  -M, --man-dir <DIR>                         manual directory (Default: /usr/local/man/man1)
  -i, --install [-b <DIR>|-c <DIR>|-m <DIR>]  setup environment with specified paths
  -G, --plugin <PLUGIN>                       if plugin is specified, only install selected plugins (e.g: vanguards,web)
  -k, --check                                 run pre-defined shellcheck
  -m, --man                                   build manual pages
  -r, --release                               prepare for commiting
  -u, --update                                development updating by pulling from upstream
"
  exit 1
}
[ -z "${1}" ] && usage


check_repo(){
  if [ ! -f "${topdir}"/usr/bin/onionjuggler-cli ] || [ ! -f "${topdir}"/usr/bin/onionjuggler-tui ]; then
    error_msg "This script must be run from inside the onionjuggler repository!"
  fi
}


while :; do
  shift_n=""
  # shellcheck disable=SC2034  
  opt_orig="${1}" ## save opt orig for error message to understand which opt failed
  # shellcheck disable=SC2034
  arg_possible="${2}" ## need to pass the second positional parameter because maybe it is an argument
  clean_opt "${1}" || break
  # shellcheck disable=SC2034  
  case "${opt}" in
    c|clone|i|install|u|update|d|uninstall|r|release|k|check|m|man) command="${opt}";;
    G|plugin|G=*|plugin=*) get_arg plugin;;
    P|purge) action="${opt}";;
    B|bin-dir|B=*|bin-dir=*) get_arg bin_dir;;
    F|conf-dir|F=*|confi-dir=*) get_arg conf_dir;;
    M|man-dir|M=*|man-dir=*) get_arg man_dir;;
    h|help) usage;;
    "") break;;
    *) error_msg "Invalid option: '${opt}'";;
  esac
  shift "${shift_n:-1}"
  [ -z "${1}" ] && break
done


###################
#### FUNCTIONS ####

requires_root(){ [ "$(id -u)" -ne 0 ] && error_msg "run as root"; }

not_as_root(){ [ "$(id -u)" -eq 0 ] && error_msg "do not run this option as root"; }

check_dir(){
  [ -d "${bin_dir:="/usr/local/bin"}" ] || error_msg "Your system does not seems to support bin_dir=${bin_dir}"
  [ -d "${conf_dir:="/etc"}" ] || error_msg "Your system does not seems to support conf_dir=${conf_dir}"
  [ -d "${man_dir:="/usr/local/man"}" ] || error_msg "Your system does not seems to support man_dir=${man_dir}"

  bin_dir="${bin_dir%*/}"
  conf_dir="${conf_dir%*/}/onionjuggler"
  man_dir="${man_dir%*/}"
}


install_package(){
  install_pkg=""
  for package in "${@}"; do
    case "${package}" in
      python-stem|python3-stem|security/py-stem|py-stem|py3-stem|py37-stem|stem)
        ## https://stem.torproject.org/download.html
        while :; do
          command -v python3 >/dev/null && python_path="$(command -v python3)" && break
          command -v python >/dev/null && python_path="$(command -v python)" && break
          notice "${red}Python is not installed and is required for Vanguards, skipping...\n${nocolor}" && break
        done
        [ -n "${python_path}" ] && ! "${python_path}" -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader('stem') else 1)" && install_pkg="${install_pkg} ${package}"
      ;;
      openssl) ! command -v "${openssl_cmd}" >/dev/null && package="${openssl_cmd}" && install_pkg="${install_pkg} ${package}";;
      nginx|apache2) if ! command -v "${package}" >/dev/null; then ! "${package}" -v >/dev/null 2>&1 && install_pkg="${install_pkg} ${package}"; fi;;
      openbsd-httpd) :;;
      libqrencode|qrencode) ! command -v qrencode >/dev/null && install_pkg="${install_pkg} ${package}";;
      *) ! command -v "${package}" >/dev/null && install_pkg="${install_pkg} ${package}";;
    esac
  done
  
  if [ -n "${install_pkg}" ]; then
    notice "${nocolor}Installing package(s): ${install_pkg}"
    # shellcheck disable=SC2086
    ${pkg_mngr_install} ${install_pkg}
  fi
}


make_shellcheck(){
  command -v shellcheck >/dev/null || error_msg "Install shellcheck to review syntax"
  notice "${yellow}Checking shell syntax${nocolor}"
  ## Customize severity with -S [error|warning|info|style]
  if ! shellcheck "${topdir}"/configure.sh "${topdir}"/etc/onionjuggler/*.conf \
  "${topdir}"/etc/onionjuggler/conf.d/*.conf "${topdir}"/usr/bin/* \
  "${topdir}"/usr/share/onionjuggler/*; then
    error_msg "Please fix the shellcheck warnings above before pushing!"
  fi
}


make_man(){
  command -v pandoc >/dev/null || error_msg "Install pandoc to create manuals"
  notice "${magenta}Creating manual pages${nocolor}"
  for man in "${topdir}"/man/*; do
    man="${man##*/}" 
    pandoc -s -f markdown-smart -t man "${topdir}/man/${man}" -o "${topdir}/auto-generated-man-pages/${man%*.md}"
  done
}


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

get_os(){
  ## Source: pfetch -> https://github.com/dylanaraps/pfetch/blob/master/pfetch
  os="$(uname -s)"
  kernel="$(uname -r)"

  case ${os} in
    Linux*)
      if test -f /usr/share/anon-gw-base-files/gateway; then
        distro="Whonix-Gateway"
      elif test -f /usr/share/anon-ws-base-files/workstation; then
        distro="Whonix-Workstation"
      elif command -v lsb_release >/dev/null; then
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
get_vars(){
  if [ ! -f /etc/onionjuggler/onionjuggler.conf ]; then
    get_os
    case "${os}" in
      Linux*)
        case "${distro}" in
          "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Linux Mint"*|"LinuxMint"*|"mint"*) . "${topdir}"/etc/onionjuggler/debian.conf;;
          "Tails"*) . "${topdir}"/etc/onionjuggler/tails.conf;;
          "Whonix-Gateway") . "${topdir}"/etc/onionjuggler/whonix-gateway.conf;;
          "Whonix-Workstation") . "${topdir}"/etc/onionjuggler/whonix-workstation.conf;;
          "Arch"*|"Artix"*|"ArcoLinux"*) . "${topdir}"/etc/onionjuggler/arch.conf;;
          "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat") . "${topdir}"/etc/onionjuggler/fedora.conf;;
        esac
      ;;
      "OpenBSD"*) . etc/onionjuggler/openbsd.conf;;
      "NetBSD"*) . etc/onionjuggler/netbsd.conf;;
      "FreeBSD"*|"HardenedBSD"*|"DragonFly"*) . "${topdir}"/etc/onionjuggler/freebsd.conf;;
      *) error_msg "Unsupported system: ${os} ${kernel} ${distro}"
    esac
  else
    [ -r /etc/onionjuggler/onionjuggler.conf ] && . /etc/onionjuggler/onionjuggler.conf
  fi
  for file in /etc/onionjuggler/conf.d/*.conf; do [ -f "${file}" ] && . "${file}"; done

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
  printf %d "${tor_control_port:=9051}" >/dev/null 2>&1 || error_msg "tor_control_port must be an integer, not ${tor_control_port}"

  range_variable su_cmd sudo doas
  range_variable webserver nginx apache2 openbsd-httpd
  range_variable dialog_box dialog whiptail
}


###################
###### MAIN #######

case "${command}" in

  c|clone)
    if ! check_repo; then
      git clone "${onionjuggler_repo}"
      onionjuggler_dir="${onionjuggler_repo%*.git}"
      onionjuggler_dir="${onionjuggler_repo##*/}"
      if [ -d "${onionjuggler_dir}" ]; then
        cd "${onionjuggler_dir}" || error_msg "Couldn't change to directory ${onionjuggler_dir}"
      fi
    else
      error_msg "Can't clone when already in the repository."
    fi
  ;;

  u|update)
    check_repo
    not_as_root
    notice "${magenta}Pulling, hold back${nocolor}"
    git pull "${onionjuggler_repo}"
  ;;

  i|install)
    check_repo
    check_dir
    get_os
    get_vars
    requires_root
    notice "${magenta}Checking requirements${nocolor}"
    # shellcheck disable=SC2086
    install_package ${requirements}
    ## see https://github.com/nyxnor/onionjuggler/issues/15 about using complete path to binary
    ## see https://github.com/nyxnor/onionjuggler/issues/29 about usermod not appending with -a
    #notice "${cyan}Appending ${USER} to the ${tor_user} group${nocolor}"
    #/usr/sbin/usermod -G "${tor_user}" "${USER}"
    notice "${yellow}Creating tor directories${nocolor}"
    [ ! -d "${tor_data_dir_services}" ] && mkdir -p "${tor_data_dir_services}"
    [ ! -d "${tor_data_dir_auth}" ] && mkdir -p "${tor_data_dir_auth}"
    chown -R "${tor_user}":"${tor_user}" "${tor_data_dir}"
    notice "${green}Copying files to path${nocolor}"
    [ ! -d "${man_dir}/man1" ] && mkdir -p "${man_dir}/man1"
    [ ! -d "${man_dir}/man1" ] && mkdir -p "${man_dir}/man5"
    for man in "${topdir}"/auto-generated-man-pages/*; do
      man_extension="${man##*.}"
      cp "${man}" "${man_dir}/man${man_extension}"
    done
    if [ -n "${plugin}" ] || [ -n "${onionjuggler_plugin}" ]; then
      ## overwrite default plugins with the ones specified on the cli, else use conf
      { [ -n "${onionjuggler_plugin}" ] && [ -z "${plugin}" ]; } && plugin="${onionjuggler_plugin}"
      cp "${topdir}"/usr/bin/onionjuggler-tui "${topdir}"/usr/bin/onionjuggler-cli "${bin_dir}"
      for pg in $(printf '%s\n' "${plugin}" | tr "," " "); do
        pg="${pg##*onionjuggler-cli-}"
        if test -f "${topdir}/usr/bin/onionjuggler-cli-${pg}"; then
          cp "${topdir}/usr/bin/onionjuggler-cli-${pg}" "${bin_dir}"
        else
          error_msg "Plugin '${pg}' does not exist and is not going to be installed"
        fi
      done
    else
      cp "${topdir}"/usr/bin/* "${bin_dir}"
    fi
    
    [ ! -d "${conf_dir}/onionjuggler" ] && mkdir -p "${conf_dir}/conf.d"
    cp "${topdir}"/etc/onionjuggler/dialogrc "${conf_dir}"
    ## Source of distro names: neofetch -> https://github.com/dylanaraps/neofetch
    case "${os}" in
      Linux*)
        case "${distro}" in
          "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Linux Mint"*|"LinuxMint"*|"mint"*) cp "${topdir}"/etc/onionjuggler/debian.conf "${conf_dir}/onionjuggler.conf";;
          "Tails"*) cp "${topdir}"/etc/onionjuggler/tails.conf "${conf_dir}/oionjuggler.conf";;
          "Whonix-Gateway") cp "${topdir}"/etc/onionjuggler/whonix-gateway.conf "${conf_dir}/onionjuggler.conf";;
          "Whonix-Workstation") cp "${topdir}"/etc/onionjuggler/whonix-workstation.conf "${conf_dir}/onionjuggler.conf";;
          "Arch"*|"Artix"*|"ArcoLinux"*) cp "${topdir}"/etc/onionjuggler/arch.conf "${conf_dir}/onionjuggler.conf";;
          "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat") cp "${topdir}"/etc/onionjuggler/fedora.conf "${conf_dir}/onionjuggler.conf";;
        esac
      ;;
      "OpenBSD"*) cp "${topdir}"/etc/onionjuggler/openbsd.conf "${conf_dir}/onionjuggler.conf";;
      "NetBSD"*) cp "${topdir}"/etc/onionjuggler/netbsd.conf "${conf_dir}/onionjuggler.conf";;
      "FreeBSD"*|"HardenedBSD"*|"DragonFly"*) cp "${topdir}"/etc/onionjuggler/freebsd.conf "${conf_dir}/onionjuggler.conf";;
    esac
    notice %s"${blue}OnionJuggler enviroment is ready${nocolor}"
  ;;

  d|uninstall)
    check_dir
    requires_root
    notice "${red}Removing OnionJuggler scripts from your system.${nocolor}"
    rm -f "${man_dir}/man1/onionjuggler-cli.1" "${man_dir}/man1/onionjuggler-tui.1" "${man_dir}/man5/onionjuggler.conf.5"
    rm -f "${bin_dir}/onionjuggler-cli" "${bin_dir}/onionjuggler-tui"
    if [ "${action}" = "-P" ] || [ "${action}" = "--purge" ]; then
      notice "${red}Purging OnionJuggler configuration from your system.${nocolor}"
      rm -f "${conf_dir}/onionjuggler"
    fi
    notice "${green}Done!${nocolor}"
  ;;

  r|release)
    check_repo
    not_as_root
    notice "${blue}Preparing release${nocolor}"
    install_package shellcheck pandoc git
    make_man
    make_shellcheck
    notice "${cyan}Checking git status${nocolor}"
    find "${topdir}" -type f -exec sed -i'' "s/set \-\x//g;s/set \-\v//g;s/set \+\x//g;s/set \+\v//g" {} \; ## should not delete, could destroy lines, just leave empty lines
    if [ -n "$(git status -s)" ]; then
      git status
      error_msg "Please record the changes to the file(s) above with a commit before pushing!"
    fi
    notice "${green}Done!${nocolor}"
  ;;

  k|check) check_repo; make_shellcheck;;

  m|man) check_repo; not_as_root; make_man;;

  *) usage;;

esac
