#!/usr/bin/env sh
# shellcheck disable=SC2034

## Define default values and functions


###################
#### VARIABLES ####

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

## display error message with instructions to use the script correctly.
notice(){ printf %s"${1}\n"; }
error_msg(){ notice "${red}error: ${1}${nocolor}" 1>&2; exit 1; }

## : ${var:="value"} -> initialize the variable (SC2154) and if empty or unset, use default values
## var=${var%*/} -> removes the trailing slash "/" at the end of directories variables

## system
: "${su_cmd:="sudo"}"
: "${openssl_cmd:="openssl"}"
: "${webserver:="nginx"}"
: "${webserver_conf:="/etc/nginx/sites-enabled"}"
: "${website_dir:="/var/www"}"; website_dir="${website_dir%*/}"
: "${vanguards_commit:="10942de93f6578f8303f60014f34de2fca345545"}"

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
: "${tor_control_port:="9051"}" ## only the port, not the host
: "${tor_backup_dir:="/var/lib/onionjuggler/backup"}"; tor_backup_dir="${tor_backup_dir%*/}"
: "${tor_hiddenserviceport_target_addr:="127.0.0.1"}"


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
  ## assign
  value="${arg}"
  ## Escaping quotes is needed because else it will fail if the argument is quoted
  # shellcheck disable=SC2140
  eval "${1}"="\"${value}\""

  ## shift positional argument two times, as this option demands argument, unless they are separated by equal sign '='
  ## shift_n default value was assigned when trimming hifens '--' from the options
  ## if shift_n is equal to zero, '--option arg'
  ## if shift_n is not equal to zero, '--option=arg'
  [ -z "${shift_n}" ] && shift_n=2
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

## 1. source default configuration file first
## 2. source local (user made) configuration files to override the default values
source_conf(){
  test -f /etc/onionjuggler/onionjuggler.conf || error_msg "Default configuration file not found: /etc/onionjuggler/onionjuggler.conf"
  for file in /etc/onionjuggler/onionjuggler.conf /etc/onionjuggler/conf.d/*.conf; do
    test -r "${file}" && . "${file}"
  done
}

## block plugins that are not enabled if any is configured
check_plugin_enabled(){
  if [ -n "${onionjuggler_plugin}" ]; then
    plugin="${1##*onionjuggler-cli-}"
    printf '%s\n' "${onionjuggler_plugin}" | tr "," " " | tr -s " " | tr " " "\n" | grep -q -- "^${plugin}$" \
    || error_msg "Plugin '${plugin}' is disabled in settings"
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

## error_msg self explanatory, tor breaks with special chars on the dir name
check_service_name(){
  [ "${service%%*[^a-zA-Z0-9_.-]*}" ] || {
  error_msg "Service name \"${service}\" is invalid\nIt must only contain the characters that are:
  - letters (a-z A-Z)
  - numbers (0-9)
  - punctuations limited to hifen (-), underscore (_), dot (.)"
  }
}

## Elegantly modify files on a temporary directory. Test the configuration with another function.
## If correct, then save file back to its original location. This avoids running with an invalid
## configuration that can make a daemon fail to reload or even start
## Limitation is file name cannot start with a number.
## $ safe_edit tmp variable
## $ safe_edit tmp tor_conf
## modify the "${tor_conf_tmp}"
## use the daemon option to verify config -f "${tor_conf_tmp}"
## $ safe_edit save tor_conf
safe_edit(){
  [ -w "${TMPDIR:="/tmp"}" ] || export TMPDIR="~"
  TMPDIR="${TMPDIR%*/}"
  key="${2}"
  eval file="$(printf '%s\n' '$'"${key}")"
  case "${1}" in
    tmp)
      file_name_tmp="$(mktemp "${TMPDIR}/${file##*/}.XXXXXX")"
      notice "Saving a copy of ${file} to ${file_name_tmp}"
      chown "${tor_conf_user_group}" "${file_name_tmp}"
      ## copy preserving mode
      cp -p "${file}" "${file_name_tmp}"
      ## assign variable_tmp
      eval "${key}"_tmp="${file_name_tmp}"
      # shellcheck disable=SC2064
      trap "printf %s\"Exiting script ${me}\nDeleting ${file_name_tmp}\n\"; rm -f ${file_name_tmp}" EXIT INT TERM
    ;;
    save)
      ## get variable_tmp file
      eval file_name_tmp='$'"${key}_tmp"
      if cmp -s "${file_name_tmp}" "${file}"; then
        notice "File ${file_name_tmp} do not differ from ${file}"
        notice "Not writing back to original location.${nocolor}"
        rm -f "${file_name_tmp}"
      else
        notice "Moving ${file_name_tmp} back to its original location ${file}"
        mv "${file_name_tmp}" "${file}"
      fi
    ;;
  esac
}


## Verify tor configuration of the temporary file and if variable is empty, use the main configuration, if wrong, exit.
verify_config_tor(){
  config="${tor_conf_tmp:-"${tor_conf}"}"
  ## if User is set on the config, then run tor as root
  grep -q "^User" "${config}" && su_tor_cmd="${su_cmd}"
  ## user may not be on this config, but on another, so run tor as its user if $su_tor_cmd is empty
  : "${su_tor_cmd:="${su_cmd} -u ${tor_user}"}"
  notice "Verifying tor configuration file ${config}"
  ! ${su_tor_cmd} tor -f "${config}" --verify-config --hush && error_msg "aborting: configuration is invalid"
  notice "${green}Configuration OK${nocolor}"
  [ -n "${tor_conf_tmp}" ] && safe_edit save tor_conf
}


## TODO: vinculate with verify_config_tor()
## TODO: parse this with the modified file and without the original one
## get files tor will read
read_tor_files(){
  if test -f /lib/systemd/system/tor@default.service; then
    tor_start_command="$(grep "ExecStart=" /lib/systemd/system/tor@default.service | sed "s/ExecStart=//")"
  elif test -f /lib/systemd/system/tor.service; then
    tor_start_command="$(grep "ExecStart=" /lib/systemd/system/tor.service | sed "s/ExecStart=//")"
  fi
  tor_verify_config_output="$(${tor_start_command:="tor"} --verify-config)"
  tor_config_files="$(printf '%s\n' "${tor_verify_config_output}" |  grep -E " Read configuration file [^ ]*| Including configuration file [^ ]*" | awk '{print $NF}' | sed "s/\"//;s/\".//;s/\/\//\//" | tr "\n" " ")"
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


## returns 1 if is not empty
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
  onion_hostname=$(grep ".onion" "${tor_data_dir_services}"/"${service}"/hostname 2>/dev/null)
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
  [ -n "${client_name_list}" ] && client_name_list="$(printf '%s\n' "${client_name_list}" | tr "\n" "," | sed "s/\,$//" | sed "s/^,//")"
  client_count=""
  # shellcheck disable=SC2086
  [ -n "${client_name_list}" ] && client_count="$(IFS=','; set -f -- ${client_name_list}; printf %s"${#}")"
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
