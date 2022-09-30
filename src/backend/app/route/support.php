<?php

$app->get('/support', function () use ($app) {
    return $app['view']->render('pages','support/support',[]);
});

$app->post('/support/send_question', function () use ($app) {
	$name = $app['request']->get('name');
	$email = $app['request']->get('email');
	$topic = $app['request']->get('topic');
	$text = $app['request']->get('text');
	$fields = [
		"name"=>$name,
		"email"=>$email,
		"topic"=>$topic,
		"text"=>$text,
	];
	$app["Support"]->insertSupport($fields);
	return $app->response->redirect("/support/thanks");
});

$app->get('/support/thanks', function () use ($app) {
    return $app['view']->render('pages','support/thanks',[]);
});