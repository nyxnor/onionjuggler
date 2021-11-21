#!/usr/bin/env sh

## DESCRIPTION
## This file should be run from inside the cloned repository to set the correct PATH
## It setup tor directories, user, packages need for OnionService.
## It also prepare for releases deleting my path ONIONSERVICE_PWD
##
## SYNTAX
## ./setup.sh [<setup>|release]
##
## Lines that begin with "## " try to explain what's going on. Lines
## that begin with just "#" are disabled commands.

# TODO: THINK: copy to /usr/local/bin instead of adding dir to path? ONIONSERVICE_PWD still has to be on the shell rc.

## SET ENV MANUALLY (dev)
##  Write:
##   printf "\nexport ONIONSERVICE_PWD=\"/absolute/path/to/onionservice/repo\"\n" >> ~/."${SHELL##*/}"rc
##	 printf "PATH=\"\${PATH}:\${ONIONSERVICE_PWD}\"\n\n" >> ~/."${SHELL##*/}"rc
##	 . ~/."${SHELL##*/}"rc
##  Update:
## 	 sed "s|export ONIONSERVICE_PWD=.*|export ONIONSERVICE_PWD=/absolute/path/to/onionservice/repo|" ~/."${SHELL##*/}"rc
##   . ~/."${SHELL##*/}"rc
## SET ENV GUIDED (easy)

###################
#### VARIABLES ####
: "${tor_user:?}"
: "${tor_service:?}"
: "${pkg_mngr_install:?}"
: "${web_server:?}"
: "${requirements:?}"

: "${website_dir:?}"

: "${nocolor:?}"
: "${red:?}"
: "${green:?}"
: "${yellow:?}"
: "${blue:?}"

: "${data_dir:?}"
: "${data_dir_services:?}"
: "${data_dir_auth:?}"
: "${torrc:?}"

###################
#### FUNCTIONS ####

add_onionservice_to_path(){
  ## add variable to enviroment and export it to call from inside shell scripts
  printf '\n%s\n' "export ONIONSERVICE_PWD=\"${ONIONSERVICE_PWD}\"" >> ~/."${SHELL##*/}"rc
  ## add directory to path to call script as a command from any folder without prepending the shell or path
  printf "PATH=\"\${PATH}:\${ONIONSERVICE_PWD}\"\n\n" >> ~/."${SHELL##*/}"rc
  ## source shell rc
  . ~/."${SHELL##*/}"rc
}

inform_to_add_onionservice_to_path(){
  printf "\033[1;31mERROR: \${ONIONSERVICE_PWD} needs to be exported first. There are two options to set the variable:\n"
  printf "\\033[1;33mSAFE: Run this script again from inside the repository, it will automatically use the \${PWD}.\n"
  printf "\033[0m  ./setup/setup.sh\n"
  printf "\\033[1;33mDEV:  Or input the path manually by running the command below (no trailing/not ending with \"/\"):\n"
  printf "\033[0m  ./setup/setup.sh -s -p /absolute/path/to/onionservice\n\n"
  printf "\\033[1;33mSee usage:\033[0m\n"
  usage
  exit 1
}

usage(){
  printf "Configure the environment for OnionService
\nUsage: %s${0##*/} command [REQUIRED] <OPTIONAL>
\nOptions:
  -s, --setup             setup environment
  -r, --release           prepare for commiting
  -h, --help              show this help message
\nAdvanced usage:
  -s <-p /path/to/repo>   specify the \$ONIONSERVICE_PWD, it will overwrite the current configuration
"
}

## MAIN
action=${1:--s}
argument=${2}
definition=${3}

case "${action}" in

  -s|--setup|setup)
    case "${argument}" in
      -p|--path|path)
        [ -f "${definition}"/.onionrc ] || { printf "\033[1;31mERROR: Path is invalid.\033[0m\n"; exit 1; }
        ## delete previous configuration just in case
        sed -i'' "/ONIONSERVICE_PWD/d" ~/."${SHELL##*/}"rc
        ONIONSERVICE_PWD="${definition}"
        add_onionservice_to_path
      ;;

      *)
        if [ -f .onionrc ] && [ -f onionservice-cli ]; then ## onionservice-tui is not required to exist
          ## delete previous configuration just in case
          sed -i'' "/ONIONSERVICE_PWD/d" ~/."${SHELL##*/}"rc
          ## this is necessary because on the first run, the var is empty and lead to wrong paths down below
          ONIONSERVICE_PWD="${PWD}"
          add_onionservice_to_path
        else
          printf "\033[1;31mERROR: \${ONIONSERVICE_PWD} needs to be exported first. There are two options to set the variable:\n"
          printf "\\033[1;33mSAFE: Run this script again from inside the repository, it will automatically use the \${PWD}.\n"
          printf "\033[0m  ./setup/setup.sh\n"
          printf "\\033[1;33mDEV:  Or input the path manually by running the command below (no trailing/not ending with \"/\"):\n"
          printf "\033[0m  ./setup/setup.sh -s -p /absolute/path/to/onionservice\n\n"
          printf "\\033[1;33mSee usage:\033[0m\n"
          usage
          exit 1
        fi
    esac
    . "${ONIONSERVICE_PWD}"/.onionrc
    ## configure
    # shellcheck disable=SC2086
    install_package ${requirements}
    sudo usermod -aG "${tor_user}" "${USER}"
    sudo -u "${tor_user}" mkdir -p "${data_dir_services}"
    sudo -u "${tor_user}" mkdir -p "${data_dir_auth}"
    restarting_tor
    printf "# Creating man pages\n"
    sudo mkdir -p /usr/local/man/man1
    pandoc "${ONIONSERVICE_PWD}"/docs/ONIONSERVICE-CLI.md -s -t man -o /tmp/onionservice-cli.1
    gzip -f /tmp/onionservice-cli.1
    #tar -czvf --no-xattrs /tmp/onionservice-cli.1.gz /tmp/onionservice-cli.1 ## TODO: tar prints file bits information inside the file
    sudo mv /tmp/onionservice-cli.1.gz /usr/local/man/man1/
    sudo mandb -q -f /usr/local/man/man1/onionservice-cli.1.gz
    ## finish
    printf %s"${blue}# OnionService enviroment is ready\n${nocolor}"
  ;;

  -r|--release|release)
    [ -f .onionrc ] && ONIONSERVICE_PWD="${PWD}"
    . "${ONIONSERVICE_PWD}"/.onionrc
    install_package shellcheck
    printf %s"${blue}# Preparing Release\n"
    printf "# Checking syntax\n" ## quits to warn workflow test failed
    ## Customize severity with -S [error|warning|info|style]
    shellcheck "${ONIONSERVICE_PWD}"/setup/setup.sh "${ONIONSERVICE_PWD}"/.onionrc "${ONIONSERVICE_PWD}"/onionservice-cli "${ONIONSERVICE_PWD}"/onionservice-tui || exit 1
    ## cleanup
    find "${ONIONSERVICE_PWD}" -type f -exec sed -i'' "s/set \-\x//g" {} \; ## should not delete, could destroy lines, just leave empty lines
    printf %s"${green}# Done!\n${nocolor}"
  ;;

  *) printf %s"${yellow}"; usage; printf %s"${nocolor}"

esac
