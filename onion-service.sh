#!/bin/bash

## This file is part of onion-cli, an easy to use Tor hidden services manager.
##
## Copyright (C) 2018-2021 openoms, rootzoll, frennkie, nolith (MIT)
## Github: https://github.com/openoms, https://github.com/rootzoll, https://github.com/frennkie, https://github.com/nolith
## Source: https://github.com/rootzoll/raspiblitz/tree/v1.7/home.admin/config.scripts/internet.hiddenservice.sh
##
## Copyright (C) 2021 nyxnor (GPLv3)
## Contact: nyxnor@protonmail.com
## Github:  https://github.com/nyxnor
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
## This file lets you manage your hidden services
##
## SYNTAX
## bash onion-service.sh COMMAND [REQ_OPTION] <OPTIONAL>
##
## string   --> Command and is necessary
## [string] --> Necessary
## <string> --> Optional
##
## Changes applied to X modify Y:
##   on              Create <torrc> config, tor will create <HiddenServiceDir>
##   off             Delete <torrc> config, optionally purge <HiddenServiceDir>
##   renew:          Remove <HiddenServiceDir>/* (contents: keys, hostname, authorized_clients)
##   auth server     Create or remove '.auth' files inside <HiddenServiceDir>/authorized_clients/
##   auth client     Create or remove '.auth_private' files inside <ClientOnionAuthDir>
##   credentials     No modification, reads the <torrc> and <HiddenServiceDir>/
##
## COMMAND INFO
onion_usage(){
  printf %s"
Configure an Onion Service

Usage: bash ${0} COMMAND [REQUIRED] <OPTIONAL>

Options:

  on tcp [SERV] [VIRTPORT] <TARGET> <VIRTPORT2> <TARGET2>                            activate a service targeting tcp socket

  on unix [SERV] [VIRTPORT] <VIRTPORT2>                                              activate a service targeting unix socket

  off [SERV1,SERV2,...] <purge>                                                      deactivate a service and optionally purge its directory

  renew [all-services|SERV1,SERV2,...]                                               renew indicated|all services addresses

  auth server on [SERV] [CLIENT] <CLIENT_PUB_KEY>                                    when auth content is especified, use the public key given by the client

  auth server on [all-services|SERV1,SERV2,...] [CLIENT1,CLIENT2,...]                add authorization of client access

  auth server off [all-services|SERV1,SERV2,...] [all-clients|CLIENT1,CLIENT2,...]   remove authorization of client access

  auth server list [SERV1,SERV2,...]                                                 list clients for indicated service

  auth client on [ONION_DOMAIN] <CLIENT_PRIV_KEY>                                    add your client key, if no key specified, will create one

  auth client off [ONION_DOMAIN]                                                     remote your client key

  auth client list                                                                   list your keys as a client

  credentials [all-services|SERV1,SERV2,...]                                         see credentials from indicated services

  location [SERV] [nginx|apache|html]                                                onion-location guide, no execution

  backup [create|integrate]                                                          create backup or import backup and integrate the files

  vanguards [install|logs|upgrade|remove]                                            install, upgrade, remove or see logs for vanguards addon

'# Done': You should always see it at the end, else something unexpected occured.
It does not imply the code worked, you should always pay attention for errors in the logs.\n"
  exit 1
}

###########################
######## FUNCTIONS ########

[ "$EUID" -eq 0 ] && { printf "Not as root !!!\n" && exit 1; }

{ [ "$#" -eq 0 ] || [ -z "${2}" ] || [ "${1}" = "-h" ] || [ "${1}" = "-help" ] || [ "${1}" = "--help" ]; } && onion_usage

## include lib
source onion.lib

#clear
COMMAND="${1}"
SERVICE="${2}"

command -v openssl >/dev/null || ${PKG_MANAGER_INSTALL} openssl
command -v basez >/dev/null || ${PKG_MANAGER_INSTALL} basez
command -v git >/dev/null || ${PKG_MANAGER_INSTALL} git
command -v qrencode >/dev/null || ${PKG_MANAGER_INSTALL} qrencode

## display error message with instructions to use the script correctly.
error_msg(){
  [ -n "${1}" ] && { printf %s"ERROR: ${1}\n\n"; onion_usage; }
}


## '# Done': You should always see it at the end, else something unexpected occured.
## It does not imply the code worked, you should always pay attention for errors in the logs."
success_msg(){
  [ "${1}" = "reload" ] && restarting_tor
  printf "\n# Done\n"
  #read -n 1 -s -r -p "Press any key to continue"
  #exit 1
}


## check if variable is integer
is_integer(){
  printf %d "${1}" >/dev/null 2>&1 || { printf %s"Not an integer: ${1}\n" && exit 1; }
}


## checks if the TARGET is valid.
## Address range from 0.0.0.0 to 255.255.255.255. Port ranges from 0 to 65535
## accept localhos:port if port is valid.
## this is not perfect but it is better than nothing
is_addr_port(){
  ADDR_PORT="${1}"
  ADDR=$(printf %s"${ADDR_PORT}" | cut -d ':' -f1)
  ADDR_1=$(printf %s"${ADDR_PORT}" | cut -d '.' -f1)
  ADDR_2=$(printf %s"${ADDR_PORT}" | cut -d '.' -f2)
  ADDR_3=$(printf %s"${ADDR_PORT}" | cut -d '.' -f3)
  ADDR_4=$(printf %s"${ADDR_PORT}" | cut -d '.' -f4 | cut -d ':' -f1)
  PORT=$(printf %s"${ADDR_PORT}" | cut -d ':' -f2)

  is_integer "${ADDR_1}"; is_integer "${ADDR_2}"; is_integer "${ADDR_3}"; is_integer "${ADDR_4}"; is_integer "${PORT}"

  { [ "${PORT}" -gt 0 ] && [ "${PORT}" -le 65535 ] ; } \
  || { printf %s"PORT=${PORT} \n"; error_msg "PORT is not within range: 0 < PORT <= 65535" ; }

  { { [ "${ADDR_1}" -ge 0 ] && [ "${ADDR_1}" -le 255 ] ; } \
  && { [ "${ADDR_2}" -ge 0 ] && [ "${ADDR_2}" -le 255 ] ; } \
  && { [ "${ADDR_3}" -ge 0 ] && [ "${ADDR_3}" -le 255 ] ; } \
  && { [ "${ADDR_4}" -ge 0 ] && [ "${ADDR_4}" -le 255 ] ; } ; } \
  || { printf %s"ADDR=${ADDR}\n"; error_msg "TARGET address is not within range: 0.0.0.0 to 255.255.255.255" ; }
}


