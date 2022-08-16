#!/usr/bin/env sh
# shellcheck disable=SC2034

## Define default values and functions


###################
#### VARIABLES ####

## don't change here, automatically set by configure.sh
version="0.0.1"

## colors
nocolor="\033[0m"
bold="\033[1m"
#nobold="\033[22m"
underline="\033[4m"
nounderline="\033[24m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
## signals
get_intr="$(stty -a | sed -n '/.*intr = / {s///;s/;.*$//;p;}')"


###############################
########### getopt ############

## this getopts might seem complex, so check this template
##  https://github.com/nyxnor/scripts/blob/master/getopts.sh

## check if argument is within range
## usage:
## $ range_arg key "1-5"
## $ range_arg key "1" "2" "3" "4" "5"
## $ range_arg key "a-cA-C"
## $ range_arg key "a" "b" "c" "A" "B" "C"
range_arg(){
  list="${*}"
  eval var='$'"${1}"
  range="${list#"${1} "}"
  if [ -n "${var:-}" ]; then
    success=0
    for tests in ${range}; do
      ## it needs to expand for ranges 'a-z' to be evaluated, and not considered as a value to be used
      # shellcheck disable=SC2295
      [ "${var%%*[^${tests}]*}" ] && success=1
    done
    ## if not withing range, fail and show the fixed range that can be used
    [ ${success} -ne 1 ] && error_msg "Option '${opt_orig}' can not be '${var}'! It can only be: ${range}."
  fi
}

## if option requires argument, check if it was provided, if yes, assign the arg to the opt
## $arg was already assigned, and if valid, will use it for the key value
## usage: get_arg key
get_arg(){
  ## if argument is empty or starts with '-', fail as it possibly is an option
  case "${arg}" in ""|-*) error_msg "Option '${opt_orig}' requires an argument.";; esac
  set_arg "${1}" "${arg}"

  ## shift positional argument two times, as this option demands argument, unless they are separated by equal sign '='
  ## shift_n default value was assigned when trimming hifens '--' from the options
  ## if shift_n is equal to zero, '--option arg'
  ## if shift_n is not equal to zero, '--option=arg'
  [ -z "${shift_n}" ] && shift_n=2
}

## single source to set getopts so it can later be used to print the options parsed
set_arg(){
  ## Escaping quotes is needed because else it will fail if the argument is quoted
  # shellcheck disable=SC2140
  eval "${1}"="\"${2}\""
  ## variable used for --getopt
  if test -z "${arg_saved}"; then
    arg_saved="${1}=\"${2}\""
  else
    arg_saved="${arg_saved}\n${1}=\"${2}\""
  fi
}

## '--option=value' should shift once and '--option value' should shift twice
## but at this point it is not possible to be sure if option requires an argument
## reset shift to zero, at the end, if it is still 0, it will be assigned to one
## has to be zero here so we can check later if option argument is separated by space ' ' or equal sign '='
clean_opt(){
  case "${opt_orig}" in
    --) shift 1; return 1;; ## stop option parsing
    --*=*) opt="${opt_orig%=*}"; opt="${opt#*--}"; arg="${opt_orig#*=}"; shift_n=1;; ## long option '--sleep=1'
    -*=*) opt="${opt_orig%=*}"; opt="${opt#*-}"; arg="${opt_orig#*=}"; shift_n=1;; ## short option '-s=1'
    --*) opt="${opt_orig#*--}"; arg="${arg_possible}";; ## long option '--sleep 1'
    -*) opt="${opt_orig#*-}"; arg="${arg_possible}";; ## short option '-s 1'
    "") return 1;; ## options ended
    *) usage;; ## not an option
  esac
}


###################
#### FUNCTIONS ####

## display error message with instructions to use the script correctly.
notice(){ printf %s"${1}\n"; }
error_msg(){ notice "${red}error: ${1}${nocolor}" 1>&2; exit 1; }

