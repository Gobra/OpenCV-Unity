namespace PaperPlaneTools.AR {
	using UnityEngine;
	using System.Collections;
	using System.Runtime.InteropServices;
	using System;
	using System.Collections.Generic;
	using OpenCvSharp;
	using OpenCvSharp.Aruco;

	public class MarkerDetector {
		private List<Matrix4x4> markerTransforms = new List<Matrix4x4>();

		/// <summary>
		/// Initializes a new instance of the <see cref="PaperPlaneTools.AR.MarkerDetector"/> class.
		/// </summary>
		public MarkerDetector() {
		}


		/// <summary>
		/// Detect markers.
		/// </summary>
		/// <param name="pixels">
		///   The image where to detect markers.
		///   For example, you can use get pixels from web camera https://docs.unity3d.com/ScriptReference/WebCamTexture.GetPixels32.html
		/// </param>
		public List<int> Detect(Mat mat, int width, int height) {
			List<int> result = new List<int> ();
			markerTransforms.Clear ();

			// Create default parameres for detection
			DetectorParameters detectorParameters = DetectorParameters.Create();
			
			// Dictionary holds set of all available markers
			Dictionary dictionary = CvAruco.GetPredefinedDictionary (PredefinedDictionaryName.Dict6X6_250);
			
			// Variables to hold results
			Point2f[][] corners;
			int[] ids;
			Point2f[][] rejectedImgPoints;

			// Convert image to grasyscale
			Mat grayMat = new Mat ();
			Cv2.CvtColor (mat, grayMat, ColorConversionCodes.BGR2GRAY);
			
			// Detect markers
			CvAruco.DetectMarkers (grayMat, dictionary, out corners, out ids, detectorParameters, out rejectedImgPoints);

//			CvAruco.DrawDetectedMarkers (mat, corners, ids);

			float markerSizeInMeters = 1f;

			Point3f[] markerPoints = new Point3f[] {
				new Point3f(-markerSizeInMeters / 2f,  markerSizeInMeters / 2f, 0f),
				new Point3f( markerSizeInMeters / 2f,  markerSizeInMeters / 2f, 0f),
				new Point3f( markerSizeInMeters / 2f, -markerSizeInMeters / 2f, 0f),
				new Point3f(-markerSizeInMeters / 2f, -markerSizeInMeters / 2f, 0f)
			};


			double max_wh = (double)Math.Max (width, height);
			double fx = max_wh;
			double fy = max_wh;
			double cx = width / 2.0d;
			double cy = height / 2.0d;
//			
			double[,] cameraMatrix = new double[3, 3] {
				{fx, 0d, cx},
				{0d, fy, cy},
				{0d, 0d, 1d}
			};

			double[] distCoeffs = new double[4] {0d, 0d, 0d, 0d};

			double[] rvec = new double[3]{0d, 0d, 0d};
			double[] tvec = new double[3]{0d, 0d, 0d};
			double[,] rotMat = new double[3, 3] {{0d, 0d, 0d}, {0d, 0d, 0d}, {0d, 0d, 0d}};


			for (int i=0; i<ids.Length; i++) {

				Cv2.SolvePnP(markerPoints, corners[i], cameraMatrix, distCoeffs, out rvec, out tvec, false, SolvePnPFlags.Iterative);

//				CvAruco.DrawAxis(mat, cameraMatrix, distCoeffs, rvec, tvec, 1.0f);
				Cv2.Rodrigues (rvec, out rotMat);
				Matrix4x4 matrix = new Matrix4x4();
				matrix.SetRow(0, new Vector4((float)rotMat[0, 0], (float)rotMat[0, 1], (float)rotMat[0, 2], (float)tvec[0]));
				matrix.SetRow(1, new Vector4((float)rotMat[1, 0], (float)rotMat[1, 1], (float)rotMat[1, 2], (float)tvec[1]));
				matrix.SetRow(2, new Vector4((float)rotMat[2, 0], (float)rotMat[2, 1], (float)rotMat[2, 2], (float)tvec[2]));
				matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));

				result.Add(ids[i]);
				markerTransforms.Add(matrix);
			}

			return result;
		}

		/// <summary>
		/// Return transfrom matrix for previously detected markers
		/// </summary>
		/// <returns>Return transfrom matrix for previously detected markers</returns>
		/// <param name="markerIndex">Index in the result liist of <see cref="PaperPlaneTools.AR.MarkerDetector.Detect"/> function</param>
		public Matrix4x4 TransfromMatrixForIndex(int markerIndex) {
			return markerTransforms [markerIndex];
		}
	}

}