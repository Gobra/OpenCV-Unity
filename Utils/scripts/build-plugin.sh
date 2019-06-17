#!/bin/bash

# ************************************************************************************
# plugin BUILD SCRIPT
# ************************************************************************************
# Script designed to build the project completely for a single $platform-$arch pair
# with all the sub-projects in correct order, assembles single binary when necessary.
# Examples:
# - build OpenCV, DLib and wrapper for Windows/x86_64, output .lib to the temp directory (see build-library.sh)
# - build OpenCV, DLIb and wrapper for iOS/armv7, combine all output .a libs into a single fat binary

# Arguments:
# - [required] platform (-p, --platform)		- target platform name { windows, android, macos, ios }
# - [optional] type (--type)					- full or trial, defaults to "full"
# - [required] version (-v , --version)			- library version
# - [required] arch (-a, --arch)				- target architecture (i.e. x86, armv7 etc, depends on targte platform and make system)
# - [required] makesys (-m, --makesys)			- CMake generator name (ex. "Xcode", "Unix Makesfiles" etc, see cmake man)
# - [optional] rebuild (-r, --rebuild)			- just a flag with no additional arguments, when set script will erase any existing build data, else previous builds data will be reused
# - [optiona] wrapper only (-w, --wrapper-only) - signal to build only wrapper, leave OpenCV, dlib etc. as is. Might lead to errors if libs are not built
#
# DOES NOT:
# - Create .frameworks, bundle or whichever platform-dependent thing you may think of
#
# OUTPUT:
# - see root/utils/scripts/build-library.sh OUTPUT section, count it per each library in this script
# - additionaly copies or assembles output library to the root/bin/$plugin_version/$platform/$arch folder
#
# Final installation steps (universal binaries, frameworks etc.) are taken care by upper-level script

# this function help to execute some command as error-fatal
function required {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "FATAL ERROR: \"$@\" <-- command failed"
        exit 1
    fi
}

# compute paths
cd $(dirname "$0")
SCRIPTDIR=$PWD
BASEDIR=$(dirname $(dirname "$SCRIPTDIR"))

BIN="$BASEDIR/bin"
TEMP="$BASEDIR/temp"
SOURCE="$BASEDIR/source"

# parse input
arguments=("$@")
argsCount=${#arguments[@]}
index=0

rebuild=0
lib_compile=""
type="full"
while [ $index -lt $argsCount ]; do
    argument=${arguments[$index]}
    index=$(($index + 1))

    case $argument in
        -p | --platform )		platform="${arguments[$index]}";        index=$(($index + 1));;
        -v | --version )		version_plugin="${arguments[$index]}";  index=$(($index + 1));;
		-t | --type )			type="${arguments[$index]}";			index=$(($index + 1));;
        -a | --arch )			arch="${arguments[$index]}";            index=$(($index + 1));;
        -m | --makesys )		makesystem="${arguments[$index]}";      index=$(($index + 1));;
		-r | --rebuild )		rebuild=1;;
		-w | --wrapper-only )	lib_compile="--no-compile";;

        * ) break ;;
    esac
done

if [ -z "$platform" ]; then
    echo "No 'platform' argument supplied, must be one of { windows, macos, ios, android }"
    exit 1
fi

if [ -z "$arch" ]; then
    echo "No 'arch' argument supplied, must be one of { 32, 64, any of android ABI (see android toolchain) }"
    exit 1
fi

VER_FILE="$SCRIPTDIR/../Versions/$version_plugin.txt"
if [ -z "$version_plugin" ]; then
    echo "No 'version' argument supplied, must be valid plugin version number"
    exit 1
elif [ ! -f "$VER_FILE" ]; then
    echo "Version $version_plugin is specified, but the is no $VER_FILE file."
    exit 1
fi

if [ -z "$makesystem" ]; then
    echo "No 'makesys' argument supplied, must be valid CMake generator ('Unix Makefiles', 'MSYS Makefiles', 'Ninja' etc.)"
    exit 1
