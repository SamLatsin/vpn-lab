<?php

$app->post('/api/sign-in', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
	$email = clearText($app['request']->get('email'));
	$password = clearText($app['request']->get('password'));
	$user = $app['User']->getUserByEmail($email);
	if ($user) {
		if (md5($password) == $user[0]['password']) {
			$result = [
		        "error"=>false,
		        "result"=> [
		        	"email" => $user[0]['email'],
		        	"token" => $user[0]['token'],
		        	"isPremium"=> $user[0]['isPremium'],
		        	"subscriptionEndDate"=> $user[0]["subscriptionEndDate"],
		    	],
		    ];
		    return json_encode($result);
		}
		$result = [
	        "error"=>true,
	        "result"=> "Wrong password",
	    ];
	    return json_encode($result);
	}
	$result = [
        "error"=>true,
        "result"=> "No user with this email",
    ];
    return json_encode($result);
});

$app->post('/api/sign-up', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
	$email = clearText($app['request']->get('email'));
	$password = clearText($app['request']->get('password'));
	$token = md5($email.microtime(true));
	$fields = [
        'email'=>$email,
        'password'=>md5($password),
        'token'=>$token,
    ];
    $user = $app['User']->getUserByEmail($email);
    if ($user) {
    	$result = [
	        "error"=>true,
	        "result"=> "This email is already in use",
	    ];
	    return json_encode($result);
    }
    $res = $app['User']->insertUser($fields);
    // send email
	$result = [
        "error"=>false,
        "result"=> true,
    ];
    return json_encode($result);
});

$app->post('/api/change-password', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $email = clearText($app['request']->get('email'));
    $code = clearText($app['request']->get('code'));
    $password = clearText($app['request']->get('password'));
	$user = $app['User']->getUserByEmail($email);
	if ($user) {
		if ($user[0]['verificationCode'] == null) {
			$result = [
		        "error"=>true,
		        "result"=> "Account isn't restoring",
		    ];
		    return json_encode($result);
		}
		if ($code == $user[0]['verificationCode']) {
			$fields = [
				'verificationCode'=>null,
				'password'=>md5($password),
			];
			$app['User']->updateUser($fields, $user[0]['id']);
			$result = [
		        "error"=>false,
		        "result"=> true,
		    ];
		    return json_encode($result);
		}
		$result = [
	        "error"=>true,
	        "result"=> "Wrong code",
	    ];
	    return json_encode($result);
	}
	$result = [
        "error"=>true,
        "result"=> "No user with this email",
    ];
    return json_encode($result);
});

$app->post('/api/send-verification-code', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $email = clearText($app['request']->get('email'));
	$user = $app['User']->getUserByEmail($email);
	if ($user) {
		$code = random_int(100000, 999999);
		$fields = [
			'verificationCode'=>$code,
			'verificationCodeExpiration'=>date('Y-m-d H:i:s', time() + 1800),
		];
		$app['User']->updateUser($fields, $user[0]['id']);
		// send code
		sendAutentificationCode($email, $code);
		$result = [
	        "error"=>false,
	        "result"=> true,
	    ];
	    return json_encode($result);
	}
	$result = [
        "error"=>true,
        "result"=> "No user with this email",
    ];
    return json_encode($result);
});

$app->post('/api/check-verification-code', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $email = clearText($app['request']->get('email'));
    $code = clearText($app['request']->get('code'));
	$user = $app['User']->getUserByEmail($email);
	if ($user) {
		if ($user[0]['verificationCode'] == null) {
			$result = [
		        "error"=>true,
		        "result"=> "Account isn't restoring",
		    ];
		    return json_encode($result);
		}
		if ($code == $user[0]['verificationCode']) {
			$result = [
		        "error"=>false,
		        "result"=> true,
		    ];
		    return json_encode($result);
		}
		$result = [
	        "error"=>true,
	        "result"=> "Wrong code",
	    ];
	    return json_encode($result);
	}
	$result = [
        "error"=>true,
        "result"=> "No user with this email",
    ];
    return json_encode($result);
});

$app->post('/api/is-token-valid', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $token = clearText($app['request']->get('token'));
	$user = $app['User']->getUserByToken($token);
	if ($user) {
		$result = [
	        "error"=>false,
	        "result"=> [
	        	"email" => $user[0]['email'],
	        	"token" => $user[0]['token'],
	        	"isPremium"=> $user[0]['isPremium'],
	        	"subscriptionEndDate"=> $user[0]["subscriptionEndDate"],
	    	],
	    ];
	    return json_encode($result);
	}
	$result = [
        "error"=>false,
        "result"=> false,
    ];
    return json_encode($result);
});

$app->post('/cron/check-code-timeout', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $app['User']->removeVerificationCodes();

	$result = [
        "error"=>false,
        "result"=> true,
    ];
    return json_encode($result);
});

$app->post('/cron/check-premium-timeout', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $app['User']->removeSubscription();

	$result = [
        "error"=>false,
        "result"=> true,
    ];
    return json_encode($result);
});




