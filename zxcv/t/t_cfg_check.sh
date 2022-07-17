#!/usr/bin/env bash

function zxcv_terraform_cfg-check() {

  local cliCfgFile="${TF_CLI_CONFIG_FILE}"
  local tCfgFile="${HOME}/.config/zxcv/zxcv.cfg"
  local tfeToken="${TFE_TOKEN}"
  local zxcvBaseDir="${ZXCV_BASEDIR}"

  # Basic checks of core config items.
  _check "E" "ZXCV_BASE_DIR" "${zxcvBaseDir}"
  [[ ! -f "${tCfgFile}" ]] && _result "E" "${tCfgFile} is not found"


  echo 111

  if ls "${HOME}"/.config/zxcv_*.cfg 2> /dev/null; then
    _result "W" "Stale zxcv config files found"
  fi

  echo 222

  _check " " "TF_CLI_CONFIG_FILE" "${cliCfgFile}"
  [[ -n "${cliCfgFile}" && ! -f "${cliCfgFile}" ]] && _result "E" "${cliCfgFile} is not found"

  _check " " "TFE_TOKEN" "${tfeToken}"

  if _zxcv_terraform_isroot; then
    echo "${PWD} is a root directory."
  fi

  # Make sure the tCfgFile has values for required entries.
  _check_tcfgfile "${tCfgFile}" "hostname"
  _check_tcfgfile "${tCfgFile}" "organization"

  # Check for conflicting config files.
  [[ -f "${cliCfgFile}" && -f "${HOME}/.terraformrc" ]] && _result "W" "Potentially confusing config files"

}

function _check_tcfgfile() {
  local v && v="$(_zxcv_terraform_var -s -c "${1}" -d "" -k "${2}")"
  [[ "${v}" == "" ]] && _result "E" "${2} is not found in ${1}"
}

function _check() {
  if [[ -n "${3}" ]]; then
    _result " " "$(printf "%s = %s\n" "${2}" "${3}")"
  else
    _result "${1}" "$(printf "%s is not set\n" "${2}")"
  fi
}

function _result() {
  printf "%s %s\n" "${1}" "${2}"
}