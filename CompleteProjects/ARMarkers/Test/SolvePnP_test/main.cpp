#include <opencv2/opencv.hpp>
#include <opencv2/aruco.hpp>
#include <opencv2/calib3d.hpp>


//#include <iostream>
//#include <cmath>


using namespace cv;
using namespace std;

int main ( int argc, char **argv ) {
	if ( argc != 2 )
	{
		printf("usage: main.out <Image_Path>\n");
		return -1;
	}

	Mat inputImage = imread( argv[1], 1 );


	vector< int > markerIds;
	vector< vector<Point2f> > markerCorners, rejectedCandidates;

	//cv::aruco::DetectorParameters parameters
	Ptr<cv::aruco::DetectorParameters> parameters = cv::aruco::DetectorParameters::create();

	Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
	

	cv::aruco::detectMarkers(inputImage, dictionary, markerCorners, markerIds, parameters, rejectedCandidates);
	//cv::aruco::detectMarkers(inputImage, dictionary, markerCorners, markerIds);
	
	cv::aruco::drawDetectedMarkers(inputImage, markerCorners, markerIds);

	cout<<markerCorners.size()<<" "<<rejectedCandidates.size()<<endl;

/*
    //set cameraparam


            int max_d = (int)Mathf.Max (width, height);
            double fx = max_d;
            double fy = max_d;
            double cx = width / 2.0f;
            double cy = height / 2.0f;

            camMatrix.put (0, 0, fx);
            camMatrix.put (0, 1, 0);
            camMatrix.put (0, 2, cx);
            camMatrix.put (1, 0, 0);
            camMatrix.put (1, 1, fy);
            camMatrix.put (1, 2, cy);
            camMatrix.put (2, 0, 0);
            camMatrix.put (2, 1, 0);
            camMatrix.put (2, 2, 1.0f);
            Debug.Log ("camMatrix " + camMatrix.dump ());

            MatOfDouble distCoeffs = new MatOfDouble (0, 0, 0, 0);
            Debug.Log ("distCoeffs " + distCoeffs.dump ());
*/

    

	double width = (double)inputImage.rows;
	double height = (double)inputImage.cols;
	double max_d = max(width, height);
	double fx = max_d;
	double fy = max_d;

	double cx = width / 2.0f;
	double cy = height / 2.0f;

 	Mat camMatrix(3, 3, CV_64FC1);
	camMatrix.at<double>(0,0) = fx;
	camMatrix.at<double>(0,1) = 0.0;
	camMatrix.at<double>(0,2) = cx;
	camMatrix.at<double>(1,0) = 0.0;
	camMatrix.at<double>(1,1) = fy;
	camMatrix.at<double>(1,2) = cy;
	camMatrix.at<double>(2,0) = 0.0;
	camMatrix.at<double>(2,1) = 0.0;
	camMatrix.at<double>(2,2) = 1.0;


 	Mat distCoeffs(1, 4, CV_64FC1);
	distCoeffs.at<double>(0,0) = 0.0;
	distCoeffs.at<double>(0,1) = 0.0;
	distCoeffs.at<double>(0,2) = 0.0;
	distCoeffs.at<double>(0,3) = 0.0;

	// Way 1: estimatePoseSingleMarkers
	// vector< Vec3d > rvecs, tvecs;
	// double markerSizeInMeters = 0.05;
	// aruco::estimatePoseSingleMarkers(markerCorners, markerSizeInMeters, camMatrix, distCoeffs, rvecs, tvecs);
	// cout<<markerIds.size()<<endl;
	// for(int i=0; i<markerIds.size(); i++) {
	// 	cout<<"rvecs: "<<rvecs[i][0]<<" "<<rvecs[i][1]<<" "<<rvecs[i][2]<<endl;
	// 	cout<<"tvecs: "<<tvecs[i][0]<<" "<<tvecs[i][1]<<" "<<tvecs[i][2]<<endl;
	// 	cv::aruco::drawAxis(inputImage, camMatrix, distCoeffs, rvecs[i], tvecs[i], markerSizeInMeters);	

	// }

	// Way 2: solvePnP
	double markerSizeInMeters = 0.05;
	cout<<markerIds.size()<<endl;

	std::vector<Point3f> markerPoints;
	markerPoints.push_back(Point3f(-markerSizeInMeters / 2.0,  markerSizeInMeters / 2.0, 0.0));
	markerPoints.push_back(Point3f( markerSizeInMeters / 2.0,  markerSizeInMeters / 2.0, 0.0));
	markerPoints.push_back(Point3f( markerSizeInMeters / 2.0, -markerSizeInMeters / 2.0, 0.0));
	markerPoints.push_back(Point3f(-markerSizeInMeters / 2.0, -markerSizeInMeters / 2.0, 0.0));


	for(int i=0; i<markerIds.size(); i++) {
		Vec3d rvec, tvec;

		cv::solvePnP(markerPoints, markerCorners[i], camMatrix, distCoeffs, rvec, tvec, false, CV_ITERATIVE);

		// cout<<"rvecs: "<<rvecs[i][0]<<" "<<rvecs[i][1]<<" "<<rvecs[i][2]<<endl;
		// cout<<"tvecs: "<<tvecs[i][0]<<" "<<tvecs[i][1]<<" "<<tvecs[i][2]<<endl;
		cv::aruco::drawAxis(inputImage, camMatrix, distCoeffs, rvec, tvec, markerSizeInMeters);	
	}


	namedWindow("Display Image", WINDOW_AUTOSIZE );
	imshow("Display Image", inputImage);
	waitKey(0);
	return 0;
}
