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
## command info
onion_usage(){
  echo "Configure an Onion Service

Usage: bash ${0} COMMAND [REQUIRED] <OPTIONAL>

Options:

  on tcp [SERV] [VIRTPORT] <TARGET> <VIRTPORT2> <TARGET2>         activate a service targeting tcp socket

  on unix [SERV] [VIRTPORT] <VIRTPORT2>                           activate a service targeting unix socket

  off [SERV1,SERV2,...] <purge>                                   deactivate a service and optionally purge its directory

  renew [all-services|SERV1,SERV2,...]                            renew indicated|all services addresses

  auth server [on|off] [SERV1,SERV2,...] [CLIENT1,CLIENT2,...]    authorize or remove authorization of client access

  auth client [on|off] [AUTH_FILE] <AUTH_PRIV_KEY>                add or remove your client key, key not needed when removing

  credentials [all-services|SERV1,SERV2,...]                      see credentials from indicated services

  onion-location [SERV]                                           only guide, not execution

  backup [export|import]                                          create backup or import backup and integrate the files

  vanguards [install|logs|upgrade|remove]                         install, upgrade, remove or see logs for vanguards addon

'# Done': You should always see it at the end, else something unexpected occured.
It does not imply the code worked, you should always pay attention for errors in the logs."
  exit 1
}

###########################
######## FUNCTIONS ########

## include lib
. onion.lib

#clear
COMMAND="${1}"
SERVICE="${2}"

## check if variable is integer
is_integer(){
  if [[ ${1} =~ ^-?[0-9]+$ ]]; then
    echo "Is integer: ${1}"
  else
    echo "Must be an integer: ${1}"
    exit 1
  fi
}

