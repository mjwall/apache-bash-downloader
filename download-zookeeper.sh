#!/bin/bash

# script to download a zookeeper distribution
# 
# Can change verison like
# VERSION=3.3.6 ./download-zookeeper.sh

#https://dist.apache.org/repos/dist/release/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.tar.gz

ZOOKEEPER_VERSION="${VERSION:-3.4.8}" 
ZOOKEEPER_FILE="zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
ZOOKEEPER_SHA_FILE="${ZOOKEEPER_FILE}.sha1"
ZOOKEEPER_URL_FROM_BASE="zookeeper/zookeeper-${ZOOKEEPER_VERSION}/"

get_sha1_from_sig() {
  local SHAFILE=$1
  if [ ! -e "${SHAFILE}" ]; then
    abort "get_sha1_from_sig requires 1 argument that names an existing signature [file]"
  fi
  cat "${SHAFILE}" | awk '{print $1}'
}

run() {
  log Downloading and checking "${ZOOKEEPER_FILE}"
  download_file_from_mirror "${ZOOKEEPER_FILE}" "${ZOOKEEPER_URL_FROM_BASE}"
  download_signature_file "${ZOOKEEPER_SHA_FILE}" "${ZOOKEEPER_URL_FROM_BASE}"
  local EXPECTED=$(get_sha1_from_sig "${ZOOKEEPER_SHA_FILE}")
  local ACTUAL=$(get_sha1_from_file "${ZOOKEEPER_FILE}")
  assert_signature "${EXPECTED}" "${ACTUAL}"
}

source ./common.sh
run
