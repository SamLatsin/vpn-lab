<?php

$app->post('/api/appstore/notifications', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
	$postdata = json_decode(file_get_contents("php://input"), true);
	$data = explode(".", $postdata['signedPayload']);
	$header = json_decode(base64_decode($data[0]), true);
	$payload = json_decode(base64_decode($data[1]), true);
	$signature = $data[2];

	$payload_data = explode("." ,$payload["data"]["signedTransactionInfo"]);
	unset($payload["data"]["signedTransactionInfo"]);
	$payload_header = json_decode(base64_decode($payload_data[0]), true);
	$payload_payload = json_decode(base64_decode($payload_data[1]), true);
	$payload_signature = $payload_data[2];

	$renewal_data = explode("." ,$payload["data"]["signedRenewalInfo"]);
	unset($payload["data"]["signedRenewalInfo"]);
	$renewal_header = json_decode(base64_decode($renewal_data[0]), true);
	$renewal_payload = json_decode(base64_decode($renewal_data[1]), true);
	$renewal_signature = $renewal_data[2];

	$status = "no";
	if ($payload["notificationType"] == "EXPIRED") {
		$status = "delete subscription";
	}
	if ($payload["notificationType"] == "DID_RENEW") {
		$status = "update subscription period";
	}
	if ($payload["notificationType"] == "SUBSCRIBED") {
		$status = "add subscription";
	}

	$fields1 = [
		"id"=>$payload["notificationUUID"],
		"header"=>json_encode($header),
		"payload"=>json_encode($payload),
		"signature"=>$signature,
		"payload_header"=>json_encode($payload_header),
		"payload_payload"=>json_encode($payload_payload),
		"payload_signature"=>$payload_signature,
		"renewal_header"=>json_encode($renewal_header),
		"renewal_payload"=>json_encode($renewal_payload),
		"renewal_signature"=>$renewal_signature,
		"raw"=>json_encode($postdata),
	];

	$app["AppStoreNotification"]->insertAppStoreNotification($fields1);

	$app_store_api = new \yanlongli\AppStoreServerApi\AppStoreServerApi(
    	APP_STORE_ENVIRONMENT,
	    APP_STORE_API_KEY_ID,
	    file_get_contents(__DIR__ . APP_STORE_API_KEY),
	    APP_STORE_ISSUER_ID,
	    APP_STORE_BUNDLE_ID,
	);

	$data = $app_store_api->subscriptions(strval($payload_payload["originalTransactionId"]), APP_STORE_BUNDLE_ID);
	$expiresDate = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->expiresDate;
	$purchaseID = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->originalTransactionId;

	if ($expiresDate) {
		$user = $app["User"]->getUserByAppStorePurchaseId($purchaseID);
		if ($user) {
			$user = $user[0];
			if (time() < $expiresDate/1000) {
				$fields = [
					"isPremium"=>1,
					"subscriptionEndDate"=> date("Y-m-d H:i:s", $expiresDate/1000),
					"appStorePurchaseId"=>$purchaseID,
				];
				$app["User"]->updateUser($fields, $user["id"]);
				$result = [
			        "error"=>false,
			        "result"=>"subscription updated successfully",
			    ];
			    return json_encode($result);
			}
			$fields = [
				"isPremium"=>0,
				"subscriptionEndDate"=> null,
				"appStorePurchaseId"=>null,
			];
			$app["User"]->updateUser($fields, $user["id"]);
			$result = [
		        "error"=>true,
		        "result"=>"subscription is expired",
		    ];
		    return json_encode($result);
		}
	}
	$result = [
        "error"=>false,
        // "status"=>$status,
        // "result"=> $fields,
    ];
    return json_encode($result);
});

