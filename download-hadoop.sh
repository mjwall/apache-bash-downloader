#!/bin/bash

# just a script to download verify a hadoop distribution
# respects the apache mirrors and also verifies the checksum
# 

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
    CURLCMD="curl -s -L http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}?as_json=1" 
    BASE=$(${CURLCMD} | grep preferred | awk '{print $NF}' | sed 's/\"//g')
    URL="${BASE}hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
    echo Downloading $URL
    curl -L ${URL} -o ${HADOOP_FILE} || abort "Failed to download ${HADOOP_FILE}"
  fi
}

check_sha() {
    echo Checking sha256 of the file
    SHAFILE="hadoop-${HADOOP_VERSION}.tar.gz.mds"
    if [ ! -e ${SHAFILE} ]; then
      curl -s -L "https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/${SHAFILE}" -o "${SHAFILE}" || abort "Failed to down ${SHAFILE}"
    fi
    FILESHA=$(shasum -a 256 ${HADOOP_FILE} | awk '{print $1}')
    EXPECTEDSHA=$(grep -A1 SHA256 ${SHAFILE} | tr '\n' ' ' | sed 's/.*SHA256 = //;s/ //g' | awk '{print tolower($0)}')
    if [ "${EXPECTEDSHA}" == "${FILESHA}" ]; then
      echo "File looks good"
    else
      abort "SHAs did not match. Expected ${EXPECTEDSHA} but was ${FILESHA}"
    fi
}

ensure_curl() {
  which curl 2>&1 >/dev/null || abort "You must have curl installed to use this"
}

run() {
  echo "Looking for ${HADOOP_FILE}"
  ensure_curl
  download_hadoop
  check_sha
}

run
