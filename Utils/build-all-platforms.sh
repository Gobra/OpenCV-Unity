#!/bin/bash

# ************************************************************************************
# WHOLE THING BUILD SCRIPT
# ************************************************************************************
# Script designed to build everything this host platform is capable of building with
# minimum input from the user
#
# Arguments:
# - [required] version (--version)					- library version
# - [optional] type (--type)						- full or trial, defaults to "full"
# - [optional] ndkpath (--ndkpath)					- full path to the valid Android NDK, when empty the script searcher for "root/../Android/ndk-r10e", if still nothing - it does not build Android target
# - [optional] rebuild (--rebuild)					- just a flag with no additional arguments, when set script will erase any existing build data, else previous builds data will be reused
# - [optional] wrapper-only (--wrapper-only)		- signals whether we need only wrapper to be build, without dependencies (might lead to failed build as it makes no checks)
# - [optional] no-{$platform} (--no-windows, --no-android, --no-ios, --no-macos) - special flag signaling target platform is not needed
#
# OUTPUT files with project build for all targets supported by this platform, examples:
# On macOS:
# - root/bin/OpenCvSharp-$version/$type
#   - macOS
#       - OpenCvSharpExtern.bundle      <-- output bundle for macOS
#       - i386
#       - x86_64
#   - iOS
#       - libOpenCvSharpExtern.a        <-- output library for iOS
#       - armv7
#       - arm64
#   - Android [optional, if we have NDK]
#       - armeabi-v7a
#           - libOpenCvSharpExtern.so   <-- output library for Android/armv7
#       - x86
#           - libOpenCvSharpExtern.so   <-- output library for Android/x86
#
# On Windows:
# - root/bin/$version
#   - Windows
#       - x86
#          - OpenCvSharpExtern.dll      <-- output library for Windows/x86
#       - x86_64
#          - OpenCvSharpExtern.dll      <-- output library for Windows/x86_64
#   - Android [optional]
#       ... same as example above ...
#
# Script output can be used directly with Unity3d

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
BIN="$BASEDIR/bin"

arguments=("$@")
argsCount=${#arguments[@]}
index=0

# build flags: windows, android, macos, ios
targets=(1 1 1 1)
rebuild=0
wrapper_only=""
type="full"

while [ $index -lt $argsCount ]; do
    argument=${arguments[$index]}
    index=$(($index + 1))

    case $argument in
        --ndkpath ) ndkpath="${arguments[$index]}";         index=$(($index + 1));;
        --version ) version_plugin="${arguments[$index]}";  index=$(($index + 1));;
		--type )	type="${arguments[$index]}";			index=$(($index + 1));;

		# optional command to avoid some actions (building, installing)
		--no-windows )		targets[0]=0 ;;
		--no-android )		targets[1]=0 ;;
		--no-macos )		targets[2]=0 ;;
		--no-ios )			targets[3]=0 ;;
		--wrapper-only )	wrapper_only="--wrapper-only" ;;

		# general rebuild flag
		--rebuild ) rebuild=1 ;;
        * ) break ;;
    esac
done

if [ -z "$ndkpath" ]; then
	root=$(dirname $BASEDIR)
	defndk="$root/android/ndk-r10e"
    if [ -d "$defndk" ]; then
		ndkpath=$defndk
	fi
else
	if [ ! -d "$ndkpath" ]; then
		echo "Android NDK is not found ($ndkpath)."
		exit 1
	fi
fi

VER_FILE="$SCRIPTDIR/versions/$version_plugin.txt"
if [ -z "$version_plugin" ]; then
    echo "No 'version' argument supplied, must be valid plugin version number"
    exit 1
elif [ ! -f "$VER_FILE" ]; then
    echo "Version $version_plugin is specified, but the is no $VER_FILE file."
    exit 1
fi

echo "###################################################################################"
echo "Testing build system"
echo "###################################################################################"
nixmakesys=""

# do not build Win on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
	nixmakesys="Unix Makefiles"
	targets[0]=0

	echo "Host: macOS"
# do not build Mac and iOS on Win
elif [[ "$OSTYPE" == "msys" ]]; then
	nixmakesys="MSYS Makefiles"
    targets[2]=0
	targets[3]=0

	echo "Host: Windows MSYS"
fi

# do not build Android if we have no NDK
if [ -z "$ndkpath" ]; then
	targets[1]=0
fi

# report
echo "Build targets:"
if [ ${targets[0]} -eq 1 ]; then
	echo "	- Windows { x86, x86_64 }"
fi

if [ ${targets[1]} -eq 1 ]; then
	echo "	- Android { armeabi-v7a, x86 }, NDK path=$ndkpath"
fi

if [ ${targets[2]} -eq 1 ]; then
	echo "	- macOS { i386, x86_64 }"
fi

