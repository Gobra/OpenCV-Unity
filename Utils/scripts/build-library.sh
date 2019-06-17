#!/bin/bash

# ************************************************************************************
# LIBRARY BUILD SCRIPT
# ************************************************************************************
# General script deisgned to build single libraries without any additional management
# Arguments:
# - [required] name (-n, --name) - library name, must be located in the root/source folder
# - [required] platform (-p, --platform) - target platform name { windows, android, macos, ios }
# - [required] version (-v , --version) - library version
# - [required] arch (-a, --arch) - target architecture (i.e. x86, armv7 etc, depends on targte platform and make system)
# - [required] makesys (-m, --makesys) - CMake generator name (ex. "Xcode", "Unix Makesfiles" etc, see cmake man)
# - [optional] suffix (-s, --suffix) - custom suffix to add to the lib folder name (allows to compile the same lib twice, probably with various flags)
# - [optional] options (-o, --options) - custom cmake arguments for the library (ex. OpenCV modules list, C++ library type etc.), empty by default
# - [optional] no-compile (-n, --no-compile) - signals whether library compilation is skipped, false by default
# - RETURNS:   last printed data from ths script is "$name_$platform_$arch_OUTPUT_DIR=/path/to/output/data/folder" that cna be parsed by the parent script
#
# DOES NOT:
# - Compile dependencies (unless library CMake project does that)
# - Strip symbols
# - Assemble FAT binaries
# - Assemble Uniersla binaries
# - Create .frameworks, bundle or whichever platform-dependent thing you may think of
#
# OUTPUT:
# - Creates root/temp/$platform/$arch/build/$name directory, there goes all the temporary files
# - Creates root/temp/$platform/$arch/libs/$name directory, that's where compiled library is copied (w/o any headers, just plain binary)
#
# Each specific library should have another script on top of this one to take care about
# any additional build steps thta might be necessary

# this function help to execute some command as error-fatal
function required {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "FATAL ERROR: \"$@\" <-- command failed"
        exit 1
    fi
}

# parse arguments
arguments=("$@")
argsCount=${#arguments[@]}
index=0

rebuild=0
compile=1
suffix=""
while [ $index -lt $argsCount ]; do
    argument=${arguments[$index]}
    index=$(($index + 1))

    case $argument in
		-n | --name )		name="${arguments[$index]}";        index=$(($index + 1));;
        -p | --platform )	platform="${arguments[$index]}";    index=$(($index + 1));;
        -a | --arch )		arch="${arguments[$index]}";        index=$(($index + 1));;
        -m | --makesys )	makesystem="${arguments[$index]}";  index=$(($index + 1));;
		-o | --options )	params="${arguments[$index]}";      index=$(($index + 1));;
		-v | --version )	version="${arguments[$index]}";     index=$(($index + 1));;
		-s | --suffix )		suffix="-${arguments[$index]}";		index=$(($index + 1));;
		-r | --rebuild )	rebuild=1;;
		-n | --no-compile)	compile=0;;

        * ) break ;;
    esac
done

if [ -z "$name" ]; then
    echo "No 'name' argument supplied, must be valid library name from the Source directory"
	exit 1
fi

if [ -z "$version" ]; then
    echo "No 'version' argument supplied, must be valid library version number"
    exit 1
fi

if [ -z "$platform" ]; then
    echo "No 'platform' argument supplied, must be one of { windows, macos, ios, android }"
	exit 1
fi

if [ -z "$arch" ]; then
    echo "No 'arch' argument supplied, must be one of { x86, x86_64, any of android ABI (see android toolchain), Apple archs }"
	exit 1
fi

if [ -z "$makesystem" ]; then
    echo "No 'makesys' argument supplied, must be valid CMake generator ('Unix Makefiles', 'MSYS Makefiles', 'Ninja' etc.)"
	exit 1
fi

# prepare
# make $PWD command refer to absolute roots
cd $(dirname "$0")
SCRIPTDIR=$PWD
BASEDIR=$(dirname $(dirname "$SCRIPTDIR"))

