#!/bin/bash

# stupid simple tests
# change to the test directory and run ./test.sh

source $(dirname $0)/../common.sh

SC_DIR=$(_script_dir)
#echo "Script dir is ${SC_DIR}" && exit 1

run_good_tests() {
  light_blue Running tests we expect to work
  # run defaults, then some variations
  ${SC_DIR}/download-hadoop.sh &&
    ${SC_DIR}/download-maven.sh &&
    ${SC_DIR}/download-zookeeper.sh &&
    ${SC_DIR}/download-accumulo.sh &&
    ${SC_DIR}/download-ant.sh &&
    DEBUG=1 ${SC_DIR}/download-maven.sh &&
    VERSION=3.3.6 ${SC_DIR}/download-zookeeper.sh &&
    DEBUG=1 VERSION=1.7.1 ${SC_DIR}/download-accumulo.sh &&
    VERSION=1.9.6 ${SC_DIR}/download-ant.sh
  RET=$?
  if [ "$RET" -gt 0 ]; then
    red "Something failed, leaving the files so can investigate"
    exit 1
  else
    green "All tests passed"
    log Cleaning up downloads
    for f in *.tar.gz*; do rm $f; done
  fi
}

run_failure_tests() {
  light_blue Running tests we expect to fail
  # bad version
  VERSION=3.3.4 ${SC_DIR}/download-zookeeper.sh ||
    VERSION=1.4.1 ${SC_DIR}/download-accumulo.sh ||
    VERSION=0.4.1 ${SC_DIR}/download-ant.sh
  RET=$?
  if [ "$RET" -gt 0 ]; then
    green "Expected these to fail, so we are good."
    log Cleaning up downloads
    for f in *.tar.gz*; do rm $f; done
  else
    red "Something should have failed, leaving the downloads so you investigate"
    exit 1
  fi
}

run_all() {
  # make sure we are in the test dir
  pushd ${SC_DIR}/test 2>&1 1>/dev/null
  run_good_tests && run_failure_tests
  RET=$?
  light_blue "====================================="
  light_blue Final results
  light_blue "====================================="
  if [ "$RET" -gt 0 ]; then
    red "There were failures, check the files in $(dirname $0)"
  else
    green "All good"
  fi
  popd 2>&1 1>/dev/null
  # make sure the whole scripts returns the right code
  return $RET
}

run_all
