#!/usr/bin/env sh

## This file should be run from inside the cloned repository
## Setup tor directories, user, packages needed for OnionJuggler.

command -v git >/dev/null || { printf '%s\n' "Missing dependency, please install git"; exit 1; }
git_top_dir="$(git rev-parse --show-toplevel || exit 1)"
me="${0##*/}"
version="$(cat "${git_top_dir}"/version.txt)"

usage(){
  printf %s"Configure the environment for OnionJuggler
Usage: ${me} [--option <ARG>]
Options:
  -b, --build                                 build onionjuggler
  -i, --instal                                copy build to path
  -d, --uninstall [-P, --purge]               remove onionjuggler scripts and manual pages from path
  -V, --version
  -h, --help                                  show this help message
\nDev options:
  -k, --check                                 run pre-defined shellcheck
  -m, --man                                   build manual pages
  -S, --clean                                 remove temporary files
  -r, --release                               prepare for commiting
"
  exit 1
}
[ -z "${1}" ] && usage


###################
#### FUNCTIONS ####

check_repo(){
  if [ "${PWD}" != "${git_top_dir}" ]; then
    error_msg "This script must be run from the root of the onionjuggler repository!"
  fi
}

requires_root(){ [ "$(id -u)" -ne 0 ] && error_msg "run as root"; }

not_as_root(){ [ "$(id -u)" -eq 0 ] && error_msg "do not run this option as root"; }

install_package(){
  install_pkg=""
  for package in "${@}"; do
    case "${package}" in
      openssl) ! command -v "${openssl_cmd}" >/dev/null && package="${openssl_cmd}" && install_pkg="${install_pkg} ${package}";;
      nginx|apache2) if ! command -v "${package}" >/dev/null; then ! "${package}" -v >/dev/null 2>&1 && install_pkg="${install_pkg} ${package}"; fi;;
      openbsd-httpd) :;;
      libqrencode|qrencode) ! command -v qrencode >/dev/null && install_pkg="${install_pkg} ${package}";;
      *) ! command -v "${package}" >/dev/null && install_pkg="${install_pkg} ${package}";;
    esac
  done

  if test -n "${install_pkg}" && [ "${install_pkg}" != " " ]; then
    notice "Missing requirements, maybe try: ${pkg_mngr_install} ${install_pkg}"
  fi
}

make_shellcheck(){
  command -v shellcheck >/dev/null || error_msg "Install shellcheck to review syntax"
  notice "${yellow}Checking shell syntax${nocolor}"
  ## Customize severity with -S [error|warning|info|style]
  if
  ! shellcheck -s sh "${git_top_dir}"/configure.sh "${git_top_dir}"/etc/onionjuggler/*.conf \
    "${git_top_dir}"/etc/onionjuggler/conf.d/*.conf "${git_top_dir}"/usr/bin/* \
    "${git_top_dir}"/usr/share/onionjuggler/* || \
  ! shellcheck -s bash "${git_top_dir}"/usr/share/bash-completion/completions/onionjuggler-*
  then
    error_msg "Please fix the shellcheck warnings above before pushing!"
  fi
}

make_man(){
  command -v pandoc >/dev/null || error_msg "Install pandoc to create manuals"
  notice "${yellow}Setting version ${version}${nocolor}"
  sed -i'' "s/^version=.*/version=\"${version}\"/" "${git_top_dir}/usr/share/onionjuggler/defaults.sh"
  notice "${magenta}Creating manual pages${nocolor}"
  for man in "${git_top_dir}"/man/*; do
    man="${man##*/}"
    ## remove man number (5,8) and file ending (.md)
    man_ref="${man%.*}"; man_ref="${man_ref%.*}"
    pandoc -s -f markdown-smart -V header="Tor's System Manager Manual" -V footer="${man_ref} ${version}" -t man "${git_top_dir}/man/${man}" -o "${git_top_dir}/auto-generated-man-pages/${man%*.md}"
    sed -i'' "s/default_date/$(date +%Y-%m-%d)/" "${git_top_dir}/auto-generated-man-pages/${man%*.md}"
  done
}

range_variable(){
  name="${1}"
  eval var='$'"${1}"
  shift
  if [ -n "${var:-}" ]; then
    success=0
    for tests in "${@}"; do
      [ "${var}" = "${tests}" ] && success=1
    done
    [ ${success} -ne 1 ] && error_msg "${name} has an incorrect value of : ${var}! Check onionjuggler.conf for more details."
  fi
}

