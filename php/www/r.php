<?php
$shortcuts = [
	'opencv_plus_unity_android' => '/download/opencv_plus_unity_android.apk',
	'opencv_plus_unity_android_extended' => '/download/opencv_plus_unity_android_extended.apk',
	'opencv_plus_unity_mac' => '/download/opencv_plus_unity_mac.app.zip',
	'opencv_plus_unity_mac_extended' => '/download/opencv_plus_unity_mac_extended.app.zip',
	'opencv_plus_unity_windows_x86_64_extended' => '/download/opencv_plus_unity_windows_x86_64_extended.zip',
];

$path = '/';
if (isset($_GET['p'])) {
	$str = trim($_GET['p']);
	// avoid urls started from double slashes //
	if (substr($str, 0, 1) != '/') {
		$path = '/'.$str;
	}
}
if (isset($_GET['s'])) {

	$key = $_GET['s'];
	if (isset($shortcuts[$key])) {
		$path = $shortcuts[$key];
	}
}

$path = htmlspecialchars($path);

?>
<!DOCTYPE html>
<html lang="en-US" class="no-js">
<head>
	<meta charset="UTF-8">
	<meta http-equiv="refresh" content="3;url=<?php print($path); ?>" />
	<script>
		(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
		(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
		m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
		})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

		ga('create', 'UA-57024747-9', 'auto');
		ga('send', 'pageview');
	</script>
	</head>
<body>
<div style="padding:100px;">
	Your download should begin shortly.
	If not please follow the <a href="<?php print($path); ?>">link</a>
</div>
</body>