## helper for --getconf
get_conf_values(){
  for key in openssl_cmd webserver webserver_conf website_dir requirements \
  tor_daemon tor_user tor_conf_dir tor_conf_user_group tor_conf tor_data_dir tor_data_dir_services tor_data_dir_auth \
  tor_hiddenserviceport_target_addr; do
    eval val='$'"${key}"
    test -n "${val}" && printf '%s\n' "${key}=\"${val}\""
  done
}

## only called after source_conf
set_default_conf_values(){
  ## : ${var:="value"} -> initialize the variable (SC2154) and if empty or unset, use default values
  ## var=${var%*/} -> removes the trailing slash "/" at the end of directories variables

  ## system
  : "${openssl_cmd:="openssl"}"
  : "${webserver:="nginx"}"
  : "${webserver_conf:="/etc/nginx/sites-enabled"}"
  : "${website_dir:="/var/www"}"; website_dir="${website_dir%*/}"

  ## tor defaults
  : "${daemon_control:="systemctl"}"; daemon_control="${daemon_control%*/}"
  : "${tor_daemon:="tor@default"}"
  : "${tor_user:="debian-tor"}"
  : "${tor_conf_user_group:="root:root"}"
  : "${tor_data_dir:="/var/lib/tor"}"; tor_data_dir="${tor_data_dir%*/}"
  : "${tor_data_dir_services:="${tor_data_dir}/services"}"; tor_data_dir_services="${tor_data_dir_services%*/}"
  : "${tor_data_dir_auth:="${tor_data_dir}/onion_auth"}"; tor_data_dir_auth="${tor_data_dir_auth%*/}"
  : "${tor_conf_dir:="/etc/tor"}"; tor_conf_dir="${tor_conf_dir%*/}"
  : "${tor_conf:="${tor_conf_dir}/torrc"}"
  : "${tor_hiddenserviceport_target_addr:="127.0.0.1"}"
}