get_os(){
  ## Source: pfetch -> https://github.com/dylanaraps/pfetch/blob/master/pfetch
  os="$(uname -s)"
  kernel="$(uname -r)"

  case ${os} in
    Linux*)
      if test -f /usr/share/anon-dist/marker; then
        test -f /usr/share/anon-gw-base-files/gateway && distro="Anon Gateway"
        test -f /usr/share/anon-ws-base-files/workstation && distro="Anon Workstation"
      elif command -v lsb_release >/dev/null; then
        distro=$(lsb_release -sd)
      elif test -f /etc/os-release; then
        while IFS='=' read -r key val; do
          case "${key}" in (PRETTY_NAME) distro=${val};; esac
        done < /etc/os-release
      else
        command -v crux >/dev/null && distro=$(crux)
        command -v guix >/dev/null && distro='Guix System'
      fi
      distro=${distro##[\"\']}
      distro=${distro%%[\"\']}
      case ${PATH} in (*/bedrock/cross/*) distro='Bedrock Linux' ;; esac
      if [ "${WSLENV}" ]; then
        distro="${distro}${WSLENV+ on Windows 10 [WSL2]}"
      elif [ -z "${kernel%%*-Microsoft}" ]; then
        distro="${distro} on Windows 10 [WSL1]"
      fi
    ;;
    Haiku) distro=$(uname -sv);;
    Minix|DragonFly) distro="${os} ${kernel}";;
    SunOS) IFS='(' read -r distro _ < /etc/release;;
    OpenBSD*) distro="$(uname -sr)";;
    FreeBSD) distro="${os} $(freebsd-version)";;
    *) distro="${os} ${kernel}";;
  esac

  case "${os}" in
    Linux*)
      case "${distro}" in
        "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Linux Mint"*|"LinuxMint"*|"mint"*|"Tails"*)
          pkg_mngr_install="apt install -y"
          requirements="tor grep sed openssl basez qrencode whiptail nginx bash-completion"
        ;;
        "Anon Gateway")
          pkg_mngr_install="apt install -y"
          requirements="tor grep sed openssl basez qrencode dialog bash-completion"
        ;;
        "Anon Workstation")
          pkg_mngr_install="apt install -y"
          requirements="grep sed qrencode dialog nginx bash-completion"
        ;;
        "Arch"*|"Artix"*|"ArcoLinux"*)
          pkg_mngr_install="pacman -Syu"
          requirements="tor grep sed openssl basez qrencode dialog nginx bash-completion"
        ;;
        "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat")
          pkg_mngr_install="dnf install -y"
          requirements="tor grep sed openssl basez qrencode dialog nginx bash-completion"
        ;;
      esac
    ;;
    "OpenBSD"*)
      pkg_mngr_install="pkg_add"
      requirements="tor grep sed eopenssl30 basez libqrencode dialog nginx shells/bash-completion"
    ;;
    "NetBSD"*)
      pkg_mngr_install="pkg_add"
      requirements="tor grep sed openssl basez libqrencode dialog nginx shells/bash-completion"
     ;;
    "FreeBSD"*|"HardenedBSD"*|"DragonFly"*)
      pkg_mngr_install="pkg install"
      requirements="tor grep sed openssl basez libqrencode dialog nginx shells/bash-completion"
    ;;
    *) error_msg "Unsupported system: ${os} ${kernel} ${distro}"
  esac


}

get_vars(){
  ## get default values and functions
  onionjuggler_defaults="${git_top_dir}/usr/share/onionjuggler/defaults.sh"
  if ! test -f "${onionjuggler_defaults}" || ! test -r "${onionjuggler_defaults}"; then
    printf '%s\n' "${onionjuggler_defaults} does not exist, or is not a regular file or can not be read"
    exit 1
  fi
  . "${onionjuggler_defaults}"
}


###################
###### MAIN #######

get_vars
get_os
build_dir="${git_top_dir}/build"

while :; do
  shift_n=""
  # shellcheck disable=SC2034
  opt_orig="${1}" ## save opt orig for error message to understand which opt failed
  # shellcheck disable=SC2034
  arg_possible="${2}" ## need to pass the second positional parameter because maybe it is an argument
  clean_opt "${1}" || break
  # shellcheck disable=SC2034
  case "${opt}" in
    i|install|b|build|d|uninstall|r|release|k|check|m|man|S|clean) command="${opt}";;
    P|purge) action="${opt}";;
    V|version) printf '%s\n' "${me} ${version}"; exit 0;;
    h|help) usage;;
    "") break;;
    *) error_msg "Invalid option: '${opt_orig}'";;
  esac
  shift "${shift_n:-1}"
  [ -z "${1}" ] && break
done

case "${command}" in

  b|build)
    lib_dir="/usr/share"
    man_dir="/usr/share"
    bin_dir="/usr"
    conf_dir="/etc"

    check_repo
    rm -rf "${build_dir}"
    notice "${cyan}Build targeting ${os} ${distro} to ${build_dir}${nocolor}"

    mkdir "${build_dir}"
    for man in "${git_top_dir}/auto-generated-man-pages"/*; do
      man_extension="${man##*.}"
      mkdir -p "${build_dir}${man_dir}/man${man_extension}"
      cp "${man}" "${build_dir}${man_dir}/man${man_extension}"
    done

    ## make helper dirs
    mkdir -p "${build_dir}${lib_dir}/onionjuggler"
    cp "${git_top_dir}/usr/share/onionjuggler"/* "${build_dir}${lib_dir}/onionjuggler"
    mkdir -p "${build_dir}${conf_dir}/onionjuggler/conf.d"
    cp "${git_top_dir}/etc/onionjuggler/dialogrc" "${build_dir}${conf_dir}/onionjuggler"
    mkdir -p "${build_dir}${bin_dir}/bin"
    cp "${git_top_dir}/usr/bin"/* "${build_dir}${bin_dir}/bin"

    ## configuration
    case "${os}" in
      Linux*)
        case "${distro}" in
          "Debian"*|*"buntu"*|"Armbian"*|"Rasp"*|"Linux Mint"*|"LinuxMint"*|"mint"*) os_conf="${git_top_dir}/etc/onionjuggler/debian.conf";;
          "Tails"*) os_conf="${git_top_dir}/etc/onionjuggler/tails.conf";;
          "Anon"*) os_conf="${git_top_dir}/etc/onionjuggler/anon.conf";;
          "Arch"*|"Artix"*|"ArcoLinux"*) os_conf="${git_top_dir}/etc/onionjuggler/arch.conf";;
          "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat") os_conf="${git_top_dir}/etc/onionjuggler/fedora.conf";;
        esac
      ;;
      "OpenBSD"*) os_conf="${git_top_dir}/etc/onionjuggler/openbsd.conf";;
      "NetBSD"*) os_conf="${git_top_dir}/etc/onionjuggler/netbsd.conf";;
      "FreeBSD"*|"HardenedBSD"*|"DragonFly"*) os_conf="${git_top_dir}/etc/onionjuggler/freebsd.conf";;
    esac
    cp "${os_conf}" "${build_dir}${conf_dir}/onionjuggler/onionjuggler.conf"
    notice %s"${blue}OnionJuggler built${nocolor}"
  ;;

  i|install)
    check_repo
    requires_root
    test -d "${build_dir}" || error_msg "${build_dir} does not exist"
    is_dir_empty "${build_dir}" && error_msg "${build_dir} does not have build files, use the option '--build'"
    notice "${magenta}Checking requirements${nocolor}"
    # shellcheck disable=SC2086
    install_package ${requirements}
    notice "${green}Copying files to path${nocolor}"
    cp -r "${build_dir}"/* /
    notice %s"${blue}OnionJuggler enviroment is ready${nocolor}"
  ;;

  d|uninstall)
    requires_root
    notice "${red}Removing OnionJuggler scripts from your system.${nocolor}"
    rm -f "${man_dir}/man1/onionjuggler-cli.1" "${man_dir}/man1/onionjuggler-tui.1" "${man_dir}/man5/onionjuggler.conf.5"
    #find "${man_dir}" -name "onionjuggler*" -delete
    rm -f "${bin_dir}/onionjuggler-cli"* "${bin_dir}/onionjuggler-tui"
    if [ "${action}" = "-P" ] || [ "${action}" = "--purge" ]; then
      notice "${red}Purging OnionJuggler configuration from your system.${nocolor}"
      rm -f "${conf_dir}/onionjuggler"
    fi
    notice "${green}Done!${nocolor}"
  ;;

  r|release)
    check_repo
    not_as_root
    notice "${blue}Preparing release${nocolor}"
    install_package shellcheck pandoc git
    make_man
    make_shellcheck
    notice "${cyan}Checking git status${nocolor}"
    ## should not delete, could destroy lines, just leave empty lines
    find "${git_top_dir}/usr" -type f -exec sed -i'' "s/set \-\x//g;s/set \-\v//g;s/set \+\x//g;s/set \+\v//g" {} \;
    if [ -n "$(git status -s)" ]; then
      git status
      error_msg "Please record the changes to the file(s) above with a commit before pushing!"
    fi
    notice "${green}Done!${nocolor}"
  ;;

  k|check) check_repo; make_shellcheck;;

  m|man) check_repo; not_as_root; make_man;;

  S|clean)
    requires_root
    notice "Cleaning directory..."
    rm -rf "${build_dir}"
    cd "${git_top_dir}" || error_msg "Failed to change directory to ${git_top_dir}"
    rm -rf -- *-build-deps_*.buildinfo *-build-deps_*.changes \
      debian/*.debhelper.log debian/*.substvars \
      debian/.debhelper debian/files \
      debian/debhelper-build-stamp debian/tmp
    find debian/ -type d -name "onionjuggler*" -exec rm -r {} + 2>/dev/null
    rm -f -- ../onionjuggler_*.deb ../onionjuggler_*.buildinfo ../onionjuggler_*.changes
  ;;

  *) usage;;

esac
