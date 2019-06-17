#!/bin/bash

# ************************************************************************************
# Unity projects creation script
# ************************************************************************************
# root/Unity folder contains only project placeholders while C# wrapper, demo-scenes,
# resources and documntation are located in the root/source/unity folder
#
# this script fills each Unity placeholder to make it whole project by creating proper
# folder structure and adding symlinks to required resources

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

# ************************************************************************************
# Function: make_plugin_symlink
# $1 - root directory
# $2 - project type ("full", "trial", "desktop")
# ************************************************************************************
make_project_whole()
{
	local root=$1
	local type=$2
	local source="$root/source/unity"

	# project folder name
	local PROJDIR="$root/Unity/OpenCV+Unity"
	if [ "$type" == "trial" ]; then
		PROJDIR="$PROJDIR.Trial"
	elif [ "$type" == "desktop" ]; then
		PROJDIR="$PROJDIR.Desktop"
	fi

	# report
	echo "Making project structure for $PROJDIR"

	# proper target folders
	local asset_root="$PROJDIR/Assets"
	local asset_dir="$asset_root/OpenCV+Unity"

	if [ -d "$asset_root" ]; then
		required rm -r "$asset_root"
    fi
	required mkdir -p "$asset_dir/Assets"

	# main folders
	required ln -s "$source/opencv-sharp"	"$asset_dir/Assets/Scripts"
	required ln -s "$source/demo-scenes"	"$asset_dir/Demo"
	required ln -s "$source/documentation"	"$asset_dir/Documentation"

	if [ "$type" != "trial" ]; then
		required ln -s "$source/AssetStoreTools" "$asset_root/AssetStoreTools"
	fi

	# 'unsafe' - to the root to apply
	required ln -s "$source/unsafe.rsp" "$asset_root/gmcs.rsp"
	required ln -s "$source/unsafe.rsp" "$asset_root/smcs.rsp"
	required ln -s "$source/unsafe.rsp" "$asset_root/mcs.rsp"

	# 'unsafe' - to the Assets to make it exportable within the package
	required ln -s "$source/unsafe.rsp" "$asset_dir/gmcs.rsp"
	required ln -s "$source/unsafe.rsp" "$asset_dir/smcs.rsp"
	required ln -s "$source/unsafe.rsp" "$asset_dir/mcs.rsp"

	# trial stuff
	if [ "$type" == "trial" ]; then
		local trial_dir="$source/trial/Editor"
		local editor_dir="$asset_dir/Editor"

		required mkdir -p "$editor_dir"
		required ln -s "$trial_dir/Resources" "$editor_dir/Resources"
		required ln -s "$trial_dir/opencv+unity-editor.dll" "$editor_dir/opencv+unity-editor.dll"
	fi
}

# ************************************************************************************
# Acual script: build structure for full, trial and desktop versions
# ************************************************************************************
make_project_whole "$BASEDIR" "full"
make_project_whole "$BASEDIR" "trial"
make_project_whole "$BASEDIR" "desktop"