## 1. source default configuration file first
## 2. source local (user made) configuration files to override the default values
## 3. set default values for empty variables
source_conf(){
  test -f /etc/onionjuggler/onionjuggler.conf || error_msg "Default configuration file not found: /etc/onionjuggler/onionjuggler.conf"
  for file in /etc/onionjuggler/onionjuggler.conf /etc/onionjuggler/conf.d/*.conf; do
    ## not sourcing file directly to avoid running commands
    ## also us"eful to save variables to a list to be later printed
    conf_filtered="/tmp/onionjuggler.conf.read"
    grep -v -e "^[[:space:]]*\#" -e "^[[:space:]]*$" "${file}" | tee "${conf_filtered}" >/dev/null
    #printf '%s\n' "${conf_read}" | while IFS='=' read -r key val; do
    while IFS='=' read -r key val; do
       test -n "${key}" && eval "${key}"="${val}"
    done < "${conf_filtered}"
  done
  rm -f "${conf_filtered}"
  set_default_conf_values
}

## block plugins that are not enabled if any is configured
check_plugin_enabled(){
  if [ -n "${onionjuggler_plugin}" ]; then
    printf '%s\n' "${onionjuggler_plugin}" | tr "," " " | tr -s " " | tr " " "\n" | \
    grep -q -- "^${1##*onionjuggler-cli-}$" || return 1
  fi
}

## This is just a simple wrapper around 'command -v' to avoid
## spamming '>/dev/null' throughout this function. This also guards
## against aliases and functions.
## https://github.com/dylanaraps/pfetch/blob/pfetch#L53
has() {
  _cmd="$(command -v "${1}")" 2>/dev/null || return 1
  [ -x "${_cmd}" ] || return 1
}


## http://sed.sourceforge.net/local/docs/emulating_unix.txt
## tac is not posix
tac(){
  sed '1!G;h;$!d' "${1}"
}

## 'cat -s' is not posix
cat_squeeze_blank(){
  while :; do
    case "${1}" in
        "/"*|[[:alnum:]]*) files="${files} ${1}"; shift;; ## only consider path starting with "/" or alphanumeric
        *) break;; ## made to break on pipes and everything else
    esac
  done
  # shellcheck disable=SC2086
  sed '1s/^$//p;/./,/^$/!d' ${files}
}

## block names with special characters
## usage: check_name service
## where service is a variable with a value already assigned
check_name(){
  key="${1}"
  eval val='$'"${key}"
  [ "${val%%*[^a-zA-Z0-9_.-]*}" ] || error_msg "${key}=\"${val}\" is invalid, must only contain letters, numbers, hifen, underscore and dot"
  echo "${val}" | cut -c 1 | grep -qF "." && error_msg "${key} can not start with dot"
}

## check if option has value, if not, error out
## this is intended to be used with required options
check_opt_filled(){
  key="${1}"
  eval val='$'"${key}"
  test -n "${val}" || error_msg "${key} is missing"
}

## Elegantly modify files. Test the configuration with another function.
## Original file will be hidden with a preceding dot in its name.
## Temporary file will have a temporary name to be easily identified.
## If parsing is correct, then save file back to its original location.
## This avoids running with an invalid
## configuration that can make a daemon fail to reload or even start
## $ safe_edit tmp variable
## $ safe_edit tmp tor_conf
## modify the "${tor_conf_tmp}"
## use the daemon option to verify config -f "${tor_conf_tmp}"
## $ safe_edit save tor_conf
safe_edit(){
  key="${2}"
  safe_edit_keys_parsed="${safe_edit_keys_parsed} ${key}"
  eval file="$(printf '%s\n' '$'"${key}")"
  case "${1}" in
    tmp)
      file_dir="${file%/*}"
      file_name="${file##*/}"
      echo "${file_name}" | grep -qF "." && file_suffix="${file_name##*.}"
      file_dot_tmp="${file_dir}/.${file_name}-orig"
      file_tmp_pattern="${file_name}.XXXXX"
      test -n "${file_suffix}" && file_tmp_pattern="${file_tmp_pattern}.${file_suffix}"
      file_name_tmp="$(mktemp "${file_dir}/${file_tmp_pattern}")"
      notice "Saving a copy of ${file} to ${file_name_tmp}"
      chown "${tor_conf_user_group}" "${file_name_tmp}"
      ## create an empty file if not existent
      test -f "${file}" || touch "${file}"
      ## copy preserving mode
      cp -p "${file}" "${file_name_tmp}"
      ## tor won't parse a hidden file
      notice "Moving original file ${file} to ${file_dot_tmp}"
      mv "${file}" "${file_dot_tmp}"
      ## delete temp file. Also, if the hidden file still exists, means it wasn't saved,
      ## so move it back to original location.
      exit_remove_file="${exit_remove_file} ${file_name_tmp}"
      exit_restore_file="${exit_restore_file} ${file_dot_tmp} ${file_dir}/${file_name}"
      ## assign variable_tmp
      eval "${key}"_tmp="${file_name_tmp}"
      eval "${key}"_dot_tmp="${file_dot_tmp}"
    ;;
    save)
      for key in ${safe_edit_keys_parsed}; do
        eval file="$(printf '%s\n' '$'"${key}")"
        eval file_name_tmp='$'"${key}_tmp"
        if cmp -s "${file_name_tmp}" "${file_dot_tmp}"; then
          notice "File ${file_name_tmp} does not differ from ${file_dot_tmp}"
          notice "Not writing back tmp file to original location${nocolor}"
          rm -f "${file_name_tmp}"
          notice "Restoring original file that was mde hidden ${file_dot_tmp} to ${file}"
          mv "${file_dot_tmp}" "${file}"
        else
          notice "File ${file_name_tmp} differs from ${file_dot_tmp}"
          notice "Moving temporary ${file_name_tmp} back to its original location ${file}"
          mv "${file_name_tmp}" "${file}"
          notice "Removing original file that was made hidden ${file_dot_tmp}"
          rm -f "${file_dot_tmp}"
        fi
      done
    ;;
  esac

  trap 'trap_exit_all' EXIT INT QUIT TERM
}


# shellcheck disable=SC2086
trap_exit_all(){
  trap_exit_restore ${exit_restore_file}
  rm -fv ${exit_remove_file}
}