fi

echo "###################################################################################"
echo "Building plugin: platform = $platform, version = $version_plugin, architecture = $arch, generator = $makesystem"
echo "###################################################################################"
IFS=$'\n' read -d '' -r -a lines < "$VER_FILE"

version_opencv=${lines[0]}
version_dlib=${lines[1]}
version_wrapper=${lines[2]}

echo "Plugin version:       $version_plugin"
echo "OpenCV version:       $version_opencv"
echo "DLib version:         $version_dlib"
echo "SharpExtern version:  $version_wrapper"
echo "Rebuild mode:         $rebuild"
echo "Wrapper only:         $wrapper_only"
echo ""

rebuild_option=""
if [ $rebuild -eq 1 ]; then
	rebuild_option="--rebuild"
fi

# Aux function
compile_library()
{
    local fname=$1
    local fver=$2
	local suffix=$3
    local fopt=$4
	local fextra=$5
    local foutval=$6
    local foutmarker=$(printf "%s_%s_%s_OUTPUD_DIR=" "$fname" "$platform" "$arch")
    compile_cmd="bash build-library.sh --name $fname --platform $platform --arch $arch --makesys \"$makesystem\" --version $fver --options \"$fopt\" $rebuild_option $fextra"

	if [ ! -z "$suffix" ]; then
		compile_cmd="$compile_cmd --suffix $suffix"
	fi

    # another damn hint to print to console and capture result
    local console=$(eval "$compile_cmd" 2>&1 |tee /dev/tty)
    local exit_code=$?

    # check for error
    if [ $exit_code -ne 0 ]; then
        echo "FATAL ERROR: Failed to compile { lib = $fname, platform = $platform, arch = $arch }"
        echo "failed command: $compile_cmd"
        exit 1
    fi

    # now we must parse
    local result=$(echo "$console" | grep -A 5 $foutmarker | sed -e "s/^$foutmarker//")
    eval "$foutval=$result"
}

# *****************************************
# OpenCV
# *****************************************
CONTRIB_DIR="$SOURCE/contrib-$version_opencv/modules"

# macOS/i386 does not compile with LAPACK (Apple Accelerator framework)
if [ "$platform" == "macos" ]; then
    :

    # NOTE:
    # this is turned off as we don't need i386 version and x86_64 does compile fine
    # with LAPACK
    #opencv_issue="-DWITH_LAPACK=OFF"
fi

# NOTE:
# I have also tried -DBUILD_opencv_highgui=OFF, but HIGHGUI is used all over Contrib modules without any IFDEF's so it's virtually impossible to
# cut this module off, at leats not until we're ready to manually fix A LOT of Contrib stuff

# Those modules can be turned off should we have no need for video/capture support
# -DWITH_AVFOUNDATION=OFF -DWITH_DSHOW=OFF -DWITH_VFW=OFF -DWITH_FFMPEG=OFF
opencv_dependencies="-DWITH_VTK=OFF -DWITH_1394=OFF -DWITH_GSTREAMER=OFF DWITH_V4L=OFF -DWITH_QT=OFF -DWITH_GTK=OFF -DWITH_GPHOTO2=OFF -DWITH_MATLAB=OFF -DWITH_TIFF=OFF -DWITH_JASPER=OFF -DWITH_JPEG=OFF -DWITH_PNG=OFF -DWITH_CUDA=OFF"
opencv_modules="-DBUILD_opencv_hdf=OFF -DBUILD_OPENCV_JAVA=OFF -DBUILD_OPENCV_WORLD=OFF -DBUILD_OPENCV_PYTHON=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_opencv_apps=OFF -DBUILD_ANDROID_EXAMPLES=OFF -DBUILD_DOCS=OFF"
opencv_options="$opencv_dependencies $opencv_modules $opencv_issue -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_WITH_DEBUG_INFO=OFF -Wno-deprecated -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_WARN_DEPRECATED -DOPENCV_EXTRA_MODULES_PATH=\"$CONTRIB_DIR\""

