#!/usr/bin/env bash

# -- base settings START -- #

WKM_VER=0.0.1
WKM_NAME="wkman"
WKM_ENTRY="wkman.sh"
WKM_PROJECT="https://github.com/nickfan/${WKM_NAME}"
WKM_GET_URL="https://raw.githubusercontent.com/nickfan/wkman/master//get.wkman.sh"
WKM_DL_URL="https://raw.githubusercontent.com/nickfan/wkman/master/wkman.sh"

DEFAULT_INSTALL_HOME="${HOME}/.${WKM_NAME}"

_SCRIPT_="$0"

LOCAL_ANY_ADDRESS="0.0.0.0"

NO_VALUE="no"

LOG_LEVEL_1=1
LOG_LEVEL_2=2
LOG_LEVEL_3=3
DEFAULT_LOG_LEVEL="$LOG_LEVEL_1"

DEBUG_LEVEL_1=1
DEBUG_LEVEL_2=2
DEBUG_LEVEL_3=3
DEBUG_LEVEL_DEFAULT=$DEBUG_LEVEL_1
DEBUG_LEVEL_NONE=0


SYSLOG_ERROR="user.error"
SYSLOG_INFO="user.info"
SYSLOG_DEBUG="user.debug"

#error
SYSLOG_LEVEL_ERROR=3
#info
SYSLOG_LEVEL_INFO=6
#debug
SYSLOG_LEVEL_DEBUG=7
#debug2
SYSLOG_LEVEL_DEBUG_2=8
#debug3
SYSLOG_LEVEL_DEBUG_3=9

SYSLOG_LEVEL_DEFAULT=${SYSLOG_LEVEL_ERROR}
#none
SYSLOG_LEVEL_NONE=0

DEFAULT_OPENSSL_BIN="openssl"

__INTERACTIVE=""
if [ -t 1 ]; then
  __INTERACTIVE="1"
fi

# -- base settings END -- #

wkm_install(){
  _info OK
}

wkm_uninstall(){
  _info OK
}

wkm_upgrade(){
  _info OK
}

# -- base functions START -- #
_installOnline(){
  _info "Installing from online archive."
  _noprofile="$2"
  if [ ! "$WKM_BRANCH" ]; then
    WKM_BRANCH="master"
  fi

  target="$WKM_PROJECT/archive/$WKM_BRANCH.tar.gz"
  _info "Downloading $target"
  localname="$WKM_BRANCH.tar.gz"
  if ! _get "$target" >$localname; then
    _err "Download error."
    return 1
  fi
  (
    _info "Extracting $localname"
    if ! (tar xzf $localname || gtar xzf $localname); then
      _err "Extraction error."
      exit 1
    fi

    cd "$WKM_NAME-$WKM_BRANCH"
    chmod +x $WKM_ENTRY
    if ./$WKM_ENTRY install "" "$_noprofile"; then
      _info "Install success!"
    fi

    cd ..

    rm -rf "$WKM_NAME-$WKM_BRANCH"
    rm -f "$localname"
  )
}
_process_parameters(){
  args=("$@")

  _CMD=""
  _useragent=""
  _confighome=""
  _noprofile=""
  _logfile=""
  _log=""
  _local_address=""
  _log_level=""
  _openssl_bin=""
  _syslog=""
  _use_wget=""
  while [ ${#} -gt 0 ]; do
    case "${1}" in

      --help | -h)
        showhelp
        return
        ;;
      --version | -v)
        version
        return
        ;;
      --install)
        _CMD="install"
        ;;
      --uninstall)
        _CMD="uninstall"
        ;;
      --upgrade)
        _CMD="upgrade"
        ;;
      --force | -f)
        FORCE="1"
        ;;
      --debug)
        if [ -z "$2" ] || _startswith "$2" "-"; then
          DEBUG="$DEBUG_LEVEL_DEFAULT"
        else
          DEBUG="$2"
          shift
        fi
        ;;
      --home)
        WKM_WORKING_DIR="$2"
        shift
        ;;
      --config-home)
        _confighome="$2"
        WKM_CONFIG_HOME="$_confighome"
        shift
        ;;
      --useragent)
        _useragent="$2"
        USER_AGENT="$_useragent"
        shift
        ;;
      --noprofile)
        _noprofile="1"
        ;;
      --no-color)
        export ACME_NO_COLOR=1
        ;;
      --force-color)
        export ACME_FORCE_COLOR=1
        ;;
      --log | --logfile)
        _log="1"
        _logfile="$2"
        if _startswith "$_logfile" '-'; then
          _logfile=""
        else
          shift
        fi
        LOG_FILE="$_logfile"
        if [ -z "$LOG_LEVEL" ]; then
          LOG_LEVEL="$DEFAULT_LOG_LEVEL"
        fi
        ;;
      --log-level)
        _log_level="$2"
        LOG_LEVEL="$_log_level"
        shift
        ;;
      --syslog)
        if ! _startswith "$2" '-'; then
          _syslog="$2"
          shift
        fi
        if [ -z "$_syslog" ]; then
          _syslog="$SYSLOG_LEVEL_DEFAULT"
        fi
        ;;
      --openssl-bin)
        _openssl_bin="$2"
        WKM_OPENSSL_BIN="$_openssl_bin"
        shift
        ;;
      --use-wget)
        _use_wget="1"
        WKM_USE_WGET="1"
        ;;
      --wkm-branch)
        export WKM_BRANCH="$2"
        shift
        ;;
      *)
        _err "Unknown parameter : $1"
        return 1
        ;;
    esac

    shift 1
  done

  if [ "${_CMD}" != "install" ]; then
    __initHome
    if [ "$_log" ]; then
      if [ -z "$_logfile" ]; then
        _logfile="$DEFAULT_LOG_FILE"
      fi
    fi
    if [ "$_logfile" ]; then
      LOG_FILE="$_logfile"
    fi

    if [ "$_log_level" ]; then
      LOG_LEVEL="$_log_level"
    fi

    if [ "$_syslog" ]; then
      if _exists logger; then
        SYS_LOG="$_syslog"
      else
        _err "The 'logger' command is not found, can not enable syslog."
        SYS_LOG=""
      fi
    fi
  fi

  _debug2 WKM_WORKING_DIR "$WKM_WORKING_DIR"

  if [ "$DEBUG" ]; then
    version
  fi


  case "${_CMD}" in
    install) wkm_install "$_confighome" "$_noprofile" ;;
    uninstall) wkm_uninstall;;
    upgrade) wkm_upgrade ;;
    *)
      if [ "$_CMD" ]; then
        _err "Invalid command: $_CMD"
      fi
      showhelp
      return 1
      ;;
  esac


  if [ "${_CMD}" = "install" ]; then
    if [ "$_log" ]; then
      if [ -z "$LOG_FILE" ]; then
        LOG_FILE="$DEFAULT_LOG_FILE"
      fi
    fi

    if [ "$_syslog" ]; then
      if _exists logger; then
        _debug2 SYS_LOG "$_syslog"
      else
        _err "The 'logger' command is not found, can not enable syslog."
        SYS_LOG=""
      fi
    fi
  fi

}

