cmake_minimum_required(VERSION 3.6)


# aux function to match regext case-insenitive (cmake doesn't support (i)')
function(TestLibraryPath path name)
	# local changes
	string(TOLOWER ${path} lopath)
	string(TOLOWER ${CMAKE_PREFIX_PATH} lochecker)

	IF (NOT "${lopath}" MATCHES "^${lochecker}")
		MESSAGE (FATAL_ERROR "*** '${name}' invalid install path = '${path}', should match '${CMAKE_PREFIX_PATH}'")
	ELSE()
		MESSAGE ("*** '${name}' install path = '${path}'")
	ENDIF ()
endfunction(TestLibraryPath)

# define project
project(OpenCvSharpExtern)

# force static C++ runtime
if (BUILD_WITH_STATIC_CRT)
	include ("ucm.cmake")
	ucm_set_runtime("STATIC")
endif()

# C++ lib for Apple OS
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
if (APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++")
endif()
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# OpenCV is a bit specific: it has different output folders for Windows, Android and iOS/Mac, so we have to "hint" all three
find_package(OpenCV REQUIRED PATHS "${CMAKE_PREFIX_PATH}" "${CMAKE_PREFIX_PATH}/*/Shared/OpenCV" "${CMAKE_PREFIX_PATH}/*/sdk/native/jni" NO_DEFAULT_PATH )
TestLibraryPath(${OpenCV_INSTALL_PATH} "OpenCV")

# DLib
find_package(dlib REQUIRED PATHS "${CMAKE_PREFIX_PATH}" NO_DEFAULT_PATH)
TestLibraryPath(${dlib_INSTALL_PATH} "DLib")
MESSAGE ("*** DLIBS = ${dlib_LIBS} ***")

# Include
include_directories(${OpenCV_INCLUDE_DIRS} ${dlib_INCLUDE_DIRS})

# SOURCE FILES
set(OPENCVSHARP_FILES 
	aruco.cpp
	bgsegm.cpp
	calib3d.cpp
	core.cpp
	cuda.cpp
	dlib.cpp
	face.cpp
	features2d.cpp
	flann.cpp
	highgui.cpp
	imgproc.cpp
	imgcodecs.cpp
	ml.cpp
	objdetect.cpp
	optflow.cpp
	photo.cpp
	shape.cpp
	std_vector.cpp
	stitching.cpp
	superres.cpp
	text.cpp
	tracking.cpp
	video.cpp
	videoio.cpp
	xfeatures2d.cpp
	xphoto.cpp
	utils.cpp
)

# iOS - Unity expects static library
if (IPHONEOS)
	add_library(OpenCvSharpExtern STATIC ${OPENCVSHARP_FILES})
# Windows, Android - just regular dynamic library for the target
# macOS - shared library will became .bundle
else()
	add_library(OpenCvSharpExtern SHARED ${OPENCVSHARP_FILES})
endif()

# OUTPUT FOLDER(s)
install(TARGETS OpenCvSharpExtern
        RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
        LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
)

target_link_libraries(OpenCvSharpExtern ${OpenCV_LIBS} ${dlib_LIBS})

if (CMAKE_WRAPPER_TRIAL_VERSION)
	target_compile_definitions(OpenCvSharpExtern PRIVATE OPENCV_SHARP_TRIAL)
endif()