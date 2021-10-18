#!/bin/sh

## This file is part of onionservice, an easy to use Tor hidden services manager.
##
## Copyright (C) 2021 onionservice developers (GPLv3)
## Github:  https://github.com/nyxnor/onionservice
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it is useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program. If not, see <http://www.gnu.org/licenses/>.
##
## DESCRIPTION
## This file should be run from inside the cloned repository to set the correct PATH
## It setup tor directories, user, packages need for onionservice.
## It also prepare for releases deleting my path ONIONSERVICE_PWD
##
## SYNTAX
## sh setup.sh [<setup>|release]
##
## SET ENV MANUALLY (dev)
##  Write:
##   printf "\nexport ONIONSERVICE_PWD=\"/absolute/path/to/onionservice/repo\"\n" >> ~/."${SHELL##*/}"rc
##	 printf "PATH=\"\${PATH}:\${ONIONSERVICE_PWD}\"\n\n" >> ~/."${SHELL##*/}"rc
##	 . ~/."${SHELL##*/}"rc
##  Update:
## 	 sed "s|export ONIONSERVICE_PWD=.*|export ONIONSERVICE_PWD=/absolute/path/to/onionservice/repo|" ~/."${SHELL##*/}"rc
##   . ~/."${SHELL##*/}"rc
## SET ENV GUIDED (easy)
if [ -z "${ONIONSERVICE_PWD}" ]; then
	if [ -f .onionrc ] && [ -f onionservice-cli ]; then
		## add variable to enviroment and export it to call from inside shell scripts
		printf '\n%s\n' "export ONIONSERVICE_PWD=\"${PWD}\"" >> ~/."${SHELL##*/}"rc
		## add directory to path to call script as a command from any folder without prepending the shell or path
		printf "PATH=\"\${PATH}:\${ONIONSERVICE_PWD}\"\n\n" >> ~/."${SHELL##*/}"rc
		## source
    . ~/."${SHELL##*/}"rc
	else
		printf "\033[1;31mERROR: \${ONIONSERVICE_PWD} needs to be exported first. There are two options to set the variable:\n"
		printf "\\033[1;33mSAFE: Run this script again from inside the repository, it will automatically use the \${PWD}.\n"
		printf "\\033[1;33mDEV:  Or input the path manually by running the command below (no trailing/not ending with \"/\"):\n"
		printf "\033[0m\tprintf \"\\\nexport ONIONSERVICE_PWD=\\\"/absolute/path/to/onionservice/repo\\\"\\\n\" >> ~/."${SHELL##*/}"rc\n"
		printf "\tprintf \"PATH=\\\"\\\${PATH}:\\\${ONIONSERVICE_PWD}\\\"\\\n\" >> ~/."${SHELL##*/}"rc\n"
		printf "\t. ~/."${SHELL##*/}"rc\n"
		exit 1
	fi
fi

## MAIN
. "${ONIONSERVICE_PWD}"/.onionrc

ACTION=${1:-SETUP}
case "${ACTION}" in

  setup|SETUP)
    ## configure tor
    #python3-stem
    install_package tor grep sed openssl basez git qrencode pandoc lynx gzip "${WEBSERVER}"
    sudo usermod -aG "${TOR_USER}" "${USER}"
    sudo -u "${TOR_USER}" mkdir -p "${DATA_DIR_HS}"
    sudo -u "${TOR_USER}" mkdir -p "${CLIENT_ONION_AUTH_DIR}"
    restarting_tor
    [ -z "$(grep "ClientOnionAuthDir" "${TORRC}")" ] && { printf %s"\nClientOnionAuthDir ${CLIENT_ONION_AUTH_DIR}\n\n" | sudo tee -a "${TORRC}"; }
    printf "# Creating man pages\n"
		sudo mkdir -p /usr/local/man/man1
		pandoc "${ONIONSERVICE_PWD}"/docs/ONIONSERVICE-CLI.md -s -t man -o /tmp/onionservice-cli.1
		gzip -f /tmp/onionservice-cli.1
		sudo mv /tmp/onionservice-cli.1.gz /usr/local/man/man1/
		sudo mandb -q -f /usr/local/man/man1/onionservice-cli.1.gz
    ## finish
    printf %s"${FOREGROUND_BLUE}# OnionService enviroment is ready\n${UNSET_FORMAT}"
  ;;

  release|RELEASE)
		printf %s"${FOREGROUND_BLUE}# Preparing Release\n"
		## syntax
		## Customize severity with -s [error|warning|info|style]
		## quits to warn workflow test failed
		printf "# Checking syntax\n"
		shellcheck -x -s sh -e 1090,2034,2086,2236 "${ONIONSERVICE_PWD}"/onionservice-tui || SHELLCHECK_FAIL=1
		shellcheck -x -s sh -e 1090,2086,2153,2236 "${ONIONSERVICE_PWD}"/onionservice-cli || SHELLCHECK_FAIL=1
		shellcheck -x -s sh -e 1090,2034,2119,2236 "${ONIONSERVICE_PWD}"/setup.sh || SHELLCHECK_FAIL=1
		shellcheck -s sh -e 2034,2236 "${ONIONSERVICE_PWD}"/.onionrc || SHELLCHECK_FAIL=1
		[ -n "${SHELLCHECK_FAIL}" ] && exit 1
    ## cleanup
    sed -i'' "s/set \-\x//g" "${ONIONSERVICE_PWD}"/.onionrc
    sed -i'' "s/set \-\x//g" "${ONIONSERVICE_PWD}"/onionservice-cli
    sed -i'' "s/set \-\x//g" "${ONIONSERVICE_PWD}"/onionservice-tui
    printf %s"${FOREGROUND_GREEN}# Done!\n${UNSET_FORMAT}"
  ;;

  *) printf "Commands: [help|setup|release]\n"

esac
