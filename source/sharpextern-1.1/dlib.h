#ifndef _CPP_DLIB_H_
#define _CPP_DLIB_H_

// our basic include file
#include "include_opencv.h"

// dlib
#include <dlib/image_processing/generic_image.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>

// dlib bridge with OpenCV
#include <dlib/opencv/cv_image.h>

//------------------------------------------------------------------------------------------------------
// Auxiliary
//------------------------------------------------------------------------------------------------------

/// <summary>
/// membuf trick, requires sub classing as it accesses some protected members
/// </summary>
class membuf : public std::basic_streambuf<char>
{
public:
	membuf(char* p, size_t n)
	{
		setg(p, p, p + n);
		setp(p, p + n);
	}
};

//------------------------------------------------------------------------------------------------------
// DLib minimal C-wrapper for face shape recognition
//------------------------------------------------------------------------------------------------------

/// <summary>
/// Allocates new dlib::shape_predictor
/// </summary>
/// <returns>Newely allocated and initialized dlib::shape_predictor</returns>
CVAPI(dlib::shape_predictor*) dlib_shapePredictor_new()
{
	return new dlib::shape_predictor();
}

/// <summary>
/// Loads the shape predictor into the landmark builder
/// </summary>
/// <param name="predictor">[in] dlib::shape_predictor object to initialize with data. </param>
/// <param name="dataArray">[in] buffer with predictor data. </param>
/// <param name="dataSize">[in] buffer length. </param>
CVAPI(void) dlib_shapePredictor_loadData(dlib::shape_predictor* predictor, char* dataArray, int dataSize)
{
	// quick check
	if (nullptr == predictor || nullptr == dataArray)
		return;

	// get stream
	membuf buf(dataArray, dataSize);
	std::istream stream(&buf);
	stream.seekg(0);

	// dlib de-serialization
	dlib::deserialize(*predictor, stream);
}

/// <summary>
/// Detects landmarks in image
/// </summary>
///
/// <param name="predictor">[in] dlib::shape_predictor to use for landmark recognition</param>
/// <param name="image">[in] Cv::Mat with image to detect fce shape on</param>
/// <param name="roi">[in] Region of interest: the rect where the face is located (must be pre-detected with OpenCV or DLib)</param>
/// <param name="landmarks">[in, out] If non-null, is filled with detected landmarks. </param>
CVAPI(bool) dlib_shapePredictor_detectLandmarks(dlib::shape_predictor* predictor, cv::Mat* image, MyCvRect roi, std::vector<CvVec2i> **landmarks)
{
	if (nullptr == landmarks)
		return false;

	// prepare
	dlib::rectangle rect(roi.x, roi.y, roi.x + roi.width, roi.y + roi.height);
	dlib::cv_image<unsigned char> img(*image);
	dlib::full_object_detection fod = (*predictor)(img, rect);

	// parse to vector
	*landmarks = new std::vector<CvVec2i>(fod.num_parts());

	CvVec2i* data = (*landmarks)->data();
	for (unsigned long i = 0; i < fod.num_parts(); ++i, ++data)
	{
		data->val[0] = fod.part(i).x();
		data->val[1] = fod.part(i).y();
	}

	return true;
}

/// <summary>
/// Releases dlib::shape_detector
/// </summary>
CVAPI(void) dlib_shapePredictor_delete(dlib::shape_predictor* object)
{
	delete object;
}

#endif // _CPP_DLIB_H_