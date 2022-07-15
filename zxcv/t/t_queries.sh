#!/usr/bin/env bash

function zxcv_terraform_mq() {
  # shellcheck disable=2016
  _zxcv_terraform_q1 "${@}" --apiurl 'https://${host}/api/v2/organizations/${org}/registry-modules\?page\[size\]\=100'
}

# Organization Query
# Simple API query to return a list of all organizations.
# The naked query is intended to supply just the org names
# to be used as input into other functions (notabled wq).
# Additional output fields can be specified.
function zxcv_terraform_oq() {
  # shellcheck disable=2016
  _zxcv_terraform_q1 "${@}" --apiurl 'https://${host}/api/v2/organizations\?page\[size\]\=100'
}

function zxcv_terraform_pq() {
  # shellcheck disable=2016
  _zxcv_terraform_q1 "${@}" --apiurl 'https://${host}/api/v2/organizations/${org}/registry-providers\?page\[size\]\=100'
}

# State Query
# Add capabilities to terraform state list.  t sq with no parameters
# is just a wrapper for state list.  --filter and a1 a2 a3 can be used
# to filter resources and display additional attributes, respectively.
# Must be executed from a TF project root folder.
#
# Examples:
# - t sq                # Simple wrapper around state list.
# - t sq .id .arn       # Show id and arn attributes along with resource name.
function zxcv_terraform_sq() {
  if ! _zxcv_terraform_isroot; then
    echo "Must be executed from a TF project root." && return 1
  fi

  local    fields         # --     Additional fields to include in result.
  local    host           # --host TFC/TFE hostname.
  local -i json=0 title=0 # --json --title Output json, titles or none.
  local    org            # --org  TFC/TFE org if applicable to API.
  local    sort           # --sort Field to sort by
  local    wsname && wsname=$(_zxcv_terraform_var -k workspaces.name)
  local    wsprefix && wsprefix=$(_zxcv_terraform_var -k workspaces.prefix)
  local    wssuffix && [[ -f "${PWD}/.terraform/environment" ]] && wssuffix=$(cat "${PWD}"/.terraform/environment)
  local    wsspec="${wsname}" && [[ "${wsprefix}" != "null" ]] && [[ -n "${wsprefix}" ]] && wsspec="${wsprefix}${wssuffix}"
  local    wid && wid=$(t wq --ws "${wsspec}" name | cut -d ' ' -f 1)

  shift && shift && shift
  while [[ $# -gt 0 ]]; do
    case $1 in
      --host|-h)  shift && host="${1}" ;;
      --json|-j)  json=1 ;;
      --org)      shift && org="${1}" ;;
      --sort|-s)  shift && sort="${1}" ;;
      --title|-t) title=1 ;;
      *) # Naked args at end are fields.
        fields+="attributes.${1}," ;;
    esac
    shift
  done

  [[ -z "${host}" ]] && host="$(_zxcv_terraform_var -k hostname -d app.terraform.io)"
  [[ -z "${org}" ]]  && org="$(_zxcv_terraform_var -k organization)"

  local csvresult
  # shellcheck disable=SC2016
  csvresult=$(_zxcv_terraform_q2 -c sq \
    -f "${fields}" \
    -h "${host}" \
    -j "${json}" -t "${title}" \
    -r "1" \
    -1 "1" \
    -au "https://${host}/api/v2/workspaces/${wid}/current-state-version")

  local hsdu
  hsdu=$(echo "${csvresult}" | jq '.data.attributes."hosted-state-download-url"')
  #>&2 echo hsdu=$hsdu

  local hsduresult
  # shellcheck disable=SC2016
  hsduresult=$(_zxcv_terraform_q2 -c sq \
    -f "${fields}" \
    -h "${host}" \
    -j "${json}" -t "${title}" \
    -s "${sort}" \
    -1 "1" \
    -au "${hsdu}")

  hsduresult=$(printf "%s" "${hsduresult}")

  _zxcv_terraform_spit "${hsduresult}" "${json}" "${title}" "id" "${fields[@]}"
}

