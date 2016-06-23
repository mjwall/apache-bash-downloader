#!/bin/bash

# script to download a maven distribution
# 
# Can change verison like
# VERSION=3.2.5 ./download-maven.sh

MAVEN_VERSION="${VERSION:-3.3.9}" 
MAVEN_FILE="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_SHA_FILE="${MAVEN_FILE}.sha1"
MAVEN_URL_FROM_BASE="maven/maven-3/${MAVEN_VERSION}/binaries/"

get_maven_sha1_from_sig() {
  local SHAFILE=$1
  if [ ! -e "${SHAFILE}" ]; then
    abort "get_maven_sha1_from_sig requires 1 argument that names an existing signature [file]"
  fi
  cat "${SHAFILE}"
}

run() {
  yellow Downloading Maven version "${MAVEN_VERSION}"
  download_file_from_mirror "${MAVEN_FILE}" "${MAVEN_URL_FROM_BASE}"
  download_signature_file "${MAVEN_SHA_FILE}" "${MAVEN_URL_FROM_BASE}"
  local EXPECTED=$(get_maven_sha1_from_sig "${MAVEN_SHA_FILE}")
  local ACTUAL=$(get_sha1_from_file "${MAVEN_FILE}")
  assert_signature "${EXPECTED}" "${ACTUAL}"
}

source $(dirname $0)/common.sh
run
