/*************************************************************************
* OpenCv Contrib::Text module wrapper
*
*************************************************************************/

#ifndef _CPP_CONTRIB_TEXT_H_
#define _CPP_CONTRIB_TEXT_H_

#include "include_opencv.h"

//------------------------------------------------------------------------------------------------------
// Public static methods
//------------------------------------------------------------------------------------------------------
CVAPI(void) text_computeNMChannels(cv::Mat* img, std::vector<cv::Mat> **mv, int mode)
{
	*mv = new std::vector<cv::Mat>();
	cv::text::computeNMChannels(*img, **mv, mode);
}

CVAPI(void) text_MSERsToERStats(cv::_InputArray* image, std::vector<std::vector<cv::Point>>* contours, std::vector<std::vector<cv::text::ERStat>>* regions)
{
	cv::text::MSERsToERStats(*image, *contours, *regions);
}

CVAPI(void) text_createOCRHMMTransitionsTable(const char* vocabulary, std::vector<std::string>* lexicon, cv::_OutputArray* transition_probabilities_table)
{
	std::string voc(vocabulary);
	cv::text::createOCRHMMTransitionsTable(voc, *lexicon, *transition_probabilities_table);
}

CVAPI(void) text_detectRegions(cv::_InputArray* image, cv::Ptr<cv::text::ERFilter>* er_filter1, cv::Ptr<cv::text::ERFilter>* er_filter2, std::vector<std::vector<cv::Point>>* regions)
{
	cv::text::detectRegions(*image, *er_filter1, *er_filter2, *regions);
}

CVAPI(void) text_erGrouping1(cv::_InputArray* img, cv::_InputArray* channels, std::vector<std::vector<cv::text::ERStat>>* regions, std::vector<std::vector<cv::Vec2i>>* groups, std::vector<cv::Rect>* groups_rects, int method, const char* filename, float minProbablity)
{
	cv::text::erGrouping(*img, *channels, *regions, *groups, *groups_rects, method, filename, minProbablity);
}

CVAPI(void) text_erGrouping2(cv::_InputArray* image, cv::_InputArray* channel, std::vector<std::vector<cv::Point>>* regions, std::vector<cv::Rect>* groups_rects, int method, const char* filename, float minProbablity)
{
	cv::text::erGrouping(*image, *channel, *regions, *groups_rects, method, filename, minProbablity);
}

//******************************************************************************************************
// ERStat
//******************************************************************************************************
CVAPI(cv::text::ERStat*) text_ERStat_new1()
{
	return new cv::text::ERStat();
}

CVAPI(cv::text::ERStat*) text_ERStat_new2(cv::text::ERStat* ref)
{
	return new cv::text::ERStat(*ref);
}

CVAPI(void) text_ERStat_getRect(cv::text::ERStat* ref, cv::Rect* output)
{
	*output = ref->rect;
}

CVAPI(double) text_ERStat_getProbability(cv::text::ERStat* ref)
{
	return ref->probability;
}

CVAPI(void) text_ERStat_delete(cv::text::ERStat* obj)
{
	delete obj;
}

//******************************************************************************************************
// OCRHMMDecoder
//******************************************************************************************************
//------------------------------------------------------------------------------------------------------
// OCRHMMDecoder::ClassifierCallback
//------------------------------------------------------------------------------------------------------
CVAPI(cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>*) text_loadOCRHMMClassifierCNN(const char *fileName)
{
	auto classifier = cv::text::loadOCRHMMClassifierCNN(fileName);
	return new cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>(classifier);
}

CVAPI(cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>*) text_loadOCRHMMClassifierNM(const char *fileName)
{
	auto classifier = cv::text::loadOCRHMMClassifierNM(fileName);
	return new cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>(classifier);
}

CVAPI(void) text_OCRHMMDecoder_ClassifierCallback_delete(cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>* obj)
{
	delete obj;
}

CVAPI(void) text_OCRHMMDecoder_ClassifierCallback_eval(cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>* obj, cv::_InputArray* input, std::vector<int>* out_class, std::vector<double>* out_confidence)
{
	obj->get()->eval(*input, *out_class, *out_confidence);
}

