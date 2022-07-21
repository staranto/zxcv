#!/usr/bin/env bash

function timerStart() {
_timerName="${1}"
  typeset -F _timestart
  _timerStart="$(date +%s%N)"
}

function timerEnd() {
  typeset -F _timerEnd
  _timerEnd="$(date +%s%N)"
  printf "%s: %.0fms\n" "${_timerName}" $(( (_timerEnd-_timerStart) / 1000000 ))
  unset _timerName _timerStart _timerEnd
}

function date() {
  if command -v gdate &> /dev/null; then
    gdate "${@}"
  else
    /usr/bin/date "${@}"
  fi
}
