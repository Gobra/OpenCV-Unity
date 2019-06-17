using UnityEngine;
using UnityEditor;
using System;

[InitializeOnLoad]

public class WelcomeWindow : EditorWindow
{
	static WelcomeWindow() {
		EditorApplication.update += ShowWindow;
	}

	public static void ShowWindow() {
		EditorApplication.update -= ShowWindow;
		if ( now() - PlayerPrefs.GetInt ("WelcomeScreenShownAt", 0)  < 2 * 3600 ) {
			return;
		}
		PlayerPrefs.SetInt ("WelcomeScreenShownAt", now ());



		// get an instance to the editor window
		WelcomeWindow screen = (WelcomeWindow)EditorWindow.GetWindow(typeof(WelcomeWindow),false);

		// set the window title
		GUIContent titleContent = new GUIContent ("OpenCV plus Unity - trial");
		screen.titleContent = titleContent;

		// contrain the window size
		Vector2 maxSize = new Vector2 (710, 296 + 48);
		screen.maxSize = maxSize;
		screen.minSize = maxSize;
		// show the window
		screen.Show ();
	}	

	
	void OnGUI()
	{

		GUIStyle myBanner = new GUIStyle ();
		myBanner.normal.background = (Texture2D)Resources.Load ("trial-table");
		GUI.Box (new Rect (0, 0, 710, 264), "", myBanner);

		if (createEntry ("get-full-version-button", new Rect (710 - 180, 280, 180, 48))) {
			Application.OpenURL ("http://www.paperplanetools.com/r.php?s=opencv_plus_unity_fullversion&ref=unityeditor");
		}

	}

	private static readonly DateTime Epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
	private static int now() {	
		DateTime now = DateTime.UtcNow;
		TimeSpan elapsedTime = now - Epoch;
		return (int) elapsedTime.TotalSeconds;
	}

	private bool createEntry(string icon, Rect rect) {

		GUIStyle myButton = new GUIStyle ();
		myButton.normal.background = (Texture2D)Resources.Load (icon);
		GUI.Box (rect, "", myButton);


		//GUILayout.Box ((Texture)Resources.Load (icon), GUIStyle.none,GUILayout.MaxHeight(64),GUILayout.MaxWidth(64));


		//var entryRect = GUILayoutUtility.GetLastRect ();
		EditorGUIUtility.AddCursorRect (rect, MouseCursor.Link);
		
		// check for an click inside the entry to fire up an action
		// http://answers.unity3d.com/questions/21261/can-i-place-a-link-such-as-a-href-into-the-guilabe.html
		if (Event.current.type == EventType.MouseUp && rect.Contains (Event.current.mousePosition))
			return true;
		
		return false;
	}

}