## test if service exists to continue the script or output error logs.
## if the service exists, will save the hostname for when requested.
test_service_exists(){
  SERVICE="${1}"
  ADDRESS_EXISTS=$(sudo -u "${DATA_DIR_OWNER}" cat "${DATA_DIR_HS}"/"${SERVICE}"/hostname 2>/dev/null | grep -c ".onion")
  if [ "${ADDRESS_EXISTS}" -eq 0 ]; then
    printf %s"ERROR: Could not locate hostname file for the service ${SERVICE}\n"
    service_existent=0
    exit 1
  else
    ONION_HOSTNAME=$(sudo -u "${DATA_DIR_OWNER}" cat "${DATA_DIR_HS}"/"${SERVICE}"/hostname)
    service_existent=1
  fi
}


## save the clients names that are inside the <HiddenServiceDir>/authorized_clients/ in list format (CLIENT1,CLIENT2,...)
create_client_list(){
  SERVICE="${1}"
  CLIENT_NAME_LIST=""
  CLIENT_COUNT=0
  for AUTHORIZATION in $(sudo -u "${DATA_DIR_OWNER}" ls "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/); do
    AUTHORIZATION_NAME=$(printf %s"${AUTHORIZATION##*/}" | cut -f1 -d '.')
    CLIENT_NAME_LIST="${CLIENT_NAME_LIST},${AUTHORIZATION_NAME}"
    CLIENT_COUNT=$((CLIENT_COUNT+1))
  done
  CLIENT_NAME_LIST=$(printf %s"${CLIENT_NAME_LIST}" | sed 's/^,//g')
  [ "${CLIENT_NAME_LIST}" = "1" ] && CLIENT_NAME_LIST=""
}


## save the service names that have a <HiddenServiceDir> in list format (SERV1,SERV2,...)
create_service_list(){
  SERVICE_NAME_LIST=""
  for SERVICE in $(sudo -u "${DATA_DIR_OWNER}" ls "${DATA_DIR_HS}"/); do
    SERVICE_NAME=$(printf %s"${SERVICE##*/}")
    SERVICE_NAME_LIST="${SERVICE_NAME_LIST},${SERVICE_NAME}"
    SERVICE_NUMBER=$((SERVICE_NUMBER+1))
  done
  SERVICE_NAME_LIST=$(printf %s"${SERVICE_NAME_LIST}" | sed 's/^,//g')
  [ "${SERVICE_NAME_LIST}" = "1" ] && SERVICE_NAME_LIST=""
}


## loops the parameters
## $1 CALL_FUNCTION must be the function to loop
## $2 normally is service, but can be any other parameter (accepts list -> serv1,serv2,...)
## $3 normally is client, but can be any other (accepts list -> client1,client2...)
## $4 if $3 is a list (client1,client2,...), fill it with "1" (anything non zero)
## Examples:
##  bash onion-service.sh off ssh,xmpp,nextcloud purge
##   loop_array_dynamic delete_service "${SERVICE}" "${PURGE}"
##  bash onion-service.sh auth server on ssh,xmpp,nextcloud alice,bob
##   loop_array_dynamic auth_server_add "${SERVICE}" "${CLIENT}" 1
##  bash onion-service.sh auth server purge ssh,xmpp,nextcloud
##   loop_array_dynamic auth_server_purge "${SERVICE}"
##  bash onion-service.sh auth client off bob-ssh-service
##   loop_array_dynamic auth_client_remove "${AUTH_FILE_NAME}"
##  bash onion-service.sh renew ssh,xmpp,nextcloud
##   loop_array_dynamic renew_service_address "${SERVICE}"
## DONT LIKE THE VARIBLES NAMES? GIVE ME SOME SUGGESTIONS, THE VAR IS USED FOR DIFFERENT THINGS
loop_array_dynamic(){
  CALL_FUNCTION="${1}"
  VAR_ONE="${2}"
  VAR_TWO="${3}"
  VAR_THREE="${4}"

  VAR_ONE=$(printf %s"${VAR_ONE}" | cut -f1- -d ',' --output-delimiter=' ')
  IFS=' ' read -r -a VAR_ONE_ARRAY <<< "${VAR_ONE}"
  VAR_ONE_COUNT=${#VAR_ONE_ARRAY[@]}

  VAR_ONE_NUMBER_CURRENT=$((VAR_ONE_COUNT-1))
  while [ ${VAR_ONE_NUMBER_CURRENT} -ge 0 ]; do
    if [ -z "${VAR_THREE}" ]; then
      "${CALL_FUNCTION}" "${VAR_ONE_ARRAY[VAR_ONE_NUMBER_CURRENT]}" "${VAR_TWO}"
    else
      VAR_TWO=$(printf %s"${VAR_TWO}" | cut -f1- -d ',' --output-delimiter=' ')
      IFS=' ' read -r -a VAR_TWO_ARRAY <<< "${VAR_TWO}"
      VAR_TWO_COUNT=${#VAR_TWO_ARRAY[@]}
      VAR_TWO_NUMBER_CURRENT=$((VAR_TWO_COUNT-1))
      while [ ${VAR_TWO_NUMBER_CURRENT} -ge 0 ]; do
        "${CALL_FUNCTION}" "${VAR_ONE_ARRAY[VAR_ONE_NUMBER_CURRENT]}" "${VAR_TWO_ARRAY[VAR_TWO_NUMBER_CURRENT]}"
        VAR_TWO_NUMBER_CURRENT=$((VAR_TWO_NUMBER_CURRENT-1))
      done
    fi
    VAR_ONE_NUMBER_CURRENT=$((VAR_ONE_NUMBER_CURRENT-1))
  done
}


###########################

## tor needs to be running to create services and renew addresses (on, renew)
## tor does not need to be running to delete service, authorize or remove authorization from clients or see credentials (off, auth, credentials)
#check_tor
sudo cp "${TORRC}" "${TORRC}".bak

case "${COMMAND}" in

  ## deactivate a service by removing service torrc's block.
  ## it is raw, services variables should be separated by an empty line per service, else you might get other non-related configuration deleted.
  ## purge is optional, it deletes the <HiddenServiceDir>
  ## will not check if folder or configuration exist, this is cleanup mode
  ## will not use 'all-services'. Purge is dangerous, purging all service is even more dangerous. Always backup.
  off)
    PURGE="${3}"
    delete_service(){
      SERVICE="${1}"
      PURGE="${2}"
      ## remove service service data
      if [ "${PURGE}" = "purge" ]; then
        #read -p "# WARNING: Permanently delete the HiddenServiceDir of ${SERVICE}, keys included)? (yes/no) " -n 1 -r PURGE_RESPONSE
        #if [ "${PURGE_RESPONSE}" = "y" ]; then
          printf %s"\n# Deleting Hidden Service data in ${DATA_DIR_HS}/${SERVICE}\n"
          sudo rm -rf "${DATA_DIR_HS}"/"${SERVICE}"
        #else
        #  printf %s"\n# HiddenServiceDiretory was kept"
        #fi
      fi
      ## remove service paragraph in torrc
      printf %s"# Deleting Hidden Service configuration in ${TORRC}\n"
      sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" "${TORRC}"
      ## substitute multiple sequential empty lines to a single one per sequence
      awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' "${TORRC}" | sudo tee "${TORRC}".tmp >/dev/null && sudo mv "${TORRC}".tmp "${TORRC}"
      printf %s"# Removed service  ${SERVICE}\n\n"
    }
    loop_array_dynamic delete_service "${SERVICE}" "${PURGE}"
    success_msg reload
  ;;


  ## activate a service by configure its own torrc's block, consequentially the <HiddenServiceDir> will be created.
  ## tcp-socket uses addr:port, which can be remote or localhost. It leaks onion address to the local network
  ## unix-socket uses unix:path, which is create a unique name for it. It does not leak onion address to the local network.
  ## VIRTPORT is the port to be used by the client when visiting the service.
  ## TARGET is where the incoming traffic from VIRTPORT gets redirected. This option is abscent on unix-socket because the script completes it.
  ##  if TARGET is not specified, will use the same port from VIRTPORT and bind to localhost.
  ##  if TARGET only contains the port number and not the address, will bind to localhost.
  ## VIRTPORT2 and TARGET 2 are optional
  on)
    SOCKET="${2}"
    SERVICE="${3}"

    finish_service_activation(){
      ## remove double empty lines
      awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' "${TORRC}" | sudo tee "${TORRC}".tmp >/dev/null && sudo mv "${TORRC}".tmp "${TORRC}"
      printf "# Reloading tor to activate the Hidden Service...\n"
      restarting_tor
      sleep 3

      ## show the Hidden Service address
      service_existent=0; test_service_exists "${SERVICE}"
      if [ "${service_existent}" -eq 1 ]; then
        printf "\n# Tor Hidden Service information:\n"
        qrencode -m 2 -t ANSIUTF8 "${ONION_HOSTNAME}"
        printf %s"Service name    = ${SERVICE}\n"
        printf %s"Service address = ${ONION_HOSTNAME}\n"
        printf %s"Virtual port    = ${VIRTPORT}\n"
        [ -n "${VIRTPORT2}" ] && printf %s"Virtual port    = ${VIRTPORT2}\n"
        success_msg
      fi
    }

    case "${SOCKET}" in

      tcp)
        ## tor-manual: By default, this option maps the virtual port to the same port on 127.0.0.1 over TCP
        ## Because of that, this project lets the user leave TARGET="" and write TARGET as 127.0.0.1:VIRTPORT
        ## Also, substitutes localhost:PORT for 127.0.0.1:PORT
        ## This measures avoid using the same local port for different services
        ## grep torrc TARGET to see if port is already in use and by which service, reading the file in reverse
        printf "# Checking if command is valid...\n"
        ## Required
        VIRTPORT="${4}"; [ -z "${VIRTPORT}" ] && error_msg "VIRTPORT is missing" || is_integer "${VIRTPORT}"
        TARGET="${5}"
        { [ -n "${VIRTPORT}" ] && [ -z "${TARGET}" ]; } && TARGET="127.0.0.1:${VIRTPORT}"
        TARGET_ADDR=$(printf %s"${TARGET}" | cut -d ':' -f1)
        TARGET_PORT=$(printf %s"${TARGET}" | cut -d ':' -f2)
        { [ -n "${TARGET}" ] && [ "${TARGET_ADDR}" = "${TARGET_PORT}" ] || [ "${TARGET_ADDR}" = "localhost" ]; } && TARGET="127.0.0.1:${TARGET_PORT}"
        TARGET_ALREADY_INSERTED=$(sudo -u "${CONF_DIR_OWNER}" grep -c "HiddenServicePort .*${TARGET}$" "${TORRC}")
        TARGET_ALREADY_INSERTED_BLOCK=$(tac "${TORRC}" | sudo sed -n "/HiddenServicePort .*${TARGET}$/,/^\s*$/{p}" | grep "HiddenServiceDir")
        TARGET_ALREADY_INSERTED_SERVICE=${TARGET_ALREADY_INSERTED_BLOCK##*/}
        [ "${TARGET_ALREADY_INSERTED}" -gt 0 ] && error_msg "TARGET=${TARGET} is being used by the service: ${TARGET_ALREADY_INSERTED_SERVICE}"
        is_integer "${VIRTPORT}"; is_addr_port "${TARGET}" "TARGET"
        ## Optional
        VIRTPORT2="${6}"
        TARGET2="${7}"
        if [ -n "${VIRTPORT2}" ]; then
          if [ -z "${TARGET2}" ]; then
            TARGET2="127.0.0.1:${VIRTPORT2}"
          else
            TARGET2_ADDR=$(printf %s"${TARGET2}" | cut -d ':' -f1)
            TARGET2_PORT=$(printf %s"${TARGET2}" | cut -d ':' -f2)
            { [ "${TARGET2_ADDR}" -eq "${TARGET2_PORT}" ] || [ "${TARGET2_ADDR}" = "localhost" ]; } && TARGET2="127.0.0.1:${TARGET2_PORT}"
          fi
          [ "${TARGET}" = "${TARGET2}" ] && error_msg "TARGET is the same as TARGET2"
          TARGET2_ALREADY_INSERTED=$(sudo -u "${CONF_DIR_OWNER}" grep -c "HiddenServicePort .*${TARGET2}$" "${TORRC}")
          TARGET2_ALREADY_INSERTED_BLOCK=$(tac "${TORRC}" | sudo sed -n "/HiddenServicePort .*${TARGET2}$/,/^\s*$/{p}" | grep "HiddenServiceDir")
          TARGET2_ALREADY_INSERTED_SERVICE=${TARGET2_ALREADY_INSERTED_BLOCK##*/}
          [ "${TARGET2_ALREADY_INSERTED}" -gt 0 ] && error_msg "TARGET2=${TARGET2} is being used by the service: ${TARGET2_ALREADY_INSERTED_SERVICE}"
          is_integer "${VIRTPORT2}"; is_addr_port "${TARGET2}" "TARGET2"
        fi

        ## delete any old entry for that servive
        sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" "${TORRC}"
        ## add configuration block, empty line after and before it
        printf %s"\n# Including Hidden Service configuration in ${TORRC}\n"
        [ -n "${VIRTPORT2}" ] \
        && printf %s"\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\nHiddenServicePort ${VIRTPORT2} ${TARGET2}\n\n" | sudo tee -a "${TORRC}" \
        || printf %s"\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\n\n" | sudo tee -a "${TORRC}"
        finish_service_activation
      ;;

      unix)
        printf "# Checking if command is valid...\n"
        VIRTPORT="${4}"; [ -z "${VIRTPORT}" ] && error_msg "VIRTPORT is missing" || is_integer "${VIRTPORT}"
        VIRTPORT2="${5}"; [ -n "${VIRTPORT2}" ] && is_integer "${VIRTPORT2}" ## var not mandatory

        ## delete any old entry for that servive
        sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" "${TORRC}"
        ## add configuration block, empty line after and before it
        printf %s"\n# Including Hidden Service configuration in ${TORRC}\n"
        UNIX_PATH="unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT}.sock"
        UNIX_PATH2="unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT2}.sock"
        [ -n "${VIRTPORT2}" ] \
        && printf %s"\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${UNIX_PATH}\nHiddenServicePort ${VIRTPORT2} ${UNIX_PATH2}\n\n" | sudo tee -a "${TORRC}" \
        || printf %s"\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${UNIX_PATH}\n\n" | sudo tee -a "${TORRC}"
        finish_service_activation
      ;;

      *)
        error_msg "Invalid '${COMMAND}' argument: ${SOCKET}"
    esac
  ;;


  auth)
    HOST="${2}"
    STATUS="${3}"
    SERVICE="${4}"
    CLIENT="${5}"
    case "${HOST}" in

      server)

        case "${STATUS}" in

          ## as the onion service operator, make your onion authenticated by generating a pair or public and private keys,
          ## the client pub key is automatically saved inside <HiddenServiceDir>/authorized_clients/alice.auth
          ## the client private key is shown in the screen and the key file deleted
          ## the onion service operator should send the private key for the desired client
          on)
            #printf "\n# Generating keys to access onion service (Client Authorization) ...\n"
            auth_server_add(){
              SERVICE="${1}"
              CLIENT="${2}"
              service_existent=0; test_service_exists "${SERVICE}"
              if [ "${service_existent}" -eq 1 ]; then
                ## Generate pem and derive pub and priv keys
                openssl genpkey -algorithm x25519 -out /tmp/k1.prv.pem
                grep -v " PRIVATE KEY" /tmp/k1.prv.pem | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.prv.key
                openssl pkey -in /tmp/k1.prv.pem -pubout | grep -v " PUBLIC KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.pub.key
                ## save variables
                CLIENT_PUB_KEY=$(cat /tmp/k1.pub.key)
                CLIENT_PRIV_KEY=$(cat /tmp/k1.prv.key)
                ONION_HOSTNAME_WITHOUT_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -c1-56)
                CLIENT_PRIV_KEY_CONFIG="${ONION_HOSTNAME_WITHOUT_ONION}:descriptor:x25519:${CLIENT_PRIV_KEY}"
                CLIENT_PUB_KEY_CONFIG="descriptor:x25519:${CLIENT_PUB_KEY}"
                # Server side configuration
                printf %s"${PUB_KEY_CONFIG}\n" | sudo tee "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/"${CLIENT}".auth >/dev/null
                ## Client side configuration
                printf "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
                printf "# Declare the variables\n"
                printf %s"SERVICE=${SERVICE}\n"
                printf %s"CLIENT=${CLIENT}\n"
                printf %s"ONION_HOSTNAME=${ONION_HOSTNAME}\n"
                printf %s"CLIENT_PUB_KEY=${CLIENT_PUB_KEY}"
                printf %s"CLIENT_PUB_KEY_CONFIG=descriptor:x25519:${CLIENT_PUB_KEY}"
                printf %s"CLIENT_PRIV_KEY=${PRIV_KEY}\n"
                printf %s"CLIENT_PRIV_KEY_CONFIG=${CLIENT_PRIV_KEY_CONFIG}\n"
                printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n"
                ## Delete pem and keys
                sudo rm -f /tmp/k1.pub.key /tmp/k1.prv.key /tmp/k1.prv.pem
              fi
            }
            instructions_auth(){
              printf "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
              printf "# Send these instructions to the client:\n"
              printf "\n"
              printf "# Check if <ClientOnionAuthDir> was configured in the <torrc>, if it was not, insert it: ClientOnionAuthDir /var/lib/tor/onion_auth\n"
              printf " [ \$(grep -c 'ClientOnionAuthDir' /etc/tor/torrc) -eq 0 ] && { printf "\"ClientOnionAuthDir"\" /var/lib/tor/onion_auth | sudo tee -a /etc/tor/torrc ; }\n"
              printf "\n"
              printf "# Create a file with the suffix '.auth_private' inside <ClientOnionAuthDir>\n"
              printf " printf "\"\${CLIENT_PRIV_KEY_CONFIG}"\" | sudo tee /var/lib/tor/onion_auth/\${SERVICE}-\${ONION_HOSTNAME}.auth_private\n"
              printf "\n"
              printf "# Reload tor\n"
              printf " sudo chown -R debian-tor:debian-tor /var/lib/tor\n"
              printf " sudo systemctl reload-or-restart-tor tor\n"
              printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
            }
            [ "${SERVICE}" = "all-services" ] && { create_service_list ; SERVICE="${SERVICE_NAME_LIST}" ; }
            [ "${CLIENT}" = "all-clients" ] && error_msg "Client name cannot be equal to: all-clients"
            CLIENT_PUB_KEY="${6}"
            if [ "${CLIENT_PUB_KEY}" != "" ]; then
              test_service_exists "${SERVICE}"
              ONION_HOSTNAME_WITHOUT_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -c1-56)
              CLIENT_PUB_KEY_CONFIG="descriptor:x25519:${CLIENT_PUB_KEY}"
              printf %s"${CLIENT_PUB_KEY_CONFIG}" | sudo tee "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/"${CLIENT}".auth >/dev/null
              printf "\n# Server side authorization configured\n\n"
              printf %s" CLIENT_PUB_KEY_CONFIG=${CLIENT_PUB_KEY_CONFIG}\n"
              printf "\n# As you inserted the public key manually, we expect that the client already has the private key\n"
            else
              loop_array_dynamic auth_server_add "${SERVICE}" "${CLIENT}" 1
              instructions_auth
            fi
            success_msg reload
          ;;

          ## as the onion service operator, after making your onion service authenticated, you can also remove a specific client authorization
          ## if no clients are present, the service will be available to anyone that has the onion service address
          off)
            auth_server_remove_clients(){
              SERVICE="${1}"
              CLIENT="${2}"
              printf %s"Service  = ${SERVICE}\n"
              [ -n "${CLIENT}" ] \
              && { printf %s"Client   = ${CLIENT}\n\n" ; sudo rm -f "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/"${CLIENT}".auth ; } \
              || sudo rm -rf "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/
            }
            if [ "${SERVICE}" = "all-services" ]; then
              printf "# Removing client authorization for all services\n"
              if [ "${CLIENT}" = "all-clients" ]; then
                printf "# All clients will be removed and the service will be accessible to anyone with the onion address.\n\n"
                create_service_list; SERVICE="${SERVICE_NAME_LIST}"
                loop_array_dynamic auth_server_remove_clients "${SERVICE}"
              else
                printf "# If any client remains, the service will still be authenticated.\n\n"
                create_service_list; SERVICE="${SERVICE_NAME_LIST}"
                loop_array_dynamic auth_server_remove_clients "${SERVICE}" "${CLIENT}" 1
              fi
            else
              printf %s"# Removing client authorization for the services: ${SERVICE}\n"
              if [ "${CLIENT}" = "all-clients" ]; then
                printf "# All clients will be removed and the service will be accessible to anyone with the onion address.\n\n"
                loop_array_dynamic auth_server_remove_clients "${SERVICE}"
              else
                printf "# If any client remains, the service will still be authenticated.\n\n"
                loop_array_dynamic auth_server_remove_clients "${SERVICE}" "${CLIENT}" 1
              fi
            fi
            success_msg reload
          ;;

          list)
            auth_server_list(){
              SERVICE="${1}"
              service_existent=0; test_service_exists "${SERVICE}"
              printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
              printf "# Authorized clients for hidden service:\n\n"
              printf %s"Service    = ${SERVICE}\n"
              create_client_list "${SERVICE}"
              printf %s"Clients    = ${CLIENT_NAME_LIST} (${CLIENT_COUNT})\n"
            }
            loop_array_dynamic auth_server_list "${SERVICE}"
            printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
            success_msg
          ;;

          *)
            error_msg "Invalid '${COMMAND} ${HOST} ${STATUS}' argument: ${STATUS}"
        esac
      ;;


      client)
        case "${STATUS}" in

          ## as the onion service client, add a key given by the onion service operator to authenticate yourself inside ClientOnionAuthDir
          ## The suffix '.auth_private' should not be mentioned, it will be automatically inserted when mentioning the name of the file.
          ## private key format must be: <onion-addr-without-.onion-part>:descriptor:x25519:<private-key>
          ## use the onion hostname as the file name, this avoid overriding the file by mistake and it indicates outside of the file for which service it refers to (of course it is written inside also)
          ## adding to Tor Browser automatically not supported yet
          on)
            ONION_HOSTNAME="${4}"
            CLIENT_PRIV_KEY="${5}"
            ONION_HOSTNAME_WITHOUT_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -d '.' -f1)
            ONION_HOSTNAME_WITHOUT_ONION_LENGTH=${#ONION_HOSTNAME_WITHOUT_ONION}
            SUFFIX_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -d '.' -f2)
            [ "${ONION_HOSTNAME_WITHOUT_ONION%%*[^a-z2-7]*}" ] || error_msg "ONION_DOMAIN is invalid, it is not within base32 alphabet lower-case encoding [a-z][2-7]"
            [ "${ONION_HOSTNAME_WITHOUT_ONION_LENGTH}" = "56" ] || error_msg "ONION_DOMAIN is invalid, length is different than 56 characters"
            [ "${SUFFIX_ONION}" = "onion" ] || error_msg "ONION_DOMAIN is invalid, suffix is not '.onion'"
            if [ "${CLIENT_PRIV_KEY}" = "" ]; then
              ## Generate pem and derive pub and priv keys
              openssl genpkey -algorithm x25519 -out /tmp/k1.prv.pem
              grep -v " PRIVATE KEY" /tmp/k1.prv.pem | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.prv.key
              openssl pkey -in /tmp/k1.prv.pem -pubout | grep -v " PUBLIC KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.pub.key
              ## save variables
              PUB_KEY=$(cat /tmp/k1.pub.key)
              PRIV_KEY=$(cat /tmp/k1.prv.key)
              ONION_HOSTNAME_WITHOUT_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -c1-56)
              PRIV_KEY_CONFIG="${ONION_HOSTNAME_WITHOUT_ONION}:descriptor:x25519:${PRIV_KEY}"
              PUB_KEY_CONFIG="descriptor:x25519:${PUB_KEY}"
              ## Delete pem and keys
              sudo rm -f /tmp/k1.pub.key /tmp/k1.prv.key /tmp/k1.prv.pem
              # Client side configuration
              printf %s"${PRIV_KEY_CONFIG}\n" | sudo tee "${CLIENT_ONION_AUTH_DIR}"/"${ONION_HOSTNAME}".auth_private >/dev/null
              printf "# Client side authorization configured\n"
              printf "# This is your private key, keep it safe, keep it hidden:\n\n"
              printf %s" PRIV_KEY=${PRIV_KEY}\n"
              printf %s" PRIV_KEY_CONFIG=${PRIV_KEY_CONFIG}\n"
              printf "\n# Now it depends on the service operator to authorize you client public key\n\n"
              ## Server side configuration
              printf "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
              printf "# Send these instructions to the onion service operator\n\n"
              printf %s" ONION_HOSTNAME=${ONION_HOSTNAME}\n"
              printf %s" PUB_KEY=${PUB_KEY}\n"
              printf %s" PUB_KEY_CONFIG=descriptor:x25519:${PUB_KEY}\n\n"
              printf "# Create a file with the client name (eg. alice) using the suffix '.auth' (eg. alice.auth) inside the folder\n"
              printf %s"#  '<HiddenServiceDir>/authorized_clients/' where the service hostname is ${ONION_HOSTNAME}\n\n"
              printf %s" printf "\""${PUB_KEY_CONFIG}""\" | sudo tee /var/lib/tor/hidden_service/authorized_clients/alice.auth\n\n"
              printf "# Reload tor\n\n"
              printf " sudo chown -R debian-tor:debian-tor /var/lib/tor\n"
              printf " sudo systemctl reload-or-restart tor\n"
              printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
            else
              ONION_HOSTNAME_WITHOUT_ONION=$(printf %s"${ONION_HOSTNAME}" | cut -c1-56)
              PRIV_KEY_CONFIG="${ONION_HOSTNAME_WITHOUT_ONION}:descriptor:x25519:${CLIENT_PRIV_KEY}"
              printf %s"${PRIV_KEY_CONFIG}\n" | sudo tee "${CLIENT_ONION_AUTH_DIR}"/"${ONION_HOSTNAME}".auth_private >/dev/null
              printf "\n# Client side authorization configured\n"
              printf %s"\n PRIV_KEY_CONFIG=${PRIV_KEY_CONFIG}\n"
              printf "\n# As you inserted the private key manually, we expect that you have already sent/received the public key to/from the onion service operator\n"
            fi
            success_msg
          ;;

          ## as the onion service client, delete '.auth_private' files from ClientOnionAuthDir that are not valid or has no use anymore
          off)
            auth_client_remove  (){
              ONION_HOSTNAME="${1}"
              sudo rm -f "${CLIENT_ONION_AUTH_DIR}"/"${ONION_HOSTNAME}".auth_private
            }
            ONION_HOSTNAME="${4}"
            loop_array_dynamic auth_client_remove "${ONION_HOSTNAME}"
            printf "\n# Client side authorization removed\n"
            success_msg
          ;;

          list)
            printf %s"# ClientOnionAuthDir ${CLIENT_ONION_AUTH_DIR}\n"
            for AUTH in $(sudo -u "${DATA_DIR_OWNER}" ls "${CLIENT_ONION_AUTH_DIR}"); do
              printf %s"\n# File name: ${AUTH}\n"
              sudo -u "${DATA_DIR_OWNER}" cat "${CLIENT_ONION_AUTH_DIR}"/"${AUTH}"
            done
            printf "\n"
            success_msg
          ;;

          *)
            error_msg "Invalid '${COMMAND} ${HOST} ${STATUS}' argument: ${STATUS}"
        esac
      ;;

      *)
        error_msg
    esac
  ;;


  ## change service hostname by deleting its ed25519 pub and priv keys.
  ## <HiddenServiceDir>/authorized_clients/ because the would need to update their '.auth_private' file with the new onion address anyway and for security reasons.
  ## all-services will read through all services folders and execute the commands.
  renew)
    renew_service_address(){
      SERVICE="${1}"
      service_existent=0; test_service_exists "${SERVICE}"
      if [ ${service_existent} -eq 1 ]; then
        printf "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
        printf %s"\n# Renewing service ${SERVICE}\n"
        OLD_HOSTNAME="${ONION_HOSTNAME}"
        printf %s"Current = ${ONION_HOSTNAME}\n"
        ## save clients names that are inside <HiddenServiceDir>/authorized_clients/
        create_client_list "${SERVICE}"
        ## delete the service folder
        #sudo rm -rf ${DATA_DIR_HS}/${SERVICE}/
        ## delete service public and secret keys
        sudo rm -f "${DATA_DIR_HS}"/"${SERVICE}"/hs_ed25519_secret_key
        sudo rm -f "${DATA_DIR_HS}"/"${SERVICE}"/hs_ed25519_public_key
        ## delete authorized clients
        sudo rm -rf "${DATA_DIR_HS}"/"${SERVICE}"/authorized_clients/*
        ## reload tor now so auth option can get the new hostname
        restarting_tor
        sleep 3
        ## generate auth for clients
        [ -n "${CLIENT_NAME_LIST}" ] && { bash "${0}" auth server on "${SERVICE}" "${CLIENT_NAME_LIST}"; }
        test_service_exists "${SERVICE}"
        NEW_HOSTNAME="${ONION_HOSTNAME}"
        printf %s"New     = ${ONION_HOSTNAME}\n"
        [ "${OLD_HOSTNAME}" != "${NEW_HOSTNAME}" ] \
        && { qrencode -m 2 -t ANSIUTF8 "${NEW_HOSTNAME}" && printf "# Service renewed.\n"; } \
        || printf %s"# Failed to renew service: ${SERVICE}\n"
        printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
      fi
    }
    if [ "${SERVICE}" = "all-services" ]; then
      for SERVICE in $(sudo -u "${DATA_DIR_OWNER}" ls "${DATA_DIR_HS}"/); do
        renew_service_address "${SERVICE}"
      done
    else
      loop_array_dynamic renew_service_address "${SERVICE}"
    fi
    success_msg reload
  ;;

  ## show all the necessary information to access the service such as the hostname and the QR encoded hostname to scan for Tor Browser Mobile
  ## show the clients names and quantity, as well as the service torrc's block
  ## all-services will read through all services folders and execute the commands
  credentials)
    get_credentials(){
      SERVICE="${1}"
      service_existent=0; test_service_exists "${SERVICE}"
      if [ "${service_existent}" -eq 1 ]; then
        ## save clients names that are inside <HiddenServiceDir>/authorized_clients/
        create_client_list "${SERVICE}"
        printf "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
        qrencode -m 2 -t ANSIUTF8 "${ONION_HOSTNAME}"
        printf %s"Address    = ${ONION_HOSTNAME}\n"
        printf %s"Name       = ${SERVICE}\n"
        [ ${#CLIENT_NAME_LIST} -gt 0 ] && printf %s"Clients    = ${CLIENT_NAME_LIST} (${CLIENT_COUNT})\n"
        [ -n "$(sudo grep -c "HiddenServiceDir .*/${SERVICE}$" "${TORRC}")" ] \
        && { printf "Status     = active\n" \
          && sudo sed -n "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{p}" "${TORRC}" | sed '/^[[:space:]]*$/d' ; } \
        || printf "Status     = inactive\n"
        printf ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
      fi
    }
    if [ "${SERVICE}" = "all-services" ]; then
      for SERVICE in $(sudo -u "${DATA_DIR_OWNER}" ls "${DATA_DIR_HS}"/); do
        get_credentials "${SERVICE}"
      done
    else
      loop_array_dynamic get_credentials "${SERVICE}"
    fi
    success_msg
  ;;


  ## guide to add onion-location to redirect tor users when using your plainnet site to the onion service address
  location)
    ## https://matt.traudt.xyz/posts/website-setup/
    SERVICE="${2}"
    METHOD="${3}"
    service_existent=0; test_service_exists "${SERVICE}"
    if [ ${service_existent} -eq 1 ]; then

