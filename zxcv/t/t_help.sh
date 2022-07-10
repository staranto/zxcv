#!/usr/bin/env bash

function _zxcv_terraform_help() {

  case "${1}" in

    mq)
\cat << HELPTEXT
Common fields are name, provider, updated-at and version-statuses.
HELPTEXT
;;

    oq)
\cat << HELPTEXT
Common fields are email and created-at.
HELPTEXT
;;

    pq)
\cat << HELPTEXT
Common fields are email, created-at t and external-id.
id is a synonym for attributes.name.
HELPTEXT
;;

    wq)
\cat << HELPTEXT
Common fields are resource-count, terraform-version and updated-at.
HELPTEXT
;;

  esac
}