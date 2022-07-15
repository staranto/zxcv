#!/usr/bin/env bash

function _get_var() {

  local cfgfile
  local default
  local key

  while [[ $# -gt 0 ]]; do
    case $1 in
      -c) shift && cfgfile="${1}" ;;
      -d) shift && default="${1}" ;;
      -k) shift && key="${1}" ;;
      *)
        >&2 echo "Unknown argument ${1}"
        return 1
        ;;
    esac
    shift
  done

  [[ "${val}" == "null" || -z "${val}" ]] && val=$(awk -F= -v key="${key}" '$1==key {print $2}' "${cfgfile}")

  # The key wasn't in cfg file, so take the default.
  [[ "${val}" == "null" || -z "${val}" ]] && val="${default}"

  echo "${val}"
}

include="${1}"  # Should key line be included in output?
show=1          # Should current line be output?

if [[ -n "${ZXCV_CUT}" ]]; then
  off=$(_get_var -c "${HOME}/.config/zxcv_t.cfg" -k "cut.${ZXCV_CUT}.off" -d "zxcv_ZAKP_zxcv")
  on=$(_get_var -c "${HOME}/.config/zxcv_t.cfg" -k "cut.${ZXCV_CUT}.on"   -d "zxcv_ZAKP_zxcv")
fi

# Are we processing a key hit?  Only check for an ON
# key of we're not already working on an OFF key.
hit=0  # 1=off 2=on

# Have we already processed a key?  If so, no
# need to look for any more.
processed=0

while IFS= read -r line; do

  [[ "${processed}" == "0" && "${line}" == *"${off}"* ]]  && show=0 && hit=1 && processed=1
  [[ "${hit}" == "0" && "${line}" == *"${on}"* ]]         && show=1 && hit=2 && processed=1

  [[ "${show}" == "1" && "${hit}" == "0" ]] ||
    [[ "${include}" == "1" && "${hit}" != "0" ]] &&
      printf "%s\n" "${line}"

  hit=0
done