function zxcv_terraform_sv() {
  if ! _zxcv_terraform_isroot; then
    echo "Must be executed from a TF project root." && return 1
  fi
  local    fields         # --     Additional fields to include in result.
  local    host           # --host TFC/TFE hostname.
  local -i json=0 title=0 # --json --title Output json, titles or none.
  local    org            # --org  TFC/TFE org if applicable to API.
  local    sort           # --sort Field to sort by
  local    wsname && wsname=$(_zxcv_terraform_var -k workspaces.name)
  local    wsprefix && wsprefix=$(_zxcv_terraform_var -k workspaces.prefix)
  local    wssuffix && [[ -f "${PWD}/.terraform/environment" ]] && wssuffix=$(cat "${PWD}"/.terraform/environment)
  local    wsspec="${wsname}" && [[ "${wsprefix}" != "null" ]] && [[ -n "${wsprefix}" ]] && wsspec="${wsprefix}${wssuffix}"

  shift && shift && shift
  while [[ $# -gt 0 ]]; do
    case $1 in
      --host|-h)  shift && host="${1}" ;;
      --json|-j)  json=1 ;;
      --sort|-s)  shift && sort="${1}" ;;
      --title|-t) title=1 ;;
      *) # Naked args at end are fields.
        fields+="attributes.${1}," ;;
    esac
    shift
  done

  [[ -z "${host}" ]] && host="$(_zxcv_terraform_var -k hostname -d app.terraform.io)"
  [[ -z "${org}" ]]  && org="$(_zxcv_terraform_var -k organization)"

  local wsfilter
  if [[ -n "${wsspec}" ]]; then
    wsfilter="\&filter\[workspace\]\[name\]\=${wsspec}\&filter\[organization\]\[name\]\=${org}"
  fi

  local apiresult
  # shellcheck disable=SC2016
  apiresult=$(_zxcv_terraform_q2 -c sv \
    -f "${fields}" \
    -h "${host}" \
    -j "${json}" -t "${title}" \
    -o "${org}" \
    -s "${sort}" \
    -au 'https://${host}/api/v2/state-versions\?page\[size\]\=100'"${wsfilter}"
  )

  _zxcv_terraform_spit "${apiresult}" "${json}" "${title}" "id" "${fields[@]}"
}

function zxcv_terraform_wq() {
  local    fields         # --     Additional fields to include in result.
  local    host           # --host TFC/TFE hostname.
  local -i json=0 title=0 # --json --title Output json, titles or none.
  local -a orgs
  local -i progress=0
  local    sort
  local    wsname && wsname=$(_zxcv_terraform_var -k workspaces.name)
  local    wsprefix && wsprefix=$(_zxcv_terraform_var -k workspaces.prefix)
  local    wsspec="${wsname}" && [[ "${wsprefix}" != "null" ]] && [[ -n "${wsprefix}" ]] && wsspec="${wsprefix}"

  shift && shift && shift
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help)
        _zxcv_terraform_help wq
        return
        ;;
      --all|-a)
        wsspec="" ;;
      --dump|-d)
        # shellcheck disable=2207
        orgs=($(t oq --host "${host}"))
        ;;
      --host|-h)  shift && host="${1}" ;;
      --json|-j)  json=1 ;;
      --org|-o)   shift && orgs=("${1}") ;;
      --progress|-p) progress=1 ;;
      --sort|-s)  shift && sort="${1}" ;;
      --title|-t) title=1 ;;
      --ws|-w)    shift && wsspec="${1}" ;;
      *) # Naked args at end are fields.
        fields+="attributes.${1}," ;;
    esac
    shift
  done

  [[ -z "${host}" ]] && host="$(_zxcv_terraform_var -k hostname -d app.terraform.io)"
  [[ "${#orgs[@]}" == "0" ]] && orgs=("$(_zxcv_terraform_var -k organization)")

  local    wsfilter && [[ -n "${wsspec}" ]] && wsfilter="\&search\[name\]\=${wsspec}"
  local    apiresult
  local -i t=${title}
  for o in "${orgs[@]}"; do

    [[ "${progress}" == "1" ]] && >&2 printf "%s " "${o}"

    # shellcheck disable=SC2016
    apiresult+=$(_zxcv_terraform_q2 -c wq \
      -f "${fields}" \
      -h "${host}" \
      -j "${json}" -t "${t}" \
      -o "${o}" \
      -au 'https://${host}/api/v2/organizations/${o}/workspaces\?page\[size\]\=100'"${wsfilter}"
    )
    t=0
  done

  [[ "${progress}" == "1" ]] && >&2 printf "\n"

  # Slurp here prior to the sort.  This could be inlined with the sort
  # below, but that makes the filter syntax a little more convuluted,
  # so it's better to just take a tiny performance hit and call jq
  # one additional time.
  apiresult=$(printf "%s" "${apiresult}" | jq --slurp "add")

  # Sorting is deferred to here and not handled in _zxcv_terraform_q2 because
  # the apiresult cam back in json lines chunks (pre slurp above).  We don't get
  # the full collection of result lines and, therefore, can't sort it, until
  # after the last call to q2 is made.
  if [[ -n "${sort}" ]]; then
    apiresult=$(printf "%s" "${apiresult}" \
      | jq --raw-output "$(_zxcv_terraform_sort_filter "${sort}")" )
  fi

  _zxcv_terraform_spit "${apiresult}" "${json}" "${title}" "id" "${fields[@]}"
}

