#!/usr/bin/env sh

## DESCRIPTION
## This file should be run from inside the cloned repository
## Setup tor directories, user, packages needed for OnionJuggler.
##
## SYNTAX
## ./setup.sh [-s|-r]

###################
#### VARIABLES ####

## check if user configuration is readable and if yes, source it
[ -r "${ONIONJUGGLER_CONF:="/etc/onionjuggler.conf"}" ] && . "${ONIONJUGGLER_CONF}"
## if any of the configurations are empty, use default ones

: "${privilege_command:="sudo"}"
: "${tor_user:="debian-tor"}"
: "${pkg_mngr_install:="apt install -y"}"
: "${dialog_box:="dialog"}"
: "${web_server:=""}"
: "${requirements:="tor grep sed openssl basez git qrencode tar python3-stem ${dialog_box} ${web_server}"}"
: "${data_dir:="/var/lib/tor"}"
: "${data_dir_services:="${data_dir}/services"}"
: "${data_dir_auth:="${data_dir}/onion_auth"}"

## colors
: "${bold:=0}"
nocolor="\033[0m"
#white="\033[${bold};97m"
#black="\033[${bold};30m"
red="\033[${bold};31m"
green="\033[${bold};32m"
yellow="\033[${bold};33m"
blue="\033[${bold};34m"
magenta="\033[${bold};35m"
cyan="\033[${bold};36m"

## sanity check
{ [ "${privilege_command}" != "sudo" ] && [ "${privilege_command}" != "doas" ]; } && error_msg "privilege_command can be either 'sudo' or 'doas', not '${privilege_command}'"
{ [ "${dialog_box}" != "dialog" ] && [ "${dialog_box}" != "whiptail" ]; } && error_msg "dialog_box can be either 'dialog' or 'whiptail', not '${dialog_box}'"
printf %d "${control_port:=9050}" >/dev/null 2>&1 || error_msg "control_port must be an integer, not ${control_port}"

###################
#### FUNCTIONS ####

usage(){
  printf "Configure the environment for OnionJuggler
\nUsage: %s${0##*/} command [required] <optional>
\nOptions:
  -s, --setup       setup environment
  -r, --release     prepare for commiting
  -h, --help        show this help message
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
            py_command="python"
          fi
        else
          py_command="python3"
        fi
        if [ -n "${py_command}" ]; then
          if ! "${py_command}" -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader('stem') else 1)"; then
            install_pkg=1
          fi
        fi
      ;;
      libqrencode|qrencode) ! command -v qrencode >/dev/null && install_pkg=1;;
      nginx|apache2)
        if ! command -v "${package}" >/dev/null; then
          ! ${privilege_command} "${package}" -v >/dev/null 2>&1 && install_pkg=1
        fi
      ;;
      *) ! command -v qrencode >/dev/null && install_pkg=1;;
    esac

    if [ "${install_pkg}" = 1 ]; then
      printf %s"${nocolor}# Installing ${package}\n"
      # shellcheck disable=SC2086
      ${privilege_command} ${pkg_mngr_install} "${package}"
    fi
  done
}


if [ ! -f onionjuggler-cli ] || [ ! -f onionjuggler-tui ] || [ ! -f etc/onionjuggler.conf ] || [ ! -f docs/onionjuggler-cli.1.md ] || [ ! -f docs/onionjuggler.conf.1.md ]; then
  printf %s"${red}ERROR: OnionJuggler files not found\n"
  printf %s"${yellow}INFO: Run this script from inside the onionjuggler repository!\n"
  printf %s"${nocolor}See usage:\n"
  usage
  exit 1
fi


###################
###### MAIN #######

action=${1:--s}

case "${action}" in

  -s|--setup|setup)
    ## configure
    printf %s"${nocolor}# Checking requirements\n"
    ## python3-stem and nginx will be checked again because python3-stem is a library (not a command) and nginx is only acessible by root
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
    printf %s"${green}# Copying files default path\n${nocolor}"
    "${privilege_command}" mkdir -p /usr/local/bin ## just in case
    "${privilege_command}" cp -v onionjuggler-cli onionjuggler-tui /usr/local/bin/
    [ ! -f "${ONIONJUGGLER_CONF}" ] && "${privilege_command}" cp -v etc/onionjuggler.conf /etc/onionjuggler.conf
    cp -v .dialogrc-onionjuggler "${HOME}/.dialogrc-onionjuggler"
    printf %s"${magenta}# Creating man pages\n${nocolor}"
    "${privilege_command}" mkdir -p /usr/local/man/man1
    "${privilege_command}" mv man/onionjuggler-cli.1 man/onionjuggler.conf.1 /usr/local/man/man1/
    #"${privilege_command}" mandb -q -f /usr/local/man/man1/onionjuggler-cli.1 /usr/local/man/man1/onionjuggler.conf.1
    ## finish
    printf %s"${blue}# OnionJuggler enviroment is ready\n${nocolor}"
  ;;

  -r|--release|release)
    ## ShellCheck is needed
    ## install https://github.com/koalaman/shellcheck#installing
    ## compile from source https://github.com/koalaman/shellcheck#compiling-from-source
    install_package shellcheck pandoc
    printf %s"${magenta}# Creating Manual pages\n"
    pandoc -s -f markdown-smart -t man docs/onionjuggler-cli.1.md -o man/onionjuggler-cli.1
    pandoc -s -f markdown-smart -t man docs/onionjuggler.conf.1.md -o man/onionjuggler.conf.1
    printf %s"${blue}# Preparing Release\n"
    printf "# Checking syntax\n" ## quits to warn workflow test failed
    ## Customize severity with -S [error|warning|info|style]
    shellcheck setup.sh etc/onionjuggler.conf onionjuggler-cli onionjuggler-tui || exit 1
    ## cleanup
    find . -type f -exec sed -i'' "s/set \-\x//g" {} \; ## should not delete, could destroy lines, just leave empty lines
    printf %s"${green}# Done!\n${nocolor}"
  ;;

  *) usage;;

esac