# paths
BIN="$BASEDIR/bin"
TEMP="$BASEDIR/temp"
SOURCE="$BASEDIR/source"
OUTDIR="$TEMP/$platform/$arch"

LIBNAME="$name-$version"
LIBSOURCE="$SOURCE/$LIBNAME"
INSTALLDIR="$OUTDIR/libs/$LIBNAME$suffix"
LIBOUTPUT="$OUTDIR/build/$LIBNAME$suffix"

echo "-----------------------------------------------------------------------------------"
echo "Building library \"$name\":"
echo "	platform = $platform, architecture = $arch, version = $version, generator = $makesystem"
echo "  compile = $compile, user defined options = $params"
echo "	source = $LIBSOURCE, output = $LIBOUTPUT"
echo "-----------------------------------------------------------------------------------"

if [ $compile -eq 0 ]; then
	echo "Library compilation skipped as requested by user"
else
	# cleanup?
	if [ $rebuild -eq 1 ]; then
		echo "Rebuil mode, erasing:"
		echo "	- $LIBOUTPUT"
		echo "	- $INSTALLDIR"

		if [ -d "$LIBOUTPUT" ]; then
			required rm -f -r "$LIBOUTPUT"
		fi

		if [ -d "$INSTALLDIR" ]; then
			required rm -f -r "$INSTALLDIR"
		fi

		echo ""
	fi

	# prepare build folder
	if [ ! -d "$LIBOUTPUT" ]; then
		required mkdir -p "$LIBOUTPUT"
	fi
	cd "$LIBOUTPUT"

	# choose toolchain & define platform-specific options:
	# 1. try to choose arch-specific toolchain
	# 2. try to choose wide platform-specific toolchain
	# 3. give up and take a rest
	TOOLCHAINSDIR="$SCRIPTDIR/../toolchains"
	toolchain="TOOLCHAINSDIR/toolchain.$platform-$arch.cmake"
	if [ ! -f "$toolchain" ]; then
		toolchain="$TOOLCHAINSDIR/toolchain.$platform.cmake"
		if [ ! -f "$toolchain" ]; then
			toolchain=""
		fi
	fi

	if [ ! -z "$toolchain" ]; then
		toolchain="-DCMAKE_TOOLCHAIN_FILE=\"$toolchain\""
	fi

	# build option
	params="$params $toolchain"
	case $platform in
		"windows" ) params="$params -DBUILD_WITH_STATIC_CRT=ON" ;;
		"android" ) params="$params -DANDROID_ABI=$arch -DANDROID_STL=gnustl_static" ;;
		"ios" )		params="$params -DIOS_ARCH=$arch -DCMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET=\"7.0\"" ;;
		"macos" )	params="$params -DCMAKE_OSX_ARCHITECTURES=\"$arch\" -DCMAKE_OSX_DEPLOYMENT_TARGET=\"10.10\"" ;;
	esac

	cmake_command="cmake -G \"$makesystem\" $params -DCMAKE_INSTALL_PREFIX:PATH=\"$INSTALLDIR\" -DCMAKE_BUILD_TYPE=Release \"$LIBSOURCE\""
	echo "Building $platform/$name-$arch project with cmake command:"
	echo "$cmake_command"
	required eval $cmake_command

	# makefiles
	if [[ $makesystem == *"Makefiles"* ]]; then
		required make -j 4
		required make install
	# IDE projects
	else
		# XCode
		if [[ $makesystem == "Xcode" ]]; then
			sdk_type=""
			if [ "$platform" == "ios" ]; then
				sdk_type="iphoneos"
			else
				sdk_type="macosx"
			fi

			makecommand=$"xcodebuild ARCHS=$arch -target install -sdk $sdk_type -configuration Release -parallelizeTargets -jobs 4"
			required eval $makecommand
		# MSVC
		else
			required cmake --build . --config Release --target INSTALL
		fi
	fi
fi

RESULT_NAME=$(printf "%s_%s_%s_OUTPUD_DIR" "$name" "$platform" "$arch")
echo "$RESULT_NAME=$INSTALLDIR"
echo ""