function _zxcv_terraform_api() {
  local cmd
  local filter
  local org
  local singlemode="0"
  local tfe_token

  local apiurl

  while [[ $# -gt 0 ]]; do
    case $1 in
      -c) shift && cmd="${1}" ;;
      -f) shift && filter="${1}" ;;
      -t) shift && tfe_token="${1}" ;;
      -o) shift && org="${1}" ;;
      -1) shift && singlemode="${1}" ;;
      -u) shift && apiurl="${1}" ;;
      *)
        >&2 echo "Unknown argument ${1}"
        return 1
        ;;
    esac
    shift
  done

  if [[ -n "${ZXCV_DBG}" ]]; then
    >&2 echo api filter="${filter}"
    >&2 echo api tfe_token="${tfe_token}"
    >&2 echo api org="${org}"
    >&2 echo api apiurl="${apiurl}"
    >&2 echo api singlemode="${singlemode}"
  fi

  local -i page=1
  local    cur
  local    nxt

  # Include the org in the payload so we can report on it.
  orgjq=".data[].attributes.org=\"${org}\""

  # Loop through each page of results until there is no next-page attribute.
  # The result of each API call should be appended into a single document.
  local tapiurl="${apiurl}"
  while : ; do
    [[ "${singlemode}" == 0 ]] && tapiurl="${apiurl}&page[number]=${page}"

    [[ -n "${ZXCV_DBG}" ]] && >&2 echo "api page=${page} nxt=${nxt} tapiurl=${tapiurl}"

    cur=$(curl --globoff --silent \
      --header "Authorization: Bearer ${tfe_token}" \
      --header "Content-Type: application/vnd.api+json" \
      "${tapiurl}")

    [[ -n "${ZXCV_DBG}" ]] && >&2 printf "api cur=%s\n" "${cur}"

    # Check for a valid JSON page.  If the JSON is not
    # valid report the error.  Unable to continue with
    # subsequent pages because we cannot parse the payload
    # to determine the next-page.  Bummer.
    if ! jq '.' > /dev/null <<<"${cur}" ; then
      >&2 echo "JSON page ${page} received from the API is invalid."
      >&2 echo "All remaining pages are excluded from the result set"
      >&2 echo "and it should be considered incomplete."
      return
    fi

    [[ -n "${org}" ]] && cur=$(echo "${cur}" | jq "${orgjq}")

    printf "%s" "${cur}"

    [[ "${singlemode}" == "1" ]] && return

    ((page++))

    # Breakout if we've hit the last page of results.
    nxt=$(echo "${cur}" | jq '.meta.pagination."next-page"')
    [[ -n "${ZXCV_DBG}" ]] && >&2 echo "api nxt=${nxt}"
    [[ "${nxt}" ==  "null" ]] && break
  done
}

function _zxcv_terraform_q1() {
  local    apiurl
  local    cmd
  local    fields         # --       Additional fields to include in result.
  local    filter         # --filter jq select spec
  local    host           # --host   TFC/TFE hostname.
  local -i json=0 title=0 # --json --title Output json, titles or none.
  local    org            # --org    TFC/TFE org if applicable to API.
  local    sort           # --sort   Field to sort by

  shift && shift && cmd="${1}" && shift
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      --help)
        _zxcv_terraform_help "${cmd}"
        return
        ;;
      --apiurl|-a)  shift && apiurl="${1}" ;;
      --filter|-f)  shift && filter="${1}" ;;
      --host|-h)    shift && host="${1}" ;;
      --json|-j)    json=1 ;;
      --org)        shift && org="${1}" ;;
      --sort|-s)    shift && sort="${1}" ;;
      --title|-t)   title=1 ;;
      *) # Naked args at end are fields.
        fields+="attributes.${1}," ;;
    esac
    shift
  done

  [[ -z "${host}" ]] && host="$(_zxcv_terraform_var -k hostname -d app.terraform.io)"
  [[ -z "${org}" ]]  && org="$(_zxcv_terraform_var -k organization)"

  local apiresult
  # shellcheck disable=SC2016
  apiresult=$(_zxcv_terraform_q2 -c oq \
    -f "${fields}" \
    -h "${host}" \
    -j "${json}" -t "${title}" \
    -o "${org}" \
    -fi "${filter}" \
    -s "${sort}" \
    -au "${apiurl}")

  _zxcv_terraform_spit "${apiresult}" "${json}" "${title}" "id" "${fields[@]}"
}