## helper for restoring files
trap_exit_restore(){
  while test -n "${1}" && test -n "${2}"; do
    orig_copy="${1}"
    orig_place="${2}"
    test -f "${orig_copy}" && notice "Restoring ${orig_copy} to ${orig_place}" && mv "${orig_copy}" "${orig_place}"
    shift
  done
}


## Verify tor configuration of the temporary file and if variable is empty, use the main configuration, if wrong, exit.
verify_config_tor(){
  notice "Verifying tor configuration"
  read_tor_files
  ! ${tor_start_command:="tor"} --verify-config --hush && error_msg "aborting: configuration is invalid"
  notice "${green}Configuration OK${nocolor}"
  ## as configuration is ok, move modified file with temp name to correct original name
  ## remove original hidden file
  safe_edit save
}


## get files tor will read
read_tor_files(){
  if test -f /lib/systemd/system/tor@default.service; then
    tor_start_command="$(grep "ExecStart=" /lib/systemd/system/tor@default.service | sed "s/ExecStart=//")"
  elif test -f /lib/systemd/system/tor.service; then
    tor_start_command="$(grep "ExecStart=" /lib/systemd/system/tor.service | sed "s/ExecStart=//")"
  fi
  ## verify tor confgiuration just to grep which files were included
  tor_verify_config_output="$(${tor_start_command:="tor"} --verify-config)"
  tor_config_files="$(printf '%s\n' "${tor_verify_config_output}" |  grep -E " Read configuration file [^ ]*| Including configuration file [^ ]*" | sed "s/.* //" | cut -d "\"" -f2 | tr "\n" " ")"
}


## set correct permissions for tor directories and files
## find helps do the job because it can segreggate directories from files
set_owner_permission(){
  ## data
  chown -R "${tor_user}:${tor_user}" "${tor_data_dir}"
  find "${tor_data_dir}" -type d -exec chmod 700 {} \;
  find "${tor_data_dir}" -type f -exec chmod 600 {} \;
  ## conf
  chown -R "${tor_conf_user_group}" "${tor_conf_dir}"
  find "${tor_conf_dir}" -type d -exec chmod 755 {} \;
  find "${tor_conf_dir}" -type f -exec chmod 644 {} \;
}


# reloads tor by default or forces to restart if $1 is not empty
# shellcheck disable=SC2120
signal_tor(){
  verify_config_tor
  set_owner_permission
  ## default signal is to reload, but if restart was specified, use it
  : "${signal:="reload"}"
  [ "${signal}" = "r" ] && signal="reload"
  [ "${signal}" = "R" ] && signal="restart"
  printf "\n"
  notice "${signal}ing tor, please be patient."
  notice "Process hanged? Press (${get_intr}) to abort and maintain previous configuration."
  case "${daemon_control}" in
    systemctl|sv|rcctl) "${daemon_control}" "${signal}" "${tor_daemon}";;
    service) "${daemon_control}" "${tor_daemon}" "${signal}";;
    /etc/rc.d) "${daemon_control}"/"${tor_daemon}" "${signal}";;
    *) error_msg "daemon_control value not supported: ${daemon_control}"
  esac
  [ "${?}" -eq 1 ] && error_msg "Failed to ${signal} tor. Check logs first, correct the problem them restart tor."
  notice "${green}${signal}ed tor succesfully!${nocolor}"
  printf "\n"
}


## check if variable is integer
is_integer(){ printf %d "${1}" >/dev/null 2>&1 || error_msg "Not an integer: ${1}" ; }


## checks if the target is valid.
## Address range from 0.0.0.0 to 255.255.255.255. Port ranges from 0 to 65535
## this is not perfect but it is better than nothing
is_addr_port(){
  addr_port="${1}"
  port="${addr_port##*:}"
  addr="${addr_port%%:*}"

  printf %d "${port}" >/dev/null 2>&1 || error_msg "'${port}' is not a valid port, not an integer"
  { [ "${port}" -gt 0 ] && [ "${port}" -le 65535 ]; } || \
    error_msg "${port} is not a valid port, not within range: 0-65535"

  for quad in $(printf '%s\n' "${addr}" | tr "." " "); do
    printf %d "${quad}" >/dev/null 2>&1 || error_msg "${addr} is not a valid address, ${quad} is not and integer"
    { [ "${quad}" -ge 0 ] && [ "${quad}" -le 255 ]; } || \
      error_msg "${addr} is not a valid address, ${quad} is not within range: 0-255"
  done
}