__initHome() {
  if [ -z "$_SCRIPT_HOME" ]; then
    if _exists readlink && _exists dirname; then
      _debug "Lets find script dir."
      _debug "_SCRIPT_" "$_SCRIPT_"
      _script="$(_readlink "$_SCRIPT_")"
      _debug "_script" "$_script"
      _script_home="$(dirname "$_script")"
      _debug "_script_home" "$_script_home"
      if [ -d "$_script_home" ]; then
        _SCRIPT_HOME="$_script_home"
      else
        _err "It seems the script home is not correct:$_script_home"
      fi
    fi
  fi

  #  if [ -z "$LE_WORKING_DIR" ]; then
  #    if [ -f "$DEFAULT_INSTALL_HOME/account.conf" ]; then
  #      _debug "It seems that $PROJECT_NAME is already installed in $DEFAULT_INSTALL_HOME"
  #      LE_WORKING_DIR="$DEFAULT_INSTALL_HOME"
  #    else
  #      LE_WORKING_DIR="$_SCRIPT_HOME"
  #    fi
  #  fi

  if [ -z "${WKM_WORKING_DIR}" ]; then
    _debug "Using default home:${DEFAULT_INSTALL_HOME}"
    WKM_WORKING_DIR="${DEFAULT_INSTALL_HOME}"
  fi
  export WKM_WORKING_DIR

  if [ -z "${WKM_CONFIG_HOME}" ]; then
    WKM_CONFIG_HOME="$WKM_WORKING_DIR"
  fi
  _debug "Using config home:${WKM_CONFIG_HOME}"
  export WKM_CONFIG_HOME

  DEFAULT_LOG_FILE="${WKM_CONFIG_HOME}/${WKM_NAME}.log"

  if [ -z "${WKM_TEMP_DIR}" ]; then
    WKM_TEMP_DIR="${WKM_CONFIG_HOME}/tmp"
  fi
}

_initpath() {

  __initHome

  if [ -z "$WKM_DIR" ]; then
    WKM_DIR="/home/.wkman"
  fi

}

showhelp() {
  _initpath
  version
  echo "Usage: ${WKM_ENTRY}  command ...[parameters]....
Commands:
  --help, -h               Show this help message.
  --version, -v            Show version info.
  --install                Install ${WKM_NAME} to your system.
  --uninstall              Uninstall ${WKM_NAME}, and uninstall the cron job.
  --upgrade                Upgrade ${WKM_NAME} to the latest code from ${WKM_PROJECT}.

Parameters:
  --force, -f                       Used to force to install or force to setup project.
  --debug                           Output debug info.
  --log    [/path/to/logfile]       Specifies the log file. The default is: \"${DEFAULT_LOG_FILE}\" if you don't give a file path here.
  --log-level 1|2                   Specifies the log level, default is 1.
  --syslog [0|3|6|7]                Syslog level, 0: disable syslog, 3: error, 6: info, 7: debug.
  --home                            Specifies the home dir for ${WKM_NAME}.
  --config-home                     Specifies the home dir to save all the configurations.
  --useragent                       Specifies the user agent string. it will be saved for future use too.
  --noprofile                       Only valid for '--install' command, which means: do not install aliases to user profile.
  --no-color                        Do not output color text.
  --force-color                     Force output of color text. Useful for non-interactive use with the aha tool for HTML E-Mails.
  --openssl-bin                     Specifies a custom openssl bin location.
  --use-wget                        Force to use wget, if you have both curl and wget installed.
  --wkm-branch                      Only valid for '--upgrade' command, specifies the branch name to upgrade to.
  "
}


