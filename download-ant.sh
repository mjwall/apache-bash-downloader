#!/bin/bash

# script to download Apache Ant
#
# Can change verison like
#
# VERSION=1.8.1 ./download-ant.sh

# As of 19 Feb, 1.9.13 is the oldest in the mirrors

ANT_VERSION="${VERSION:-1.9.13}"
ANT_FILE="apache-ant-${ANT_VERSION}-bin.tar.gz"
ANT_SHA_FILE="${ANT_FILE}.sha1"
ANT_URL_FROM_BASE="ant/binaries/"

get_ant_sha1_from_sig() {
  local SHAFILE=$1
  if [ ! -e "${SHAFILE}" ]; then
    abort "get_ant_sha1_from_sig requires 1 argument that names an existing signature [file]"
  fi
  cat "${SHAFILE}"
}

download_from_mirror() {
  download_file_from_mirror "${ANT_FILE}" "${ANT_URL_FROM_BASE}"
  download_signature_file "${ANT_SHA_FILE}" "${ANT_URL_FROM_BASE}"
}

download_from_apache_archive() {
  ARCHIVE="http://archive.apache.org/dist/ant/binaries/"
  download_file "${ARCHIVE}${ANT_FILE}" "${ANT_FILE}"
  download_file "${ARCHIVE}${ANT_SHA_FILE}" "${ANT_SHA_FILE}"
}

run() {
  yellow Downloading Ant version "${ANT_VERSION}"
  if [ "${ANT_VERSION}" == "1.9.7" ]; then
    # only the latest is stored on the mirror
    download_from_mirror
  else
    # must get from apache archive
    download_from_apache_archive
  fi
  local EXPECTED=$(get_ant_sha1_from_sig "${ANT_SHA_FILE}")
  local ACTUAL=$(get_sha1_from_file "${ANT_FILE}")
  assert_signature "${EXPECTED}" "${ACTUAL}"
}

source $(dirname $0)/common.sh
run
