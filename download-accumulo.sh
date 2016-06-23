#!/bin/bash

# script to download an Accumulo distribution
# 
# Can change verison like
# VERSION=1.6.4 ./download-accumulo.sh
#
# Accumulo 1.5.0 started using -bin.tar.gz.  Prior to that is was -dist.tar.gz.
# This script is not supporting prior to 1.5.0.
# 
# Accumulo only has the latest releases in dist.apache.org, so we need to go
# the archive.apache.org/dist server to get the SHA1SUM file.  For the same
# reason, this script will download the binary package from maven central
#


ACCUMULO_VERSION="${VERSION:-1.7.2}" 
ACCUMULO_FILE="accumulo-${ACCUMULO_VERSION}-bin.tar.gz"
ACCUMULO_FILE_URL="https://repo.maven.apache.org/maven2/org/apache/accumulo/accumulo/${ACCUMULO_VERSION}/${ACCUMULO_FILE}"
ACCUMULO_SHAFILE="${ACCUMULO_FILE}.sha1"
ACCUMULO_SHAFILE_URL="https://archive.apache.org/dist/accumulo/${ACCUMULO_VERSION}/SHA1SUM"

get_sha1_from_sig() {
  local SHAFILE=$1
  if [ ! -e "${SHAFILE}" ]; then
    abort "get_sha1_from_sig requires 1 argument that names an existing signature [file]"
  fi
  cat "${SHAFILE}" | grep "bin.tar.gz" | awk '{print $1}'
}

run() {
  yellow Downloading Accumulo "${ACCUMULO_VERSION}"
  download_file "${ACCUMULO_FILE_URL}" "${ACCUMULO_FILE}"
  download_file "${ACCUMULO_SHAFILE_URL}" "${ACCUMULO_SHAFILE}"
  local EXPECTED=$(get_sha1_from_sig "${ACCUMULO_SHAFILE}")
  local ACTUAL=$(get_sha1_from_file "${ACCUMULO_FILE}")
  assert_signature "${EXPECTED}" "${ACTUAL}"
}

source $(dirname $0)/common.sh
run
