#!/bin/bash

# Common functions in a file that all scripts should source.

# Best practice for download scripts is to make everything a function and then
# call one function at the bottom of the script. Only put variables at the top
# of the script that can be override by default environment variables.  All
# other variables should be local.  Functions should not modify variables that
# are passed in, instead they should modify and use a copy.  This will help to
# avoid collisions and hopefully avoid side effects.  Always double quote
# variables when the they are used and wrap with curly braces.  See
# download-hadoop.sh for an example.

# Typical scripts will

# STEP 1 
# Call download_file_from_mirror, passing in the file name and directories from
# the root url to the file.  For example:
# Here is the function.
download_file_from_mirror() {
  local URL_BASE="http://www.apache.org/dyn/closer.cgi/" #end in /
  local FILENAME=$1
  local URL_DIRECTORIES=$2 #part between the url base and the filename
  if [ "${FILENAME}x" == "x" ] || [ "${URL_DIRECTORIES}x" == "x" ]; then
    abort "download_file_from_mirror takes 2 arguments [filename] [url_directories]"
  fi

  # make sure the URL_DIRECTORIES ends in a /
  test "${URL_DIRECTORIES: -1}" != "/" && URL_DIRECTORIES="${URL_DIRECTORIES}/"

  # use the closer.cgi to pick a mirror
  local CURLCMD="curl -s -L ${URL_BASE}${URL_DIRECTORIES}${FILENAME}?as_json=1" 
  local BASE=$(${CURLCMD} | grep preferred | awk '{print $NF}' | sed 's/\"//g')
  local URL="${BASE}${URL_DIRECTORIES}${FILENAME}"
  download_file "${URL}" "${FILENAME}"
}

# STEP 2 
# Call download_signature_file, passing in the file name and directories
# from the root of the dist.apache url.  For example:
# Here is the function.
download_signature_file() {
  # only download from dist.apache
  local URL_BASE="https://dist.apache.org/repos/dist/release/" 
  local FILENAME=$1
  local URL_DIRECTORIES=$2 #part between the url base and the filename
  if [ "${FILENAME}x" == "x" ] || [ "${URL_DIRECTORIES}x" == "x" ]; then
    abort "download_signature_file takes 2 arguments [filename] [url_directories]"
  fi

  # make sure the URL_DIRECTORIES ends in a /
  test "${URL_DIRECTORIES: -1}" != "/" && URL_DIRECTORIES="${URL_DIRECTORIES}/"

  download_file "${URL_BASE}${URL_DIRECTORIES}${FILENAME}" "${FILENAME}"
}

# STEP 3 
# Implement a function to read the appropriate checksum from the signature file.
# This is left to each script, because signature file format varies depending
# on how the developers of the project produce the signature files. Store this
# result in a variable for later use.  For example:

# STEP 4
# Call get_sha256_from_file or get_sha1_from_file on the file downloaded from mirror and store
# in variable. For example:
# Here is the function.
get_sha256_from_file() {
  local FILE=$1
  if [ ! -e "${FILE}" ]; then
    abort "get_sha256_from_file requires a file argument that exists [file]"
  fi

  local CMD=$(sha256sum_cmd)
  echo $(${CMD} "${FILE}" | awk '{print $1}')
}
get_sha1_from_file() {
  local FILE=$1
  if [ ! -e "${FILE}" ]; then
    abort "get_sha1_from_file requires a file argument that exists [file]"
  fi

  local CMD=$(sha1sum_cmd)
  echo $(${CMD} "${FILE}" | awk '{print $1}')
}
get_md5_from_file() {
  local FILE=$1
  if [ ! -e "${FILE}" ]; then
    abort "get_md5_from_file requires a file argument that exists [file]"
  fi

  local CMD=$(md5sum_cmd)
  echo $(${CMD} "${FILE}" | awk '{print $1}')
}
# STEP 5
# Call assert_signature passing in the variable from step 3 and variable
# from step 4.  For example:
# Here is the function.  Note, strip_space_and_lowercase is called on both
# input variables, so you don't have to do that before.
assert_signature() {
  local EXPECTED="$(strip_spaces_and_lowercase ${1})"
  local ACTUAL="$(strip_spaces_and_lowercase ${2})"
  if [ "${EXPECTED}x" == "x" ] || [ "${ACTUAL}x" == "x" ]; then
    abort "assert_signature takes 2 arguments [expected] [actual]"
  fi

  log Checking signatures match
  if [ "${EXPECTED}" == "${ACTUAL}" ]; then
    green "Signatures match, the downloaded file is not corrupt."
  else
    abort "Signatures did not match. Expected ${EXPECTED} but was ${ACTUAL}."
  fi
}

