#!/bin/bash

# script to download a hadoop distribution
# that respects the apache mirrors and also verifies the checksum
# 
# Can change verison like
# VERSION=2.6.1 ./download-hadoop

# Note, the structure of the hadoop hadoop project changed early in 2.  Prior
# to that, you would download from a different place like hadoop/core.  After
# the change, you had to go to hadoop/common

# Note2, as of 22 Jun 2016, it looks like most mirrors have back to 2.5.2. This
# script could be improved to go the apache archive if it can't find the
# requested version, someplace like
# http://archive.apache.org/dist/hadoop/common/hadoop-${hadoop.version}/hadoop-${hadoop.version}.tar.gz

HADOOP_VERSION="${VERSION:-2.6.4}" 
HADOOP_FILE="hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_SHA_FILE="${HADOOP_FILE}.mds"
HADOOP_URL_FROM_BASE="hadoop/common/hadoop-${HADOOP_VERSION}"

get_hadoop_sha256_from_sig() {
  local SHAFILE=$1
  if [ ! -e "${SHAFILE}" ]; then
    abort "get_hadoop_sha256_from_sig requires 1 argument that names an existing signature [file]"
  fi
  # The hadoop signature file has multiple signatures and each signature can be
  # 1 or more lines.
  echo $(cat ${SHAFILE} | tr -d '\n' | sed "s/hadoop-/\\`echo -e '\n\r'`/g" | grep SHA256 | sed 's/.* SHA256 = //')
}

run() {
  yellow Downloading Hadoop version "${HADOOP_VERSION}"
  download_file_from_mirror "${HADOOP_FILE}" "${HADOOP_URL_FROM_BASE}"
  download_signature_file "${HADOOP_SHA_FILE}" "${HADOOP_URL_FROM_BASE}"
  local EXPECTED=$(get_hadoop_sha256_from_sig "${HADOOP_SHA_FILE}")
  local ACTUAL=$(get_sha256_from_file "${HADOOP_FILE}")
  assert_signature "${EXPECTED}" "${ACTUAL}"
}

source $(dirname $0)/common.sh
run