//------------------------------------------------------------------------------------------------------
// OCRHMMDecoder
//------------------------------------------------------------------------------------------------------
CVAPI(cv::Ptr<cv::text::OCRHMMDecoder>*) text_OCRHMMDecoder_create(
	cv::Ptr<cv::text::OCRHMMDecoder::ClassifierCallback>* classifier,
	const char* vocabulary,
	cv::_InputArray* transition_probabilities_table,
	cv::_InputArray* emission_probabilities_table,
	int mode)
{
	auto decoder = cv::text::OCRHMMDecoder::create(*classifier, vocabulary, *transition_probabilities_table, *emission_probabilities_table, cv::text::OCR_DECODER_VITERBI);
	return new cv::Ptr<cv::text::OCRHMMDecoder>(decoder);
}

CVAPI(void) text_OCRHMMDecoder_delete(cv::Ptr<cv::text::OCRHMMDecoder>* obj)
{
	delete obj;
}

CVAPI(void) text_OCRHMMDecoder_run(cv::Ptr<cv::text::OCRHMMDecoder>* decoder, cv::Mat* image, std::vector<cv::Rect>* rects, std::vector<std::string>* texts, std::vector<float>* confidences, int component_level)
{
	std::string result;
	decoder->get()->run(*image, result, rects, texts, confidences, component_level);
}

//******************************************************************************************************
// OCRBeamSearchDecoder
//******************************************************************************************************
//------------------------------------------------------------------------------------------------------
// OCRBeamSearchDecoder::ClassifierCallback
//------------------------------------------------------------------------------------------------------
CVAPI(cv::Ptr<cv::text::OCRBeamSearchDecoder::ClassifierCallback>*) text_loadOCRBeamSearchClassifierCNN(const char *fileName)
{
	auto classifier = cv::text::loadOCRBeamSearchClassifierCNN(fileName);
	return new cv::Ptr<cv::text::OCRBeamSearchDecoder::ClassifierCallback>(classifier);
}

CVAPI(void) text_OCRBeamSearchDecoder_ClassifierCallback_delete(cv::Ptr<cv::text::OCRBeamSearchDecoder::ClassifierCallback>* obj)
{
	delete obj;
}

CVAPI(void) text_OCRBeamSearchDecoder_ClassifierCallback_eval(cv::Ptr<cv::text::OCRBeamSearchDecoder::ClassifierCallback>* obj, cv::_InputArray* input, std::vector<std::vector<double>>* recognition_probabilities,
	std::vector<int>* oversegmentation)
{
	obj->get()->eval(*input, *recognition_probabilities, *oversegmentation);
}

//------------------------------------------------------------------------------------------------------
// OCRBeamSearchDecoder
//------------------------------------------------------------------------------------------------------
CVAPI(cv::Ptr<cv::text::OCRBeamSearchDecoder>*) text_OCRBeamSearchDecoder_create(
	cv::Ptr<cv::text::OCRBeamSearchDecoder::ClassifierCallback>* classifier,
	const char* vocabulary,
	cv::_InputArray* transition_probabilities_table,
	cv::_InputArray* emission_probabilities_table,
	int mode,
	int beam_size)
{
	auto decoder = cv::text::OCRBeamSearchDecoder::create(*classifier, vocabulary, *transition_probabilities_table, *emission_probabilities_table, cv::text::OCR_DECODER_VITERBI, beam_size);
	return new cv::Ptr<cv::text::OCRBeamSearchDecoder>(decoder);
}

CVAPI(void) text_OCRBeamSearchDecoder_delete(cv::Ptr<cv::text::OCRBeamSearchDecoder>* obj)
{
	delete obj;
}

CVAPI(void) text_OCRBeamSearchDecoder_run(cv::Ptr<cv::text::OCRBeamSearchDecoder>* decoder, cv::Mat* image, std::vector<cv::Rect>* rects, std::vector<std::string>* texts, std::vector<float>* confidences, int component_level)
{
	std::string result;
	decoder->get()->run(*image, result, rects, texts, confidences, component_level);
}

CVAPI(void) text_OCRBeamSearchDecoder_run2(cv::Ptr<cv::text::OCRBeamSearchDecoder>* decoder, cv::Mat* image, cv::Mat* mask, std::vector<cv::Rect>* rects, std::vector<std::string>* texts, std::vector<float>* confidences, int component_level)
{
	std::string result;
	decoder->get()->run(*image, *mask, result, rects, texts, confidences, component_level);
}