start_location(){
  printf %s"# Onion-Location guided steps

* The below output is printing text, no file was modified by this script, therefore, user needs to manually configure.
* For web servers, include header line inside the plainnet ssl block (port 443).
* It assumes you know how to run a plainnet server, configuration is an example and should be adapted to your needs.

## Add to your "\"${METHOD}"\" configuration:
"
}

finish_location(){
  printf "## Test redirection

* Open the web site in Tor Browser and a purple pill will appear in the address bar; or
* Fetch the web site HTTP headers and look for onion-location entry and the onion service address:

  wget --server-response --spider your-website.tld
"
}

    case "${METHOD}" in

      nginx)
        start_location
        printf '%s\n' "
  server {
      listen 443 ssl http2;
      add_header Onion-Location http://"${ONION_HOSTNAME}"\$request_uri;
  }

## Reload web server:

  sudo nginx -t
  sudo nginx -s reload
"
        finish_location
      ;;

      apache)
        start_location
        printf '%s\n' "
  <VirtualHost *:443>
          Header set Onion-Location "\"http://"${ONION_HOSTNAME}"%{REQUEST_URI}s"\"
  </Virtualhost>

## Enable headers and rewrite modules:

  sudo a2enmod headers rewrite

## Reload web server:

  sudo systemctl reload apache