## returns 1 if not empty
## returns 0 if empty
## no better way to do with posix utilities
check_folder_is_not_empty(){
  dir="${1}"
  if [ -d "${dir}" ] && files=$(ls -qAH -- "${dir}") && [ -z "${files}" ]; then
    return 1
  else
    return 0
  fi
}


is_service_dir_empty(){
  check_folder_is_not_empty "${tor_data_dir_services}" || error_msg "Onion services directory is empty. Create a service first before running this command again."
}


## test if service exists to continue the script or output error logs.
## if the service exists, will save the hostname for when requested.
test_service_exists(){
  service="${1}"
  onion_hostname=$(grep -F ".onion" "${tor_data_dir_services}/${service}/hostname" 2>/dev/null)
  [ -z "${onion_hostname}" ] && error_msg "Service does not exist: ${service}"
}


## save the clients names that are inside the <HiddenServiceDir>/authorized_clients/ in list format (CLIENT1,CLIENT2,...)
create_client_list(){
  service="${1}"
  client_name_list=""
  for client_listed in "${tor_data_dir_services}/${service}/authorized_clients"/*; do
    client_listed="${client_listed##*/}"
    [ "${client_listed}" = "*" ] && break
    client_listed="${client_listed%*.auth}"
    client_name_list="$(printf '%s\n%s\n' "${client_name_list}" "${client_listed}")"
  done
  [ -n "${client_name_list}" ] && client_name_list="$(printf '%s\n' "${client_name_list}" | tr "\n" "," | sed "s/\,$//;s/^,//")"
  client_count=""
  # shellcheck disable=SC2086
  [ -n "${client_name_list}" ] && client_count="$(IFS=','; set -f -- ${client_name_list}; printf %s"${#}")"
}

## save <ClientOnionAuthDir> files in list format (CLIENT1,CLIENT2,...)
create_client_priv_list(){
  client_name_priv_list=""
  for client_listed in "${tor_data_dir_auth}"/*; do
    client_listed="${client_listed##*/}"
    [ "${client_listed}" = "*" ] && break
    client_listed="${client_listed%*.auth_private}"
    client_name_priv_list="$(printf '%s\n%s\n' "${client_name_priv_list}" "${client_listed}")"
  done
  [ -n "${client_name_priv_list}" ] && client_name_priv_list="$(printf '%s\n' "${client_name_priv_list}" | tr "\n" "," | sed "s/\,$//;s/^,//")"
  client_count=""
  # shellcheck disable=SC2086
  [ -n "${client_name_priv_list}" ] && client_priv_count="$(IFS=','; set -f -- ${client_name_priv_list}; printf %s"${#}")"
}


## save the service names that have a <HiddenServiceDir> in list format (SERV1,SERV2,...)
create_service_list(){
  for hs in "${tor_data_dir_services}"/*; do
    hs="${hs##*/}"
    service_name_list="$(printf '%s\n' "${service_name_list}" "${hs}")"
  done
}

## loops the parameters
## $1 must be the function to loop
## $2 normally is service, but can be any other parameter (accepts list -> SERV1,SERV2,...)
## $3 normally is client, but can be any other (accepts list -> client1,client2...)
## $ loop_list function_name ssh,xmpp,web [alice,bob]
loop_list(){
  for item in $(printf %s"${2}" | tr "," " "); do
    case "${3}" in
      "") "${1}" "${item}";;
      *) for subitem in $(printf %s"${3}" | tr "," " "); do "${1}" "${item}" "${subitem}"; done;;
    esac
  done
}

## https://github.com/koalaman/shellcheck/wiki/SC3050
escape_printf_percent() { printf "%s\n" "$(printf '%s' "${1}" | sed "s/\%/\%/g")"; }


