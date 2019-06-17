#ifndef _CPP_UTILS_H_
#define _CPP_UTILS_H_

#include "include_opencv.h"

//////////////////////////////////////////////////////////////////////////
// NOTE:
// OpenCV allows some algorithms to be performed "in-place", i.e. without additional memory allocation:
// like cv::algo(image, image, ...);
// However, OpenCV documentation is totally unclear about whether it is safe. On my tests it seemed
// to be fine on some OS and fail on others, googling shows some programmers using in-place for, let's say,
// cv::flip while others face "segfault".
// In order to make it stable we avoid in-place processing at all
//////////////////////////////////////////////////////////////////////////

/// <summary>
/// Converts raw pixel dtaa into cv::mat
/// </summary>
/// <param name="pixels32">[in] Image pixels as RGBA 32-bit</param>
/// <param name="w">Image width</param>
/// <param name="h">Image height</param>
/// <param name="flipVertically">True to flip image vertically (around X axis), false otherwise</param>
/// <param name="flipHorizontally">True to flip image horizontally (around Y axis), false otherwise</param>
/// <param name="rotationAngle">Image rotation angle in CCW direction, must be one of { -270, -180, -90, 0, 90, 180, 270 }</param>
/// <returns>cv::Mat with image in OpenCV format</returns>
CVAPI(cv::Mat*) utils_texture_to_mat(unsigned char *pixels32, int w, int h, bool flipVertically, bool flipHorizontally, int rotationAngle)
{
	// [Referenced] input buffer, 4-channel RGBA
	cv::Mat input(h, w, CV_8UC4, pixels32);

	// [Allocated, Stack] buffer, 3-channel BGR
    cv::Mat bgr(h, w, CV_8UC3);
    cv::cvtColor(input, bgr, CV_RGBA2BGR);

	// [Allocated, Heap] output buffer, 3-channel BGR, transformed
	cv::Mat* output = new cv::Mat(h, w, CV_8UC3);

	// rotation:
	// since we have 90-degree step, we actually do not rotate
	// image, but transpose + flip it, the last one is delayed
	// as we have flip params to process as a separate step
	switch (rotationAngle)
	{
	case 90:
	case -270:
		bgr = bgr.t();
		flipVertically = !flipVertically;
		break;

	case 180:
	case -180:
		flipVertically = !flipVertically;
		flipHorizontally = !flipHorizontally;
		break;

	case 270:
	case -90:
		bgr = bgr.t();
		flipHorizontally = !flipHorizontally;
		break;
	}
    
	// flip
	if (flipVertically || flipHorizontally)
	{
		// OpenCV flip codes are { 0 -> flip vertically, 1+ (any positive) -> flip horizontally, -1 -> flip both }
		int flipCode = (flipVertically && flipHorizontally) ? -1 : (flipVertically ? 0 : 1);
		cv::flip(bgr, *output, flipCode);
	}
	// or simply assign without flip
	else
	{
		*output = bgr;
	}
    
	// we're good
    return output;
}

// colorConversionCode expected to convert mat color to RGBA color that is Unity color space
CVAPI(cv::Mat*) utils_mat_to_texture_1(cv::Mat *mat, int colorConversionCode)
{
	// Reverse of utils_texture_to_mat algorithm
	cv::Mat *output = new cv::Mat(mat->size(), CV_8UC4);

	// #0 trial marker
#ifdef OPENCV_SHARP_TRIAL
	{
		auto size = mat->size();
		auto text = "Trial OpenCV Plus Unity";

		int baseLine;
		auto textSize = cv::getTextSize(text, cv::FONT_HERSHEY_SIMPLEX, 1.0, 1, &baseLine);
		auto textScale = 0.7 * (size.width / textSize.width);
		auto fontThickness = std::max(1, (int)textScale);
		textSize = cv::getTextSize(text, cv::FONT_HERSHEY_SIMPLEX, textScale, fontThickness, &baseLine);

		auto padding = int(textSize.width * 0.1);
		cv::putText(*mat, text, cv::Point(padding, size.height - textSize.height - padding), cv::FONT_HERSHEY_SIMPLEX, textScale, cv::Scalar(0, 0, 0), fontThickness + 2);
		cv::putText(*mat, text, cv::Point(1 + padding, 1 + size.height - textSize.height - padding), cv::FONT_HERSHEY_SIMPLEX, textScale, cv::Scalar(255, 255, 255), fontThickness);
	}
#endif

	// #1 flip
	cv::Mat flipped(mat->size(), mat->type());
	cv::flip(*mat, flipped, 0);

	// #2 convert color
	cv::cvtColor(flipped, *output, colorConversionCode);
	
	return output;
}

CVAPI(cv::Mat*) utils_mat_to_texture_2(cv::Mat *mat)
{
	int code = CV_BGR2RGBA;
	if (mat->channels() == 1) {
		code = CV_GRAY2RGBA;
	}
	return utils_mat_to_texture_1(mat, code);
}

#endif /* _CPP_UTILS_H_ */