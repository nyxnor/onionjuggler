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
## Syntetic exaplanation for bit brains:
##   on          --> create torrc config, tor will create HiddenServiceDir
##   off         --> delete torrc config, optionally purge service inside DataDir
##   renew       --> remove <HiddenServiceDir>/* (contents: keys, hostname, authorized_clients)
##   auth        --> <HiddenServiceDir>/authorized_clients/ or <ClientOnionAuthDir>/
##   credentials --> qrencode -m 2 -t ANSIUTF8 <HiddenServiceDir>/hostname
##
## Changes applied to X modify Y:
##   on              <torrc> and consequentially <HiddenServiceDir>/ if not existent
##   off             <torrc> and optionally <HiddenServiceDir>/
##   renew:          <HiddenServiceDir>/
##   auth-server-*   <HiddenServiceDir>/authorized_clients/
##   auth-client-*   <torrc> once and <ClientOnionAuthDir>/
##   credentials     null
##
## command info
if [[ $# -eq 0 || -z ${2} || "$1" = "-h" || "$1" = "-help" || "$1" = "--help" ]]; then
  echo "Configure an Onion Service

Usage: bash ${0} COMMAND [REQUIRED] <OPTIONAL>

Options:

  man 1                                                           read the manual, you will need it

  on tcp-socket [SERV] [VIRTPORT] <TARGET> <VIRTPORT2> <TARGET2>  activate a service targeting tcp socket

  on unix-socket [SERV] [VIRTPORT] <VIRTPORT2>                    activate a service targeting unix socket

  off [SERV1,SERV2,...] <purge>                                   deactivate a service and optionally
                                                                    purge data
  renew [all-services|SERV1,SERV2,...]                            renew indicated services or
                                                                    all-services addresses
  auth-server-[on|off] [SERV1,SERV2,...] [CLIENT1,CLIENT2,...]    add or delete client keys from indicated
                                                                    services
  auth-server-purge [all-services|SERV1,SERV2,...]                delete all client keys from indicated
                                                                    services or all-services
  auth-client-on [AUTH_FILE] [AUTH_PRIV_KEY]                      add your client key

  auth-client-off [AUTH_FILE1,AUTH_FILE2,...]                     delete your client key

  credentials [all-services|SERV1,SERV2,...]                      see credentials from indicated services

  onion-location [SERV]                                           only guide, not execution

  backup [export|import]                                          create backup and export to remote host or
                                                                    import backup from remote host and
                                                                    integrate the new configuation

'# Done': You should always see it at the end, else something unexpected occured.
It does not imply the code worked, you should always pay attention for errors in the logs."
  exit 1
fi


###########################
######## FUNCTIONS ########

## include lib
. onion.lib

#clear
fail_log=0
var_not_integer=0
valid_addr_port=0
COMMAND="${1}"
SERVICE="${2}"

## check if variable is integer
is_integer(){
  if [[ ${1} =~ ^-?[0-9]+$ ]]; then
    echo "Variable is integer: ${1}"
  else
    echo "Variable must be an integer: ${1}"
    fail_log=1
  fi
}

## checks if the TARGET is valid.
## Address range from 0.0.0.0 to 255.255.255.255. Port ranges from 0 to 65535
## accept localhos:port if port is valid.
is_addr_port(){
  ADDR=$(echo "${1}" | cut -d ':' -f1)
  PORT=$(echo "${1}" | cut -d ':' -f2)
  DEFINED_VAR="${2}"
  if [ "${ADDR}" == "${PORT}" ]; then fail_log=1
  elif [ "${ADDR}" == "localhost" ]; then
    if [[ "${PORT}" =~ ^-?[0-9]+$ ]] && [[ ${PORT} -gt 0 && ${PORT} -le 65535 ]]; then
      valid_addr_port=1; else fail_log=1; fi
  else
    ## port must be integer, 0 < port <= 65535
    if [[ "${PORT}" =~ ^-?[0-9]+$ && ${PORT} -gt 0 && ${PORT} -le 65535 \
      ## addr must be integer, 0 < addr <=255
      && "${ADDR}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
      valid_addr_port=1; else fail_log=1; fi
  fi

  if [ ${valid_addr_port} -eq 1 ]; then
    echo "Valid 'addr:port': ${DEFINED_VAR}=${ADDR}:${PORT}"
  else
    echo "Invalid 'addr:port': ${DEFINED_VAR}=${ADDR}:${PORT}"
    fail_log=1
  fi
}

## display error message with instructions to use the script correctly.
## fail_log=1 makes the script abort after checking all of the variables.
error_msg(){
  if [ ${#1} -gt 0 ]; then
    echo "ERROR: ${1} missing"
  fi
  echo "Invalid command!"
  echo "See instructions for this script with:"
  echo "  bash ${0} --help"
  echo "See manual for this sotware with:"
  echo "  man ./onion-cli-manual"
  fail_log=1
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
  read -n 1 -s -r -p "Press any key to continue"
  echo
  exit 1
}


## test if service exists to continue the script or output error logs.
## if the service exists, will save the hostname for when requested.
test_service_exists(){
  SERVICE="${1}"
  ADDRESS_EXISTS=$(sudo -u ${OWNER_DATA_DIR} cat ${SERVICES_DATA_DIR}/${SERVICE}/hostname 2>/dev/null | grep -c ".onion")
  if [ ${ADDRESS_EXISTS} -eq 0 ]; then
    echo "ERROR: Could not locate hostname file for the service ${SERVICE}"
    service_existent=0
  else
    TOR_HOSTNAME=$(sudo -u ${OWNER_DATA_DIR} cat ${SERVICES_DATA_DIR}/${SERVICE}/hostname)
    service_existent=1
  fi
}


## save the clients names that are inside the <HiddenServiceDir>/authorized_clients/
create_auth_list(){
  SERVICE="${1}"
  CLIENT_NAME_LIST=""
  AUTH_NUMBER=0
  for AUTHORIZATION in $(sudo -u ${OWNER_DATA_DIR} ls ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/); do
    AUTHORIZATION_NAME=$(echo "${AUTHORIZATION##*/}" | cut -f1 -d '.')
    CLIENT_NAME_LIST="${CLIENT_NAME_LIST},${AUTHORIZATION_NAME}"
    ((AUTH_NUMBER++))
  done
  CLIENT_NAME_LIST=$(echo ${CLIENT_NAME_LIST} | sed 's/^,//g')
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
## tor does not need to be running to delete service, authorize o remove authorization from clients or see credentials (off, auth, credentials)
#check_tor


sudo -u ${OWNER_DATA_DIR} mkdir -p ${SERVICES_DATA_DIR}
sudo -u ${OWNER_DATA_DIR} mkdir -p ${CLIENT_ONION_AUTH_DIR}
sudo sed -i 's/\/$//' ${TORRC} ## no config should end with '/' to find exact match.

case ${COMMAND} in

  ## show manual
  man)
    man text/onion-cli.man
  ;;

  ## deactivate a service by removing service torrc's block.
  ## it is raw, services variables should be separated by an empty line per service, else you might get other non-related configuration deleted.
  ## purge is optional, it deletes the <HiddenServiceDir>
  off)
    PURGE="${3}"
    delete_service(){
      SERVICE="${1}"
      PURGE="${2}"
      ## remove service service data
      if [ "${purge}" == "purge" ]; then
        echo "# Deleting Hidden Service data of ${SERVICE}"
        sudo rm -rf ${SERVICES_DATA_DIR}/${SERVICE}
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
  ## VIRTPORT is the port to be used by the client when visiting the service
  ## TARGET is where the incoming traffic from VIRTPORT gets redirected. This option is abscent on unix-socket because the script completes it.
  ## VIRTPORT2 and TARGET 2 are optional
  on)
    SOCKET="${2}"
    SERVICE="${3}"
    echo "# Checking if command is valid..."
    if [ "${SOCKET}" == "tcp-socket" ]; then
      ## Required
      VIRTPORT="${4}"; if [ -z ${VIRTPORT} ]; then error_msg "VIRTPORT"; fi
      TARGET="${5}"
      TARGET_ADDR_DOTS=$(echo "${TARGET}" | awk -F '.' '{ print NF - 1 }')
      TARGET_TEXT_LOCALHOST=$(echo "${TARGET}" | cut -d ':' -f1)
      if [ -z ${TARGET} ] || [[ "${TARGET_TEXT_LOCALHOST}" != "localhost" && ${TARGET_ADDR_DOTS} -eq 0 ]]; then TARGET="127.0.0.1:"${VIRTPORT}; fi
      is_integer ${VIRTPORT}; is_addr_port ${TARGET} "TARGET"
      TARGET_ALREADY_INSERTED=$(sudo -u ${OWNER_CONF_DIR} cat ${TORRC} 2>/dev/null | grep -c "\b${TARGET}\b")
      if [ ${TARGET_ALREADY_INSERTED} -eq 1 ]; then error_msg "TARGET=${TARGET} was already inserted"; fi
      ## Optional
      VIRTPORT2="${6}"
      TARGET2="${7}"
      TARGET2_ADDR_DOTS=$(echo "${TARGET2}" | awk -F '.' '{ print NF - 1 }')
      TARGET2_TEXT_LOCALHOST=$(echo "${TARGET2}" | cut -d ':' -f1)
      if [ -z ${TARGET2} ] || [[ "${TARGET2_TEXT_LOCALHOST}" != "localhost" && ${TARGET2_ADDR_DOTS} -eq 0 ]]; then TARGET2="127.0.0.1:"${VIRTPORT2}; fi
      if [ ! -z ${VIRTPORT2} ]; then
        if [ -z ${TARGET2} ]; then TARGET2="127.0.0.1:"${VIRTPORT2}; fi
        is_integer ${VIRTPORT2}; is_addr_port ${TARGET2} "TARGET2"
        if [ "${TARGET}" == "${TARGET2}" ]; then error_msg "TARGET is the same as TARGET2"; fi
        TARGET2_ALREADY_INSERTED=$(sudo -u ${OWNER_CONF_DIR} cat ${TORRC} 2>/dev/null | grep -c "\b${TARGET2}\b")
        if [ ${TARGET2_ALREADY_INSERTED} -eq 1 ]; then error_msg "The TARGET2=${TARGET2} was already inserted"; fi
      fi

    elif [ "${SOCKET}" == "unix-socket" ]; then
      VIRTPORT="${4}"; if [ -z ${VIRTPORT} ]; then error_msg "VIRTPORT"; else is_integer ${VIRTPORT}; fi
      VIRTPORT2="${5}"; if [ ! -z ${VIRTPORT2} ]; then is_integer ${VIRTPORT2}; fi ## var not mandatory
    fi

    if [ ${fail_log} -eq 1 ]||[[ "${SOCKET}" != "tcp-socket" && "${SOCKET}" != "unix-socket" ]]; then
      echo "Check the error message above before running this script again."
    else
      echo

      ## delete any old entry for that servive
      sudo sed -i "/HiddenServiceDir .*\/${SERVICE}$/,/^\s*$/{d}" ${TORRC}

      echo "# Including Hidden Service configuration in ${TORRC}"
      ## add configuration block, empty line after and before it
      if [ "${SOCKET}" == "tcp-socket" ]; then
        if [ -n ${VIRTPORT2} ]; then
          echo -e "\nHiddenServiceDir ${SERVICES_DATA_DIR}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\nHiddenServicePort ${VIRTPORT2} ${TARGET2}" | sudo tee -a ${TORRC}
        else
          echo -e "\nHiddenServiceDir ${SERVICES_DATA_DIR}/${SERVICE}\nHiddenServicePort ${VIRTPORT} ${TARGET}\n" | sudo tee -a ${TORRC}
        fi
      elif [ "${SOCKET}" == "unix-socket" ]; then
        if [ -n ${VIRTPORT2} ]; then
          echo -e "\nHiddenServiceDir ${SERVICES_DATA_DIR}/${SERVICE}\nHiddenServicePort ${VIRTPORT} unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT}.sock\nHiddenServicePort ${VIRTPORT2} unix:/var/run/tor-${SERVICE}-${VIRTPORT2}.sock" | sudo tee -a ${TORRC}
        else
          echo -e "\nHiddenServiceDir ${SERVICES_DATA_DIR}/${SERVICE}\nHiddenServicePort ${VIRTPORT} unix:/var/run/tor-hs-${SERVICE}-${VIRTPORT}.sock\n" | sudo tee -a ${TORRC}
        fi
      fi

      ## remove double empty lines
      awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' ${TORRC} | sudo tee ${TORRC}.tmp >/dev/null && sudo mv ${TORRC}.tmp ${TORRC}
      echo
      echo "# Reloading tor to activate the Hidden Service..."
      PREVIOUS_TIMESTAMP=$(systemctl show tor@default.service --property=StateChangeTimestampMonotonic)
      sudo systemctl reload-or-restart tor@default.service
      # sleep 1
      # CURRENT_TIMESTAMP=$(systemctl show tor@default.service --property=StateChangeTimestampMonotonic)
      # if [ ${CURRENT_TIMESTAMP} -gt ${PREVIOUS_TIMESTAMP} ]; then
      #   echo "# Reloaded succesfully"
      # else
      #   echo "# Failed to reload"
      # fi
      sleep 3

      ## show the Hidden Service address
      service_existent=0; test_service_exists ${SERVICE}
      if [ ! -z ${TOR_HOSTNAME} ]; then
        echo
        echo "# Tor Hidden Service information:"
        echo "Service name    = "${SERVICE}
        echo "Service address = "${TOR_HOSTNAME}
        echo "Virtual port    = "${VIRTPORT}
        if [ ! -z ${VIRTPORT2} ]; then
          echo "Virtual port    = "${VIRTPORT2}
        fi
        success_msg
      fi
    fi
  ;;

  ## as the onion service operator, make your onion authenticated by generating a pair or public and private keys,
  ## the client pub key is automatically saved inside <HiddenServiceDir>/authorized_clients/alice.auth
  ## the client private key is shown in the screen and the key file deleted
  ## the onion service operator should send the private key for the desired client
  auth-server-on)
    CLIENT="${3}"
    ## Install basez if not installed
    echo "# Generating keys to access onion service (Client Authorization) ..."; echo -e "# -> Send this to the client(s):\n"
    command -v openssl >/dev/null || sudo apt install -y openssl
    command -v openssl >/dev/null || sudo apt install -y basez

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
        TORRC_CLIENT_KEY=(${TOR_HOSTNAME_WITHOUT_ONION}":descriptor:x25519:"${PRIV_KEY})
        TORRC_SERVER_KEY=("descriptor:x25519:"${PUB_KEY})
        3# Server side configuration
        echo ${TORRC_SERVER_KEY} | sudo tee ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/${CLIENT}.auth >/dev/null
        ## Client side configuration
        #echo "## Instructions for services available on the Tor Browser:"
        #echo
        #echo "Service  = "${SERVICE}
        #echo "Client   = "${CLIENT}
        #echo "Address  = "${TOR_HOSTNAME}
        #echo "Key      = "${PRIV_KEY}
        #echo "Conf = "${TORRC_CLIENT_KEY}
        #echo
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        echo "# Declare the variables"
        echo "SERVICE="${SERVICE}
        echo "CLIENT="${CLIENT}
        echo "TOR_HOSTNAME="${TOR_HOSTNAME}
        echo "TOR_HOSTNAME_WITHOUT_ONION="${TOR_HOSTNAME_WITHOUT_ONION}
        echo "PRIV_KEY="${PRIV_KEY}
        echo "TORRC_CLIENT_KEY="${TORRC_CLIENT_KEY}
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        echo
        ## Delete pem and keys
        sudo rm -f /tmp/k1.pub.key /tmp/k1.prv.key /tmp/k1.prv.pem
      fi
    }
    instructions_auth(){
        echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        echo -e "\n# Instructions client side:\n"
        echo "# Declare variables for files and directories:"
        CLIENT_TORRC=/etc/tor/torrc
        CLIENT_ONION_AUTH_DIR=/var/lib/tor/onion_auth
        echo "CLIENT_TORRC=/etc/tor/torrc"
        echo "CLIENT_ONION_AUTH_DIR=/var/lib/tor/onion_auth"
        echo
        echo "# Check if ClientOnionAuthDir was configured in \${CLIENT_TORRC}"
        echo "sed -i 's/#ClientOnionAuthDir/ClientOnionAuthDir/g' \${CLIENT_TORRC}"
        echo "if [ \$(grep -c '^ClientOnionAuthDir' ${CLIENT_TORRC}) -eq 0 ]; then ClientOnionAuthDir='\${CLIENT_ONION_AUTH_DIR}'; echo -e '\nClientOnionAuthDir \${ClientOnionAuthDir}\n' | sudo tee -a \${CLIENT_TORRC}"
        echo "else ClientOnionAuthDir=\$(grep 'ClientOnionAuthDir' ${CLIENT_TORRC} | cut -f2 -d ' '); fi"
        echo
        echo "# Create key"
        echo "echo \${TORRC_CLIENT_KEY} | sudo tee -a \${ClientOnionAuthDir}/\${SERVICE}-\${TOR_HOSTNAME_WITHOUT_ONION}.auth_private"
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
  auth-server-off)
    CLIENT="${3}"
    delete_auth(){
      SERVICE="${1}"
      CLIENT="${2}"
      echo "# Removing client authorization:"
      echo "Service  = "${SERVICE}
      echo "Client   = "${CLIENT}
      echo
      sudo rm -f ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/${CLIENT}.auth
    }
    loop_array_dynamic delete_auth ${SERVICE} ${CLIENT} 1
    success_msg reload
  ;;

  ## as the onion service operator, you can purge clients fast to make it available to anyone that has the onion service address
  ##  all clients for chosen service
  ##  all clients from all-services
  auth-server-purge)
    CLIENT="${3}"
    echo "# Removing all clients authorizations from listed services:"
    if [ "${SERVICE}" == "all-services" ]; then
      #sudo rm -f ${SERVICES_DATA_DIR}/*/authorized_clients/*
      for SERVICE in $(sudo -u ${OWNER_DATA_DIR} ls ${SERVICES_DATA_DIR}/); do
        sudo rm -f ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/*
      done
    else
      purge_auth(){
        SERVICE=${1}
        sudo rm -f ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/*
      }
      loop_array_dynamic purge_auth ${SERVICE}
    fi
    echo "Server side client authorization removed"
    echo "You can know access the services without being requested for a key"
    success_msg
  ;;

  ## as the onion service client, add a key given by the onion service operator to authenticate yourself inside ClientOnionAuthDir
  ## just the client name. '.auth_private' should not be mentioned, it will be automatically inserted
  ## private key format must be: <onion-addr-without-.onion-part>:descriptor:x25519:<private-key>
  ## adding to Tor Browser automatically not supported yet
  auth-client-on)
    AUTH_FILE_NAME=${2}
    AUTH_PRIV_KEY=${3}
    echo "${AUTH_PRIV_KEY}" | sudo tee -a ${CLIENT_ONION_AUTH_DIR}/${AUTH_FILE_NAME}.auth_private >/dev/null
    echo "Client side authorization added"
    success_msg
  ;;

  ## as the onion service client, delete '.auth_private' files from ClientOnionAuthDir that are not valid or has no use anymore
  auth-client-off)
    client_auth_remove(){
      AUTH_FILE_NAME=${1}
      sudo rm -f ${CLIENT_ONION_AUTH_DIR}/${AUTH_FILE_NAME}.auth_private
    }
    AUTH_FILE_NAME=${2}
    loop_array_dynamic client_auth_remove ${AUTH_FILE_NAME}
    echo "Client side authorization removed"
    success_msg
  ;;

  ## change service hostname by deleting its ed25519 pub and priv keys.
  ## <HiddenServiceDir>/authorized_clients/ because the would need to update their '.auth_private' file with the new onion address anyway and for security reasons.
  ## all-services will read through all services folders and execute the commands.
  renew)
    renew_service_address(){
      SERVICE="${1}"
      CLIENT_NAME_LIST="${2}"
      echo "# Renewing service ${SERVICE}"
      ## save clients names that are inside <HiddenServiceDir>/authorized_clients/
      create_auth_list ${SERVICE}
      ## delete service public and private keys
      sudo rm -rf ${SERVICES_DATA_DIR}/${SERVICE}/hs_ed25519_*_key
      ## delete authorized clients
      sudo rm -rf ${SERVICES_DATA_DIR}/${SERVICE}/authorized_clients/*
      ## generate auth for clients
      bash ${0} auth-server-on ${SERVICE} ${CLIENT_NAME_LIST}
      echo "# Service renewed."
      echo
    }

    if [ "${SERVICE}" == "all-services" ]; then
      for SERVICE in $(sudo -u ${OWNER_DATA_DIR} ls ${SERVICES_DATA_DIR}/); do
        renew_service_address ${SERVICE}
      done
    else
      loop_array_dynamic renew_service_address ${SERVICE} ${CLIENT} 1
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
      for SERVICE in $(sudo -u ${OWNER_DATA_DIR} ls ${SERVICES_DATA_DIR}/); do
        get_credentials ${SERVICE}
      done
    else
      loop_array_dynamic get_credentials ${SERVICE}
    fi
    success_msg
  ;;

  ## guide to redirect tor users when using your plainnet site to the onion service address
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
      import)

        ## RESTORE
        sudo mkdir -p ${HS_BK_DIR}/backup-restoration.tbx
        sudo tar -xpzvf ${HS_BK_DIR}/*.tar.gz -C ${HS_BK_DIR}/backup-restoration.tbx
        sudo chown -R ${USER}:${USER} ${HS_BK_DIR}/backup-restoration.tbx
        sudo cp -rf ${HS_BK_DIR}/backup-restoration.tbx${SERVICES_DATA_DIR}/* ${SERVICES_DATA_DIR}/ >/dev/null
        sudo cp -rf ${HS_BK_DIR}/backup-restoration.tbx${CLIENT_ONION_AUTH_DIR}/* ${CLIENT_ONION_AUTH_DIR}/ >/dev/null

        ## avoid duplication of services, it will keep the oldest config for safety
        for SERVICE in $(sudo -u ${OWNER_CONF_DIR} cat ${TORRC} | grep "HiddenServiceDir" | cut -d ' ' -f2); do
          SERVICE_NAME=$(echo "${SERVICE##*/}")
          sed -n "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{p}" ${TORRC} > ${TORRC}.tmp
          sed -i "/HiddenServiceDir .*\/${SERVICE_NAME}$/,/^\s*$/{d}" ${TORRC}
          sed '/^\s*$/Q' ${TORRC}.tmp > ${TORRC}.mod
          sudo sed -i '1 i \ ' ${TORRC}.mod; sudo sed -i "\$a\ " ${TORRC}.mod
          sudo cat ${TORRC}.mod | sudo tee -a ${TORRC} >/dev/null
        done
        sudo rm -f ${TORRC}.tmp ${TORRC}.mod
        awk 'NF > 0 {blank=0} NF == 0 {blank++} blank < 2' ${TORRC} | sudo tee ${TORRC}.tmp >/dev/null && sudo mv ${TORRC}.tmp ${TORRC}
        sudo chown -R ${OWNER_CONF_DIR}:${OWNER_CONF_DIR} ${TORRC}

        sudo rm -rf ${HS_BK_DIR}/backup-restoration.tbx
        sudo chown -R ${OWNER_DATA_DIR}:${OWNER_DATA_DIR} ${DATA_DIR}
        sudo chown -R ${OWNER_CONF_DIR}:${OWNER_CONF_DIR} ${ROOT_TORRC}

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

      export)
        ## CREATE

        ## BACKUP ON REMOTE
        echo "# Backup your configuration and export it to a remote machine."
        echo "## Backing up the services dir, onion_auth dir and the torrc"
        echo
        sudo -u ${USER} mkdir -p ${HS_BK_DIR}${ROOT_TORRC}
        sudo -u ${USER} touch ${HS_BK_DIR}${TORRC}
        sudo cp ${TORRC} ${TORRC}.rest
        echo "$(sudo sed -n "/HiddenServiceDir/,/^\s*$/{p}" ${TORRC})" | sudo tee ${TORRC}.tmp >/dev/null
        sudo mv ${TORRC}.tmp ${TORRC}
        sudo tar -cpzvf ${HS_BK_DIR}/${HS_BK_TAR} ${SERVICES_DATA_DIR} ${CLIENT_ONION_AUTH_DIR} ${TORRC} 2>/dev/null
        sudo mv ${TORRC}.rest ${TORRC}
        SHA512SUM=$(sha512sum ${HS_BK_DIR}/${HS_BK_TAR})
        SHA256SUM=$(sha256sum ${HS_BK_DIR}/${HS_BK_TAR})
        sudo chown -R ${USER}:${USER} ${HS_BK_DIR}/${HS_BK_TAR}
        sudo find ${HS_BK_DIR} \! -name ${HS_BK_TAR} -delete 2>/dev/null
        sudo chown -R ${OWNER_DATA_DIR}:${OWNER_DATA_DIR} ${DATA_DIR}
        sudo chown -R ${OWNER_CONF_DIR}:${OWNER_CONF_DIR} ${ROOT_TORRC}
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

  *)
    error_msg

esac