required compile_library "opencv" "$version_opencv" "" "$opencv_options" "$lib_compile" "opencv_output"

# macOS: 3rd party IPPICV library has i386/x86_64 archs, we need to strip it
# this step is required since it's likely to have 64-bit only macOS app and 50mb+ extra weight of extra arch is just a loss
if [ "$platform" == "macos" ]; then
    required mv "$opencv_output/share/OpenCV/3rdparty/lib/libippicv.a" "$opencv_output/share/OpenCV/3rdparty/lib/libippicv-fat.a"
    required ditto --arch $arch "$opencv_output/share/OpenCV/3rdparty/lib/libippicv-fat.a" "$opencv_output/share/OpenCV/3rdparty/lib/libippicv.a"
    required rm "$opencv_output/share/OpenCV/3rdparty/lib/libippicv-fat.a"
fi

echo ""
echo "OpenCV build successful, output = $opencv_output"
echo ""

# *****************************************
# DLib
# *****************************************
dlib_flags="-Wno-deprecated -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_WARN_DEPRECATED "
dlib_modules="-DDLIB_STATIC_ONLY=ON -DDLIB_ENABLE_ASSERTS=OFF -DDLIB_ENABLE_STACK_TRACE=OFF -DDLIB_USE_CUDA=OFF -DDLIB_NO_GUI_SUPPORT=ON -DDLIB_PNG_SUPPORT=OFF -DDLIB_GIF_SUPPORT=OFF -DDLIB_JPEG_SUPPORT=OFF -DDLIB_LINK_WITH_SQLITE3=OFF"
dlib_options="$dlib_flags $dlib_modules"

required compile_library "dlib" "$version_dlib" "" "$dlib_options" "$lib_compile" "dlib_output"

echo ""
echo "DLib build successful, output = $dlib_output"
echo ""

# *****************************************
# SharpExtern
# *****************************************
sharpextern_options="-Wno-deprecated -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_WARN_DEPRECATED -DCMAKE_PREFIX_PATH=\"$TEMP/$platform/$arch/libs\""

suffix=""
if [ $type == "trial" ]; then
	suffix="trial"
	sharpextern_options="$sharpextern_options -DCMAKE_WRAPPER_TRIAL_VERSION=YES"
fi

required compile_library "sharpextern" "$version_wrapper" "$suffix" "$sharpextern_options" "" "sharpextern_output"

echo ""
echo "SharpExtern build successful, output = $sharpextern_output"
echo ""

# *****************************************
# Assemble
# *****************************************
plugin_OUTPUT="$BIN/OpenCvSharpExtern-$version_plugin/$type/$platform/$arch"

if [ ! -d "$plugin_OUTPUT" ]; then
    required mkdir -p "$plugin_OUTPUT"
fi

echo "-----------------------------------------------------------------------------------"
echo "Assembling & installing the library:"
echo "	platform = $platform, architecture = $arch, version = $version_plugin"
echo "	destination = $plugin_OUTPUT"
echo "-----------------------------------------------------------------------------------"

case $platform in
    # just copy file
    "windows")  required cp "$sharpextern_output/bin/OpenCvSharpExtern.dll" "$plugin_OUTPUT/OpenCvSharpExtern.dll" ;;
    "android")  required cp "$sharpextern_output/lib/libOpenCvSharpExtern.so" "$plugin_OUTPUT/libOpenCvSharpExtern.so" ;;
    "macos" )   required cp "$sharpextern_output/lib/libOpenCvSharpExtern.dylib" "$plugin_OUTPUT/libOpenCvSharpExtern.dylib" ;;

    # iOS - combine separate libraries into a single one
    "ios" )     required libtool -static -o "$plugin_OUTPUT/libOpenCvSharpExtern.a" "$sharpextern_output/lib/libOpenCvSharpExtern.a" "$dlib_output/lib/"*.a "$opencv_output/lib/"*.a "$opencv_output/share/OpenCV/3rdparty/lib/"*.a ;;
esac

echo ""
