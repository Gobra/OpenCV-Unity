#ifndef _CPP_CORE_INPUTARRAY_H_
#define _CPP_CORE_INPUTARRAY_H_

#include "include_opencv.h"

CVAPI(cv::_InputArray*) core_InputArray_new_byMat(cv::Mat *mat)
{
	return new cv::_InputArray(*mat);
}

CVAPI(cv::_InputArray*) core_InputArray_new_byMatExpr(cv::MatExpr *expr)
{
	return new cv::_InputArray(*expr);
}

CVAPI(cv::_InputArray*) core_InputArray_new_byScalar(cv::Scalar val)
{
	return new cv::_InputArray(val);
}

CVAPI(cv::_InputArray*) core_InputArray_new_byDouble(double val)
{
	return new cv::_InputArray(val);
}

CVAPI(cv::_InputArray*) core_InputArray_new_byGpuMat(cv::cuda::GpuMat *gm)
{
	return new cv::_InputArray(*gm);
}

CVAPI(cv::_InputArray*) core_InputArray_new_byVectorOfMat(std::vector<cv::Mat> *vector)
{
    return new cv::_InputArray(*vector);
}

CVAPI(void) core_InputArray_delete(cv::_InputArray *ia)
{
	delete ia;
}

CVAPI(int) core_InputArray_kind(cv::_InputArray *ia)
{
	return ia->kind();
}

#endif