//******************************************************************************************************
// ERFilter
//******************************************************************************************************
//------------------------------------------------------------------------------------------------------
// ERFilter::Callback
//------------------------------------------------------------------------------------------------------
CVAPI(double) text_ERFilter_Callback_eval(cv::Ptr<cv::text::ERFilter::Callback>* obj, cv::text::ERStat* stat)
{
	return obj->get()->eval(*stat);
}

CVAPI(void) text_ERFilter_Callback_delete(cv::Ptr<cv::text::ERFilter::Callback>* obj)
{
	delete obj;
}

CVAPI(cv::Ptr<cv::text::ERFilter::Callback>*) text_loadClassifierNM1(const char* filename)
{
	auto result = cv::text::loadClassifierNM1(filename);
	return new cv::Ptr<cv::text::ERFilter::Callback>(result);
}

CVAPI(cv::Ptr<cv::text::ERFilter::Callback>*) text_loadClassifierNM2(const char* filename)
{
	auto result = cv::text::loadClassifierNM2(filename);
	return new cv::Ptr<cv::text::ERFilter::Callback>(result);
}

//------------------------------------------------------------------------------------------------------
// ERFilter
//------------------------------------------------------------------------------------------------------
CVAPI(cv::Ptr<cv::text::ERFilter>*) text_createERFilterNM1(cv::Ptr<cv::text::ERFilter::Callback>* cb, int thresholdDelta, float minArea, float maxArea, float minProbability, bool nonMaxSuppression, float minProbabilityDiff)
{
	auto result = cv::text::createERFilterNM1(*cb, thresholdDelta, minArea, maxArea, minProbability, nonMaxSuppression, minProbabilityDiff);
	return new cv::Ptr<cv::text::ERFilter>(result);
}

CVAPI(cv::Ptr<cv::text::ERFilter>*) text_createERFilterNM2(cv::Ptr<cv::text::ERFilter::Callback>* cb, float minProbability)
{
	auto result = cv::text::createERFilterNM2(*cb, minProbability);
	return new cv::Ptr<cv::text::ERFilter>(result);
}

CVAPI(void) text_ERFilter_run(cv::Ptr<cv::text::ERFilter>* obj, cv::_InputArray* image, std::vector<cv::text::ERStat>* regions)
{
	obj->get()->run(*image, *regions);
}

CVAPI(void) text_ERFilter_setCallback(cv::Ptr<cv::text::ERFilter>* obj, cv::Ptr<cv::text::ERFilter::Callback>* cb)
{
	obj->get()->setCallback(*cb);
}

CVAPI(void) text_ERFilter_setThresholdDelta(cv::Ptr<cv::text::ERFilter>* obj, int thresholdDelta)
{
	obj->get()->setThresholdDelta(thresholdDelta);
}

CVAPI(void) text_ERFilter_setMinArea(cv::Ptr<cv::text::ERFilter>* obj, float minArea)
{
	obj->get()->setMinArea(minArea);
}

CVAPI(void) text_ERFilter_setMaxArea(cv::Ptr<cv::text::ERFilter>* obj, float maxArea)
{
	obj->get()->setMaxArea(maxArea);
}

CVAPI(void) text_ERFilter_setMinProbability(cv::Ptr<cv::text::ERFilter>* obj, float minProbability)
{
	obj->get()->setMinProbability(minProbability);
}

CVAPI(void) text_ERFilter_setMinProbabilityDiff(cv::Ptr<cv::text::ERFilter>* obj, float minProbabilityDiff)
{
	obj->get()->setMinProbabilityDiff(minProbabilityDiff);
}

CVAPI(void) text_ERFilter_setNonMaxSuppression(cv::Ptr<cv::text::ERFilter>* obj, bool nonMaxSuppression)
{
	obj->get()->setNonMaxSuppression(nonMaxSuppression);
}

CVAPI(int)  text_ERFilter_getNumRejected(cv::Ptr<cv::text::ERFilter>* obj)
{
	return obj->get()->getNumRejected();
}

#endif /* _CPP_CONTRIB_TEXT_H_ */