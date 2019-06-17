This is ARMarker documentation

Intro:
ArMarker demo uses OpenCV ArUco library to detect predefined AR markers.
Check out a short video shown the process https://youtu.be/l-vbHvVE1Y0 .

Dependences:
'OpenCV plus Unity' asset is required.
https://www.assetstore.unity3d.com/en/#!/content/85928


Installation:
1. Import package
2. Download and import 'OpenCV plus Unity' package 
3. Follow 'OpenCV plus Unity' instalation instructions
4. Print or draw markers for demo /PaperPlaneTools/ARMarker/Documentation/DemoMarkers.png
5. Run MainScene /PaperPlaneTools/ARMarker/Demo/MainScene.unity

Markers:
Each marker has unique appearance and identifier.
You can find all predefined markers in archive /PaperPlaneTools/ARMarker/Documentation/Markers.zip
Each file has name pattern {MARKER_ID}.png

Customize the script:
You can show your models over the AR markers; to do so follow these steps:
1. Find `Main` object in MainScene 
2. Find `MainScript` component of `Main` object
3. Edit `Markers` property 
3.1 Set `Markers.Size` property to number of markers script will be looking for
3.2 Edit each element of the `Markers` array. Set `Marker Id` according to the file name pattern and `Marker Prefab` to your model prefab which will be placed over the detected marker

Skins for the models:
  http://www.planetminecraft.com/skin/satanic-soul/
  http://www.planetminecraft.com/skin/finn---the-human/


Early access participants:
Initially 'Ar Marker Detector' asset was paid. 
For those who purshased the plugin on its early stage we would like to offer free 'OpenCV plus Unity' licence.
To get it please write a request at paperplane@gmail.com with invoice number of the 'Ar Marker Detector' receipt.