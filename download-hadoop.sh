#!/bin/bash

# just a script to download verify a hadoop distribution
# respects the apache mirrors and also verifies the checksum
# 
# Can change verison like
# HADOOP_VERSION=2.6.1 ./download-hadoop

# Note, the structure of the hadoop hadoop project changed early in 2.  Prior
# to that, you would download from a different place like hadoop/core.  After
# the change, you had to go to hadoop/common

# Note2, as of 22 Jun 2016, it looks like most mirrors have back to 2.5.2. This
# script could be improved to go the apache archive if it can't find the
# requested version, someplace like
# http://archive.apache.org/dist/hadoop/common/hadoop-${hadoop.version}/hadoop-${hadoop.version}.tar.gz

HADOOP_VERSION="${HADOOP_VERSION:-2.6.4}" 
HADOOP_FILE=hadoop-${HADOOP_VERSION}.tar.gz

abort() {
  echo $1
  exit 1
}

download_hadoop() {
  if [ -e ${HADOOP_FILE} ]; then
    echo File ${HADOOP_FILE} already downloaded
  else
    # use the closer.cgi to pick a mirror
    local CURLCMD="curl -s -L http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}?as_json=1" 
    local BASE=$(${CURLCMD} | grep preferred | awk '{print $NF}' | sed 's/\"//g')
    local URL="${BASE}hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
    echo Downloading $URL
    curl -L ${URL} -o ${HADOOP_FILE} || abort "Failed to download ${HADOOP_FILE}"
  fi
}

check_sha() {
    echo Checking sha256 of the file
    local SHAFILE="hadoop-${HADOOP_VERSION}.tar.gz.mds"
    if [ ! -e ${SHAFILE} ]; then
      curl -s -L "https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/${SHAFILE}" -o "${SHAFILE}" || abort "Failed to down ${SHAFILE}"
    fi
    local FILESHA=$(shasum -a 256 ${HADOOP_FILE} | awk '{print $1}')
    # remove all  newlines, add a newline before each hadoop-, find the SHA256
    # line, remove up the signature, remove all spaces, then lowercase
    local EXPECTEDSHA=$(cat ${SHAFILE} | tr -d '\n' | sed "s/hadoop-/\\`echo -e '\n\r'`/g" | grep SHA256 | sed 's/.* SHA256 = //' | tr -d ' ' | awk '{print tolower($0)}')
    if [ "${EXPECTEDSHA}" == "${FILESHA}" ]; then
      echo "File looks good"
    else
      abort "SHAs did not match. Expected ${EXPECTEDSHA} but was ${FILESHA}"
    fi
}

ensure_executables() {
  local EXES=""
  which curl 2>&1 >/dev/null   || EXES="curl "
  which awk 2>&1 >/dev/null    || EXES="${EXES}awk "
  which shasum 2>&1 >/dev/null || EXES="${EXES}shasum "
  if [ "${EXES}x" != "x" ]; then
    abort "The following executables are required: ${EXES}"
  fi
}

run() {
  echo "Looking for ${HADOOP_FILE}"
  ensure_executables
  download_hadoop
  check_sha
}

run