version() {
  echo "${WKM_PROJECT}"
  echo "v${WKM_VER}"
}

# -- base functions END -- #

# -- common functions START -- #

__green() {
  if [ "${__INTERACTIVE}${WKM_NO_COLOR:-0}" = "10" -o "${WKM_FORCE_COLOR}" = "1" ]; then
    printf '\033[1;31;32m%b\033[0m' "$1"
    return
  fi
  printf -- "%b" "$1"
}

__red() {
  if [ "${__INTERACTIVE}${WKM_NO_COLOR:-0}" = "10" -o "${WKM_FORCE_COLOR}" = "1" ]; then
    printf '\033[1;31;40m%b\033[0m' "$1"
    return
  fi
  printf -- "%b" "$1"
}

_printargs() {
  _exitstatus="$?"
  if [ -z "$NO_TIMESTAMP" ] || [ "$NO_TIMESTAMP" = "0" ]; then
    printf -- "%s" "[$(date)] "
  fi
  if [ -z "$2" ]; then
    printf -- "%s" "$1"
  else
    printf -- "%s" "$1='$2'"
  fi
  printf "\n"
  # return the saved exit status
  return "$_exitstatus"
}

#class
_syslog() {
  _exitstatus="$?"
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" = "$SYSLOG_LEVEL_NONE" ]; then
    return
  fi
  _logclass="$1"
  shift
  if [ -z "$__logger_i" ]; then
    if _contains "$(logger --help 2>&1)" "-i"; then
      __logger_i="logger -i"
    else
      __logger_i="logger"
    fi
  fi
  $__logger_i -t "$PROJECT_NAME" -p "$_logclass" "$(_printargs "$@")" >/dev/null 2>&1
  return "$_exitstatus"
}

_log() {
  [ -z "$LOG_FILE" ] && return
  _printargs "$@" >>"$LOG_FILE"
}

_info() {
  _log "$@"
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_INFO" ]; then
    _syslog "$SYSLOG_INFO" "$@"
  fi
  _printargs "$@"
}

_err() {
  _syslog "$SYSLOG_ERROR" "$@"
  _log "$@"
  if [ -z "$NO_TIMESTAMP" ] || [ "$NO_TIMESTAMP" = "0" ]; then
    printf -- "%s" "[$(date)] " >&2
  fi
  if [ -z "$2" ]; then
    __red "$1" >&2
  else
    __red "$1='$2'" >&2
  fi
  printf "\n" >&2
  return 1
}

_usage() {
  __red "$@" >&2
  printf "\n" >&2
}

_debug() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_1" ]; then
    _log "$@"
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG" ]; then
    _syslog "$SYSLOG_DEBUG" "$@"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_1" ]; then
    _printargs "$@" >&2
  fi
}

#output the sensitive messages
_secure_debug() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_1" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _log "$@"
    else
      _log "$1" "$HIDDEN_VALUE"
    fi
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG" ]; then
    _syslog "$SYSLOG_DEBUG" "$1" "$HIDDEN_VALUE"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_1" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _printargs "$@" >&2
    else
      _printargs "$1" "$HIDDEN_VALUE" >&2
    fi
  fi
}

_debug2() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_2" ]; then
    _log "$@"
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG_2" ]; then
    _syslog "$SYSLOG_DEBUG" "$@"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_2" ]; then
    _printargs "$@" >&2
  fi
}

_secure_debug2() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_2" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _log "$@"
    else
      _log "$1" "$HIDDEN_VALUE"
    fi
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG_2" ]; then
    _syslog "$SYSLOG_DEBUG" "$1" "$HIDDEN_VALUE"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_2" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _printargs "$@" >&2
    else
      _printargs "$1" "$HIDDEN_VALUE" >&2
    fi
  fi
}

_debug3() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_3" ]; then
    _log "$@"
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG_3" ]; then
    _syslog "$SYSLOG_DEBUG" "$@"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_3" ]; then
    _printargs "$@" >&2
  fi
}