if [ ${targets[3]} -eq 1 ]; then
	echo "	- iOS { armv7, arm64 }"
fi

echo ""
rebuild_option=""
if [ $rebuild -eq 1 ]; then
	rebuild_option="--rebuild"
fi

OUTDIR="$BIN/OpenCvSharpExtern-$version_plugin/$type"
# *****************************************
# Windows
# *****************************************
if [ ${targets[0]} -eq 1 ]; then
	# x86
	required bash ./scripts/build-plugin.sh --type "$type" --platform windows --arch x86 --makesys "Visual Studio 14 2015" --version $version_plugin $rebuild_option $wrapper_only
	# x64
	required bash ./scripts/build-plugin.sh --type "$type" --platform windows --arch x86_64 --makesys "Visual Studio 14 2015 Win64" --version $version_plugin $rebuild_option $wrapper_only
fi

# *****************************************
# Android
# *****************************************
if [ ${targets[1]} -eq 1 ]; then
	export ANDROID_NDK="$ndkpath"

	# armv7
	required bash ./scripts/build-plugin.sh --type "$type" --platform android --version $version_plugin --arch armeabi-v7a --makesys "$nixmakesys" $rebuild_option $wrapper_only
	# x86
	required bash ./scripts/build-plugin.sh --type "$type" --platform android --version $version_plugin --arch x86 --makesys "$nixmakesys" $rebuild_option $wrapper_only
fi

# *****************************************
# Apple general
# *****************************************

# aux function that combines libs into a universal binary
function make_universal {
    local platform=$1
    local type=$2
    local libs=""
    local lib_output="$OUTDIR/$platform/libOpenCvSharpExtern.$type"
    local lib_count=0

    printf "making universal binary for platform \"$platform\", scanning \"$OUTDIR/$platform\""

    # search for libs
    for d in "$OUTDIR/$platform/"*; do
        if [[ -d "$d" ]] && [[ "$d" != *".bundle" ]]; then
            libs="$libs $d/libOpenCvSharpExtern.$type"
            lib_count=$((lib_count + 1))
        fi
    done

    # merge, lipo universla binary or simply copy single file should there be only one
    if [ $lib_count -gt 0 ]; then
        if [ $lib_count -ge 1 ]; then
            lipo_command="lipo -create $libs -output $lib_output"
            echo " - merging $lib_count libraries into the fat binary"
        else
            lipo_command="cp $libs $lib_output"
            echo " - copying library into the new location (single ARCH lib)"
        fi

        required eval $lipo_command
    else
        printf "\nFATAL: $OUTDIR does not have libraries for platform \"$platform\"\n"
        exit 1
    fi
}

# builds macOS loadable bundle around library
function make_bundle {
    platform=$1
    libname=$2
    infoplist=$3

    source_file="$OUTDIR/$platform/lib$libname.dylib"
    bundle_dir="$OUTDIR/$platform/$libname.bundle"
    echo "Building macOS bundle: $source_file -> $bundle_dir"

    # structure
    if [ -d "$bundle_dir" ]; then
        required rm -r -f "$bundle_dir"
    fi
    required mkdir -p "$bundle_dir/Contents/MacOS"
    required mkdir -p "$bundle_dir/Contents/Resources"
    required mv "$source_file" "$bundle_dir/Contents/MacOS/$libname"
    required cp "$infoplist" "$bundle_dir/Contents/Info.plist"

    sed_command="sed -i '' 's/\${SHARPEXTERN_VERSION_MARKER}/$version_plugin/g' '$bundle_dir/Contents/Info.plist'"
    #echo "$sed_command"
    required eval $sed_command
}

# *****************************************
# macOS
# *****************************************
if [ ${targets[2]} -eq 1 ]; then
	# i386
    #required bash ./scripts/build-plugin.sh --type "$type" --platform macos --version $version_plugin --arch i386 --makesys "Xcode" $rebuild_option $wrapper_only
	# x64
    required bash ./scripts/build-plugin.sh --type "$type" --platform macos --version $version_plugin --arch x86_64 --makesys "Xcode" $rebuild_option $wrapper_only

	# lipo to make universal binary
    make_universal  "macos" "dylib"
    make_bundle     "macos" "OpenCvSharpExtern" "$SCRIPTDIR/toolchains/Info.plist"
fi

# *****************************************
# iOS
# *****************************************
if [ ${targets[3]} -eq 1 ]; then
	# armv7
    required bash ./scripts/build-plugin.sh --type "$type" --platform ios --version $version_plugin --arch armv7 --makesys "Xcode" $rebuild_option $wrapper_only
	# x64
    required bash ./scripts/build-plugin.sh --type "$type" --platform ios --version $version_plugin --arch arm64 --makesys "Xcode" $rebuild_option $wrapper_only

    # lipo to make universal binary
    make_universal "ios" "a"
fi