# The next set of functions are helpers that can be called from each script.
# include the other modules
log() {
  # use log for no color
  echo -e "${@}\n"
}
yellow() {
  # to alert the user to do something they can ignore
  log "${_yellow}${@}${_normal}"
}
red() {
  # error message, something bad happened
  log "${_red}${@}${_normal}"
}
green() {
  # everything is good
  log "${_green}${@}${_normal}"
}
blue() {
  # doesn't mean anything, and hard to see.
  log "${_blue}${@}${_normal}"
}
light_blue() {
  # information log, different from system output
  log "${_light_blue}${@}${_normal}"
}
abort() {
  red "Aborting.." 1>&2
  red "$@" 1>&2
  exit 1
}
os() {
  echo $(uname -s)
}
is_mac() {
  test "$(os)" == "Darwin"
}
is_linux() {
  test "$(os)" == "Linux"
}
download_file() {
  local URL=$1
  local OUTFILE=$2
  local CURL_ARGS=""
  if [ "${URL}x" == "x" ] || [ "${OUTFILE}x" == "x" ]; then
    abort "download_file takes at least arguments [url] [outfile], the third is optional [curl_args]"
  fi
  if [ -e ${OUTFILE} ]; then
    yellow File ${OUTFILE} already downloaded
  else
    log Downloading $URL
    if _is_debug; then
      light_blue "URL: ${URL}"
      light_blue "OUTFILE: ${OUTFILE}"
      CURL_ARGS="${CURL_ARGS} -v"
    fi
    if [ "${CURL_ARGS}x" == "x" ]; then
      curl -L "${URL}" -o "${OUTFILE}" || abort "Failed to download ${OUTFILE}"
    else
      curl -L "${URL}" ${CURL_ARGS} -o "${OUTFILE}" || abort "Failed to download ${OUTFILE}"
    fi
  fi
}
sha256sum_cmd() {
  local CMD=""
  if is_mac; then
    CMD="shasum -a 256"
  elif is_linux; then
    CMD="sha256sum"
  else
    abort No shasum 256 command found on $(os)
  fi
  echo "${CMD}"
}
sha1sum_cmd() {
  local CMD=""
  if is_mac; then
    CMD="shasum -a 1"
  elif is_linux; then
    CMD="sha1sum"
  else
    abort No shasum 1 command found on $(os)
  fi
  echo "${CMD}"
}
md5sum_cmd() {
  local CMD=""
  if is_mac; then
    CMD="md5"
  elif is_linux; then
    CMD="md5sum"
  else
    abort No md5sum comman found on $(os)
  fi
  echo "${CMD}" 
}
strip_spaces_and_lowercase() {
  # note, no check to ensure you pass in a string
  local SHA=$(echo "${@}" | tr -d " " | awk '{print tolower($0)}')
  if _is_debug; then
    # must log to stderr, since this function returns a string
    light_blue "SHA ${SHA}" 1>&2
  fi
  echo "${SHA}"
}

# These last functions are helpers for the functions above and are really
# meant to be "private".  They are not meant to be used in other scripts.
# Each name starts with an underscore.
_script_dir() {
    if [ -z "${SCRIPT_DIR}" ]; then
    # even resolves symlinks, see
    # http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
        local SOURCE="${BASH_SOURCE[0]}"
        while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
        SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    fi
    echo "${SCRIPT_DIR}"
}
_blue=$(tput setaf 4)
_green=$(tput setaf 2)
_red=$(tput setaf 1)
_yellow=$(tput setaf 3)
_light_blue=$(tput setaf 6)
_normal=$(tput sgr0)
_is_debug() {
  # run with DEBUG=1 ./download-whatever.sh to help troubleshoot
  test "${DEBUG}x" != "x"
}
_ensure_executables() {
  local EXES=""
  which curl 2>&1 >/dev/null        || EXES="curl "
  which awk 2>&1 >/dev/null         || EXES="${EXES}awk "
  which cat 2>&1 >/dev/null         || EXEC="${EXES}cat "
  if is_mac; then
    which shasum 2>&1 >/dev/null    || EXES="${EXES}shasum "
    which md5 2>&1 >/dev/null       || EXES="${EXES}md5 "
  elif is_linux; then
    which sha1sum 2>&1 >/dev/null   || EXES="${EXES}sha1sum "
    which sha256sum 2>&1 >/dev/null || EXES="${EXES}sha256sum "
    which md5sum 2>&1 >/dev/null    || EXES="${EXES}md5sum "
  else
    abort "This script is not supported on $(os), sorry"
  fi
  if [ "${EXES}x" != "x" ]; then
    abort "The following executables are required on $(os): ${EXES}"
  fi
}

# when this file is sourced, let's make sure you have the executables
_ensure_executables