function _zxcv_terraform_q2() {
  local    apiurl         # -au   API URL.
  local    cmd            # -c    zxcv_terraform command - oq, mq, etc.
  local -a fields         # -f    Additional fields to include in result.
  local    filter         # -fi
  local    host           # -h    TFC/TFE hostname.
  local -i json=0 title=0 # -j -t Output json, titles or none.
  local    org            # -o    TFC/TFE org if applicable to API.
  local -i rawmode=0      # -r
  local -i singlemode=0   # -1    Single mode.  No paging in api().
  local    sort           # -s    Optional field to sort by.
  local    tfe_token      # -at   TFC/TFE token.

  [[ -z "${host}" ]]      && host=$(_zxcv_terraform_var -k hostname -d app.terraform.io)
  [[ -z "${tfe_token}" ]] && tfe_token=$(_zxcv_terraform_tfe_token)

  while [[ $# -gt 0 ]]; do
    case $1 in
      -1)   shift && singlemode=1 ;;
      -at)  shift && tfe_token="${1}" ;;
      -au)  shift && apiurl=$(eval echo "${1}") ;;
      -c)   shift && cmd="${1}" ;;
      -f)
        shift
        IFS="," read -r "${ZXCV_READ_ARRAY_OPT:=-A}" fields <<< "${1}"
        ;;
      -fi)  shift && filter="${1}" ;;
      -h)   shift && host="${1}" ;;
      -j)   shift && json=${1} ;;
      -o)   shift && org="${1}" ;;
      -r)   shift && rawmode=1 ;;
      -s)   shift && sort="${1}" ;;
      -t)   shift && title=${1} ;;
    esac
    shift
  done

  if [[ -n "${ZXCV_DBG}" ]]; then
    >&2 echo q2 cmd="${cmd}" apiurl="${apiurl}"
    >&2 echo q2 fields="${fields[*]}"
    >&2 echo q2 host="${host}" org="${org}"
    >&2 echo q2 json="${json}" title="${title}"
    >&2 echo q2 tfe_token="${tfe_token}"
    >&2 echo q2 rawmode="${rawmode}" singlemode="${singlemode}"
  fi

  [[ -z "${tfe_token}" || -z "${host}" ]] && echo "TFE_TOKEN and host are required." && return 1

  # This is the raw, complete, unfiltered result set.
  # It needs to be slimmed down in the next step to
  # just the fields we're interested in.
  local apiresult && apiresult=$( _zxcv_terraform_api -u "${apiurl}" -t "${tfe_token}" -o "${org}" -1 "${singlemode}")

  if [[ "${rawmode}" == "1" ]]; then
    printf "%s" "${apiresult}"
    return
  fi

  # shellcheck disable=2068
  apiresult=$(
    printf "%s" "${apiresult}" |
      jq --raw-output --from-file -L "${ZXCV_BASEDIR}/zxcv/t" \
        "${ZXCV_BASEDIR}/zxcv/t/${cmd}.jq" --arg j "${json}" \
        --args ${fields[@]} | jq --raw-output --slurp "$(_zxcv_terraform_sort_filter "${sort}")""${filter}"
  )
  printf "%s" "${apiresult}"
  [[ -n "${ZXCV_DBG}" ]] && >&2 printf "q2 %s.jq=%s\n" "${cmd}" "${apiresult}"
}

function _zxcv_terraform_sort_filter() {
  local sspec=""

  if [[ -n "${1}" ]]; then
    local comma
    local -a fields && IFS="," read -r "${ZXCV_READ_ARRAY_OPT:=-A}" fields <<< "${1}"
    local fspec

    for f in "${fields[@]}"; do
      local rflag=""
      if [[ "${f}" =~ ^- ]]; then
        rflag="-"     # Add the reverse attribute and
        f="${f:1}"    # Lop off the first char (-).
      fi
      # TODO Deal with numbers properly
      fspec+=$(printf "%s(.\"%s\"|if type == \"number\" then %s. else tostring|explode|map(%s.) end )" "${comma}" "${f}" "${rflag}" "${rflag}")
      comma=","
    done
    sspec=$(printf ". | sort_by(%s)" "${fspec}")
  fi

  [[ -n "${ZXCV_DBG}" ]] && >&2 printf "sspec=%s\n" "${sspec}"
  printf "%s" "${sspec}"
}

function _zxcv_terraform_spit() {
  local    payload && payload="${1}"
  local -a fields  && fields=("${@:4}")
  local -i json    && json=${2}
  local -i title   && title=${3}

  # >&2 echo fields="${fields[*]}"
  # >&2 echo json="${json}" title="${title}"

  # If json mode just dump the payload.
  if [[ "${json}" == 1 ]]; then
    printf "%s\n" "${payload}"
  else
    local out && out=$(printf "%s" "${payload}" | jq --raw-output --from-file "${ZXCV_BASEDIR}/zxcv/jq/json2tsv.jq" --arg t "${title}" | column -t)
    printf "%s\n" "${out}"
  fi
}