$app->post('/api/appstore/restore_purchases', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');

	$email = $app['request']->get('email');
	$user = $app["User"]->getUserByEmail($email);
	if ($user) {
		$user = $user[0];
		$app_store_api = new \yanlongli\AppStoreServerApi\AppStoreServerApi(
	    	APP_STORE_ENVIRONMENT,
		    APP_STORE_API_KEY_ID,
		    file_get_contents(__DIR__ . APP_STORE_API_KEY),
		    APP_STORE_ISSUER_ID,
		    APP_STORE_BUNDLE_ID,
		);
		$purchaseID = $user["appStorePurchaseId"];
		if ($purchaseID == null) {
			$result = [
		        "error"=>true,
		        "result"=>"No payments",
		    ];
		    return json_encode($result);
		}
		$data = $app_store_api->subscriptions(strval($purchaseID), APP_STORE_BUNDLE_ID);
		if (!isset($data->data[0]->lastTransactions[0])) {
			$result = [
		        "error"=>true,
		        "result"=>"No payments",
		    ];
		    return json_encode($result);
		}
		$expiresDate = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->expiresDate;
		$purchaseID = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->originalTransactionId;
		if ($expiresDate) {
			if (time() < $expiresDate/1000) {
				$fields = [
					"isPremium"=>1,
					"subscriptionEndDate"=> date("Y-m-d H:i:s", $expiresDate/1000),
					"appStorePurchaseId"=>$purchaseID,
				];
				$app["User"]->updateUser($fields, $user["id"]);
				$result = [
			        "error"=>false,
			        "result"=>"subscription restored successfully",
			    ];
			    return json_encode($result);
			}
			$fields = [
				"isPremium"=>0,
				"subscriptionEndDate"=> null,
				"appStorePurchaseId"=>null,
			];
			$app["User"]->updateUser($fields, $user["id"]);
			$result = [
		        "error"=>true,
		        "result"=>"subscription is expired",
		    ];
		    return json_encode($result);
		}
	}
	$result = [
        "error"=>true,
        "result"=>"No user with this email",
    ];
    return json_encode($result);
});

$app->post('/api/appstore/verify_purchase', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');

	$email = $app['request']->get('email');
	$purchaseID = $app['request']->get('purchaseID');

	$user = $app["User"]->getUserByAppStorePurchaseId($purchaseID);
	if ($user) {
		if ($user[0]['email'] == $email) {
			$result = [
		        "error"=>true,
		        "result"=>"user already bought a subscription",
		    ];
		    return json_encode($result);
		}
		$result = [
	        "error"=>true,
	        "result"=>"This apple id is used for another account",
	    ];
	    return json_encode($result);
	}

	$app_store_api = new \yanlongli\AppStoreServerApi\AppStoreServerApi(
    	APP_STORE_ENVIRONMENT,
	    APP_STORE_API_KEY_ID,
	    file_get_contents(__DIR__ . APP_STORE_API_KEY),
	    APP_STORE_ISSUER_ID,
	    APP_STORE_BUNDLE_ID,
	);

	$data = $app_store_api->subscriptions(strval($purchaseID), APP_STORE_BUNDLE_ID);
	$expiresDate = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->expiresDate;
	$purchaseID = $data->data[0]->lastTransactions[0]->signedTransactionInfo->payload->originalTransactionId;

	if ($expiresDate) {
		$user = $app["User"]->getUserByEmail($email);
		if ($user) {
			$user = $user[0];
			if (time() < $expiresDate/1000) {
				$fields = [
					"isPremium"=>1,
					"subscriptionEndDate"=> date("Y-m-d H:i:s", $expiresDate/1000),
					"appStorePurchaseId"=>$purchaseID,
				];
				$app["User"]->updateUser($fields, $user["id"]);
				$result = [
			        "error"=>false,
			        "result"=>"subscription added successfully",
			    ];
			    return json_encode($result);
			}
			$fields = [
				"isPremium"=>0,
				"subscriptionEndDate"=> null,
				"appStorePurchaseId"=>null,
			];
			$app["User"]->updateUser($fields, $user["id"]);
			$result = [
		        "error"=>true,
		        "result"=>"subscription is expired",
		    ];
		    return json_encode($result);
		}
	}
	
	$result = [
        "error"=>true,
        "result"=>"unexpected error occured",
    ];
    return json_encode($result);
});

$app->post('/api/store/test', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');

    $app_store_api = new \yanlongli\AppStoreServerApi\AppStoreServerApi(
    	APP_STORE_ENVIRONMENT,
	    APP_STORE_API_KEY_ID,
	    file_get_contents(__DIR__ . APP_STORE_API_KEY),
	    APP_STORE_ISSUER_ID,
	    APP_STORE_BUNDLE_ID,
	);

	// $data = $app_store_api->subscriptions('2000000132438057', APP_STORE_BUNDLE_ID);
	$data = $app_store_api->subscriptions('2000000133864621', APP_STORE_BUNDLE_ID);
	// $data = $app_store_api->history('2000000132438057');

	
	// $data = file_get_contents(__DIR__ . APP_STORE_API_KEY);
	
	$result = [
        "error"=>false,
        "result"=>$data,
    ];
    return json_encode($result);
});










