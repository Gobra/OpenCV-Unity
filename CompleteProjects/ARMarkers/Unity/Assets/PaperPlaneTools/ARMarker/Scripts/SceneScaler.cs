namespace PaperPlaneTools.AR {

	using OpenCvSharp;
	using UnityEngine;
	using System.Collections;
	using System;

	/// <summary>
	/// Script scale surface with WebCameraTexuture to match the screen size
	/// </summary>
	public class SceneScaler : MonoBehaviour {
		public Camera arCamera;
		public GameObject outputSurface;

		private Vector2 ScreenSize {
			get;
			set;
		}
		
		private Vector2 ComponentSize {
			get;
			set;
		}
		
		void Start () {
			ScreenSize = Vector2.zero;
			ComponentSize = Vector2.zero;
			Update ();
		}
		
		void Update () {
			Vector2 compontSize = outputSurface.GetComponent<RectTransform>().sizeDelta;
			if (Screen.width != ScreenSize.x || Screen.height != ScreenSize.y || compontSize.x != ComponentSize.x || compontSize.y != ComponentSize.y) {
				ScreenSize = new Vector2 (Screen.width, Screen.height);
				ComponentSize = compontSize;
				
				Scale();
			}
		}

		void Scale() {
			float width = ComponentSize.x;
			float height = ComponentSize.y;
			if (width <= 0 || height <= 0 || Screen.width <= 0 || Screen.height <= 0) {
				return;
			}

			float aspect = 1.0f;
			Size imageSize;
			float aspectWidth = (float)Screen.width / width;
			float aspectHight = (float)Screen.height / height;
			if (aspectWidth < aspectHight) {
				// Scale to match image heigth with screen height
				aspect = aspectHight;
				imageSize = new Size(width, height);
			} else {
				// Scale to match image width with screen width
				float k = (float)Screen.height / (float)Screen.width;
				imageSize = new Size(width, width * k);

				aspect = aspectWidth;
			}

			outputSurface.transform.localScale = new Vector3 (aspect, aspect, 1.0f);

			AdjustFOV (imageSize);
		}

		void AdjustFOV(Size size) {
			float width = ComponentSize.x;
			float height = ComponentSize.y;

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


			double apertureWidth = 0;
			double apertureHeight = 0;
			double fovx = 0.0;
			double fovy = 0.0;
			double focalLength = 0.0;
			Point2d principalPoint = new Point2d(0, 0);
			double aspectratio = 0;


			OpenCvSharp.Cv2.CalibrationMatrixValues (cameraMatrix, size, apertureWidth, apertureHeight, out fovx, out fovy, out focalLength, out principalPoint, out aspectratio);

			arCamera.fieldOfView = (float)fovy;

		}
	}
}