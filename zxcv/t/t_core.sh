#!/usr/bin/env bash

# This is the launcher function for Terraform.  It is
# used by zxcv to define the asdf package command
# that will be fired off.
#
# The first parameter in the call to the zxcv function
# is the command spec that determines this. There are
# two forms --
#
# {shortcut}/{command}/{alias}
#   - shortcut - REQUIRED and must match this helper function name.
#   - command - REQUIRED and must match the asdf package name.
#   - alias - an optional alias to provide additional
#      pre-processing before the asdsf package command is
#      executed.  This alias must be a Bash function that is
#      sourced in the current shell or a Bash script that is
#      available on the shell PATH.
function t() {
  ZXCV_OP=(cfg-check kill mq oq pq sq sv wq) \
    zxcv "t!terraform!${ZXCV_BASEDIR}/terraform/_t.sh" "${@}"
}

# Lifecycle function.  Define pre- and post-execution
# logic to be run.  If you don't *know* that you need
# it, then you don't.
function zxcv_terraform() {
  case "${1}" in
    "pre")  ;;
    "post") ;;
  esac
}

# In these op functions, the entire param array is passed.
# In most cases that's irrelevant and the actionable params
# begin at the first param after opid, which would be ${@:4}.

# Kill
# Interactively select resources to be removed from the current state.
function zxcv_terraform_kill() {
  local auto="-p"
  local filter=""
  for a in "${@:4}"; do
    [[ "${a}" == "--auto-approve" ]] && unset auto || filter="${a}"
  done
  t sq | fzf --query "${filter}" | xargs ${auto} -I{} "${1}" state rm "{}"
}

function _zxcv_terraform_isroot() {
  [[ -f .terraform/terraform.tfstate ]] && return 0 || return 1
}

function _zxcv_terraform_tfe_token() {
  local host && host=$(_zxcv_terraform_var -k hostname -d app.terraform.io)
  echo "${TFE_TOKEN:-$(jq --raw-output '.credentials.'"\"${host}\""'.token' "${HOME}"/.terraform.d/staranto.tfrc.json)}"
}

# Get a value from the current Teraform config.
function _zxcv_terraform_var() {

  local cfgfile="${HOME}/.config/zxcv/zxcv.cfg"
  local default
  local key
  local ns="t"
  local skipstate=0
  while [[ $# -gt 0 ]]; do
    case $1 in
      -c) shift && cfgfile="${1}" ;;
      -d) shift && default="${1}" ;;
      -k) shift && key="${1}" ;;
      -n) shift && ns="${1}" ;;
      -s) skipstate=1 ;;
      *)
        >&2 echo "Unknown argument ${1}"
        return 1
        ;;
    esac
    shift
  done

  local val
  # If this is a TF root dir (there's a state file), grab the value from it.
  [[ "${skipstate}" == "0" && -f ".terraform/terraform.tfstate" ]] && val=$(jq --raw-output .backend.config."${key}" .terraform/terraform.tfstate)

  # The key wasn't in a state file, so go to the cfg file
  [[ "${val}" == "null" || -z "${val}" ]] && val=$(awk -F= -v key="${ns}.${key}" '$1==key {print $2}' "${cfgfile}")

  # The key wasn't in cfg file either, so take the default.
  [[ "${val}" == "null" || -z "${val}" ]] && val="${default}"

  echo "${val}"
}
