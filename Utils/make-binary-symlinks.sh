#!/bin/bash

# ************************************************************************************
# Symlinks creation script
# ************************************************************************************
# In order to use Unity3d without copying binary data, we create symlinks from built
# native plug-ins binaries into the Unity3d project folder
#
# Arguments:
# - [required] version (-v, --version)  - library version, the only required parameter
# - [optional] force (-f, --force)		- will erase Plugins directory in Unity and re-create everything
#
# Requires:
# - Script expects build-all to be already executed as it scans root/bin for plug-ins.
#   If there are no built pug-ins, script doesn't do anything
#
# In the Unity3d project dir:
# - root/unity/{Package}/Assets/OpenCV+Unity/Plugins
#   - macOS
#       - OpenCvSharpExtern.bundle      --> root/bin/$version/macOS/OpenCvSharpExtern.bundle
#   - iOS
#       - libOpenCvSharpExtern.a        --> root/bin/$version/iOS/libOpenCvSharpExtern.a
#   - Android
#       - armeabi-v7a
#           - libOpenCvSharpExtern.so   --> root/bin/$version/android/armeabi-v7a/libOpenCvSharpExtern.so
#       - x86
#           - libOpenCvSharpExtern.so   --> root/bin/$version/android/x86/libOpenCvSharpExtern.so
#   - Windows
#       - x86
#           - OpenCvSharpExtern.dll     --> root/bin/$version/windows/x86/OpenCvSharpExtern.dll
#       - x86_64
#           - OpenCvSharpExtern.dll     --> root/bin/$version/windows/x86_64/OpenCvSharpExtern.dll
#
# {Package} means exact asset package name, it could be full version, desktop version or trial version
# The structure is optional, script will pass platforms and version that does not have pre-built binary
# to link with

# this function help to execute some command as error-fatal
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

arguments=("$@")
argsCount=${#arguments[@]}
index=0

force=0
while [ $index -lt $argsCount ]; do
    argument=${arguments[$index]}
    index=$(($index + 1))

    case $argument in
        -v | --version ) version_plugin="${arguments[$index]}"; index=$(($index + 1));;
		-f | --force ) force=1 ;;

        * ) break ;;
    esac
done

if [ -z "$version_plugin" ]; then
    echo "No 'version' argument supplied, must be valid plugin version number"
    exit 1
fi

# ************************************************************************************
# Function: make_plugin_symlink
# $1 - Binary Directory (something like root/bin/OpenCvSharpExtern-{version}/full)
# $2 - Destination directory
# $3 - Plugin version (macOS, Windows/x86 etc.)
# ************************************************************************************
make_plugin_symlink()
{
	local BINARYDIR=$1
	local PLUGINSDIR=$2
	local dir=$3

    local sourcedir="$BINARYDIR/$dir"
    echo "Scanning $sourcedir"
    if [ -d "$sourcedir" ]; then
        local targetdir="$PLUGINSDIR/$dir"
        if [ ! -d "$targetdir" ]; then
            required mkdir -p "$targetdir"
        fi

        # search for input lib
        local lib=""
        for d in "$sourcedir/"*OpenCvSharpExtern*; do
            echo "Found plugin $d"
            lib="$d"
            break
        done

        # symlink
        local name=$(basename "$lib")
        local target="$targetdir/$name"
        if [[ -d "$target" ]] || [[ -f "$target" ]]; then
            required touch "$target"
        else
            required ln -s "$lib" "$target"
        fi
    fi
}

# ************************************************************************************
# Function: make_project_symlink
# $1 - version ("1.0" etc.)
# $2 - type ("full", "trial", "desktop")
# $3 - force flag (0 or 1)
# ************************************************************************************
make_project_symlink()
{
	local ver=$1
	local type=$2
	local force_flag=$3
	local proj="OpenCV+Unity"
	local binsubdir="full"

	if [ "$type" == "trial" ]; then
		binsubdir="trial"
		proj="$proj.Trial"
	elif [ "$type" == "desktop" ]; then
		proj="$proj.Desktop"
	fi

	echo "-----------------------------------------------------------------------------------"
	echo "Making binary symlinks for $type-$ver"
	echo "-----------------------------------------------------------------------------------"
	local BINARYDIR="$BASEDIR/bin/OpenCvSharpExtern-$ver/$binsubdir"
	local PLUGINSDIR="$BASEDIR/Unity/$proj/Assets/OpenCV+Unity/Plugins"

	if [ $force_flag -eq 1 ]; then
		echo "Force symlinks: erasing \"$PLUGINSDIR\""
		required rm -r -f "$PLUGINSDIR"
	fi

	required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "macOS"
	required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "Windows/x86"
	required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "Windows/x86_64"

	if [ "$type" != "desktop" ]; then
		required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "iOS"
		required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "Android/armeabi-v7a"
		required make_plugin_symlink "$BINARYDIR" "$PLUGINSDIR" "Android/x86"
	fi
}

# ************************************************************************************
# Acual script: build symlinks for full, trial and desktop versions
# ************************************************************************************
make_project_symlink $version_plugin "full" $force
make_project_symlink $version_plugin "trial" $force
make_project_symlink $version_plugin "desktop" $force