_secure_debug3() {
  if [ "${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}" -ge "$LOG_LEVEL_3" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _log "$@"
    else
      _log "$1" "$HIDDEN_VALUE"
    fi
  fi
  if [ "${SYS_LOG:-$SYSLOG_LEVEL_NONE}" -ge "$SYSLOG_LEVEL_DEBUG_3" ]; then
    _syslog "$SYSLOG_DEBUG" "$1" "$HIDDEN_VALUE"
  fi
  if [ "${DEBUG:-$DEBUG_LEVEL_NONE}" -ge "$DEBUG_LEVEL_3" ]; then
    if [ "$OUTPUT_INSECURE" = "1" ]; then
      _printargs "$@" >&2
    else
      _printargs "$1" "$HIDDEN_VALUE" >&2
    fi
  fi
}

_upper_case() {
  # shellcheck disable=SC2018,SC2019
  tr 'a-z' 'A-Z'
}

_lower_case() {
  # shellcheck disable=SC2018,SC2019
  tr 'A-Z' 'a-z'
}

_startswith() {
  _str="$1"
  _sub="$2"
  echo "$_str" | grep "^$_sub" >/dev/null 2>&1
}

_endswith() {
  _str="$1"
  _sub="$2"
  echo "$_str" | grep -- "$_sub\$" >/dev/null 2>&1
}

_contains() {
  _str="$1"
  _sub="$2"
  echo "$_str" | grep -- "$_sub" >/dev/null 2>&1
}

_hasfield() {
  _str="$1"
  _field="$2"
  _sep="$3"
  if [ -z "$_field" ]; then
    _usage "Usage: str field  [sep]"
    return 1
  fi

  if [ -z "$_sep" ]; then
    _sep=","
  fi

  for f in $(echo "$_str" | tr "$_sep" ' '); do
    if [ "$f" = "$_field" ]; then
      _debug2 "'$_str' contains '$_field'"
      return 0 #contains ok
    fi
  done
  _debug2 "'$_str' does not contain '$_field'"
  return 1 #not contains
}

# str index [sep]
_getfield() {
  _str="$1"
  _findex="$2"
  _sep="$3"

  if [ -z "$_findex" ]; then
    _usage "Usage: str field  [sep]"
    return 1
  fi

  if [ -z "$_sep" ]; then
    _sep=","
  fi

  _ffi="$_findex"
  while [ "$_ffi" -gt "0" ]; do
    _fv="$(echo "$_str" | cut -d "$_sep" -f "$_ffi")"
    if [ "$_fv" ]; then
      printf -- "%s" "$_fv"
      return 0
    fi
    _ffi="$(_math "$_ffi" - 1)"
  done

  printf -- "%s" "$_str"

}

_exists() {
  cmd="$1"
  if [ -z "$cmd" ]; then
    _usage "Usage: _exists cmd"
    return 1
  fi

  if eval type type >/dev/null 2>&1; then
    eval type "$cmd" >/dev/null 2>&1
  elif command >/dev/null 2>&1; then
    command -v "$cmd" >/dev/null 2>&1
  else
    which "$cmd" >/dev/null 2>&1
  fi
  ret="$?"
  _debug3 "$cmd exists=$ret"
  return $ret
}

#a + b
_math() {
  _m_opts="$@"
  printf "%s" "$(($_m_opts))"
}


_setShebang() {
  _file="$1"
  _shebang="$2"
  if [ -z "$_shebang" ]; then
    _usage "Usage: file shebang"
    return 1
  fi
  cp "$_file" "$_file.tmp"
  echo "$_shebang" >"$_file"
  sed -n 2,99999p "$_file.tmp" >>"$_file"
  rm -f "$_file.tmp"
}

__read_password() {
  unset _pp
  prompt="Enter Password:"
  while IFS= read -p "$prompt" -r -s -n 1 char; do
    if [ "$char" = $'\0' ]; then
      break
    fi
    prompt='*'
    _pp="$_pp$char"
  done
  echo "$_pp"
}

_exec() {
  if [ -z "$_EXEC_TEMP_ERR" ]; then
    _EXEC_TEMP_ERR="$(_mktemp)"
  fi

  if [ "$_EXEC_TEMP_ERR" ]; then
    eval "$@ 2>>$_EXEC_TEMP_ERR"
  else
    eval "$@"
  fi
}

_exec_err() {
  [ "$_EXEC_TEMP_ERR" ] && _err "$(cat "$_EXEC_TEMP_ERR")" && echo "" >"$_EXEC_TEMP_ERR"
}

#file
_readlink() {
  _rf="$1"
  if ! readlink -f "$_rf" 2>/dev/null; then
    if _startswith "$_rf" "/"; then
      echo "$_rf"
      return 0
    fi
    echo "$(pwd)/$_rf" | _conapath
  fi
}

# sleep sec
_sleep() {
  _sleep_sec="$1"
  if [ "$__INTERACTIVE" ]; then
    _sleep_c="$_sleep_sec"
    while [ "$_sleep_c" -ge "0" ]; do
      printf "\r      \r"
      __green "$_sleep_c"
      _sleep_c="$(_math "$_sleep_c" - 1)"
      sleep 1
    done
    printf "\r"
  else
    sleep "$_sleep_sec"
  fi
}

_stopserver() {
  pid="$1"
  _debug "pid" "$pid"
  if [ -z "$pid" ]; then
    return
  fi

  kill $pid

}

#setopt "file"  "opt"  "="  "value" [";"]
_setopt() {
  __conf="$1"
  __opt="$2"
  __sep="$3"
  __val="$4"
  __end="$5"
  if [ -z "$__opt" ]; then
    _usage usage: _setopt '"file"  "opt"  "="  "value" [";"]'
    return
  fi
  if [ ! -f "$__conf" ]; then
    touch "$__conf"
  fi

  if grep -n "^$__opt$__sep" "$__conf" >/dev/null; then
    _debug3 OK
    if _contains "$__val" "&"; then
      __val="$(echo "$__val" | sed 's/&/\\&/g')"
    fi
    text="$(cat "$__conf")"
    printf -- "%s\n" "$text" | sed "s|^$__opt$__sep.*$|$__opt$__sep$__val$__end|" >"$__conf"

  elif grep -n "^#$__opt$__sep" "$__conf" >/dev/null; then
    if _contains "$__val" "&"; then
      __val="$(echo "$__val" | sed 's/&/\\&/g')"
    fi
    text="$(cat "$__conf")"
    printf -- "%s\n" "$text" | sed "s|^#$__opt$__sep.*$|$__opt$__sep$__val$__end|" >"$__conf"

  else
    _debug3 APP
    echo "$__opt$__sep$__val$__end" >>"$__conf"
  fi
  _debug3 "$(grep -n "^$__opt$__sep" "$__conf")"
}

_head_n() {
  head -n "$1"
}

_tail_n() {
  if ! tail -n "$1" 2>/dev/null; then
    #fix for solaris
    tail -"$1"
  fi
}

_time() {
  date -u "+%s"
}

_utc_date() {
  date -u "+%Y-%m-%d %H:%M:%S"
}

_mktemp() {
  if _exists mktemp; then
    if mktemp 2>/dev/null; then
      return 0
    elif _contains "$(mktemp 2>&1)" "-t prefix" && mktemp -t "$PROJECT_NAME" 2>/dev/null; then
      #for Mac osx
      return 0
    fi
  fi
  if [ -d "/tmp" ]; then
    echo "/tmp/${PROJECT_NAME}wefADf24sf.$(_time).tmp"
    return 0
  elif [ "$LE_TEMP_DIR" ] && mkdir -p "$LE_TEMP_DIR"; then
    echo "/$LE_TEMP_DIR/wefADf24sf.$(_time).tmp"
    return 0
  fi
  _err "Can not create temp file."
}

_inithttp() {

  if [ -z "$HTTP_HEADER" ] || ! touch "$HTTP_HEADER"; then
    HTTP_HEADER="$(_mktemp)"
    _debug2 HTTP_HEADER "$HTTP_HEADER"
  fi

  if [ "$__HTTP_INITIALIZED" ]; then
    if [ "$_WKM_CURL$_WKM_WGET" ]; then
      _debug2 "Http already initialized."
      return 0
    fi
  fi

  if [ -z "$_WKM_CURL" ] && _exists "curl"; then
    _WKM_CURL="curl -L --silent --dump-header $HTTP_HEADER "
    if [ "$DEBUG" ] && [ "$DEBUG" -ge "2" ]; then
      _CURL_DUMP="$(_mktemp)"
      _WKM_CURL="$_WKM_CURL --trace-ascii $_CURL_DUMP "
    fi

    if [ "$CA_PATH" ]; then
      _WKM_CURL="$_WKM_CURL --capath $CA_PATH "
    elif [ "$CA_BUNDLE" ]; then
      _WKM_CURL="$_WKM_CURL --cacert $CA_BUNDLE "
    fi

    if _contains "$(curl --help 2>&1)" "--globoff"; then
      _WKM_CURL="$_WKM_CURL -g "
    fi
  fi

  if [ -z "$_WKM_WGET" ] && _exists "wget"; then
    _WKM_WGET="wget -q"
    if [ "$DEBUG" ] && [ "$DEBUG" -ge "2" ]; then
      _WKM_WGET="$_WKM_WGET -d "
    fi
    if [ "$CA_PATH" ]; then
      _WKM_WGET="$_WKM_WGET --ca-directory=$CA_PATH "
    elif [ "$CA_BUNDLE" ]; then
      _WKM_WGET="$_WKM_WGET --ca-certificate=$CA_BUNDLE "
    fi
  fi

  #from wget 1.14: do not skip body on 404 error
  if [ "$_WKM_WGET" ] && _contains "$($_WKM_WGET --help 2>&1)" "--content-on-error"; then
    _WKM_WGET="$_WKM_WGET --content-on-error "
  fi

  __HTTP_INITIALIZED=1

}

# url getheader timeout
_get() {
  _debug GET
  url="$1"
  onlyheader="$2"
  t="$3"
  _debug url "$url"
  _debug "timeout=$t"

  _inithttp

  if [ "$_WKM_CURL" ] && [ "${WKM_USE_WGET:-0}" = "0" ]; then
    _CURL="$_WKM_CURL"
    if [ "$HTTPS_INSECURE" ]; then
      _CURL="$_CURL --insecure  "
    fi
    if [ "$t" ]; then
      _CURL="$_CURL --connect-timeout $t"
    fi
    _debug "_CURL" "$_CURL"
    if [ "$onlyheader" ]; then
      $_CURL -I --user-agent "$USER_AGENT" -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" "$url"
    else
      $_CURL --user-agent "$USER_AGENT" -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" "$url"
    fi
    ret=$?
    if [ "$ret" != "0" ]; then
      _err "Please refer to https://curl.haxx.se/libcurl/c/libcurl-errors.html for error code: $ret"
      if [ "$DEBUG" ] && [ "$DEBUG" -ge "2" ]; then
        _err "Here is the curl dump log:"
        _err "$(cat "$_CURL_DUMP")"
      fi
    fi
  elif [ "$_WKM_WGET" ]; then
    _WGET="$_WKM_WGET"
    if [ "$HTTPS_INSECURE" ]; then
      _WGET="$_WGET --no-check-certificate "
    fi
    if [ "$t" ]; then
      _WGET="$_WGET --timeout=$t"
    fi
    _debug "_WGET" "$_WGET"
    if [ "$onlyheader" ]; then
      $_WGET --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" -S -O /dev/null "$url" 2>&1 | sed 's/^[ ]*//g'
    else
      $_WGET --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" -O - "$url"
    fi
    ret=$?
    if [ "$ret" = "8" ]; then
      ret=0
      _debug "wget returns 8, the server returns a 'Bad request' response, lets process the response later."
    fi
    if [ "$ret" != "0" ]; then
      _err "Please refer to https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html for error code: $ret"
    fi
  else
    ret=$?
    _err "Neither curl nor wget is found, can not do GET."
  fi
  _debug "ret" "$ret"
  return $ret
}

# body  url [needbase64] [POST|PUT|DELETE] [ContentType]
_post() {
  body="$1"
  _post_url="$2"
  needbase64="$3"
  httpmethod="$4"
  _postContentType="$5"

  if [ -z "$httpmethod" ]; then
    httpmethod="POST"
  fi
  _debug $httpmethod
  _debug "_post_url" "$_post_url"
  _debug2 "body" "$body"
  _debug2 "_postContentType" "$_postContentType"

  _inithttp

  if [ "$_WKM_CURL" ] && [ "${WKM_USE_WGET:-0}" = "0" ]; then
    _CURL="$_WKM_CURL"
    if [ "$HTTPS_INSECURE" ]; then
      _CURL="$_CURL --insecure  "
    fi
    _debug "_CURL" "$_CURL"
    if [ "$needbase64" ]; then
      if [ "$_postContentType" ]; then
        response="$($_CURL --user-agent "$USER_AGENT" -X $httpmethod -H "Content-Type: $_postContentType" -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" --data "$body" "$_post_url" | _base64)"
      else
        response="$($_CURL --user-agent "$USER_AGENT" -X $httpmethod -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" --data "$body" "$_post_url" | _base64)"
      fi
    else
      if [ "$_postContentType" ]; then
        response="$($_CURL --user-agent "$USER_AGENT" -X $httpmethod -H "Content-Type: $_postContentType" -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" --data "$body" "$_post_url")"
      else
        response="$($_CURL --user-agent "$USER_AGENT" -X $httpmethod -H "$_H1" -H "$_H2" -H "$_H3" -H "$_H4" -H "$_H5" --data "$body" "$_post_url")"
      fi
    fi
    _ret="$?"
    if [ "$_ret" != "0" ]; then
      _err "Please refer to https://curl.haxx.se/libcurl/c/libcurl-errors.html for error code: $_ret"
      if [ "$DEBUG" ] && [ "$DEBUG" -ge "2" ]; then
        _err "Here is the curl dump log:"
        _err "$(cat "$_CURL_DUMP")"
      fi
    fi
  elif [ "$_WKM_WGET" ]; then
    _WGET="$_WKM_WGET"
    if [ "$HTTPS_INSECURE" ]; then
      _WGET="$_WGET --no-check-certificate "
    fi
    _debug "_WGET" "$_WGET"
    if [ "$needbase64" ]; then
      if [ "$httpmethod" = "POST" ]; then
        if [ "$_postContentType" ]; then
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --header "Content-Type: $_postContentType" --post-data="$body" "$_post_url" 2>"$HTTP_HEADER" | _base64)"
        else
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --post-data="$body" "$_post_url" 2>"$HTTP_HEADER" | _base64)"
        fi
      else
        if [ "$_postContentType" ]; then
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --header "Content-Type: $_postContentType" --method $httpmethod --body-data="$body" "$_post_url" 2>"$HTTP_HEADER" | _base64)"
        else
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --method $httpmethod --body-data="$body" "$_post_url" 2>"$HTTP_HEADER" | _base64)"
        fi
      fi
    else
      if [ "$httpmethod" = "POST" ]; then
        if [ "$_postContentType" ]; then
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --header "Content-Type: $_postContentType" --post-data="$body" "$_post_url" 2>"$HTTP_HEADER")"
        else
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --post-data="$body" "$_post_url" 2>"$HTTP_HEADER")"
        fi
      else
        if [ "$_postContentType" ]; then
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --header "Content-Type: $_postContentType" --method $httpmethod --body-data="$body" "$_post_url" 2>"$HTTP_HEADER")"
        else
          response="$($_WGET -S -O - --user-agent="$USER_AGENT" --header "$_H5" --header "$_H4" --header "$_H3" --header "$_H2" --header "$_H1" --method $httpmethod --body-data="$body" "$_post_url" 2>"$HTTP_HEADER")"
        fi
      fi
    fi
    _ret="$?"
    if [ "$_ret" = "8" ]; then
      _ret=0
      _debug "wget returns 8, the server returns a 'Bad request' response, lets process the response later."
    fi
    if [ "$_ret" != "0" ]; then
      _err "Please refer to https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html for error code: $_ret"
    fi
    _sed_i "s/^ *//g" "$HTTP_HEADER"
  else
    _ret="$?"
    _err "Neither curl nor wget is found, can not do $httpmethod."
  fi
  _debug "_ret" "$_ret"
  printf "%s" "$response"
  return $_ret
}

