#!/usr/bin/env bash

function sall() {
  while IFS= read -r -d '' file; do
    source "${file}"
  done < <(find "${1}" -name '*.sh' -print0)
}


