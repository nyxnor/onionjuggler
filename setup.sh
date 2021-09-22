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
## sh setup.sh [S]

{ [ -f .onion.lib ] && [ -f onionservice-cli ]; } \
|| { printf "\033[1;31mERROR: This command must be run from inside the onionservice cloned repository.\n"; exit 1; }

ACTION=${1:-SETUP}

case "${ACTION}" in

  setup|SETUP)
      . .onion.lib
      #python3-stem
      install_package tor openssl basez git qrencode grep sed
      sudo usermod -aG "${DATA_DIR_OWNER}" "${USER}"
      sudo -u "${DATA_DIR_OWNER}" mkdir -p "${DATA_DIR_HS}"
      sudo -u "${DATA_DIR_OWNER}" mkdir -p "${CLIENT_ONION_AUTH_DIR}"
      [ "$(grep -c "ClientOnionAuthDir" "${TORRC}")" -eq 0 ] && { printf %s"\nClientOnionAuthDir ${CLIENT_ONION_AUTH_DIR}\n\n" | sudo tee -a ${TORRC}; }
      sed -i "/.*## DO NOT EDIT. Inserted automatically by onionservice setup.sh/d" ~/.${SHELL##*/}rc
      printf %s"PATH=\"\${PATH}:${PWD}/\" ## DO NOT EDIT. Inserted automatically by onionservice setup.sh\n" >> ~/.${SHELL##*/}rc
      . ~/.${SHELL##*/}rc
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" .onion.lib
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" onionservice-cli
      sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=\"${PWD}\"|" onionservice-tui
      printf %s"${FOREGROUND_BLUE}# OnionService enviroment is ready\n${UNSET_FORMAT}"
      restarting_tor
  ;;

  release|RELEASE)
    . .onion.lib
    printf %s"${FOREGROUND_BLUE}# Preparing Release\n"
    sed -i "s/set \-\x//g" .onion.lib
    sed -i "s/set \-\x//g" onionservice-cli
    sed -i "s/set \-\x//g" onionservice-tui
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" .onion.lib
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" onionservice-cli
    sed -i "s|ONIONSERVICE_PWD=.*|ONIONSERVICE_PWD=|" onionservice-tui
    printf %s"${FOREGROUND_GREEN}# Done!\n"
  ;;

  *)
    . .onion.lib
    printf %s"${FOREGROUND_RED}ERROR: Invalid command: ${ACTION}.\n"

esac