## checks if the TARGET is valid.
## Address range from 0.0.0.0 to 255.255.255.255. Port ranges from 0 to 65535
## accept localhos:port if port is valid.
## this is not perfect but it is better than nothing
is_addr_port(){
  ADDR=$(echo "${1}" | cut -d ':' -f1)
  PORT=$(echo "${1}" | cut -d ':' -f2)
  DEFINED_VAR="${2}"
  if [ "${ADDR}" == "${PORT}" ]; then
    if [[ "${PORT}" =~ ^-?[0-9]+$ && ${PORT} -gt 0 && ${PORT} -le 65535 \ ## port must be integer, 0 < port <= 65535
      && "${ADDR}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then ## addr must be integer, 0 < addr <=255
      valid_addr_port=1
    else
      exit 1
    fi
  fi

  if [ ${valid_addr_port} -eq 1 ]; then
    echo "Valid 'addr:port': ${DEFINED_VAR}=${ADDR}:${PORT}"
  else
    echo "Invalid 'addr:port': ${DEFINED_VAR}=${ADDR}:${PORT}"
    exit 1
  fi
}

if [ "$EUID" -eq 0 ]; then
  echo "Not was root please..."
  exit 1
fi


if [[ $# -eq 0 || -z ${2} || "$1" = "-h" || "$1" = "-help" || "$1" = "--help" ]]; then
  onion_usage
fi

## display error message with instructions to use the script correctly.
error_msg(){
  if [ ! -z ${1} ]; then echo "ERROR: ${1} missing"; fi
  echo "Invalid command!"
  echo
  onion_usage
}


## '# Done': You should always see it at the end, else something unexpected occured.
## It does not imply the code worked, you should always pay attention for errors in the logs."
success_msg(){
  if [ "${1}" == "reload" ]; then
    set_owner_permission
    sudo systemctl reload-or-restart tor@default
  fi
  echo
  echo "# Done"
  #read -n 1 -s -r -p "Press any key to continue"
  #echo
  exit 1
}


## test if service exists to continue the script or output error logs.
## if the service exists, will save the hostname for when requested.
test_service_exists(){
  SERVICE="${1}"
  ADDRESS_EXISTS=$(sudo -u ${DATA_DIR_OWNER} cat ${DATA_DIR_HS}/${SERVICE}/hostname 2>/dev/null | grep -c ".onion")
  if [ ${ADDRESS_EXISTS} -eq 0 ]; then
    echo "ERROR: Could not locate hostname file for the service ${SERVICE}"
    service_existent=0
    exit 1
  else
    TOR_HOSTNAME=$(sudo -u ${DATA_DIR_OWNER} cat ${DATA_DIR_HS}/${SERVICE}/hostname)
    service_existent=1
  fi
}


## save the clients names that are inside the <HiddenServiceDir>/authorized_clients/
create_auth_list(){
  SERVICE="${1}"
  CLIENT_NAME_LIST=""
  AUTH_NUMBER=0
  for AUTHORIZATION in $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/${SERVICE}/authorized_clients/); do
    AUTHORIZATION_NAME=$(echo "${AUTHORIZATION##*/}" | cut -f1 -d '.')
    CLIENT_NAME_LIST="${CLIENT_NAME_LIST},${AUTHORIZATION_NAME}"
    ((AUTH_NUMBER++))
  done
  CLIENT_NAME_LIST=$(echo ${CLIENT_NAME_LIST} | sed 's/^,//g')
  if [ "${CLIENT_NAME_LIST}" == "1" ]; then CLIENT_NAME_LIST=""; fi
}


## loops the parameters
## $1 must be the function to loop
## $2 normally is service, but can be any other parameter (accepts list -> serv1,serv2,...)
## $3 normally is client, but can be anything other (accepts list -> client1,client2...)
## $4 if $3 is a list (client1,client2,...), fill it with "1" (anything non zero)
loop_array_dynamic(){
  CALL_FUNCTION="${1}"
  VAR_ONE="${2}"
  VAR_TWO="${3}"
  VAR_THREE="${4}"

  VAR_ONE=$(cut -f1- -d ',' --output-delimiter=' ' <<< ${VAR_ONE})
  IFS=' ' read -r -a VAR_ONE_ARRAY <<< "${VAR_ONE}"
  VAR_ONE_COUNT=${#VAR_ONE_ARRAY[@]}

  VAR_ONE_NUMBER_CURRENT=$((${VAR_ONE_COUNT}-1))
  while [ ${VAR_ONE_NUMBER_CURRENT} -ge 0 ]; do
    VAR_ONE=("${VAR_ONE_ARRAY[${VAR_ONE_NUMBER_CURRENT}]}")
    if [ -z "${VAR_THREE}" ]; then
      ${CALL_FUNCTION} ${VAR_ONE} ${VAR_TWO}
    else
      VAR_TWO=$(cut -f1- -d ',' --output-delimiter=' ' <<< ${VAR_TWO})
      IFS=' ' read -r -a VAR_TWO_ARRAY <<< "${VAR_TWO}"
      VAR_TWO_COUNT=${#VAR_TWO_ARRAY[@]}
      VAR_TWO_NUMBER_CURRENT=$((${VAR_TWO_COUNT}-1))
      while [ ${VAR_TWO_NUMBER_CURRENT} -ge 0 ]; do
        VAR_TWO_NAME_LIST=("${VAR_TWO_ARRAY[${VAR_TWO_NUMBER_CURRENT}]}")
        ${CALL_FUNCTION} ${VAR_ONE} ${VAR_TWO_NAME_LIST}
        ((VAR_TWO_NUMBER_CURRENT--))
      done
    fi
    ((VAR_ONE_NUMBER_CURRENT--))
  done
}

###########################

## tor needs to be running to create services and renew addresses (on, renew)
## tor does not need to be running to delete service, authorize or remove authorization from clients or see credentials (off, auth, credentials)
#check_tor

case ${COMMAND} in

  ## deactivate a service by removing service torrc's block.
  ## it is raw, services variables should be separated by an empty line per service, else you might get other non-related configuration deleted.
  ## purge is optional, it deletes the <HiddenServiceDir>
  ## will not check if folder or configuration exist, this is cleanup mode
  off)
    PURGE="${3}"
    delete_service(){
      SERVICE="${1}"
      PURGE="${2}"
      ## remove service service data
      if [ "${PURGE}" == "purge" ]; then
        echo "# Deleting Hidden Service data in ${DATA_DIR_HS}"
        sudo rm -rf ${DATA_DIR_HS}/${SERVICE}
      fi
      ## remove service paragraph in torrc
      echo "# Deleting Hidden Service configuration in ${TORRC}"
      sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" ${TORRC}
      ## substitute multiple sequential empty lines to a single one per sequence
      awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' ${TORRC} | sudo tee ${TORRC}.tmp >/dev/null && sudo mv ${TORRC}.tmp ${TORRC}
      echo "# Removed service  ${SERVICE}"
    }
    loop_array_dynamic delete_service ${SERVICE} ${PURGE}
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
      awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' ${TORRC} | sudo tee ${TORRC}.tmp >/dev/null && sudo mv ${TORRC}.tmp ${TORRC}
      echo; echo "# Reloading tor to activate the Hidden Service..."
      sudo systemctl reload-or-restart tor@default
      sleep 3

      ## show the Hidden Service address
      service_existent=0; test_service_exists ${SERVICE}
      if [ ${service_existent} -eq 1 ]; then
        echo; echo "# Tor Hidden Service information:"
        qrencode -m 2 -t ANSIUTF8 ${TOR_HOSTNAME}
        echo "Service name    = "${SERVICE}
        echo "Service address = "${TOR_HOSTNAME}
        echo "Virtual port    = "${VIRTPORT}
        if [ ! -z ${VIRTPORT2} ]; then echo "Virtual port    = "${VIRTPORT2}; fi
        success_msg
      fi
    }

    case ${SOCKET} in

      tcp)
      set -x
        echo "# Checking if command is valid..."
        ## Required
        VIRTPORT="${4}"; [[ -z ${VIRTPORT} ]] && error_msg "VIRTPORT"
        TARGET="${5}"
        [[ ! -z ${VIRTPORT} && -z ${TARGET} ]] && TARGET="127.0.0.1:${VIRTPORT}"
        TARGET_ADDR=$(echo "${TARGET}" | cut -d ':' -f1)
        TARGET_PORT=$(echo "${TARGET}" | cut -d ':' -f2)
        [[ ! -z ${TARGET} && ${TARGET_ADDR} -eq ${TARGET_PORT} || "${TARGET_ADDR}" == "localhost" ]] && TARGET="127.0.0.1:${TARGET_PORT}"
        TARGET_ALREADY_INSERTED=$(sudo -u ${CONF_DIR_OWNER} cat ${TORRC} 2>/dev/null | grep -c "HiddenServicePort .*${TARGET}$")
        [[ ${TARGET_ALREADY_INSERTED} -eq 1 ]] && error_msg "TARGET=${TARGET} was already inserted"
        is_integer ${VIRTPORT}; valid_addr_port=0; is_addr_port ${TARGET} "TARGET"
        ## Optional
        VIRTPORT2="${6}"
        TARGET2="${7}"
        if [ ! -z ${VIRTPORT2} ]; then
          if [ -z ${TARGET2} ]; then
            TARGET2="127.0.0.1:${VIRTPORT2}"
          else
            TARGET2_ADDR=$(echo "${TARGET2}" | cut -d ':' -f1)
            TARGET2_PORT=$(echo "${TARGET2}" | cut -d ':' -f2)
            if [[ ${TARGET2_ADDR} -eq ${TARGET2_PORT} || "${TARGET2_ADDR}" == "localhost" ]]; then TARGET2="127.0.0.1:${TARGET2_PORT}"; fi
          fi
          [[ "${TARGET}" == "${TARGET2}" ]] && error_msg "TARGET is the same as TARGET2"
          TARGET2_ALREADY_INSERTED=$(sudo -u ${CONF_DIR_OWNER} cat ${TORRC} 2>/dev/null | grep -c "HiddenServicePort .*${TARGET2}$")
          [[ ${TARGET2_ALREADY_INSERTED} -eq 1 ]] && error_msg "The TARGET2=${TARGET2} was already inserted"
          is_integer ${VIRTPORT2};  valid_addr_port=0; is_addr_port ${TARGET2} "TARGET2"
        fi

        ## delete any old entry for that servive
        sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" ${TORRC}
        ## add configuration block, empty line after and before it
        echo; echo "# Including Hidden Service configuration in ${TORRC}"
        if [ ! -z ${VIRTPORT2} ]; then
          echo -e "\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\nHiddenServicePort ${VIRTPORT2} ${TARGET2}" | sudo tee -a ${TORRC}
        else
          echo -e "\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\n" | sudo tee -a ${TORRC}
        fi
        finish_service_activation
      ;;

      unix)
        echo "# Checking if command is valid..."
        VIRTPORT="${4}"; [[ -z ${VIRTPORT} ]] && error_msg "VIRTPORT" || is_integer ${VIRTPORT}
        VIRTPORT2="${5}"; [[ ! -z ${VIRTPORT2} ]] && is_integer ${VIRTPORT2} ## var not mandatory

        ## delete any old entry for that servive
        sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" ${TORRC}
        ## add configuration block, empty line after and before it
        echo; echo "# Including Hidden Service configuration in ${TORRC}"
        UNIX_PATH="unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT}.sock"
        UNIX_PATH2="unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT2}.sock"
        if [ ! -z ${VIRTPORT2} ]; then
          echo -e "\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${UNIX_PATH}\nHiddenServicePort ${VIRTPORT2} ${UNIX_PATH2}" | sudo tee -a ${TORRC}
        else
          echo -e "\nHiddenServiceDir ${DATA_DIR_HS}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${UNIX_PATH}\n" | sudo tee -a ${TORRC}
        fi
        finish_service_activation
      ;;

      *)
        error_msg
    esac
  ;;


  auth)
    HOST="${2}"
    STATUS="${3}"
    SERVICE="${4}"
    CLIENT="${5}"
    case ${HOST} in

      server)

        case ${STATUS} in

          ## as the onion service operator, make your onion authenticated by generating a pair or public and private keys,
          ## the client pub key is automatically saved inside <HiddenServiceDir>/authorized_clients/alice.auth
          ## the client private key is shown in the screen and the key file deleted
          ## the onion service operator should send the private key for the desired client
          on)
            CLIENT="${5}"
            ## Install openssl and basez if not installed
            #echo "# Generating keys to access onion service (Client Authorization) ..."; echo -e "# -> Send this to the client(s):\n"
            command -v openssl >/dev/null || sudo apt install -y openssl
            command -v basez >/dev/null || sudo apt install -y basez

            generate_auth(){
              SERVICE="${1}"
              CLIENT="${2}"
              service_existent=0; test_service_exists ${SERVICE}
              if [ ${service_existent} -eq 1 ]; then
                ## Generate pem and derive pub and priv keys
                openssl genpkey -algorithm x25519 -out /tmp/k1.prv.pem
                cat /tmp/k1.prv.pem | grep -v " PRIVATE KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.prv.key
                openssl pkey -in /tmp/k1.prv.pem -pubout | grep -v " PUBLIC KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.pub.key
                ## save variables
                PUB_KEY=$(cat /tmp/k1.pub.key)
                PRIV_KEY=$(cat /tmp/k1.prv.key)
                TOR_HOSTNAME_WITHOUT_ONION=$(echo "${TOR_HOSTNAME}" | cut -c1-56)
                PRIV_KEY_CONFIG=(${TOR_HOSTNAME_WITHOUT_ONION}":descriptor:x25519:"${PRIV_KEY})
                TORRC_SERVER_KEY=("descriptor:x25519:"${PUB_KEY})
                # Server side configuration
                echo ${TORRC_SERVER_KEY} | sudo tee ${DATA_DIR_HS}/${SERVICE}/authorized_clients/${CLIENT}.auth >/dev/null
                ## Client side configuration
                echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                echo "# Declare the variables"
                echo "SERVICE="${SERVICE}
                echo "CLIENT="${CLIENT}
                echo "TOR_HOSTNAME="${TOR_HOSTNAME}
                echo "PRIV_KEY="${PRIV_KEY}
                echo "PRIV_KEY_CONFIG="${PRIV_KEY_CONFIG}
                echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
                echo
                ## Delete pem and keys
                sudo rm -f /tmp/k1.pub.key /tmp/k1.prv.key /tmp/k1.prv.pem
              fi
            }
            instructions_auth(){
                echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                echo -e "\n# Instructions client side:"
                echo
                echo "# Check if <ClientOnionAuthDir> was configured in the <torrc>, if it was not, insert it:"
                echo "ClientOnionAuthDir /var/lib/tor/onion_auth"
                echo "[[ $(grep -c "ClientOnionAuthDir" /etc/tor/torrc) -eq 0 ]] && echo -e '\nClientOnionAuthDir /var/lib/tor/onion_auth\n'"
                echo
                echo "# Create the auth file inside <ClientOnionAuthDir>"
                echo "echo \${PRIV_KEY_CONFIG} | sudo tee -a /var/lib/tor/onion_auth/\${SERVICE}-\${TOR_HOSTNAME}.auth_private"
                echo
                echo "# Reload tor"
                echo "sudo chown -R debian-tor:debian-tor /var/lib/tor"
                echo "sudo pkill -sighup tor"
                echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            }
            loop_array_dynamic generate_auth ${SERVICE} ${CLIENT} 1
            instructions_auth
            success_msg reload
          ;;

          ## as the onion service operator, after making your onion service authenticated, you can also remove a specific client authorization
          ## if no clients are present, the service will be available to anyone that has the onion service address
          off)
            CLIENT="${5}"
            delete_auth(){
              SERVICE="${1}"
              CLIENT="${2}"
              echo "# Removing client authorization:"
              echo "Service  = "${SERVICE}
              echo "Client   = "${CLIENT}
              echo
              sudo rm -f ${DATA_DIR_HS}/${SERVICE}/authorized_clients/${CLIENT}.auth
            }
            loop_array_dynamic delete_auth ${SERVICE} ${CLIENT} 1
            success_msg reload
          ;;

          ## as the onion service operator, you can purge clients fast to make it available to anyone that has the onion service address
          ##  all clients for chosen service
          ##  all clients from all-services
          purge)
            CLIENT="${5}"
            echo "# Removing all clients authorizations from listed services:"
            if [ "${SERVICE}" == "all-services" ]; then
              #sudo rm -f ${DATA_DIR_HS}/*/authorized_clients/*
              for SERVICE in $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/); do
                sudo rm -f ${DATA_DIR_HS}/${SERVICE}/authorized_clients/*
              done
            else
              purge_auth(){
                SERVICE=${1}
                sudo rm -f ${DATA_DIR_HS}/${SERVICE}/authorized_clients/*
              }
              loop_array_dynamic purge_auth ${SERVICE}
            fi
            echo "Server side client authorization removed"
            echo "You can know access the services without being requested for a key"
            success_msg
          ;;

          *)
            error_msg
        esac
      ;;


      client)
        case ${STATUS} in

          ## as the onion service client, add a key given by the onion service operator to authenticate yourself inside ClientOnionAuthDir
          ## just the client name. '.auth_private' should not be mentioned, it will be automatically inserted
          ## private key format must be: <onion-addr-without-.onion-part>:descriptor:x25519:<private-key>
          ## adding to Tor Browser automatically not supported yet
          on)
            AUTH_FILE_NAME=${2}
            AUTH_PRIV_KEY=${3}
            echo "${AUTH_PRIV_KEY}" | sudo tee -a ${CLIENT_ONION_AUTH_DIR}/${AUTH_FILE_NAME}.auth_private >/dev/null
            echo "Client side authorization added"
            success_msg
          ;;

          ## as the onion service client, delete '.auth_private' files from ClientOnionAuthDir that are not valid or has no use anymore
          off)
            AUTH_CLIENT_remove(){
              AUTH_FILE_NAME=${1}
              sudo rm -f ${CLIENT_ONION_AUTH_DIR}/${AUTH_FILE_NAME}.auth_private
            }
            AUTH_FILE_NAME=${2}
            loop_array_dynamic AUTH_CLIENT_remove ${AUTH_FILE_NAME}
            echo "Client side authorization removed"
            success_msg
          ;;

          *)
            error_msg
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
      service_existent=0; test_service_exists ${SERVICE}
      if [ ${service_existent} -eq 1 ]; then
        echo "# Renewing service ${SERVICE}"
        OLD_HOSTNAME=${TOR_HOSTNAME}
        echo "Current = "${TOR_HOSTNAME}
        ## save clients names that are inside <HiddenServiceDir>/authorized_clients/
        create_auth_list ${SERVICE}
        ## delete the service folder
        #sudo rm -rf ${DATA_DIR_HS}/${SERVICE}/
        ## delete service public and secret keys
        sudo rm -f ${DATA_DIR_HS}/${SERVICE}/hs_ed25519_secret_key
        sudo rm -f ${DATA_DIR_HS}/${SERVICE}/hs_ed25519_public_key
        ## delete authorized clients
        sudo rm -rf ${DATA_DIR_HS}/${SERVICE}/authorized_clients/*
        ## reload tor now so auth option can get the new hostname
        sudo systemctl reload-or-restart tor@default
        sleep 3
        ## generate auth for clients
        if [ ! -z ${CLIENT_NAME_LIST} ]; then
          bash ${0} auth server on ${SERVICE} ${CLIENT_NAME_LIST}
        fi
        test_service_exists ${SERVICE}
        NEW_HOSTNAME=${TOR_HOSTNAME}
        echo "New     = "${TOR_HOSTNAME}
        if [ "${OLD_HOSTNAME}" != "${NEW_HOSTNAME}" ]; then
          qrencode -m 2 -t ANSIUTF8 ${NEW_HOSTNAME}
          echo "# Service renewed."; echo
        else
          error_msg
        fi
      fi
    }

    if [ "${SERVICE}" == "all-services" ]; then
      for SERVICE in $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/); do
        renew_service_address ${SERVICE}
      done
    else
      loop_array_dynamic renew_service_address ${SERVICE}
    fi

    success_msg reload
  ;;

  ## show all the necessary information to access the service such as the hostname and the QR encoded hostname to scan for Tor Browser Mobile
  ## show the clients names and quantity, as well as the service torrc's block
  ## all-services will read through all services folders and execute the commands
  credentials)
    get_credentials(){
      SERVICE="${1}"
      service_existent=0; test_service_exists ${SERVICE}
      if [ ${service_existent} -eq 1 ]; then
        command -v qrencode >/dev/null || sudo apt install -y qrencode
        ## save clients names that are inside <HiddenServiceDir>/authorized_clients/
        create_auth_list ${SERVICE}
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        qrencode -m 2 -t ANSIUTF8 ${TOR_HOSTNAME}
        echo "Service address    = "${TOR_HOSTNAME}
        echo "Service name       = "${SERVICE}
        if [ ${#CLIENT_NAME_LIST} -gt 0 ]; then
          echo "Clients names      = ${CLIENT_NAME_LIST} (${AUTH_NUMBER})"
        fi
        echo
        #echo "# torrc block:"
        sudo sed -n "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{p}" ${TORRC} | sed '/^[[:space:]]*$/d'
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      fi
    }
    if [ "${SERVICE}" == "all-services" ]; then
      for SERVICE in $(sudo -u ${DATA_DIR_OWNER} ls ${DATA_DIR_HS}/); do
        get_credentials ${SERVICE}
      done
    else
      loop_array_dynamic get_credentials ${SERVICE}
    fi
    success_msg
  ;;


  ## guide to add onion-location to redirect tor users when using your plainnet site to the onion service address
  onion-location)
    #pandoc file.md | lynx -stdin
    #pandoc ONION-LOCATION.md | lynx -stdin
    ## https://matt.traudt.xyz/posts/website-setup/
    SERVICE="${2}"
    METHOD="${3}"
    service_existent=0; test_service_exists ${SERVICE}
    if [ ${service_existent} -eq 1 ]; then
      cp samples/ONION-LOCATION-CUSTOM.md /tmp/ONION-LOCATION-CUSTOM.md
      sed -i 's/TOR_HOSTNAME/'${TOR_HOSTNAME}'/g' /tmp/ONION-LOCATION-CUSTOM.md
      #cat /tmp/ONION-LOCATION-CUSTOM.md
      pandoc /tmp/ONION-LOCATION-CUSTOM.md | lynx -stdin
      sudo rm -f /tmp/ONION-LOCATION-CUSTOM.md
    fi
  ;;


  backup)
    METHOD="${2}"
    case ${METHOD} in

      ## backup tar file will be extracted and integrated into their respective tor folders
      ## scp instructions to import backup from remote host
      import)
        ## RESTORE
        sudo mkdir -p ${HS_BK_DIR}/backup-restoration.tbx
        sudo tar -xpzvf ${HS_BK_DIR}/*.tar.gz -C ${HS_BK_DIR}/backup-restoration.tbx
        sudo chown -R ${USER}:${USER} ${HS_BK_DIR}/backup-restoration.tbx
        sudo cp -rf ${HS_BK_DIR}/backup-restoration.tbx${DATA_DIR_HS}/* ${DATA_DIR_HS}/ >/dev/null
        sudo cp -rf ${HS_BK_DIR}/backup-restoration.tbx${CLIENT_ONION_AUTH_DIR}/* ${CLIENT_ONION_AUTH_DIR}/ >/dev/null
        ## avoid duplication of services, it will keep the current machine config lines for safety
        for SERVICE in $(sudo -u ${CONF_DIR_OWNER} cat ${TORRC} | grep "HiddenServiceDir" | cut -d ' ' -f2); do
          SERVICE_NAME=$(echo "${SERVICE##*/}")
          sed -n "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{p}" ${TORRC} > ${TORRC}.tmp
          sed -i "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{d}" ${TORRC}
          sed '/^\s*$/Q' ${TORRC}.tmp > ${TORRC}.mod
          sudo sed -i '1 i \ ' ${TORRC}.mod; sudo sed -i "\$a\ " ${TORRC}.mod
          sudo cat ${TORRC}.mod | sudo tee -a ${TORRC} >/dev/null
        done
        sudo rm -f ${TORRC}.tmp ${TORRC}.mod
        awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' ${TORRC} | sudo tee ${TORRC}.tmp >/dev/null && sudo mv ${TORRC}.tmp ${TORRC}
        sudo chown -R ${CONF_DIR_OWNER}:${CONF_DIR_OWNER} ${TORRC}
        sudo rm -rf ${HS_BK_DIR}/backup-restoration.tbx
        sudo chown -R ${DATA_DIR_OWNER}:${DATA_DIR_OWNER} ${DATA_DIR}
        sudo chown -R ${CONF_DIR_OWNER}:${CONF_DIR_OWNER} ${TORRC_ROOT}
        ## RESTORE BACKUP FROM REMOTE
        echo "# Restore your configuration importing from a remote machine."
        echo "## Backup the services dir, onion_auth dir and the torrc"
        echo
        ## upload from remote to this instane
        echo "## Import backup file uploading from remote. On the remote terminal, run:"
        echo "  sudo scp -r ${HS_BK_TAR} ${USER}@${LOCAL_IP}:${HS_BK_DIR}/"
        echo
        ## download from this instance
        echo "## Import backup file downloading from remote. On this terminal instance, run:"
        echo "  sudo scp -r ${SCP_TARGET_FULL} ${HS_BK_DIR}/${HS_BK_TAR}"
      ;;


      ## full backup needede to restore all of your hidden services and client keys
      ## folders/files included: <torrc>, <DataDir>/services/, <DataDir>/onion_auth/
      ## scp instructions to export backup to remote host
      export)
        ## CREATE BACKUP
        echo "# Backup your configuration and export it to a remote machine."
        echo "## Backing up the services dir, onion_auth dir and the torrc"
        echo
        sudo -u ${USER} mkdir -p ${HS_BK_DIR}${TORRC_ROOT}
        sudo -u ${USER} touch ${HS_BK_DIR}${TORRC}
        sudo cp ${TORRC} ${TORRC}.rest
        echo "$(sudo sed -n "/HiddenServiceDir/,/^\s*$/{p}" ${TORRC})" | sudo tee ${TORRC}.tmp >/dev/null
        sudo mv ${TORRC}.tmp ${TORRC}
        sudo tar -cpzvf ${HS_BK_DIR}/${HS_BK_TAR} ${DATA_DIR_HS} ${CLIENT_ONION_AUTH_DIR} ${TORRC} 2>/dev/null
        sudo mv ${TORRC}.rest ${TORRC}
        SHA512SUM=$(sha512sum ${HS_BK_DIR}/${HS_BK_TAR})
        SHA256SUM=$(sha256sum ${HS_BK_DIR}/${HS_BK_TAR})
        sudo chown -R ${USER}:${USER} ${HS_BK_DIR}/${HS_BK_TAR}
        sudo find ${HS_BK_DIR} \! -name ${HS_BK_TAR} -delete 2>/dev/null
        sudo chown -R ${DATA_DIR_OWNER}:${DATA_DIR_OWNER} ${DATA_DIR}
        sudo chown -R ${CONF_DIR_OWNER}:${CONF_DIR_OWNER} ${TORRC_ROOT}
        echo; echo "sha512sum=${SHA512SUM}"; echo; echo "sha256sum=${SHA256SUM}"; echo
        ## upload to remote
        echo "## Export backup file uploading to remote. On this terminal instance, run:"
        echo "  sudo scp -r ${HS_BK_DIR}/${HS_BK_TAR} ${SCP_TARGET_FULL}"
        echo
        ## download from this instance on remote
        echo "## Export backup file downloading from remote. On the remote terminal, run:"
        echo "  sudo scp -r ${USER}@${LOCAL_IP}:${HS_BK_DIR}/${HS_BK_TAR} ."
      ;;

      *)
        error_msg
    esac
  ;;

  ## This addon protects against guard discovery and related traffic analysis attacks.
  ## A guard discovery attack enables an adversary to determine the guard node(s) that are in use by a Tor client and/or Tor onion service.
  ## Once the guard node is known, traffic analysis attacks that can deanonymize an onion service (or onion service user) become easier.
  vanguards)
    ACTION="${2}"
    case ${ACTION} in
      install)
        echo "# Installing Vanguards..."
        sudo git clone https://github.com/mikeperry-tor/vanguards.git ${DATA_DIR}
        sudo chown -R ${DATA_DIR_OWNER}:${DATA_DIR_OWNER} ${DATA_DIR}
        sudo -u ${DATA_DIR_OWNER} git -C ${DATA_DIR}/vanguards reset --hard ${VANGUARDS_COMMIT_HASH}
        sudo -u ${DATA_DIR_OWNER} cp ${DATA_DIR}/vanguards/vanguards-example.conf ${DATA_DIR}/vanguards/vanguards.conf
        sudo sed -i "s/^control_socket =.*/control_socket = \/run\/tor\/control/" ${DATA_DIR}/vanguards/vanguards.conf
        sudo sed -i "s/^logfile =.*/logfile = \/var\/log\/tor\/vanguards.log/" ${DATA_DIR}/vanguards/vanguards.conf
        sudo chmod 700 ${DATA_DIR}
        sudo chown -R ${DATA_DIR_OWNER}:${DATA_DIR_OWNER} ${DATA_DIR}
        echo "
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
" | sudo tee /etc/systemd/system/vanguards@default.service
        sudo systemctl daemon-reload
        sudo systemctl enable vanguards@default.service
        sudo systemctl start vanguards@default.service
        echo; echo "# Check logs with:"
        echo "   sudo tail -f -n 25 /var/log/tor/vanguards.log"
        success_msg
      ;;
      update)
        echo "# Upgrading Vanguards..."
        sudo -u ${DATA_DIR_OWNER} git -C ${DATA_DIR}/vanguards pull -p
        sudo -u ${DATA_DIR_OWNER} git -C ${DATA_DIR}/vanguards reset --hard ${VANGUARDS_COMMIT_HASH}
        sudo -u ${DATA_DIR_OWNER} git -C ${DATA_DIR}/vanguards show
        success_msg
      ;;
      remove)
        echo "# Removing Vanguards..."
        sudo rm -rf ${DATA_DIR}/vanguards
        success_msg
      ;;
      logs)
        sudo tail -f -n 25 /var/log/tor/vanguards.log
      ;;
      *)
        error_msg
    esac
  ;;

  *)
    error_msg

esac
