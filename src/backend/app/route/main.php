<?php
use VPN\App;

function pageNotFound($app) {
    header("HTTP/1.0 404 Not Found");
    header('Content-Type: application/json; charset=utf-8');
    $result = [
      'error'=>true,
      'status'=>'404',
    ];
    return json_encode($result);
}

$app->notFound(function () use ($app) {
    header("HTTP/1.0 404 Not Found");
    header('Content-Type: application/json; charset=utf-8');
    $result = [
      'error'=>true,
      'status'=>'404',
    ];
    return json_encode($result);
});
 
$app->get('/', function () use ($app) {
    $result = [
      'error'=>false,
      'result'=>'Welcome to REST'
    ];
    header('Content-Type: application/json; charset=utf-8');
    return json_encode($result);
});