_normalizeJson() {
  sed "s/\" *: *\([\"{\[]\)/\":\1/g" | sed "s/^ *\([^ ]\)/\1/" | tr -d "\r\n"
}

_stat() {
  #Linux
  if stat -c '%U:%G' "$1" 2>/dev/null; then
    return
  fi

  #BSD
  if stat -f '%Su:%Sg' "$1" 2>/dev/null; then
    return
  fi

  return 1 #error, 'stat' not found
}

_url_replace() {
  tr '/+' '_-' | tr -d '= '
}

_time2str() {
  #BSD
  if date -u -r "$1" 2>/dev/null; then
    return
  fi

  #Linux
  if date -u -d@"$1" 2>/dev/null; then
    return
  fi

  #Solaris
  if _exists adb; then
    _t_s_a=$(echo "0t${1}=Y" | adb)
    echo "$_t_s_a"
  fi

  #Busybox
  if echo "$1" | awk '{ print strftime("%c", $0); }' 2>/dev/null; then
    return
  fi
}

_ss() {
  _port="$1"

  if _exists "ss"; then
    _debug "Using: ss"
    ss -ntpl 2>/dev/null | grep ":$_port "
    return 0
  fi

  if _exists "netstat"; then
    _debug "Using: netstat"
    if netstat -help 2>&1 | grep "\-p proto" >/dev/null; then
      #for windows version netstat tool
      netstat -an -p tcp | grep "LISTENING" | grep ":$_port "
    else
      if netstat -help 2>&1 | grep "\-p protocol" >/dev/null; then
        netstat -an -p tcp | grep LISTEN | grep ":$_port "
      elif netstat -help 2>&1 | grep -- '-P protocol' >/dev/null; then
        #for solaris
        netstat -an -P tcp | grep "\.$_port " | grep "LISTEN"
      elif netstat -help 2>&1 | grep "\-p" >/dev/null; then
        #for full linux
        netstat -ntpl | grep ":$_port "
      else
        #for busybox (embedded linux; no pid support)
        netstat -ntl 2>/dev/null | grep ":$_port "
      fi
    fi
    return 0
  fi

  return 1
}

