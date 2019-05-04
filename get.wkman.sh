#!/usr/bin/env sh

#https://github.com/nickfan/get.wkman.sh


WKM_GET_URL="https://raw.githubusercontent.com/nickfan/wkman/master/get.wkman.sh"
WKM_DL_URL="https://raw.githubusercontent.com/nickfan/wkman/master/wkman.sh"

_exists() {
  cmd="$1"
  if [ -z "$cmd" ] ; then
    echo "Usage: _exists cmd"
    return 1
  fi
  if type command >/dev/null 2>&1 ; then
    command -v $cmd >/dev/null 2>&1
  else
    type $cmd >/dev/null 2>&1
  fi
  ret="$?"
  return $ret
}

if _exists curl && [[ "${WKM_USE_WGET:-0}" = "0" ]]; then
  curl "${WKM_DL_URL}" | INSTALLONLINE=1  sh
elif _exists wget ; then
  wget -O -  "${WKM_DL_URL}" | INSTALLONLINE=1  sh
else
  echo "Sorry, you must have curl or wget installed first."
  echo "Please install either of them and try again."
fi