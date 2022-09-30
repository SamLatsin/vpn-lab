<?php

$app->get('/privacy', function () use ($app) {
	$file = 'files/PrivacyPolicy.pdf';
	$filename = 'files/PrivacyPolicy.pdf';
	header('Content-type: application/pdf');
	header('Content-Disposition: inline; filename="' . $filename . '"');
	header('Content-Transfer-Encoding: binary');
	header('Accept-Ranges: bytes');
  	@readfile($file);
});

$app->get('/terms', function () use ($app) {
	$file = 'files/Terms.pdf';
	$filename = 'files/Terms.pdf';
	header('Content-type: application/pdf');
	header('Content-Disposition: inline; filename="' . $filename . '"');
	header('Content-Transfer-Encoding: binary');
	header('Accept-Ranges: bytes');
  	@readfile($file);
});