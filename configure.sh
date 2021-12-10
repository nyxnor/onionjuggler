#!/usr/bin/env sh

## This file should be run from inside the cloned repository
## Setup tor directories, user, packages needed for OnionJuggler.

###################
#### VARIABLES ####

## check if user configuration is readable and if yes, source it
test -r "${ONIONJUGGLER_CONF:="/etc/onionjuggler.conf"}" && . "${ONIONJUGGLER_CONF}"
## if any of the configurations are empty, use default ones

: "${privilege_command:="sudo"}"
: "${tor_user:="debian-tor"}"
: "${pkg_mngr_install:="apt install -y"}"
: "${requirements:="tor grep sed openssl basez git qrencode tar python3-stem ${dialog_box:="dialog"} ${web_server:="nginx"}"}"
: "${data_dir:="/var/lib/tor"}"
: "${data_dir_services:="${data_dir}/services"}"
: "${data_dir_auth:="${data_dir}/onion_auth"}"

## colors
nocolor="\033[0m"
#nobold="\033[21m"
#nounderline="\033[24m"
#bold="\033[1m"
#underline="\033[4m"
#white="\033[97m"
#black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"

## sanity check
error_msg(){ printf %s"\033[0;31mERROR: ${1}\033[0m\n"; exit 1; }

printf %d "${control_port:=9050}" >/dev/null 2>&1 || error_msg "control_port must be an integer, not ${control_port}"

range_variable(){
  name="${1}"
  eval var='$'"${1}"
  shift
  if [ -n "${var:-}" ]; then
    success=0
    for tests in "${@}"; do
      [ "${var}" = "${tests}" ] && success=1
    done
    [ ${success} -ne 1 ] && error_msg "${name} has an incorrect value! Check onionjuggler.conf for more details."
  fi
}

range_variable privilege_command sudo doas
range_variable web_server nginx apache2
range_variable dialog_box dialog whiptail


###################
#### FUNCTIONS ####

usage(){
  printf "Configure the environment for OnionJuggler
\nUsage: configure.sh command [option <ARG>]
\nOptions:
  -s, --setup                                 setup environment
  -h, --help                                  show this help message
\nAdvanced options:
  -s, --setup [-b <DIR>|-c <DIR>|-m <DIR>]    setup environment with specified paths
  -b, --bin-dir <DIR>                         script directory that is on path (Default: /usr/local/bin)
  -c, --conf-dir <DIR>                        configuration directory (Default: /etc)
  -m, --man-dir <DIR>                         manual directory (Default: /usr/local/man/man1)
  -r, --release                               prepare for commiting
"
}


install_package(){
  for package in "${@}"; do
    install_pkg=0
    case "${package}" in
      python-stem|python3-stem|security/py-stem|py-stem|py37-stem|stem)
        ## https://stem.torproject.org/download.html
        if ! command -v python3 >/dev/null; then
          if ! command -v python >/dev/null; then
            printf %s"${red}Python is not installed and it is needed for Vanguards, skipping...\n${nocolor}"
          else
            python_path="python"
          fi
        else
          python_path="python3"
        fi
        if [ -n "${python_path}" ]; then
          ! "${python_path}" -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader('stem') else 1)" && install_pkg=1
        fi
      ;;
      nginx|apache2) if ! command -v "${package}" >/dev/null; then ! ${privilege_command} "${package}" -v >/dev/null 2>&1 && install_pkg=1; fi;;
      eopenssl30|eopenssl11|openssl) ! command -v "${package}" >/dev/null && package="openssl" && install_pkg=1;;
      libqrencode|qrencode) ! command -v qrencode >/dev/null && install_pkg=1;;
      *) ! command -v "${package}" >/dev/null && install_pkg=1;;
    esac

    if [ "${install_pkg}" = 1 ]; then
      printf %s"${nocolor}# Installing ${package}\n"
      # shellcheck disable=SC2086
      ${privilege_command} ${pkg_mngr_install} "${package}"
    fi
  done
}


if test ! -f onionjuggler-cli || test ! -f onionjuggler-tui || test ! -f etc/onionjuggler.conf || \
test ! -f docs/onionjuggler-cli.1.md || test ! -f docs/onionjuggler.conf.1.md || \
test ! -f man/onionjuggler-cli.1 || test ! -f man/onionjuggler.conf.1; then
  printf %s"${red}ERROR: OnionJuggler files not found\n"
  printf %s"${yellow}INFO: Run this script from inside the onionjuggler repository!\n"
  printf %s"${nocolor}See usage:\n"
  usage
  exit 1
