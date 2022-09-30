<?php

use Phalcon\Autoload\Loader;
use Phalcon\Mvc\Micro;
use Phalcon\Di\FactoryDefault;
use Phalcon\Db\Adapter\Pdo\Mysql as PdoMysql;
use Phalcon\Mvc\View;
use Phalcon\Mvc\View\Engine\Volt as VoltEngine;

$loader = new Loader();
$loader->setNamespaces([
    'MyApp\Models' => __DIR__ . '/models/',
    'MyApp\Controllers' => __DIR__ . '/controllers/',
]);

$loader->register();
$container = new FactoryDefault();

$container->set('db',function () {
    return new PdoMysql([
        'host'     => 'localhost',
        'username' => 'username',
        'password' => 'password',
        'dbname'   => 'vpn-main',
    ]);
});

$container->set('view', function (){
    $view = new View();
    $view->setViewsDir(__DIR__ . '/../templates');
    $view->registerEngines(array(
        '.html' => function ($view){

                $volt = new VoltEngine($view, $container);

                $volt->setOptions([
                   'always'=> true,
                   'extension'=>'.volt',
                ]);
                return $volt;
            },
        '.phtml' => 'Phalcon\Mvc\View\Engine\Php'
    ));

    return $view;
}, true);
 
$app = new Micro($container);
$app["request"] = new \Phalcon\Http\Request();
require_once __DIR__.'/route/load.php';

try {
    $app->handle($_SERVER["REQUEST_URI"]);
} catch (Exception $e) {
    echo $e->getMessage();
} 