"
        finish_location
      ;;

      html)
        start_location
        printf '%s\n' "
  <meta http-equiv="\"onion-location"\" content="\"http://"${ONION_HOSTNAME}""\"/>

## Reload web server that you use:

  sudo nginx -t && sudo nginx -s reload
  sudo systemctl reload apache
"
        finish_location
      ;;

      *)
        error_msg "Invalid '${COMMAND}' argument: ${METHOD}"
    esac
fi
  ;;


  backup)
    METHOD="${2}"
    case "${METHOD}" in

      ## backup tar file will be extracted and integrated into their respective tor folders
      ## scp instructions to import backup from remote host
      integrate)
        ## RESTORE
        sudo mkdir -p "${HS_BK_DIR}"/backup-restoration.tbx
        sudo tar -xpzvf "${HS_BK_DIR}"/*.tar.gz -C "${HS_BK_DIR}"/backup-restoration.tbx
        sudo chown -R "${USER}:${USER}" "${HS_BK_DIR}"/backup-restoration.tbx
        sudo cp -rf "${HS_BK_DIR}"/backup-restoration.tbx"${DATA_DIR_HS}"/* "${DATA_DIR_HS}"/ >/dev/null
        sudo cp -rf "${HS_BK_DIR}"/backup-restoration.tbx"${CLIENT_ONION_AUTH_DIR}"/* "${CLIENT_ONION_AUTH_DIR}"/ >/dev/null
        ## avoid duplication of services, it will keep the current machine config lines for safety
        for SERVICE in $(sudo -u "${CONF_DIR_OWNER}" cat "${TORRC}" | grep "HiddenServiceDir" | cut -d ' ' -f2); do
          SERVICE_NAME=$(printf %s"${SERVICE##*/}")
          sed -n "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{p}" "${TORRC}" > "${TORRC}".tmp
          sed -i "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{d}" "${TORRC}"
          sed '/^\s*$/Q' "${TORRC}".tmp > "${TORRC}".mod
          sudo sed -i '1 i \ ' "${TORRC}".mod; sudo sed -i "\$a\ " "${TORRC}".mod
          sudo cat "${TORRC}".mod | sudo tee -a "${TORRC}" >/dev/null
        done
        sudo rm -f "${TORRC}".tmp "${TORRC}".mod
        awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' "${TORRC}" | sudo tee "${TORRC}".tmp >/dev/null && sudo mv "${TORRC}".tmp "${TORRC}"
        sudo chown -R "${CONF_DIR_OWNER}:${CONF_DIR_OWNER}" "${TORRC}"
        sudo rm -rf "${HS_BK_DIR}"/backup-restoration.tbx
        sudo chown -R "${DATA_DIR_OWNER}:${DATA_DIR_OWNER}" "${DATA_DIR}"
        sudo chown -R "${CONF_DIR_OWNER}:${CONF_DIR_OWNER}" "${TORRC_ROOT}"
        ## RESTORE BACKUP FROM REMOTE
        printf "# Restore your configuration importing from a remote machine.\n"
        printf "## Backup the services dir, onion_auth dir and the torrc\n"
        printf
        ## upload from remote to this instane
        printf "## Import backup file uploading from remote. On the remote terminal, run:\n"
        printf %s"  sudo scp -r ${HS_BK_TAR} ${USER}@${LOCAL_IP}:${HS_BK_DIR}/\n"
        printf
        ## download from this instance
        printf "## Import backup file downloading from remote. On this terminal instance, run:\n"
        printf %s"  sudo scp -r ${SCP_TARGET_FULL} ${HS_BK_DIR}/${HS_BK_TAR}\n"
      ;;


      ## full backup needede to restore all of your hidden services and client keys
      ## folders/files included: <torrc>, <DataDir>/services/, <DataDir>/onion_auth/
      ## scp instructions to export backup to remote host
      create)
        ## CREATE BACKUP
        printf "# Backup your configuration and export it to a remote machine.\n"
        printf "## Backing up the services dir, onion_auth dir and the torrc\n"
        printf
        sudo -u "${USER}" mkdir -p "${HS_BK_DIR}${TORRC_ROOT}"
        sudo -u "${USER}" touch "${HS_BK_DIR}${TORRC}"
        sudo cp "${TORRC}" "${TORRC}".rest
        printf %s"$(sudo sed -n "/HiddenServiceDir/,/^\s*$/{p}" "${TORRC}")" | sudo tee "${TORRC}".tmp >/dev/null
        sudo mv "${TORRC}".tmp "${TORRC}"
        sudo tar -cpzvf "${HS_BK_DIR}"/"${HS_BK_TAR}" "${DATA_DIR_HS}" "${CLIENT_ONION_AUTH_DIR}" "${TORRC}" 2>/dev/null
        sudo mv "${TORRC}".rest "${TORRC}"
        SHA512SUM=$(sha512sum "${HS_BK_DIR}"/"${HS_BK_TAR}")
        SHA256SUM=$(sha256sum "${HS_BK_DIR}"/"${HS_BK_TAR}")
        sudo chown -R "${USER}:${USER}" "${HS_BK_DIR}"/"${HS_BK_TAR}"
        sudo find "${HS_BK_DIR}" \! -name "${HS_BK_TAR}" -delete 2>/dev/null
        sudo chown -R "${DATA_DIR_OWNER}:${DATA_DIR_OWNER}" "${DATA_DIR}"
        sudo chown -R "${CONF_DIR_OWNER}:${CONF_DIR_OWNER}" "${TORRC_ROOT}"
        printf %s"\nsha512sum=${SHA512SUM}"; printf %s" \nsha256sum=${SHA256SUM}\n\n"
        ## upload to remote
        printf "## Export backup file uploading to remote. On this terminal instance, run:\n"
        printf %s"  sudo scp -r ${HS_BK_DIR}/${HS_BK_TAR} ${SCP_TARGET_FULL}\n"
        printf
        ## download from this instance on remote
        printf "## Export backup file downloading from remote. On the remote terminal, run:\n"
        printf %s"  sudo scp -r ${USER}@${LOCAL_IP}:${HS_BK_DIR}/${HS_BK_TAR} .\n"
      ;;

      *)
        error_msg "Invalid '${COMMAND}' argument: ${METHOD}"
    esac
  ;;

  ## This addon protects against guard discovery and related traffic analysis attacks.
  ## A guard discovery attack enables an adversary to determine the guard node(s) that are in use by a Tor client and/or Tor onion service.
  ## Once the guard node is known, traffic analysis attacks that can deanonymize an onion service (or onion service user) become easier.
  vanguards)
    ACTION="${2}"
    case ${ACTION} in
      install)
        printf "# Installing Vanguards...\n"
        sudo git clone https://github.com/mikeperry-tor/vanguards.git "${DATA_DIR}"
        sudo chown -R "${DATA_DIR_OWNER}:${DATA_DIR_OWNER}" "${DATA_DIR}"
        sudo -u "${DATA_DIR_OWNER}" git -C "${DATA_DIR}"/vanguards reset --hard "${VANGUARDS_COMMIT_HASH}"
        sudo -u "${DATA_DIR_OWNER}" cp "${DATA_DIR}"/vanguards/vanguards-example.conf "${DATA_DIR}"/vanguards/vanguards.conf
        sudo sed -i "s/^control_socket =.*/control_socket = \/run\/tor\/control/" "${DATA_DIR}"/vanguards/vanguards.conf
        sudo sed -i "s/^logfile =.*/logfile = \/var\/log\/tor\/vanguards.log/" "${DATA_DIR}"/vanguards/vanguards.conf
        sudo chmod 700 "${DATA_DIR}"
        sudo chown -R "${DATA_DIR_OWNER}:${DATA_DIR_OWNER}" "${DATA_DIR}"
        printf %s"