#options file
_sed_i() {
  options="$1"
  filename="$2"
  if [ -z "$filename" ]; then
    _usage "Usage:_sed_i options filename"
    return 1
  fi
  _debug2 options "$options"
  if sed -h 2>&1 | grep "\-i\[SUFFIX]" >/dev/null 2>&1; then
    _debug "Using sed  -i"
    sed -i "$options" "$filename"
  else
    _debug "No -i support in sed"
    text="$(cat "$filename")"
    echo "$text" | sed "$options" >"$filename"
  fi
}

_egrep_o() {
  if ! egrep -o "$1" 2>/dev/null; then
    sed -n 's/.*\('"$1"'\).*/\1/p'
  fi
}

#Usage: file startline endline
_getfile() {
  filename="$1"
  startline="$2"
  endline="$3"
  if [ -z "$endline" ]; then
    _usage "Usage: file startline endline"
    return 1
  fi

  i="$(grep -n -- "$startline" "$filename" | cut -d : -f 1)"
  if [ -z "$i" ]; then
    _err "Can not find start line: $startline"
    return 1
  fi
  i="$(_math "$i" + 1)"
  _debug i "$i"

  j="$(grep -n -- "$endline" "$filename" | cut -d : -f 1)"
  if [ -z "$j" ]; then
    _err "Can not find end line: $endline"
    return 1
  fi
  j="$(_math "$j" - 1)"
  _debug j "$j"

  sed -n "$i,${j}p" "$filename"

}

