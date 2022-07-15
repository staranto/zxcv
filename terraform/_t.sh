#!/usr/bin/env bash

#
# Provide --var and TF_VAR_ for a TFC remote plan/apply.
#
# Remote WS can't deal with --var on the terraform command line.
# The only variables they can deal with have to come in via an
# .auto.tfvars file.  So, let's create one and the plan/apply
# will supply it to the WS for us.
#

function randomfilename() {
  mkdir -p "${1}"

  case "${OSTYPE}" in
      darwin*)
        echo "${1}/${2}${RANDOM}${3}"
        ;;
      *)
        mkdir --parents "${1}"
        mktemp --dry-run "${1}/${2}" --suffix "${3}"
        ;;
    esac
}

# Remove any leftover .auto.tfvars.
# if test -n "$(find "${PWD}" -maxdepth 1 -name 't_*.auto.tfvars' -print -quit)"; then
#   rm "${PWD}"/t_*.auto.tfvars
# fi
if compgen -G "${PWD}"/t_*.auto.tfvars > /dev/null; then
  rm "${PWD}"/t_*.auto.tfvars
fi

varfile=$(randomfilename "${PWD}" "t_XXXXXXXX" ".auto.tfvars")
params=()

# Loop through the env and add all TF_VAR_
# entries to the temporary .auto.tfvars
for tfv in $(compgen -A variable -X '!TF_VAR_*'); do
  v="${tfv#TF_VAR_*}" # Suffix of TF_VAR_varname
  val="${!tfv}"       # Value of TF_VAR_varname
  echo "${v}=\"${val}\"" >> "${varfile}"
done

# Loop through params and add all --var values
# to the temporary .auto.tfvars and then remove them.
while test ${#} -gt 0; do
  if [[ "${1}" =~ ^--var ]]; then
    # Shift to the key=value for a "two-step" spec.
    [[ "${1}" == "--var" ]] && shift

    # TODO Use -r -a $read_array_opt
    IFS='=' read -r f1 f2 f3 <<< "${1}"
    [[ -z "${f3}" ]] && f3="${f2}" && f2="${f1}"
    echo "${f2}=\"${f3}\"" >> "${varfile}"
  else
    params+=("${1}")
  fi
  shift
done

if [[ -n "${ZXCV_CUT}" ]]; then
  off="${ZXCV_TERRAFORM_CUT_OFF}"
  on="${ZXCV_TERRAFORM_CUT_ON}"
  terraform "${params[@]}" | "${ZXCV_BASEDIR}/terraform/_t_cut.sh" "${off}" "${on}"
else
  terraform "${params[@]}"
fi