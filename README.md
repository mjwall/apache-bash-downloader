# Apache Bash Downloader

# Description

Just a simple scripts to download stuff from Apache.  I couldn't find a utility
to programmatically download binaries and do the following:

1. Use the closer.cgi to find a mirror so I wasn't pinging one server all the time

2. Parse the signatures and verify the download, because every project packages signatures 
differently.

These scripts are designed for any tool that needs to download one of these
packages.  I am writing this to use in a Dockerfile.

# Usage

The download-\* scripts will download the package named in the script.  Each
script has a default version, but can override that with an environment
variable.  For example, running

  ./download-hadoop.sh

will download version 2.6.4 by default.  If you wanted to override it, run
something like

  VERSION=2.6.1 ./download-hadoop.sh

All the download-\* scripts source some common functions, defined in common.sh.
Check out the source for more information about what is going on.

# Details

Most of these scripts download from Apache mirrors.  Therefore it is possible the
version of a package are no longer hosted there.  For example, on 22 June 2016,
most mirrors do not have hadoop prior to 2.5.2.  Some mirrors are better than
others in terms of speed.  Some mirrors fail sometimes too.

You will note a Makefile.  This has 2 targets, test and clean.  The test target
will execute all the scripts, put the artifacts in the test directory, assert
everything is working and then clean up the downloaded files for the next run
if everything passes.  You can run the clean target to remove all files in main
directory not committed in git, including the downloaded tests files if
something fails.

These scripts currently don't use gpg.  I didn't want to go through the
exercise of downloading KEYS for each project to use.

It really should be easier than this :(  Maybe there is a better way.

# Contributing

If you don't see the project you want to download, feel free to create a
ticket.  Or if you want it faster, feel free to make a pull request.