#Usage: multiline
_base64() {
  [ "" ] #urgly
  if [ "$1" ]; then
    _debug3 "base64 multiline:'$1'"
    ${WKM_OPENSSL_BIN:-openssl} base64 -e
  else
    _debug3 "base64 single line."
    ${WKM_OPENSSL_BIN:-openssl} base64 -e | tr -d '\r\n'
  fi
}

#Usage: multiline
_dbase64() {
  if [ "$1" ]; then
    ${WKM_OPENSSL_BIN:-openssl} base64 -d -A
  else
    ${WKM_OPENSSL_BIN:-openssl} base64 -d
  fi
}

#url encode, no-preserved chars
#A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
#41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 50 51 52 53 54 55 56 57 58 59 5a

#a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
#61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 72 73 74 75 76 77 78 79 7a

#0  1  2  3  4  5  6  7  8  9  -  _  .  ~
#30 31 32 33 34 35 36 37 38 39 2d 5f 2e 7e

#stdin stdout
_url_encode() {
  _hex_str=$(_hex_dump)
  _debug3 "_url_encode"
  _debug3 "_hex_str" "$_hex_str"
  for _hex_code in $_hex_str; do
    #upper case
    case "${_hex_code}" in
      "41")
        printf "%s" "A"
        ;;
      "42")
        printf "%s" "B"
        ;;
      "43")
        printf "%s" "C"
        ;;
      "44")
        printf "%s" "D"
        ;;
      "45")
        printf "%s" "E"
        ;;
      "46")
        printf "%s" "F"
        ;;
      "47")
        printf "%s" "G"
        ;;
      "48")
        printf "%s" "H"
        ;;
      "49")
        printf "%s" "I"
        ;;
      "4a")
        printf "%s" "J"
        ;;
      "4b")
        printf "%s" "K"
        ;;
      "4c")
        printf "%s" "L"
        ;;
      "4d")
        printf "%s" "M"
        ;;
      "4e")
        printf "%s" "N"
        ;;
      "4f")
        printf "%s" "O"
        ;;
      "50")
        printf "%s" "P"
        ;;
      "51")
        printf "%s" "Q"
        ;;
      "52")
        printf "%s" "R"
        ;;
      "53")
        printf "%s" "S"
        ;;
      "54")
        printf "%s" "T"
        ;;
      "55")
        printf "%s" "U"
        ;;
      "56")
        printf "%s" "V"
        ;;
      "57")
        printf "%s" "W"
        ;;
      "58")
        printf "%s" "X"
        ;;
      "59")
        printf "%s" "Y"
        ;;
      "5a")
        printf "%s" "Z"
        ;;

      #lower case
      "61")
        printf "%s" "a"
        ;;
      "62")
        printf "%s" "b"
        ;;
      "63")
        printf "%s" "c"
        ;;
      "64")
        printf "%s" "d"
        ;;
      "65")
        printf "%s" "e"
        ;;
      "66")
        printf "%s" "f"
        ;;
      "67")
        printf "%s" "g"
        ;;
      "68")
        printf "%s" "h"
        ;;
      "69")
        printf "%s" "i"
        ;;
      "6a")
        printf "%s" "j"
        ;;
      "6b")
        printf "%s" "k"
        ;;
      "6c")
        printf "%s" "l"
        ;;
      "6d")
        printf "%s" "m"
        ;;
      "6e")
        printf "%s" "n"
        ;;
      "6f")
        printf "%s" "o"
        ;;
      "70")
        printf "%s" "p"
        ;;
      "71")
        printf "%s" "q"
        ;;
      "72")
        printf "%s" "r"
        ;;
      "73")
        printf "%s" "s"
        ;;
      "74")
        printf "%s" "t"
        ;;
      "75")
        printf "%s" "u"
        ;;
      "76")
        printf "%s" "v"
        ;;
      "77")
        printf "%s" "w"
        ;;
      "78")
        printf "%s" "x"
        ;;
      "79")
        printf "%s" "y"
        ;;
      "7a")
        printf "%s" "z"
        ;;
      #numbers
      "30")
        printf "%s" "0"
        ;;
      "31")
        printf "%s" "1"
        ;;
      "32")
        printf "%s" "2"
        ;;
      "33")
        printf "%s" "3"
        ;;
      "34")
        printf "%s" "4"
        ;;
      "35")
        printf "%s" "5"
        ;;
      "36")
        printf "%s" "6"
        ;;
      "37")
        printf "%s" "7"
        ;;
      "38")
        printf "%s" "8"
        ;;
      "39")
        printf "%s" "9"
        ;;
      "2d")
        printf "%s" "-"
        ;;
      "5f")
        printf "%s" "_"
        ;;
      "2e")
        printf "%s" "."
        ;;
      "7e")
        printf "%s" "~"
        ;;
      #other hex
      *)
        printf '%%%s' "$_hex_code"
        ;;
    esac
  done
}

