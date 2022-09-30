<?php

use VPN\App;
use VPN\User;
use VPN\Server;
use VPN\AppStoreNotification;
use VPN\Support;
use VPN\CronJob;

$app->before(function () use ($app) {
	
	define("APP_STORE_ISSUER_ID", "PUT_YOUR_DATA_HERE");
	define("APP_STORE_BUNDLE_ID", "PUT_YOUR_DATA_HERE");
	define("APP_STORE_API_KEY_ID", "PUT_YOUR_DATA_HERE");
	define("APP_STORE_IN_APP_PATH", "PUT_YOUR_DATA_HERE");
	define("APP_STORE_API_KEY", "PUT_YOUR_DATA_HERE");
	define("APP_STORE_ENVIRONMENT", "https://api.storekit-sandbox.itunes.apple.com");
	// define("APP_STORE_ENVIRONMENT", "https://api.storekit.itunes.apple.com");
	$app["App"] = new App($app,null, false);
	$app["User"] = new User($app);
	$app["Server"] = new Server($app);
	$app["AppStoreNotification"] = new AppStoreNotification($app);
	$app["Support"] = new Support($app);
	$app["CronJob"] = new CronJob($app);
    return true;
});