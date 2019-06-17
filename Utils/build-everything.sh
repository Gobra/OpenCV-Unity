#!/bin/bash

# ************************************************************************************
# Arguments:
# - [required] version (--version)	- library version
# - [optional] NDK path (--ndkpath) - path to Android NDK

# this function helps to execute some command as error-fatal
function required {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "FATAL ERROR: \"$@\" <-- command failed"
        exit 1
    fi
}

# prepare
cd $(dirname "$0")
SCRIPTDIR=$PWD
BASEDIR=$(dirname "$SCRIPTDIR")
BIN="$BASEDIR/bin"

arguments=("$@")
argsCount=${#arguments[@]}
index=0

# build flags: windows, android, macos, ios
while [ $index -lt $argsCount ]; do
    argument=${arguments[$index]}
    index=$(($index + 1))

    case $argument in
        --ndkpath ) ndkpath="--ndkpath ${arguments[$index]}"; index=$(($index + 1));;
        --version ) version="--version ${arguments[$index]}"; index=$(($index + 1));;

        * ) break ;;
    esac
done

# full version
required bash ./build-all-platforms.sh --type full  $version $ndkpath
# trial
required bash ./build-all-platforms.sh --type trial $version $ndkpath --wrapper_only
# force binary symlinks
required bash ./make-binary-symlinks.sh $version --force