## TODO: find a better way to handle commented lines and empty lines
## the problem is that the script only stop at the next HiddenServiceDir,
## but discard every line not starting with HiddenServiceDir
## https://github.com/nyxnor/onionjuggler/issues/51
service_block(){
  process="${1}"
  service="${2}"
  file="${3:-"${tor_conf_tmp}"}"
  i=0
  ## print the exact match HiddenServiceDir of the requested service that must end with the service name or with "/", also prit n lines below it
  match="HiddenServiceDir ${tor_data_dir_services}/${service}"
  hs_found=""
  hs_lines_delete=""
  while IFS="$(printf '\n')" read -r line; do
    [ -z "${hs_found}" ] && printf '%s\n' "${line}" | grep -q -E "^${match}$|^${match}/$" && hs_found="1"
    if [ "${hs_found}" = "1" ]; then
      i=$((i+1))
      case "${line}" in
        "HiddenServiceStatistics"*) :;; ## relays only
        "HiddenService"*)
          ## break on next HiddenService configuration
          { [ ${i} -gt 1 ] && [ "${line%% *}" = "HiddenServiceDir" ]; } && break
          case "${process}" in
            print|printf) printf '%s\n' "${line}";;
            delete)
              ## delete only works if hs lines are consecutive,
              ## meaning no blank lines or commented lines between the wanted hs
              if [ -z "${hs_lines_delete}" ]; then
                hs_lines_delete="$(printf '%s\n' "${line}")"
              else
                hs_lines_delete="$(printf '%s\n%s\n' "${hs_lines_delete}" "${line}")"
              fi
              ;;
          esac
        ;;
      esac
    fi
  done < "${file}"

  if [ -n "${hs_lines_delete}" ]; then
    ## sed is a stream line editor, so lets make the file a single line transforming new lines to carriage return
    hs_lines_delete="$(printf '%s\n' "${hs_lines_delete}" | tr "\n" "\r")"
    ## then convert the file also as done above, so sed can see the file and pattern on the same format
    tr "\n" "\r" < "${file}" | sed "s|${hs_lines_delete}||" | tr "\r" "\n" | tee tmpfile >/dev/null
    mv tmpfile "${file}"
  fi
}

## TODO: finish: https://github.com/nyxnor/onionjuggler/issues/32
httpd_service_block(){
  process="${1}"
  service="${2}"
  file="${3:-"/etc/httpd.conf"}"
  i=0
  test_service_exists "${service}"
  grep -A 10 "server \"${onion_hostname}\"" "${file}"  | while IFS= read -r line; do
    case "${process}" in
      print|printf) escape_printf_percent "${line}";;
      delete) [ -n "${line}" ] && sed -i'' "s|${line}||" "${file}";;
    esac
    escape_printf_percent "${line}" | grep -q "^}" && break
  done
  cat_squeeze_blank "${file}"
}


## generate key pairs for client authorization
gen_auth_key_pair(){
  ## Generate pem and derive pub and priv keys
  "${openssl_cmd}" genpkey -algorithm x25519 -out /tmp/k1.prv.pem
  grep -v " PRIVATE KEY" /tmp/k1.prv.pem | base64pem -d | tail -c 32 | base32 | sed "s/=//g" > /tmp/k1.prv.key
  "${openssl_cmd}" pkey -in /tmp/k1.prv.pem -pubout | grep -v " PUBLIC KEY" | base64pem -d | tail -c 32 | base32 | sed "s/=//g" > /tmp/k1.pub.key
  ## save variables
  client_pub_key=$(cat /tmp/k1.pub.key)
  client_priv_key=$(cat /tmp/k1.prv.key)
  client_priv_key_config="${onion_hostname%.onion}:descriptor:x25519:${client_priv_key}"
  client_pub_key_config="descriptor:x25519:${client_pub_key}"
  ## Delete pem and keys
  rm -f /tmp/k1.pub.key /tmp/k1.prv.key /tmp/k1.prv.pem
}


###############################
############ main #############
#source_conf
set_default_conf_values

