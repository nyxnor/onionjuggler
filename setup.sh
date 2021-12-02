#!/usr/bin/env sh

## DESCRIPTION
## This file should be run from inside the cloned repository
## It setup tor directories, user, packages need for OnionJuggler.
##
## SYNTAX
## ./setup.sh [--setup|--release]
##
## Lines that begin with "## " try to explain what's going on. Lines
## that begin with just "#" are disabled commands.

###################
#### VARIABLES ####

## check if user configuration is readable and if yes, source it
[ -r "${ONIONJUGGLER_CONF:="/etc/onionjuggler.conf"}" ] && . "${ONIONJUGGLER_CONF}"
## if any of the configurations are empty, use default ones

## system
: "${privilege_command:="sudo"}"
: "${tor_user:="debian-tor"}"
: "${data_dir:="/var/lib/tor"}"
: "${data_dir_services:="${data_dir}/services"}"
: "${data_dir_auth:="${data_dir}/onion_auth"}"
: "${pkg_mngr_install:="apt install -y"}"
: "${dialog_box:="dialog"}"
: "${web_server:="nginx"}"
: "${requirements:="tor grep sed openssl basez git qrencode pandoc lynx tar python3-stem ${dialog_box} ${web_server}"}"

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

###################
#### FUNCTIONS ####

usage(){
  printf "Configure the environment for OnionJuggler
\nUsage: %s${0##*/} command [REQUIRED] <OPTIONAL>
\nOptions:
  -s, --setup       setup environment
  -r, --release     prepare for commiting
  -h, --help        show this help message
"
}

## install space separated list of packages (e.g.: install_package tor openssl git)
#command -v "${package}"
#type "${package}"

install_package(){
  for package in "${@}"; do
    if ! command -v "${package}" >/dev/null; then
        # shellcheck disable=SC2086
      ${privilege_command} ${pkg_mngr_install} "${package}"
    fi
  done
}


if [ ! -f onionjuggler-cli ] && [ ! -f onionjuggler-tui ] && [ ! -f etc/onionjuggler.conf ] && [ ! -f docs/onionjuggler-cli.md ]; then
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
    printf %s"${nocolor}# Installing requirements\n"
    ## python3-stem and nginx will be checked again because python3-stem is a librarym not a command and nginx is only acessible by root
    # shellcheck disable=SC2086
    install_package ${requirements}
    printf %s"${cyan}# Appending ${USER} to the ${tor_user} group\n${nocolor}"
    "${privilege_command}" usermod -aG "${tor_user}" "${USER}"
    printf %s"${yellow}# Creating tor directories\n${nocolor}"
    "${privilege_command}" -u "${tor_user}" mkdir -pv "${data_dir_services}"
    "${privilege_command}" -u "${tor_user}" mkdir -pv "${data_dir_auth}"
    printf %s"${green}# Copying script to /usr/local/bin\n${nocolor}"
    "${privilege_command}" mkdir -pv /usr/local/bin ## just in case
    "${privilege_command}" cp -v onionjuggler-cli onionjuggler-tui /usr/local/bin/
    [ ! -f "${ONIONJUGGLER_CONF}" ] && "${privilege_command}" cp -v etc/onionjuggler.conf /etc/onionjuggler.conf
    cp -v .dialogrc "${HOME}/.dialogrc-onionjuggler"
    printf %s"${magenta}# Creating man pages\n${nocolor}"
    "${privilege_command}" mkdir -p /usr/local/man/man1
    pandoc -s -f markdown-smart -t man docs/onionjuggler-cli.md -o /tmp/onionjuggler-cli.1
    pandoc -s -f markdown-smart -t man docs/onionjuggler.conf.md -o /tmp/onionjuggler.conf.1
    "${privilege_command}" mv /tmp/onionjuggler-cli.1 /tmp/onionjuggler.conf.1 /usr/local/man/man1/
    #"${privilege_command}" mandb -q -f /usr/local/man/man1/onionjuggler-cli.1.gz
    ## finish
    printf %s"${blue}# OnionJuggler enviroment is ready\n${nocolor}"
  ;;

  -r|--release|release)
    ## ShellCheck is needed
    ## install https://github.com/koalaman/shellcheck#installing
    ## compile from source https://github.com/koalaman/shellcheck#compiling-from-source
    install_package shellcheck
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