#_ascii_hex str
#this can only process ascii chars, should only be used when od command is missing as a backup way.
_ascii_hex() {
  _debug2 "Using _ascii_hex"
  _str="$1"
  _str_len=${#_str}
  _h_i=1
  while [ "$_h_i" -le "$_str_len" ]; do
    _str_c="$(printf "%s" "$_str" | cut -c "$_h_i")"
    printf " %02x" "'$_str_c"
    _h_i="$(_math "$_h_i" + 1)"
  done
}

#stdin  output hexstr splited by one space
#input:"abc"
#output: " 61 62 63"
_hex_dump() {
  if _exists od; then
    od -A n -v -t x1 | tr -s " " | sed 's/ $//' | tr -d "\r\t\n"
  elif _exists hexdump; then
    _debug3 "using hexdump"
    hexdump -v -e '/1 ""' -e '/1 " %02x" ""'
  elif _exists xxd; then
    _debug3 "using xxd"
    xxd -ps -c 20 -i | sed "s/ 0x/ /g" | tr -d ",\n" | tr -s " "
  else
    _debug3 "using _ascii_hex"
    str=$(cat)
    _ascii_hex "$str"
  fi
}

# -- common functions END -- #

# -- prepare for online install START -- #
# -- prepare for online install END -- #

if [ "$INSTALLONLINE" ]; then
  INSTALLONLINE=""
  _installOnline
  exit
fi

main() {
    [ -z "$1" ] && showhelp && return
    args=("$@")
    _process_parameters "${args[@]}"
    if [ ${#args[@]} -gt 0 ];then
        echo "main args ${args[@]}"
    else
        showhelp && return
    fi
}

main "$@"