[Unit]
Description=Additional protections for Tor onion services
Wants=tor@default.service
After=network.target nss-lookup.target

[Service]
WorkingDirectory=${DATA_DIR}/vanguards
ExecStart=/usr/bin/python3 src/vanguards.py --control_socket /run/tor/control ## --control_port ${CONTROL_PORT}
Environment=VANGUARDS_CONFIG=${DATA_DIR}/vanguards/vanguards.conf
User=${DATA_DIR_OWNER}
Group=${DATA_DIR_OWNER}
Type=simple
Restart=always

[Install]
WantedBy=multi-user.target
\n" | sudo tee /etc/systemd/system/vanguards@default.service
        sudo systemctl daemon-reload
        sudo systemctl enable vanguards@default.service
        sudo systemctl start vanguards@default.service
        printf "\n# Check logs with:\n"
        printf "   sudo tail -f -n 25 /var/log/tor/vanguards.log\n"
        success_msg
      ;;
      update)
        printf "# Upgrading Vanguards...\n"
        sudo -u "${DATA_DIR_OWNER}" git -C "${DATA_DIR}"/vanguards pull -p
        sudo -u "${DATA_DIR_OWNER}" git -C "${DATA_DIR}"/vanguards reset --hard "${VANGUARDS_COMMIT_HASH}"
        sudo -u "${DATA_DIR_OWNER}" git -C "${DATA_DIR}"/vanguards show
        success_msg
      ;;
      remove)
        printf "# Removing Vanguards...\n"
        sudo rm -rf "${DATA_DIR}"/vanguards
        success_msg
      ;;
      logs)
        sudo tail -f -n 25 "${VANGUARDS_LOG}"
      ;;
      *)
        error_msg "Invalid vanguards argument: ${ACTION}"
    esac
  ;;

  *)
    error_msg "Invalid command: ${COMMAND}"

esac
