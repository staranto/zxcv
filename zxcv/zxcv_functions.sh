#!/usr/bin/env bash

function zxcv() {
  [[ -n "${ZXCV_TRACE}" ]] && set -x

  if [[ -z "${ZXCV_BASEDIR}" ]]; then
    >&2 echo "\$ZXCV_BASEDIR must be set."
    return 1
  fi

  if [[ -n "${ZSH_VERSION}" ]]; then
    emulate -L zsh
    if [[ -n "${ZXCV_TRACE_FUNCTIONS}" ]]; then
      typeset -ft "${ZXCV_TRACE_FUNCTIONS}"
    fi

    setopt local_options  # Restore options to entry state on exit.
    setopt localoptions
    setopt ksh_arrays     # 0-based (Bash-style) arrays.
    export ZXCV_READ_ARRAY_OPT="-A" # Zsh uses -A, Bash uses -a.
  else
    export ZXCV_READ_ARRAY_OPT="-a" # Zsh uses -A, Bash uses -a.
  fi

  IFS=! read -r short cmd wrapper <<< "${1}"

  # Store the ASDF_cmd_VERSION var so it can be maintained later.
  local envvar && envvar="ASDF_$(echo "${cmd}" | awk '{ printf toupper($1)}')_VERSION"

  # Setup core command aliases in case there is a conflict
  # with the target command.  For example, if kubectl had a native
  # switch command, then we couldn't use switch here to change
  # target versions.  So, we could change it to swap by setting
  # ZXCV_SWITCH=swap.
  local switch="${ZXCV_SWITCH:-"switch"}"
  local lcl="${ZXCV_LOCAL:-"local"}"
  local prune="${ZXCV_PRUNE:-"prune"}"

  case "${2}" in
    ""|"help")
      \cat << HELPTEXT
  ${0} helper for asdf.  Your command was ${short} which executes ${cmd}.

  Requires: Bash >=4.  Later 3.x might work, give it a try and let me know.
  Optional: fzf - https://github.com/junegunn/fzf

  usage: ${short} [options]

    help | <blank>     - This help text.

    $(printf "%-12s" "${switch} <version>")   - Explicitly switch to a specific asdf package version.

    $(printf "%-18s" "${switch}") - Interactively install and switch from a list of all
                         installed asdf package versions.

    $(printf "%-18s" "${switch} --all") - Source is all versions publicly available.

    $(printf "%-18s" "${lcl}") - Switch to version defined in .tool-versions, if it
                         exists in the folder hiearchy.

    $(printf "%-18s" "${prune}") - Interactively remove from a list of all installed.

    Additional ${cmd} operations added: ${ZXCV_OP}

  EXAMPLES:

  ${short} ${switch} 1.0.9
    - Switch to version 1.0.9 of ${cmd}.  The version will be downloaded
      and installed, if needed.

  ${short} ${switch}
    - Display a list of all locally available versions of ${cmd} and
      install the selected version.

  ${short} ${switch} --all
    - Display a list of all publicly available versions of ${cmd} and
      install the selected version.

  ${short} ${switch} --all ^1.1
    - Display a list of all publicly available 1.1.z versions of ${cmd} and
      install the selected version.  fzf fuzzy search syntax.

  ${short} ${lcl}
    - Switch to the locally defined version of ${cmd}.  See asdf install --help
      for more information.

  ${short} ${prune}
    - Remove the selected versions of ${cmd} from the local asdf cache.
HELPTEXT
      ;;

    "${switch}") # Synonyms
      local query
      local ver
      if [[ -z "${3}" ]] || [[ "${3}" == "--all" ]]; then
        local all
        [[ "${3}" == "--all" ]] && all="all" && query="${4}"
        # shellcheck disable=2086
        ver=$(asdf list ${all} "${cmd}" | fzf --tac --query "${query}" | xargs)
        [[ -z "${ver}" ]] && return 1  # Bail out if no selection.
      fi
      [[ "$(declare -fF zxcv_"${cmd}")" ]] && zxcv_"${cmd}" pre
      asdf install "${cmd}" "${ver:-${3}}"
      asdf   shell "${cmd}" "${ver:-${3}}"
      [[ "$(declare -fF zxcv_"${cmd}")" ]] && zxcv_"${cmd}" post
      ;;

    "${lcl}")
      local fnd=0
      local d="${PWD}"
      while [[ -n "${d}" ]]; do
        if [[ -f "${d}/.tool-versions" ]]; then
          fnd=1
          break
        fi
        d=${d%/*}
      done
      [[ "${fnd}" == "0" ]] && echo "No .tool-versions found." && return 1
      unset "${envvar}"
      [[ "$(declare -fF zxcv_"${cmd}")" ]] && zxcv_"${cmd}" pre
      asdf install "${cmd}"
      [[ "$(declare -fF zxcv_"${cmd}")" ]] && zxcv_"${cmd}" post
      ;;

    "${prune}")
      local vers
      vers=$(asdf list "${cmd}" | fzf --multi)
      for v in $(echo "$vers" | xargs ); do
        asdf uninstall "${cmd}" "${v}"
      done
      unset "${envvar}"
      ;;

    *)
      local -a args=()
      for arg in "${@}"; do
        if [[ "${arg}" == @* ]]; then
          local psdir && psdir=$(_get_var -c "${HOME}/.config/zxcv/zxcv.cfg" -k "t.paramset.dir" -d ~/.config/zxcv)
          local f && eval f="${psdir}/${arg:1}"
          while read -r "${ZXCV_READ_ARRAY_OPT:=-A}" fargs; do
            args=(${args[@]} ${fargs[@]})
          done < "${f}"
        else
          args+=("${arg}")
        fi
      done

      [[ -n "${ZXCV_DBG}" ]] && >&2 echo "zxcv.args ${args[*]}"

      # If there is a wrapper executable (script, function, etc)
      # defined and available, use it.  If not, just use the
      # utility binary itself.
      local exe="${wrapper}"
      if ! command -v "${exe}" &> /dev/null; then
        exe="${cmd}"
      fi

      [[ -n "${ZXCV_DBG}" ]] && >&2 printf "exe=%s\n" "${exe}"

      # Pre/post methods are defined in zxcv_${cmd}.
      # Execute them if it exists.
      local -i prepost=0
      command -v "zxcv_${cmd}" &> /dev/null
      # shellcheck disable=2181
      [[ "$?" == "0" ]] && prepost=1 && "zxcv_${cmd}" pre "${args[@]}"

      # Process ZXCV_OP if defined, otherwise pass through
      local op="${2}"
      [[ -n "${ZXCV_DBG}" ]] && >&2 printf "op=%s\n" "${op}"

      # shellcheck disable=2076
      if [[ ${ZXCV_OP[*]} =~ "${op}" ]]; then
        if command -v "zxcv_${cmd}_${op}" &> /dev/null; then
          [[ -n "${ZXCV_DBG}" ]] && >&2 printf "zxcv_cmd_op=zxcv_%s_%s\n" "${cmd}" "${op}"
          "zxcv_${cmd}_${op}" "${exe}" "${args[@]}"
        else
          echo "Operation function zxcv_${cmd}_${op}() not defined."
          return 1
        fi
      else
        "${exe}" "${args[@]:1}"
      fi

      [[ "${prepost}" == "1" ]] && "zxcv_${cmd}" post "${args[@]}"
      ;;
  esac

  if [[ -n "${ZSH_VERSION}" ]]; then
    if [[ -n "${ZXCV_TRACE_FUNCTIONS}" ]]; then
      typeset +ft "${ZXCV_TRACE_FUNCTIONS}"
    fi
  fi
  set +x
}

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