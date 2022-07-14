#!/usr/bin/env bash

off="${1}"      # Key to turn output OFF.
on="${2}"       # Key to turn output back ON.
include="${3}"  # Should key line be included in output?
show=1          # Should current line be output?

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
