namespace PaperPlaneTools.AR {
	using UnityEngine;
	using System.Collections;

	public class MatrixHelper {
		public static Quaternion GetQuaternion(Matrix4x4 matrix) {
			Vector3 forward = new Vector3 (matrix.m02, matrix.m12, matrix.m22);
			Vector3 upwards = new Vector3 (matrix.m01, matrix.m11, matrix.m21);
			return Quaternion.LookRotation (forward, upwards);
		}

		public static Vector3 GetPosition(Matrix4x4 matrix) {
			return new Vector3 (matrix.m03, matrix.m13, matrix.m23); 
		}

		public static Vector3 GetScale(Matrix4x4 matrix) {
			Vector3 scale;
			scale.x = new Vector4 (matrix.m00, matrix.m10, matrix.m20, matrix.m30).magnitude;
			scale.y = new Vector4 (matrix.m01, matrix.m11, matrix.m21, matrix.m31).magnitude;
			scale.z = new Vector4 (matrix.m02, matrix.m12, matrix.m22, matrix.m32).magnitude;
			return scale;
		}
	}
}