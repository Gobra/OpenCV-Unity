#ifndef _CPP_XPHOTO_H_
#define _CPP_XPHOTO_H_

#include "include_opencv.h"

CVAPI(void) xphoto_balanceWhite(cv::_InputArray* src, cv::_OutputArray* dst)
{
	cv::Ptr<cv::xphoto::GrayworldWB> balancer = cv::xphoto::createGrayworldWB();
	balancer->balanceWhite(*src, *dst);
}


#endif /* _CPP_XPHOTO_H_ */