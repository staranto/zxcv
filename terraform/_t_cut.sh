#!/usr/bin/env bash

. "${ZXCV_BASEDIR}/zxcv/zxcv_functions.sh"


if [[ -n "${ZXCV_CUT}" ]]; then
  off=$(_get_var -c "${HOME}/.config/zxcv/zxcv.cfg" -k "t.cut.${ZXCV_CUT}.off" -d "zxcv_ZAKP")
  on=$(_get_var -c "${HOME}/.config/zxcv/zxcv.cfg" -k "t.cut.${ZXCV_CUT}.on"   -d "zxcv_ZAKP")
fi

# Are we processing a key hit?  Only check for an ON
# key of we're not already working on an OFF key.
hit=0  # 1=off 2=on
# Should current line be output?
show=1

while IFS= read -r line; do
  if [[ -n "${off}" ]]; then
    [[ "${line}" == *"${off}"* ]] && hit=1 && show=0
    [[ "${hit}" == "0" && "${line}" == *"${on}"* ]] && hit=2 && show=1
  fi

  [[ "${hit}" == "0" && "${show}" == "1" ]] && printf "%s\n" "${line}"

  hit=0
done
