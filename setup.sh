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

{ [ -f .onionrc ] && [ -f onionservice-cli ]; } \
|| { printf "\033[1;31mERROR: This script must be run from inside the onionservice cloned repository.\n"; exit 1; }

## Customiz severity with -s [error|warning|info|style]
check_syntax(){
  shellcheck -x -s sh -e 1090,2086,2236 onionservice-tui || exit 1
  shellcheck -x -s sh -e 1090,2236 onionservice-cli || exit 1
  shellcheck -x -s sh -e 1090,2034,2119,2236 setup.sh || exit 1
  shellcheck -s sh -e 2034,2236 .onionrc || exit 1
}

ACTION=${1:-SETUP}

case "${ACTION}" in

  *help|-h)
    printf "Commands: [help|setup|release]\n"
  ;;

  setup|SETUP)
      . .onionrc
      #python3-stem
      install_package tor openssl basez git qrencode grep sed gawk "${WEBSERVER}"
      sudo usermod -aG "${TOR_USER}" "${USER}"
      sudo -u "${TOR_USER}" mkdir -p "${DATA_DIR_HS}"
      sudo -u "${TOR_USER}" mkdir -p "${CLIENT_ONION_AUTH_DIR}"
      restarting_tor
      [ "$(grep -c "ClientOnionAuthDir" "${TORRC}")" -eq 0 ] && { printf %s"\nClientOnionAuthDir ${CLIENT_ONION_AUTH_DIR}\n\n" | sudo tee -a "${TORRC}"; }
      sed -i "/.*## DO NOT EDIT. Inserted automatically by onionservice setup.sh/d" ~/."${SHELL##*/}"rc
      printf %s"PATH=\"\${PATH}:${PWD}/\" ## DO NOT EDIT. Inserted automatically by onionservice setup.sh\n" >> ~/."${SHELL##*/}"rc
      . ~/."${SHELL##*/}"rc
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" .onionrc
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" onionservice-cli
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" onionservice-tui
      printf %s"${FOREGROUND_BLUE}# OnionService enviroment is ready\n${UNSET_FORMAT}"
  ;;

  check)
    check_syntax
  ;;

  release|RELEASE)
    check_syntax
    . .onionrc
    printf %s"${FOREGROUND_BLUE}# Preparing Release\n"
    sed -i "s/set \-\x//g" .onionrc
    sed -i "s/set \-\x//g" onionservice-cli
    sed -i "s/set \-\x//g" onionservice-tui
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" .onionrc
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" onionservice-cli
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" onionservice-tui
    printf %s"${FOREGROUND_GREEN}# Done!\n"
  ;;

  *)
    . .onionrc
    printf %s"${FOREGROUND_RED}ERROR: Invalid command: ${ACTION}.\n"

esac