fi


get_arg(){
  case "${2}" in
    ""|-*) error_msg "Option '${1}' requires an argument.";;
  esac
}

while true; do
  case "${1}" in
    -*=*) arg="${1#*=}"; shift_n=1;;
    *) arg="${2}"; shift_n=2;;
  esac
  case "${1}" in
    -s|--setup|-r|--release) action="${1}"; shift;;
    -b|--bin-dir|-b=*|--bin-dir=*) bin_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -c|--conf-dir|-c=*|--confi-dir=*) conf_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    -m|--man-dir|-m=*|--man-dir=*) man_dir="${arg}"; get_arg "${1}" "${arg}"; shift "${shift_n}";;
    "") break;;
    *) error_msg "Invalid option: ${1}";;
  esac
done

[ ! -d "${bin_dir:="/usr/local/bin"}" ] && error_msg "Your system does not seems to support bin_dir=${bin_dir}"
[ ! -d "${conf_dir:="/etc"}" ] && error_msg "Your system does not seems to support conf_dir=${conf_dir}"
[ ! -d "${man_dir:="/usr/local/man/man1"}" ] && error_msg "Your system does not seems to support man_dir=${man_dir}"


###################
###### MAIN #######

case "${action}" in

  -s|--setup|setup)
    ## configure
    printf %s"${magenta}# Checking requirements\n${nocolor}"
    # shellcheck disable=SC2086
    install_package ${requirements}
    printf %s"${cyan}# Appending ${USER} to the ${tor_user} group\n${nocolor}"
    ## see https://github.com/nyxnor/onionjuggler/issues/15 about using complete path to binary
    ## see https://github.com/nyxnor/onionjuggler/issues/29 about usermod not appending with -a
    #"${privilege_command}" /usr/sbin/usermod -G "${tor_user}" "${USER}"
    printf %s"${yellow}# Creating tor directories\n${nocolor}"
    "${privilege_command}" mkdir -p "${data_dir_services}"
    "${privilege_command}" mkdir -p "${data_dir_auth}"
    "${privilege_command}" chown -R "${tor_user}":"${tor_user}" "${data_dir}"
    printf %s"${green}# Copying files to the system\n${nocolor}"
    "${privilege_command}" cp -v onionjuggler-cli onionjuggler-tui "${bin_dir}"
    [ ! -f "${ONIONJUGGLER_CONF}" ] && "${privilege_command}" cp -v etc/onionjuggler.conf "${conf_dir}"
    "${privilege_command}" cp -v man/onionjuggler-cli.1 man/onionjuggler.conf.1 "${man_dir}"
    cp -v .dialogrc-onionjuggler "${HOME}/.dialogrc-onionjuggler"
    ## finish
    printf %s"${blue}# OnionJuggler enviroment is ready\n${nocolor}"
  ;;

  -r|--release|release)
    printf %s"${blue}# Preparing release\n${nocolor}"
    ## ShellCheck is needed
    ## install https://github.com/koalaman/shellcheck#installing
    ## compile from source https://github.com/koalaman/shellcheck#compiling-from-source
    install_package shellcheck pandoc git
    printf %s"${magenta}# Creating manual pages\n${nocolor}"
    pandoc -s -f markdown-smart -t man docs/onionjuggler-cli.1.md -o man/onionjuggler-cli.1
    pandoc -s -f markdown-smart -t man docs/onionjuggler.conf.1.md -o man/onionjuggler.conf.1
    printf %s"${yellow}# Checking shell syntax\n${nocolor}"
    ## Customize severity with -S [error|warning|info|style]
    if ! shellcheck configure.sh etc/onionjuggler.conf onionjuggler-cli onionjuggler-tui; then
      printf %s"${red}# Please fix the shellcheck warnings above before pushing!\n${nocolor}"
      exit 1
    fi
    ## cleanup
    printf %s"${cyan}# Checking git status\n${nocolor}"
    find . -type f -exec sed -i'' "s/set \-\x//g;s/set \-\v//g;s/set \+\x//g;s/set \+\v//g" {} \; ## should not delete, could destroy lines, just leave empty lines
    if [ -n "$(git status -s)" ]; then
      git status
      printf %s"${red}# Please record the changes to the file(s) above with a commit before pushing!\n${nocolor}"
      exit 1
    fi
    printf %s"${green}# Done!\n${nocolor}"
  ;;

  *) usage;;

esac
